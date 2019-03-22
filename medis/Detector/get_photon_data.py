"""Top level code that takes a atmosphere phase map and propagates a wavefront through the system"""

import os
import numpy as np
import traceback
import multiprocessing
import glob
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

def gen_timeseries(inqueue, photon_table_queue, spectralcubes_queue, xxx_todo_changeme):
    """
    generates observation sequence by calling optics_propagate in time series

    is the time loop wrapper for optics_propagate
    this is where the observation sequence is generated (timeseries of observations by the detector)
    thus, where the detector observes the wavefront created by optics_propagate (for MKIDs, the probability distribution)

    :param inqueue: time index for parallelization (used by multiprocess)
    :param photon_table_queue: photon table (list of photon packets) in the multiprocessing format
    :param spectralcube_queue: series of intensity images (spectral image cube) in the multiprocessing format
    :param xxx_todo_changeme:
    :return:
    """
    # TODO change this name
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
            spectralcube, _ = prop_run('medis.Telescope.optics_propagate', 1, ap.grid_size, PASSVALUE=kwargs, VERBOSE=False, PHASE_OFFSET=1)

            if tp.detector == 'ideal':
                image = np.sum(spectralcube, axis=0)
                vmin = np.min(spectralcube)*10
                # cube = ideal.assign_calibtime(spectralcube,PASSVALUE['iter'])
                # cube = rawImageIO.arange_into_cube(packets, value='phase')
                # rawImageIO.make_phase_map(cube, plot=True)
                # return ''
            elif tp.detector == 'H2RG':

                image = np.sum(spectralcube, axis=0)
                vmin = np.min(spectralcube)*10
            elif tp.detector == 'MKIDs':
                packets = read.get_packets(spectralcube, t, dp, mp)

                if sp.show_wframe or sp.show_cube or sp.return_cube:
                    cube = pipe.arange_into_cube(packets, (mp.array_size[0], mp.array_size[1]))
                    if mp.remove_close:
                        timecube = read.remove_close_photons(cube)

                if sp.show_wframe:
                    image = pipe.make_intensity_map(cube, (mp.array_size[0], mp.array_size[1]))

                # Interpolating spectral cube from ap.nwsamp discreet wavelengths
                if sp.show_cube or sp.return_cube:
                    spectralcube = pipe.make_datacube(cube, (mp.array_size[0], mp.array_size[1], ap.w_bins))


                if sp.save_obs:
                    command = read.get_obs_command(packets,t)
                    photon_table_queue.put(command)

                vmin = 0.9

            if sp.show_wframe:
                dprint((sp.show_wframe, sp.show_wframe == 'continuous'))
                quicklook_im(image, logAmp=True, show=sp.show_wframe, vmin=vmin)

            if sp.show_cube:
                view_datacube(spectralcube, logAmp=True, vmin=vmin)

            if sp.return_cube:
                spectralcubes_queue.put((t,spectralcube))

        now = time.time()
        elapsed = float(now - start) / 60.
        each_iter = float(elapsed) / (it + 1)

        dprint(f'{elapsed:.2f} minutes elapsed, each time step took {each_iter:.2f} minutes') #* ap.numframes/sp.num_processes TODO change to log #

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

def run_medis():
    """
    main script to organize calls to various aspects of the simulation

    initialize different sub-processes, such as atmosphere and aberration maps, MKID device parameters
    sets up the multiprocessing features
    returns the observation sequence created by gen_timeseries

    :return: obs_sequence
    """
    # Printing Params
    dprint("Checking Params Info-print params from here (turn on/off)")
    # TODO change this to a logging function
    # for param in [ap, cp, tp, mp, sp, iop]:
    #     print('\n', param)
    #     pprint(param.__dict__)

    import time
    begin = time.time()
    print('********** Taking Obs Data ***********')

    try:
        multiprocessing.set_start_method('spawn')
    except RuntimeError:
        pass

    # initialize atmosphere
    print("Atmosdir = %s " % iop.atmosdir)
    if tp.use_atmos and glob.glob(iop.atmosdir + '/*.fits') == []:
        dprint("It looks like you don't have an atmospheric maps. You can either"
                    "get them from Rupert or generate them yourself with caos. Removing exit()")
        exit()
        dprint("Making New Atmosphere Model")
        caos.make_idl_params()
        caos.generate_maps()

    # initialize telescope
    if (tp.aber_params['QuasiStatic'] is True) and glob.glob(iop.aberdir + 'quasi/*.fits') == []:
        aber.generate_maps()
        if tp.aber_params['NCPA']:
            aber.generate_maps(Loc='NCPA')

    # if tp.servo_error:
    #     aber.createObjMapsEmpty()

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

    # initialize MKIDs
    if tp.detector == 'MKIDs' and not os.path.isfile(iop.device_params):
        MKIDs.initialize()

    photon_table_queue = multiprocessing.Queue()
    inqueue = multiprocessing.Queue()
    spectralcubes_queue = multiprocessing.Queue()
    jobs = []

    if sp.save_obs and tp.detector == 'MKIDs':
        proc = multiprocessing.Process(target=read.handle_output, args=(photon_table_queue, iop.obsfile))
        proc.start()

    if tp.detector == 'MKIDs':
        obs_sequence = np.zeros((ap.numframes, ap.w_bins, mp.array_size[1], mp.array_size[0]))
    else:
        obs_sequence = np.zeros((ap.numframes, ap.w_bins, ap.grid_size, ap.grid_size))

    # Sending Queues to gen_timeseries
    for i in range(sp.num_processes):
        p = multiprocessing.Process(target=gen_timeseries, args=(inqueue, photon_table_queue, spectralcubes_queue,(tp,ap,sp,iop,cp,mp)))
        jobs.append(p)
        p.start()

    if tp.quick_ao:

        for t in range(ap.startframe, ap.startframe + ap.numframes):
            inqueue.put(t)

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
            spectralcube = spectralcubes_queue.get()
            obs_sequence[spectralcube[0]-ap.startframe] = spectralcube[1]  # should be in the right order now because of the identifier

    for i, p in enumerate(jobs):
        p.join()

    photon_table_queue.put(None)
    spectralcubes_queue.put(None)
    if sp.save_obs and tp.detector == 'MKIDs':
        proc.join()
    obs_sequence = np.array(obs_sequence)


    dprint('MEDIS Data Run Completed')
    finish = time.time()
    if sp.timing is True:
        print(f'Time elapsed: {(finish-begin)/60:.2f} minutes')
    print('**************************************')
    return obs_sequence


if __name__ == '__main__':
    sp.timing = True
    run_medis()


