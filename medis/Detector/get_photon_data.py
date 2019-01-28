'''Top level code that takes a atmosphere phase map and propagates a wavefront through the system'''

import sys, os
# sys.path.append('D:/dodkins/MEDIS/MEDIS')
# sys.path.append('D:/dodkins/MEDIS/MEDIS/Telescope')


# sys.path.append(os.environ['MEDIS_DIR'])
# for p in sys.path: print(p)
# sys.path.append(os.path.join(os.environ['MEDIS_DIR'],'Telescope'))

import proper
print(proper.__file__)
import numpy as np
np.set_printoptions(threshold=np.inf)

import traceback
import medis.Utils.colormaps as cmaps
from medis.Utils.plot_tools import quicklook_im, view_datacube
from medis.Utils.misc import dprint
# import medis.Utils.misc as misc
from medis.params import ap,cp,tp,mp,sp,iop,dp
# import medis.Detector.analysis as ana
import medis.Detector.MKIDs as MKIDs
import medis.Detector.pipeline as pipe
import medis.Telescope.run_system as run_system
import medis.Detector.readout as read #import Simulation, handle_output
import medis.Telescope.telescope_dm as tdm
import medis.Atmosphere.caos as caos
from pprint import pprint
import random
import pickle as pickle
import time
# def run(verbose=False):

import multiprocessing


import glob

# from medis.params import ap, cp, tp, mp, sp
# print tp.occulter_type

sentinel = None

# for t in range(cp.numframes):
#     print 'propagating frame:', t
# def mp_worker(t):
#     kwargs = {'iter': t, 'atmos_map': cp.atmosdir + 'telz%f.fits' % (t * mp.frame_time)}
#     datacube, _ = proper.prop_run("run_system", 1, tp.grid_size, PASSVALUE=kwargs, VERBOSE=False, PHASE_OFFSET=1)
#     # ana.make_SNR_plot(datacube)
#     return datacube

# def random_walk(index, values):
#     if index > 0 and index < len(values) - 1:
#         print 'index in mid range'
#         move = int(np.random.random() * 3) - 1
#     elif index == 0:
#         print 'index at lower boundary'
#         move = int(np.random.random() * 2)
#     else:
#         print 'index at upper boundary'
#         move = int(np.random.random() * 2) - 1
#     index += move
#     print index
#     return index
# print 'line 54', tp.detector
# def Simulation(inqueue, output, datacubes, (dp,cp,tp,ap,sp,iop)):
def Simulation(inqueue, output, datacubes, xxx_todo_changeme):
# def Simulation(inqueue, output, (dp, cp)):
    (tp,ap,sp,iop,cp,mp) = xxx_todo_changeme

    # import matplotlib.pylab as plt
    # plt.plot(list(range(10)))
    # plt.show()
    # plt.show(block=True)

    try:

        if tp.detector == 'MKIDs':
            with open(iop.device_params, 'rb') as handle:
                dp = pickle.load(handle)

        # with open(iop.NCPA_meas, 'rb') as handle:
        #     tp.Imaps, tp.phase_map = pickle.load(handle)
        # hypercube = []
        start = time.time()

        for it, t in enumerate(iter(inqueue.get,sentinel)):

            if cp.vary_r0:
                # # print cp.r0s, cp.r0s_idx
                # cp.r0s_idx = caos.random_r0walk(cp.r0s_idx, cp.r0s)
                # # print cp.r0s_idx
                # r0 = cp.r0s[cp.r0s_idx]
                element = int(np.random.random()*len(cp.r0s))
                # cp.r0s_idx = element
                r0 = cp.r0s[element]
            else:
                r0 = cp.r0s # this is a scalar in this instance
            # dprint((t, r0, 'r0', tp.rot_rate))
            atmos_map = cp.atmosdir + 'telz%f_%1.3f.fits' % (t * cp.frame_time, r0) #t *
            # dprint((atmos_map, cp.atmosdir))
            kwargs = {'iter': t, 'atmos_map': atmos_map, 'params': [ap,tp,iop,sp]}
            # dprint(tp.occulter_type)
            datacube, _ = proper.prop_run("medis.Telescope.run_system", 1, tp.grid_size, PASSVALUE=kwargs, VERBOSE=False, PHASE_OFFSET=1)
            # view_datacube(datacube, logAmp=True)
            # print np.sum(datacube,axis=(1,2))

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

                # dprint(dp.__dict__)
                # print np.sum(datacube, axis=(1,2)), 'sum'
                packets = read.get_packets(datacube, t, dp, mp)
                # dprint(packets.shape)
                # plt.hist(packets[:,1] - packets[:,0])
                # plt.show()

                if sp.show_wframe or sp.show_cube or sp.return_cube:
                    cube = pipe.arange_into_cube(packets, (mp.array_size[0], mp.array_size[1]))
                    # # if mp.remove_close:
                    # #     timecube = read.remove_close_photons(cube)

                if sp.show_wframe:
                    image = pipe.make_intensity_map(cube, (mp.array_size[0], mp.array_size[1]))

                # # # packets = rawImageIO.arange_into_packets(cube)
                # # # wfo = read.convert_to_wfo(image, wfo)
                if sp.show_cube or sp.return_cube:
                    datacube = pipe.make_datacube(cube, (mp.array_size[0], mp.array_size[1], tp.w_bins))
                    # dprint(datacube.shape)
                    # datacube = datacube[:,:mp.array_size[0],:mp.array_size[0]]
                    # dprint(datacube.shape)
                # print packets.shape
                if sp.save_obs:
                    command = read.get_obs_command(packets,t)
                    output.put(command)

                vmin = 0.9
                    # return command
                # else:
                #     return ''
            # hypercube.append(datacube)

            if sp.show_wframe:
                quicklook_im(image, logAmp=True, show=sp.show_wframe, vmin=vmin)
                # dprint(np.sum(image))
            if sp.show_cube:
                # import matplotlib.pyplot as plt
                # plt.plot(np.sum(datacube,axis=(1,2)))
                # plt.show()
                view_datacube(datacube, logAmp=True, vmin=vmin)

            if sp.return_cube:
                datacubes.put((t,datacube))
            # dprint('lol')
            # return datacube
            now = time.time()
            elapsed = float(now - start) / 60.
            each_iter = float(elapsed) / (it + 1)
            # print ap.numframes, each_iter
            dprint('%i elapsed of %i mins' % (elapsed, each_iter * ap.numframes/sp.num_processes))
    except Exception as e:
        # print ' **** Caught Exception ****'
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
    dprint(cp.atmosdir)
    if tp.use_atmos and glob.glob(cp.atmosdir + '*.fits') == []:
        caos.make_idl_params()
        caos.generate_maps()

    # initialize telescope
    # if (tp.CPA_type == 'Quasi' or tp.NCPA_type == 'Quasi') and glob.glob(iop.aberdir + '*.fits') == []:
    if (tp.aber_params['QuasiStatic'] == True) and glob.glob(iop.aberdir + 'quasi/*.fits') == []:
        tdm.generate_maps2()
        if tp.aber_params['NCPA']:
            tdm.generate_maps2(Loc='NCPA')

    # if tp.servo_error:
    #     tdm.createObjMapsEmpty()

    tdm.initialize_CPA_meas()

    if tp.active_null:
        tdm.initialize_NCPA_meas()

    print(cp.atmosdir)
    caos.get_r0s()
    print(cp.r0s)
    # cp.r0s = cp.r0s[5:]
    # plt.hist(cp.r0s)
    # plt.show()

    if cp.vary_r0:
        # cp.r0s_idx = int(len(cp.r0s) / 2) # find the median location for r0 initialization later
        cp.r0s_selected = []
        for f in range(ap.numframes):
            cp.r0s_selected.append(random.choice(cp.r0s))
    else:
        cp.r0s = cp.r0s[cp.r0s_idx]  # the r0 at the index cp.r0s_idx in params will be used throughout

    # import medis.Utils.misc as misc
    # misc.debug_program()
    # plt.hist(cp.r0s_selected)
    # plt.show()

    # print 'line 139', tp.detector
    # initialize detector
    if tp.detector == 'MKIDs' and not os.path.isfile(iop.device_params):
        MKIDs.initialize()
        # dp.__dict__ = dp_init.__dict__


    # else:
    #     dp = None
    # print ap.companion
    # if not ap.companion:
    #     dprint('yes')
    #     ap.contrast= []
    #     ap.lods = []

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
    # print cp.numframes
    if tp.detector == 'MKIDs':
        hypercube = np.zeros((ap.numframes, tp.w_bins, mp.array_size[1], mp.array_size[0]))
    else:
        hypercube = np.zeros((ap.numframes,tp.w_bins,tp.grid_size,tp.grid_size))
    # hypercube = []

    dprint(sp.num_processes)
    for i in range(sp.num_processes):
        dprint(i)
        p = multiprocessing.Process(target=Simulation, args=(inqueue, output, datacubes,(tp,ap,sp,iop,cp,mp)))
        # p = multiprocessing.Process(target=Simulation, args=(inqueue, output, (dp,cp)))
        jobs.append(p)
        p.start()
        # print 'i', i

    # rollout = np.zeros((ap.numframes))
    # delay_inds = np.arange(4)*4 + 3
    # rollout[delay_inds] = 10
    # # print rollout
    if tp.quick_ao:

        for t in range(ap.startframe, ap.startframe + ap.numframes):
            inqueue.put(t)

            # dprint('lol')
    else:
        print('If the code has hung here it probably means it cant read the CPA file at some iter')
        for t in range(ap.startframe, ap.startframe+ap.numframes):
            # # print rollout[t]
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
                    print(t)
            else:
                with open(iop.NCPA_meas, 'rb') as handle:
                    _,_, iter = pickle.load(handle)
                # print t, iter, 't, iter'
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
            # dprint('lol')
            # if sp.return_cube:
            #     hypercube.append(datacubes.get())#might not be in the correct order. Will probably have to add an identifier like with saveobs
            #     # hypercube[t] = datacubes.get()  # might not be in the correct order. Will probably have to add an identifier like with saveobs
            # print 't', t
    for i in range(sp.num_processes):
        # Send the sentinal to tell Simulation to end
        inqueue.put(sentinel)
        # print 'second i', i
        # print 'line 205', tp.detector
    if sp.return_cube:
        for t in range(ap.numframes):
            dprint(t)
            datacube = datacubes.get()
            dprint(np.shape(datacube[1]))
            dprint(hypercube.shape)
            hypercube[datacube[0]-ap.startframe] = datacube[1]#should be in the right order now because of the identifier
            # quicklook_im(hypercube[t,0])
            # hypercube.append(datacubes.get())
    for i, p in enumerate(jobs):
        p.join()
        # print 'third i', i
    output.put(None)
    datacubes.put(None)
    if sp.save_obs and tp.detector=='MKIDs':
        proc.join()
    hypercube = np.array(hypercube)
    # pool = multiprocessing.Pool(sp.num_processes)
    # for t in range(cp.numframes):
    #     misc.progressBar(value=t, endvalue=cp.numframes)
    #     pool.apply_async(Simulation, (t, dp), callback=read.handle_output)
    # pool.close()
    # pool.join()

    print('Done')
    # datacubes = p.map(mp_worker, range(cp.numframes))
    return hypercube

def take_obs_data():
    import time
    # print os.path.isdir(mp.datadir)
    if not os.path.isdir(iop.datadir):
        os.mkdir(iop.datadir)
    print('********** Taking Obs Data ***********')
    begin = time.time()
    hypercube = run()
    end = time.time()
    print('Time elapsed: ', end - begin)
    print('*************************************')
    return hypercube

if __name__ == '__main__':
    import time
    # t = np.arange(cp.numframes)
    begin = time.time()
    run()
    end = time.time()
    print(end-begin)

