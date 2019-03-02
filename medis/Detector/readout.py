'''This code makes the formats the photon data products'''
import numpy as np
import os
from copy import copy
# import glob
# import multiprocessing
import tables as pt
# import matplotlib.pyplot as plt
import pickle as pickle
from medis.params import ap, cp, tp, mp, iop, hp, sp
from . import MKIDs
import proper
import medis.Utils.misc as misc
from medis.Utils.plot_tools import view_datacube, loop_frames, quicklook_im
from . import temporal as temp
from . import spectral as spec
# import medis.Detector.readout as read
# import matplotlib.pyplot as plt
# from . import H2RG
from medis.Utils.misc import dprint


def get_packets(datacube, step, dp,mp):
    # print 'Detecting photons with an MKID array'

    # quicklook_im(dp.response_map)
    # quicklook_im(datacube)

    # dprint((mp.bad_pix, mp.R_mean))
    # if mp.bad_pix == True:
    #     datacube = MKIDs.remove_bad(datacube, dp.response_map)

    # quicklook_im(dp.response_map)
    # view_datacube(datacube)
    # dprint((datacube.shape, np.sum(datacube)))
    # loop_frames(datacube)
    if tp.pix_shift is not None:

        moves = np.shape(tp.pix_shift)[0]

        iteration = step % moves
        datacube = np.roll(np.roll(datacube, tp.pix_shift[iteration][0], 1),
                           tp.pix_shift[iteration][1], 2)

    if (mp.array_size != datacube[0].shape + np.array([1,1])).all():
        left = int(np.floor(float(tp.grid_size-mp.array_size[0])/2))
        right = int(np.ceil(float(tp.grid_size-mp.array_size[0])/2))
        top = int(np.floor(float(tp.grid_size-mp.array_size[1])/2))
        bottom = int(np.ceil(float(tp.grid_size-mp.array_size[1])/2))

        print(left, right, top, bottom)
        datacube = datacube[:,bottom:-top,left:-right]
    # loop_frames(datacube)
    # quicklook_im(datacube[2], logAmp=False, vmax = 0.001, vmin=1e-8)


    if mp.respons_var:
        datacube *= dp.response_map[:datacube.shape[1],:datacube.shape[1]]
    # if mp.hot_pix:
    #     datacube = MKIDs.add_hot_pix(datacube, dp, step)


    num_events = int(ap.star_photons * ap.exposure_time * np.sum(datacube))
    dprint((num_events, ap.star_photons, np.sum(datacube), ap.exposure_time))
    if num_events * sp.num_processes > 1.0e9:
        print(num_events)
        print('Possibly too many photons for memory. Are you sure you want to do this? Remove exit() if so')
        exit()


    # if datacube.shape[2] != mp.array_size[0]-1:
    #     import scipy
    #     # datacube  = scipy.interpolate.interpn((np.arange(datacube.shape[0]),
    #     #                                        np.arange(datacube.shape[1]),
    #     #                                        np.arange(datacube.shape[2])), datacube, (np.arange(datacube.shape[0]),
    #     #                                                                                  np.arange(mp.array_size),
    #     #                                                                                  np.arange(mp.array_size)))
    #     # loop_frames(datacube)
    #     dprint((mp.array_size[0]-1)/datacube.shape[2])
    #     flux = np.sum(datacube)
    #     datacube = scipy.ndimage.zoom(datacube, (1, (mp.array_size[0]-1)/datacube.shape[2], (mp.array_size[0]-1)/datacube.shape[2]))
    #     datacube = np.abs(datacube)
    #     datacube = datacube*flux/np.sum(datacube)
        # loop_frames(datacube)

    photons = temp.sample_cube(datacube, num_events)
    # dprint((num_events, photons.shape))

    if mp.hot_pix:
        hot_photons = MKIDs.get_hot_packets(dp)
        photons = np.hstack((photons, hot_photons))
    photons = spec.calibrate_phase(photons)


    photons = temp.assign_calibtime(photons, step)

    # locs = []
    # locs = np.hstack((locs,np.where(np.logical_and(photons[2, :] == 32, photons[3, :] == 54))[0]))
    # locs = np.hstack((locs,np.where(np.logical_and(photons[2, :] == 33, photons[3, :] == 54))[0]))
    # locs = np.hstack((locs,np.where(np.logical_and(photons[2, :] == 34, photons[3, :] == 54))[0]))
    # locs = np.hstack((locs,np.where(np.logical_and(photons[2, :] == 32, photons[3, :] == 55))[0]))
    # locs = np.hstack((locs,np.where(np.logical_and(photons[2, :] == 33, photons[3, :] == 55))[0]))
    # locs = np.hstack((locs,np.where(np.logical_and(photons[2, :] == 34, photons[3, :] == 55))[0]))
    # locs = np.hstack((locs,np.where(np.logical_and(photons[2, :] == 32, photons[3, :] == 56))[0]))
    # locs = np.hstack((locs,np.where(np.logical_and(photons[2, :] == 33, photons[3, :] == 56))[0]))
    # locs = np.hstack((locs,np.where(np.logical_and(photons[2, :] == 34, photons[3, :] == 56))[0]))
    # locs = np.int_(locs)
    # bins = np.linspace(-100,-10,25)
    # fig, ax = plt.subplots()
    # ax.tick_params(direction='in', which='both', right=True, top=True, width=1, length=3)
    # # ax.tick_params(which='minor',length=2)
    # ax.set_xlabel('Phase (deg)')
    # ax.hist(photons[1,locs], bins=bins, alpha=0.5, label='Seed')
    # # plt.show()
    # # print photons[:,:5], np.shape(photons)

    # if mp.phase_background:
    #     pix_background = dp.basesDeg
    # else:
    #     pix_background = 0
    pix_phase = photons[1]
    if mp.phase_uncertainty:
        photons = MKIDs.apply_phase_distort_array(photons, dp.sigs)
    thresh = dp.basesDeg[np.int_(photons[3]),np.int_(photons[2])] < -1 * photons[1]
    # dprint('here')
    photons = photons[:,thresh]

    packets = np.transpose(photons)

    # packets=[]
    # for ip, photon in enumerate(photons.T):
    #     if ip%1e6 ==0: misc.progressBar(value = ip, endvalue=num_events)
    #
    #     # R = mp.Rs[int(photon[2]), int(photon[3])]
    #     if mp.phase_background:
    #         pix_background = dp.basesDeg[int(photon[3]), int(photon[2])]
    #     else:
    #         pix_background = 0
    #     # pix_background = MKIDs.get_phase_background(R, 1)
    #     pix_phase = photon[1]
    #     # if mp.respons_var:
    #     #     pix_phase *= dp.response_map[int(photon[2]), int(photon[3])]
    #     if mp.phase_uncertainty:
    #         pix_phase = MKIDs.apply_phase_distort(pix_phase, [int(photon[3]), int(photon[2])], dp.sigs)
    #     # print pix_response
    #     # pixId = np.arange(mp.total_pix).reshape(int(photon[1]), int(photon[2]))[int(photon[1]), int(photon[2])]
    #     # pixId = int(photon[1]) * mp.xnum + int(photon[2])
    #     # if pix_background + pix_phase < mp.threshold_phase:#photon[3]
    #     if pix_background < -1*pix_phase:# < mp.threshold_phase:#photon[3]
    #         #print 'photon detected'
    #         packet = [pix_background, pix_phase, photon[0], photon[3], photon[2]]
    #         # print packet
    #         packets.append(packet)
    #
    # packets = np.array(packets)


    # print packets[:5]
    # print packets[np.where(np.logical_and(packets[:,3] == 64, packets[:,4]==64)),1]
    # plt.hist(packets[np.where(np.logical_and(packets[:,3] == 32, packets[:,4]==54)),1][0])
    # plt.show()


    # phase_band = spec.phase_cal(tp.band)
    # # dprint(phase_band)
    # psamps = np.linspace(phase_band[0],phase_band[1],12)
    # # dprint(dp.sigs.shape)
    # # dprint(psamps)
    # p_widths = np.mean(dp.sigs[:,32:34,54:56], axis=(1,2))
    # # dprint(p_widths)
    # from distribution import gaussian2
    # ax.hist(packets[locs,1], bins=bins, alpha=0.5, label='Measured')
    # for ip, (psamp, p_width) in enumerate(zip(psamps,p_widths)):
    #     x = np.linspace(-100,-10,100)
    #     ax.plot(x, 2000*gaussian2(x,p_width,psamp), linestyle='--', c='#d62728', alpha=0.5, label='Spec. Res.')
    #     if ip == 0:
    #         ax.legend()
    # MEDIUM_SIZE = 17
    # plt.rc('font', size=MEDIUM_SIZE)  # controls default text sizes
    # plt.show()


    # # bins = np.linspace(phase_band[0], phase_band[1], tp.nwsamp+1)
    # band = phase_band[1] - phase_band[0]
    # bins = np.linspace(phase_band[0], phase_band[1], 10 + 1)
    # plt.hist(packets[:,1], bins=100)
    # plt.figure()
    # plt.hist(packets[:,1], bins=bins)
    # plt.plot(bins[:-1],np.histogram(packets[:,1], bins=bins)[0])
    # plt.show()
    dprint("Completed Readout Loop")
    return packets

# def make_packet(basesDeg, phases, timestamp, pixId, xCoord, yCoord):
# # def make_packet(loc,toa,p=80):
#     # '''If used alone assumes 100% QE '''
#     # packet = np.append(loc,[toa,p], axis=0)
#     # packet {'loc': loc, 'toa': toa, 'phase': p, 'bg', p/10}
#     packet = {'basesDeg':basesDeg, 'phases':phases, 'timestamp':timestamp, 'pixId':pixId, 'xCoord':xCoord, 'yCoord':yCoord}
#     return packet

# def detector(datacube, t):
#     if tp.detector == 'MKIDs':
#         packets = get_packets(datacube, t)
#         print np.shape(packets)
#
#         # if tp.save_obs:
#         #     write_obs(packets)
#         command = get_obs_command(packets)
#
#         if tp.show_wframe:
#             cube = pipe.arange_into_cube(packets)
#             # # if mp.remove_close:
#             # #     timecube = read.remove_close_photons(cube)
#             image = pipe.make_intensity_map(cube)
#             quicklook_im(image, logAmp=True, show=tp.show_wframe)
#         # # # packets = rawImageIO.arange_into_packets(cube)
#         # # # wfo = read.convert_to_wfo(image, wfo)
#         # datacube = pipe.make_datacube(cube)
#         return command
#
#     elif tp.detector == 'ideal':
#         # print 'Detecting photons with an ideal array'
#         if tp.show_wframe:
#             quicklook_im(datacube[0], logAmp=True, show=tp.show_wframe)
#         # cube = ideal.assign_calibtime(datacube,PASSVALUE['iter'])
#         # cube = rawImageIO.arange_into_cube(packets, value='phase')
#         # rawImageIO.make_phase_map(cube, plot=True)
#         return None

def get_obs_command(packets, t):

    # time = packets[0,2]

    command = []
    # command.append(('createGroup', ('/', 't%s' % time)))
    # command.append(('createArray', ('/t%s' % time, 'p%s' % time, packets)))
    # print packets[:5]
    # command.append(('createArray', ('/', 'p%i' % t, packets)))
    command = ('createArray', ('/', 'p%i' % t, packets))
    return command


def handle_output(output, filename):

    hdf = pt.openFile(filename, mode='a')
    while True:
        args = output.get()
        # for args in command:
        if args:

            method, args = args
            getattr(hdf, method)(*args)
        else:
            break
    hdf.close()

def write_obs(packets):
    '''Saving the packets in a pseudo h5 obsfile'''
    packets = np.array(packets)
    print(np.shape(packets))
    num_processes = 4  # mp.cpu_count()

    # time = step*mp.frame_time
    # nearest_sec = np.arange(mp.total_int+1)[time<=np.arange(mp.total_int+1)][0]
    # filename = os.path.join(mp.datadir,cp.date) + '%s.bin' % nearest_sec
        # f_handle = file(filename, 'a')
    # with open(filename, 'ab') as obs:
    #     np.save(obs, packets)    # .npy extension is added if not given
    # with open(filename, 'rb') as obs:
    #     # packets = cPickle.load(obs)
    #     d = np.load(obs)
    # return packets['image']
    # # with open('obs.pkl', 'ab') as obs:
    # #     cPickle.dump(packets, obs) 


    # pixIds = np.int_(packets[:,3]) * mp.xnum + np.int_(packets[:,4])
    # packets = {'basesDeg':packets[:,0], 'phases':packets[:,1], 'timestamps':packets[:,2], 'pixIds':pixIds}#, 'image':image, 'xCoords':packets[:,3], 'yCoords':packets[:,4]}

    # print glob.glob(filename), glob.glob(filename) == [], np.shape(packets)
    # if glob.glob(filename) == []:
    #     h5file = h5py.File(filename, 'w')
    #     d = h5file.create_dataset('photons', (len(packets),5), maxshape=(None,5), dtype='f', chunks=True)
    #     d[:] = packets
    #     h5file.flush()
    #     h5file.close()
    # else:
    #     with h5py.File(filename, 'a') as hf:
    #         # print hf["photons"][:5]
    #         hf["photons"].resize((hf["photons"].shape[0] + len(packets)), axis = 0)
    #         hf["photons"][-len(packets):] = packets


    # clear the file

    # def run(num_simulations):
    # hdf = pt.openFile('simulation.h5', mode='w')
    # hdf.close()
    # time=packets[0,2]
    # pool = mp.Pool(num_processes)
    # pool.apply_async(Simulation, (time, ), callback=handle_output)
    # pool.close()
    # pool.join()
    # print 'Done'


def convert_to_wfo(image, wfo):
    wf_temp = copy(wfo)
    wf_temp.wfarr = proper.prop_shift_center(image +0j)

    return wf_temp

def remove_close_photons(cube):
    # TODO test this
    dprint('**** this is untested! ****')
    # ind = np.argsort( photons[0,:] )
    # photons = photons[:,ind]
    image = np.zeros((mp.xnum,mp.ynum))
    for x in range(mp.xnum):
        for y in range(mp.ynum):
            events = np.array(cube[x][y])
            print(events, np.shape(events))
            try:
                diff = events[0,0] - np.roll(events[0,0],1)
                print(x, y, diff)
            except IndexError:
                pass
     
    # missed = 
    print('need to finish remove_close_photons')
    exit()
    return photons

def take_exposure(obs_sequence):
    # dprint(np.sum(obs_sequence))
    # dprint((ap.exposure_time, cp.frame_time))
    factor = ap.exposure_time/ cp.frame_time
    num_exp = int(ap.numframes/factor)
    # print factor, num_exp
    downsample_cube = np.zeros((num_exp,obs_sequence.shape[1],obs_sequence.shape[2], obs_sequence.shape[3]))
    # print ap.numframes, factor, num_exp
    for i in range(num_exp):
        # print np.shape(downsample_cube[i]), np.shape(obs_sequence), np.shape(np.sum(obs_sequence[i * factor : (i + 1) * factor], axis=0))
        downsample_cube[i] = np.sum(obs_sequence[int(i*factor):int((i+1)*factor)],axis=0)#/float(factor)
    return downsample_cube

def med_collapse(obs_sequence):
    downsample_cube = np.median(obs_sequence,axis=0)
    return downsample_cube


def save_obs_sequence(obs_sequence, HyperCubeFile = 'hyper.pkl'):
    print(HyperCubeFile)
    # quicklook_im(obs_sequence[-1,0])
    # print obs_sequence.shape, 'saving'
    with open(HyperCubeFile, 'wb') as handle:
        pickle.dump(obs_sequence, handle, protocol=pickle.HIGHEST_PROTOCOL)
    with open(HyperCubeFile, 'rb') as handle:
        obs_sequence = pickle.load(handle)
    # quicklook_im(obs_sequence[-1, 0])
    # HyperCubeFile = HyperCubeFile[:-3]+'npy'
    # np.save(HyperCubeFile, hypercube)

def save_hypercube_hdf5(hypercube, HyperCubeFile = 'hyper.hdf'):
    f = pt.open_file(HyperCubeFile, 'w')
    # atom = pt.Atom.from_dtype(hypercube.dtype)
    # ds = f.createCArray(f.root, 'data', atom, hypercube.shape)
    ds = f.create_array(f.root, 'data', hypercube)
    # ds[:] = hypercube
    f.close()

def get_integ_hypercube(plot=False):
    import medis.Detector.get_photon_data as gpd
    print(os.path.isfile(iop.obs_seq), iop.obs_seq)
    print(ap.numframes)


    if os.path.isfile(iop.obs_seq):
        if iop.obs_seq[-3:] == '.h5':
        # try:
            obs_sequence = open_hypercube_hdf5(HyperCubeFile=iop.obs_seq)
        else:
        # except:
            obs_sequence = open_hypercube(HyperCubeFile=iop.obs_seq)
    else:

        # obs_sequence = gpd.run()
        obs_sequence = gpd.take_obs_data()
        dprint(np.sum(obs_sequence))
        if plot:
            loop_frames(obs_sequence[:,0])
            loop_frames(obs_sequence[0])
        print('finished run')
        print(np.shape(obs_sequence))
        if plot: view_datacube(obs_sequence[0], logAmp=True)

        if tp.detector == 'H2RG':
            obs_sequence = H2RG.scale_to_luminos(obs_sequence)
            if plot: view_datacube(obs_sequence[0], logAmp=True)

        # obs_sequence = take_exposure(obs_sequence)
        # if tp.detector == 'H2RG':
        if tp.detector == 'H2RG' and hp.use_readnoise == True:
             obs_sequence = H2RG.add_readnoise(obs_sequence, hp.readnoise)
             # if plot: view_datacube(obs_sequence[0], logAmp=True)

        if plot: view_datacube(obs_sequence[0], logAmp=True)
        # save_obs_sequence(obs_sequence, HyperCubeFile=iop.obs_seq)
        dprint(iop.obs_seq)
        save_obs_sequence_hdf5(obs_sequence, HyperCubeFile=iop.obs_seq)
    # print np.shape(obs_sequence)

    if plot: loop_frames(obs_sequence[:, 0])
    if plot: loop_frames(obs_sequence[0])
    return obs_sequence

def open_obs_sequence(HyperCubeFile = 'hyper.pkl'):
    with open(HyperCubeFile, 'rb') as handle:
        hypercube =pickle.load(handle)
    # quicklook_im(hypercube[-1, 0])
    # HyperCubeFile = HyperCubeFile[:-3]+'npy'
    # hypercube = np.load(HyperCubeFile)
    return hypercube

def open_hypercube_hdf5(HyperCubeFile = 'hyper.h5'):
    # hdf5_path = "my_data.hdf5"
    read_hdf5_file = pt.open_file(HyperCubeFile, mode='r')
    # Here we slice [:] all the data back into memory, then operate on it
    hypercube = read_hdf5_file.root.data[:]
    # hdf5_clusters = read_hdf5_file.root.clusters[:]
    read_hdf5_file.close()
    return hypercube





