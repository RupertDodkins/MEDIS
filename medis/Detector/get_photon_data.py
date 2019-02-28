"""Top level code that takes a atmosphere phase map and propagates a wavefront through the system"""

import os
import numpy as np
import traceback
import multiprocessing
import glob
from pprint import pprint
import random
import pickle as pickle
import time
from proper_mod import prop_run
from medis.Utils.plot_tools import quicklook_im, view_datacube
from medis.Utils.misc import dprint
from medis.params import ap,cp,tp,mp,sp,iop,dp
import medis.Detector.MKIDs as MKIDs
import medis.Detector.pipeline as pipe
import medis.Detector.readout as read
import medis.Telescope.aberrations as aber
import medis.Atmosphere.caos as caos

sentinel = None

def Simulation(inqueue, output, datacubes, xxx_todo_changeme):
    (tp,ap,sp,iop,cp,mp) = xxx_todo_changeme

    try:

        if tp.detector == 'MKIDs':
            with open(iop.device_params, 'rb') as handle:
                dp = pickle.load(handle)

        start = time.time()

        for it, t in enumerate(iter(inqueue.get, sentinel)):

            if cp.vary_r0:
                # cp.r0s_idx = caos.random_r0walk(cp.r0s_idx, cp.r0s)
                # cp.r0s_idx = element
                element = int(np.random.random()*len(cp.r0s))

                r0 = cp.r0s[element]
            else:
                r0 = cp.r0s # this is a scalar in this instance

            atmos_map = iop.atmosdir + '/telz%f_%1.3f.fits' % (t * cp.frame_time, r0) #t *
            kwargs = {'iter': t, 'atmos_map': atmos_map, 'params': [ap, tp, iop, sp]}
            datacube, _ = prop_run('medis.Telescope.run_system', 1, tp.grid_size, PASSVALUE=kwargs, VERBOSE=False, PHASE_OFFSET=1)

            if tp.detector == 'ideal':
                image = np.sum(datacube, axis=0)
                vmin = np.min(datacube)*10
                # cube = ideal.assign_calibtime(datacube,PASSVALUE['iter'])
                # cube = rawImageIO.arange_into_cube(packets, value='phase')
                # rawImageIO.make_phase_map(cube, plot=True)
                # return ''
            elif tp.detector == 'H2RG':

                image = np.sum(datacube, axis=0)
                vmin = np.min(datacube)*10
            elif tp.detector == 'MKIDs':

                packets = read.get_packets(datacube, t, dp, mp)

                if sp.show_wframe or sp.show_cube or sp.return_cube:
                    cube = pipe.arange_into_cube(packets, (mp.array_size[0], mp.array_size[1]))
                    if mp.remove_close:
                        timecube = read.remove_close_photons(cube)

                if sp.show_wframe:
                    image = pipe.make_intensity_map(cube, (mp.array_size[0], mp.array_size[1]))

                if sp.show_cube or sp.return_cube:
                    datacube = pipe.make_datacube(cube, (mp.array_size[0], mp.array_size[1], tp.w_bins))


                if sp.save_obs:
                    command = read.get_obs_command(packets,t)
                    output.put(command)

                vmin = 0.9

            if sp.show_wframe:
                quicklook_im(image, logAmp=True, show=sp.show_wframe, vmin=vmin)

            if sp.show_cube:
                view_datacube(datacube, logAmp=True, vmin=vmin)

            if sp.return_cube:
                datacubes.put((t,datacube))

            now = time.time()
            elapsed = float(now - start) / 60.
            each_iter = float(elapsed) / (it + 1)

            dprint('%i elapsed of %i mins' % (elapsed, each_iter * ap.numframes/sp.num_processes)) #TODO change to log

    except Exception as e:
        traceback.print_exc()
        # raise e
        pass

def wait_until(somepredicate, timeout, period=0.25, *args, **kwargs):
  mustend = time.time() + timeout
  while time.time() < mustend:
    if somepredicate(*args, **kwargs): return True
    time.sleep(period)
  return False

def run():
    try:
        multiprocessing.set_start_method('spawn')
    except RuntimeError:
        pass

    # initialize atmosphere
    dprint("Atmosdir = %s " % iop.atmosdir)
    if tp.use_atmos and glob.glob(iop.atmosdir + '/*.fits') == []:
        print("It looks like you don't have an atmospheric maps. You can either"
              "get them from Rupert or generate them yourself with caos. Removing exit()")
        exit()
        print("Making New Atmosphere Model")
        caos.make_idl_params()
        caos.generate_maps()

    # initialize telescope
    if (tp.aber_params['QuasiStatic'] == True) and glob.glob(iop.aberdir + 'quasi/*.fits') == []:
        aber.generate_maps()
        if tp.aber_params['NCPA']:
            aber.generate_maps(Loc='NCPA')

    # if tp.servo_error:
    #     aber.createObjMapsEmpty()

    if tp.aber_params['CPA'] or tp.aber_params['NCPA']:
        if not os.path.isdir(iop.aberdir):
            os.makedirs(iop.aberdir, exist_ok=True)  # Only works in Python >= 3.2
    aber.initialize_CPA_meas()

    if tp.active_null:
        aber.initialize_NCPA_meas()

    caos.get_r0s()

    if cp.vary_r0:
        cp.r0s_selected = []
        for f in range(ap.numframes):
            cp.r0s_selected.append(random.choice(cp.r0s))
    else:
        cp.r0s = cp.r0s[cp.r0s_idx]  # the r0 at the index cp.r0s_idx in params will be used throughout

    # initialize detector
    if tp.detector == 'MKIDs' and not os.path.isfile(iop.device_params):
        MKIDs.initialize()

    for param in [ap, cp, tp, mp, sp, iop]:
        print('\n', param)
        pprint(param.__dict__)
    tp.check_args()

    output = multiprocessing.Queue()
    inqueue = multiprocessing.Queue()
    datacubes = multiprocessing.Queue()
    jobs = []

    if sp.save_obs and tp.detector=='MKIDs':
        proc = multiprocessing.Process(target=read.handle_output, args=(output, iop.obsfile))
        proc.start()

    if tp.detector == 'MKIDs':
        hypercube = np.zeros((ap.numframes, tp.w_bins, mp.array_size[1], mp.array_size[0]))
    else:
        hypercube = np.zeros((ap.numframes, tp.w_bins, tp.grid_size, tp.grid_size))

    for i in range(sp.num_processes):
        p = multiprocessing.Process(target=Simulation, args=(inqueue, output, datacubes,(tp,ap,sp,iop,cp,mp)))
        jobs.append(p)
        p.start()

    if tp.quick_ao:

        for t in range(ap.startframe, ap.startframe + ap.numframes):
            inqueue.put(t)

            # dprint('lol')
    else:
        dprint('If the code has hung here it probably means it cant read the CPA file at some iter')
        for t in range(ap.startframe, ap.startframe+ap.numframes):
            # time.sleep(rollout[t])
            print(t)
            if not tp.active_null:
                with open(iop.CPA_meas, 'rb') as handle:
                    _, iters = pickle.load(handle)
                # print t, iter, 't, iter'
                print(iters, 'iters')
                while iters[0] + ap.startframe < t:
                    time.sleep(0.1)
                    print('looping', t)
                    try:
                        with open(iop.CPA_meas, 'rb') as handle:
                            _, iters = pickle.load(handle)
                        iter = iters[0]
                    # sys.stdout.write("\rWaiting for aberration measurements...\n")
                    # sys.stdout.flush()
                    except EOFError:
                        print('Errored')
            else:
                with open(iop.NCPA_meas, 'rb') as handle:
                    _,_, iter = pickle.load(handle)
                while iter < t:
                    time.sleep(0.1)
                    try:
                        with open(iop.NCPA_meas, 'rb') as handle:
                            _,_, iter = pickle.load(handle)
                        # sys.stdout.write("\rWaiting for aberration measurements...\n")
                        # sys.stdout.flush()
                    except EOFError:
                        print('Errored')
            # if t in delay_inds:
            #     with open(iop.NCPA_meas, 'rb') as handle:
            #         _, _, iter = pickle.load(handle)
            #     print iter, t
            #     while iter != t:
            #         with open(iop.NCPA_meas, 'rb') as handle:
            #             _, _, iter = pickle.load(handle)
            #     # wait_until()
            inqueue.put(t)

    for i in range(sp.num_processes):
        # Send the sentinal to tell Simulation to end
        inqueue.put(sentinel)
    if sp.return_cube:
        for t in range(ap.numframes):
            datacube = datacubes.get()
            hypercube[datacube[0]-ap.startframe] = datacube[1]#should be in the right order now because of the identifier

    for i, p in enumerate(jobs):
        p.join()

    output.put(None)
    datacubes.put(None)
    if sp.save_obs and tp.detector=='MKIDs':
        proc.join()
    hypercube = np.array(hypercube)

    dprint('Photon Data Run Completed')
    return hypercube

def take_obs_data():
    import time
    print('********** Taking Obs Data ***********')
    begin = time.time()
    hypercube = run()
    end = time.time()
    print('Time elapsed: ', end - begin)
    print('*************************************')
    return hypercube

if __name__ == '__main__':
    import time
    begin = time.time()
    run()
    end = time.time()
    print(end-begin)