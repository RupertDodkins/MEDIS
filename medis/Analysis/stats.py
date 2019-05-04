'''Tools for photon statistics-based discrimination'''
import os
import numpy as np
import scipy.stats as stats
import multiprocessing
from medis.params import cp, mp, tp, ap, sp, iop
import medis.Detector.pipeline as pipe
import traceback
import itertools
import pickle as pickle
from medis.Utils.plot_tools import quicklook_im, quicklook_wf, quicklook_IQ, loop_frames
import proper
import matplotlib.pyplot as plt
import medis.Utils.misc as misc
from medis.Detector.distribution import gaussian, poisson, MR, gaussian2
from scipy.optimize import curve_fit
import medis.Detector.readout as read
from . import phot
from medis.Utils.misc import dprint
import copy

sentinel = None
xlocs = list(range(0, mp.array_size[0]))  # range(0,128)#65
ylocs = list(range(0, mp.array_size[1]))  # range(0,128)#85

def save_pix_IQ(wf, plot=False):
    with open(iop.IQpixel, 'a') as the_file:
        complex_map = proper.prop_shift_center(wf.wfarr)
        pix0 = complex_map[64, 64]
        pix1 = complex_map[100, 100]

        the_file.write('%f, %f, %f, %f\n' % (np.real(pix0), np.imag(pix0), np.real(pix1), np.imag(pix1)))

    if plot:
        quicklook_im(np.real(complex_map))
        quicklook_wf(wf, show=True)
        quicklook_IQ(wf, show=True)


def save_LCmap(LCmap):
    with open(iop.LCmapFile, 'wb') as handle:
        pickle.dump(LCmap, handle, protocol=pickle.HIGHEST_PROTOCOL)

def LCmap_worker(inqueue, output, packqueue):
# def LCmap_worker(inqueue, output, packets):
    try:
        # idx = inqueue.get()

        for idx in iter(inqueue.get, sentinel):
            # print inqueue.qsize(), output.qsize()  # , packqueue.qsize()
            ix = idx / len(xlocs)
            iy = idx % len(xlocs)
            xloc = xlocs[ix]
            yloc = ylocs[iy]
            # print inqueue.qsize(), output.qsize(), packqueue.qsize(),  'line305 3queues'
            packets = packqueue.get()
            # print inqueue.qsize(), output.qsize(), packqueue.qsize(), 'line307 3queues'
            start = 0#packets[0, 0]
            end = ap.numframes * ap.sample_time#packets[-1, 0]
            # print packets[:5],
            # print packets[-5:],
            # print np.shape(packets)
            # print start, end, 'start end'
            # print ix, iy, inqueue.qsize(), output.qsize(), packqueue.qsize()
            # time0 = time.time()
            LC = pipe.get_lightcurve(packets, xloc, yloc, start, end + ap.sample_time, bin_time=mp.bin_time)
            # LC = pipe.get_lightcurve(packets, xloc, yloc, start, end + ap.sample_time, bin_time=bin_time, speed_up=False)
            # print LC['intensity'], len(LC['intensity'])
            # time1 = time.time()
            # print 'time', time1 - time0
            # tp.LCmap[ix, iy] = LC['intensity']
            # if (ix * len(ylocs) + iy) % 10 == 0: misc.progressBar(value=(ix * len(ylocs) + iy),
            #                                                       endvalue=len(xlocs) * len(ylocs))
            # return LC['intensity']
            output.put(LC['intensity'])
            # packqueue.put(newpackets)
    except Exception as e:
        # print ' **** Caught Exception ****'
        traceback.print_exc()
        raise e

def LCmap_speedup():
    packets = pipe.read_obs()
    packets = packets[:,2:]
    print('Sorting packets (takes a while)')
    ind = np.lexsort((packets[:, 1], packets[:, 2]))
    packets = packets[ind]

    print(packets.shape, sp.num_processes)
    # exit()
    num_ints = int(ap.sample_time * ap.numframes / mp.bin_time)
    LCmap = np.zeros((len(xlocs), len(ylocs), num_ints))
    # for i in range(num_chunks):
    #     packets_chunk = packets[i * max_photons:(i + 1) * max_photons]
    output = multiprocessing.Queue()
    inqueue = multiprocessing.Queue()
    packqueue = multiprocessing.Queue()
    jobs = []

    for i in range(sp.num_processes):
        p = multiprocessing.Process(target=LCmap_worker, args=(inqueue, output, packqueue))
        jobs.append(p)
        p.start()
        # print 'ip', i
    for idx in range(len(xlocs) * len(ylocs)):
        # print 'idx', idx
        inqueue.put(idx)
    lower=0
    # for ix, iy in zip(xlocs,ylocs):
    for ix, iy in list(itertools.product(xlocs, ylocs)):
        print(ix, iy, 'ix iy')#'idx', idx
        # print inqueue.qsize(), output.qsize(), packqueue.qsize(), ' 3queues'
        diff = 0
        span = lower
        while diff == 0:
            # print diff, packets[span,1], iy,  span
            diff = packets[span,1] - iy
            span += 1
            if span == ap.star_photons*ap.numframes:
                break
        print('lower and span', lower, span)
        upper = span -1
        packets_chunk = packets[lower:upper]
        lower=upper
        packqueue.put(packets_chunk)
        LClist = output.get()
        # if ix == 1 and iy == 1:
        #     exit()
        # print LClist, 'LClist'
        # binned_chunk = num_ints / num_chunks
        # print debprint((len(LClist[0]), binned_chunk))
        # for idx in idxs:
        # ix = idx / len(xlocs)
        # iy = idx % len(xlocs)
        # LCmap[ix, iy, i * binned_chunk:(i + 1) * binned_chunk] = LClist  # [idx]
        LCmap[ix, iy] = LClist  # [idx]
    print(inqueue.qsize(), output.qsize(), packqueue.qsize(),  'line380 3queues')
    output.put(None)
    # packqueue.put(None)
    print(inqueue.qsize(), output.qsize(), packqueue.qsize(),  'line383 3queues')
    for i in range(sp.num_processes):
        # Send the sentinal to tell Simulation to end
        inqueue.put(sentinel)
        print('second i', i)
        print('line 205', tp.detector)
        print(inqueue.qsize(), output.qsize(), packqueue.qsize(), 'line389 3queues')
    for i, p in enumerate(jobs):
        p.join()
        print('third i', i)

    return LCmap

def get_LCmap():
    if not os.path.isdir(iop.datadir):
        os.mkdir(iop.datadir)
    import time
    sp.num_processes = 35
    print('********** Making LightCurve file ***********')
    begin = time.time()
    LCmap = LCmap_speedup()
    # LCmaps = LCmap_speedup_colors()
    end = time.time()
    # save_LCmap(LCmaps)
    save_LCmap(LCmap)
    print('Time elapsed: ', end - begin)
    print('*********************************************')
    return LCmap

# def Dmap_quad(target, ref, binning=10, plot=False):
#     k = 0
#     Dmap = np.zeros((target.shape[2], target.shape[3]))
#     # diff_cube = np.zeros(((target.shape[0]/binning)**2,1,mp.array_size[0],mp.array_size[1]))
#     # for a in target[::factor,0]:
#     #     for b in ref[::factor,0]:
#     nexps = target.shape[0]
#     intervals = range(0, nexps + 1, binning)
#     print intervals
#     idx = np.arange(0,len(target),binning)
#     for i in range(len(idx)-1):
#         for j in range(len(idx)-1):
#             diff_cube = target[idx[i]:idx[i+1]] - ref[idx[j]:idx[j+1]]
#             print i, j, idx[i], idx[j]
#             # quicklook_im(a)
#             # quicklook_im(b)
#             # loop_frames(diff_cube[:,0])
#             print k
#             k += 1
#             # diff_cube = np.array([[i-j] for i in simple_obs_sequence_1[::10,0] for j in simple_obs_sequence_2[::10,0]])
#             dprint(np.shape(diff_cube))
#             # # quicklook_im(np.mean(diff_cube[:,0],axis=0), logAmp=False)
#             # quicklook_im(np.mean(diff_cube[:, 0], axis=0), logAmp=True)
#             # quicklook_im(np.median(diff_cube[:, 0], axis=0), logAmp=True)
#
#             LCmap = np.transpose(diff_cube, (2, 3, 0, 1))
#
#             for iw in range(LCmap.shape[3]):
#                 for ie in range(nexps / binning):
#                     print ie
#                     print intervals[ie], intervals[ie + 1]
#                     exp = np.sum(LCmap[:, :, intervals[ie]:intervals[ie + 1], iw], axis=2)
#
#                     # darkmask = np.logical_or(exp <= 1, exp >= 15)
#                     darkmask = exp <= 1e-10  # 0#, np.abs(exp)>2)#5e-6
#                     # quicklook_im(exp,logAmp=False)
#                     # quicklook_im(darkmask,logAmp=False)
#                     Dmap += darkmask
#
#     finite = Dmap != 0
#     min_nonzero = np.min(Dmap[finite])
#     print min_nonzero
#     Lmap = 1. / (Dmap + min_nonzero / 100)
#     quicklook_im(Lmap)

def get_LmapBB(LCmap, threshold=0, binning=100, plot=False, verb_output=False):
    dprint(LCmap.shape)
    # mask = phot.aperture(ap.grid_size/2,ap.grid_size/2,9)
    # mask = mask==0 #flip the zeros and ones
    # add_rc = np.ones((mp.array_size[0],mp.array_size[1])) # add row col of ones to mask
    # add_rc[:-1,:-1] = mask
    # mask=add_rc
    # mask = np.transpose(np.resize(mask,(8,ap.numframes,129,129)))
    # LCmap *= mask
    Lmap = np.zeros((LCmap.shape[0],LCmap.shape[1]))
    nexps = LCmap.shape[2]
    # print nexps

    intervals = list(range(0,nexps+1,binning))
    dprint(intervals)
    Dmaps = []

    for ie in range(nexps/binning):
        # print ie,
        # print intervals[ie], intervals[ie + 1]
        exp = np.sum(LCmap[:,:,intervals[ie]:intervals[ie+1],:], axis=2)

        lightmask = np.all(exp > threshold, axis=2)  # 0#, np.abs(exp)>2)#5e-6
        Lmap += lightmask
        # if plot and ie % 100 == 0:
        #     plt.hist(exp.flatten(), bins=np.linspace(-10,10,100))
        #     plt.show()
        #     quicklook_im(lightmask, logAmp=True, vmin=1)
        #     loop_frames(np.transpose(exp, (2, 0, 1)), logAmp=True)  # , vmin=0.1)
        #     quicklook_im(Lmap, logAmp=True, vmin=1)

    # quicklook_im(Lmap, logAmp=True, vmin=1)
    return Lmap


def get_Dmap(LCmap, threshold=1, binning=10, plot=False, verb_output=False):
    dprint(LCmap.shape)
    # mask = phot.aperture(ap.grid_size/2,ap.grid_size/2,9)
    # mask = mask==0 #flip the zeros and ones
    # add_rc = np.ones((mp.array_size[0],mp.array_size[1])) # add row col of ones to mask
    # add_rc[:-1,:-1] = mask
    # mask=add_rc
    # mask = np.transpose(np.resize(mask,(8,ap.numframes,129,129)))
    # LCmap *= mask
    Dmap = np.zeros((LCmap.shape[0],LCmap.shape[1]))
    nexps = LCmap.shape[2]
    # print nexps

    intervals = list(range(0,nexps+1,binning))
    print(intervals)
    Dmaps = []

    for iw in range(LCmap.shape[3]):
        for ie in range(nexps/binning):
            # print ie,
            # print intervals[ie], intervals[ie + 1]
            exp = np.mean(LCmap[:,:,intervals[ie]:intervals[ie+1],iw], axis=2)
            # quicklook_im(exp,logAmp=False)

            # for x in range(exp.shape[0]):
            #     for y in range(exp.shape[1]):
            #         exp[x,y] = np.sum(exp[x-1:x+2,y-1:y+2])/9

            # quicklook_im(exp,logAmp=False)
            # darkmask = np.logical_or(exp <= 0.5, exp >=1.5)
            # darkmask = np.logical_or(exp <= 1, exp >= 2)
            # darkmask = np.logical_or(exp <= 1, exp >= 15)
            # darkmask = exp <= 1e-10#0#, np.abs(exp)>2)#5e-6
            # darkmask = np.logical_and(exp <= threshold, exp >= 0) # 0#, np.abs(exp)>2)#5e-6
            darkmask = exp <= threshold#, exp >= 0) # 0#, np.abs(exp)>2)#5e-6
            # quicklook_im(exp,logAmp=False)
            # quicklook_im(darkmask,logAmp=False)
            Dmap += darkmask
            if plot and ie % 10 == 0:
                print(ie, end=' ')
                print(intervals[ie], intervals[ie + 1])
                quicklook_im(exp, logAmp=True)#, vmin=0.1)
                quicklook_im(Dmap,logAmp=True, vmin=1)
            if ie == 0 and iw ==0:
                # quicklook_im(Dmap, logAmp=True, vmin=1)
                Dmaps.append(exp)
                Dmaps.append(copy.deepcopy(Dmap))
            if ie == 10 and iw ==0:
                # quicklook_im(Dmap, logAmp=True, vmin=1)
                Dmaps.append(copy.deepcopy(Dmap))
            if ie == nexps/binning - 1 and iw ==0:
                # quicklook_im(Dmap, logAmp=True, vmin=1)
                Dmaps.append(copy.deepcopy(Dmap))
    print(len(Dmaps))
    # quicklook_im(Dmap)
    # Dmap /= np.max(Dmap)
    # quicklook_im(Dmap)
    # quicklook_im(1-Dmap)
    finite = Dmap!=0
    min_nonzero = np.min(Dmap[finite])
    # plt.hist(Dmap.flatten(), bins=25)
    # plt.show()
    print(min_nonzero)
    Lmap = 1./(Dmap+min_nonzero/100)

    # plt.hist(Lmap.flatten(), bins=100)
    # plt.show()
    # Lmap[Lmap == 100] = np.min(Lmap)
    # Lmap = np.max(Dmap) - Dmap
    # loc_max = np.argmax(LCmap, axis=(0,1,2))
    # loc_max = np.unravel_index(LCmap.argmax(), LCmap.shape)
    # print 'loc_max', loc_max
    # # loc_max = np.array(loc_max)
    # from vip_hci import phot, pca
    # rawscaler = phot.contrcurve.aperture_flux(LCmap[loc_max[0]], [loc_max[1]], [loc_max[2]], 8, 1)[0]
    # print rawscaler
    # loc_max = np.unravel_index(Lmap.argmax(), Lmap.shape)
    # procscaler = phot.contrcurve.aperture_flux(Lmap, [loc_max[0]], [loc_max[1]], 8, 1)[0]
    # scale = rawscaler/procscaler
    # print  rawscaler, procscaler, scale, 'scale'
    # plt.hist(Lmap.reshape(Lmap.shape[0]**2), bins = 500)
    # plt.figure()
    # plt.hist(LCmap[:,:,0].reshape(Lmap.shape[0]**2), bins=500)
    # plt.figure()
    # plt.hist(LCmap)

    # LCmap_max = np.sum(np.argsort(-Lmap.reshape(128**2))[:10])
    # Lmap_max = np.sum(np.argsort(-np.median(LCmap, axis=2).reshape(128**2))[:10])
    # print Lmap.shape, np.median(LCmap, axis=2).shape
    # print np.argsort(-Lmap.reshape(128**2))[:10], np.argsort(-np.median(LCmap, axis=2).reshape(128**2))[:10]
    # scale = float(LCmap_max)/Lmap_max
    # LCmap_max = float(np.max(LCmap[:,:,0]))
    # Lmap_max = np.max(LCmap)
    stacked = np.mean(LCmap[:,:,:,0], axis=2)
    LCmap_max = stacked[64,57]
    Lmap_max = Lmap[64,57]

    scale =  1.#LCmap_max/ Lmap_max
    # scale = np.max(LCmap[:,:,:])/np.max(Lmap)
    print(LCmap_max, Lmap_max, scale, 'scale')

    # quicklook_im(Lmap)
    # quicklook_im(stacked)
    # Lmap *= scale
    # Lmap = np.max(Dmap)-Dmap
    # plt.hist(Lmap.reshape(Lmap.shape[0]**2), bins = 500)
    # plt.show()
    if plot:
        quicklook_im(Lmap, logAmp=True, vmin=0.1)
    if verb_output:
        return Dmaps, Lmap
    else:
        return Lmap

def plot_DSI(xlocs, ylocs, LCmapFile):
    with open(LCmapFile, 'rb') as handle:
        LCmap = pickle.load(handle)

    total_map = np.sum(LCmap, axis=2)
    median_map = np.median(LCmap, axis=2)
    interval_map = np.sum(LCmap[:, :, :5], axis=2)
    # quicklook_im(total_map, logAmp=True, show=False)
    # quicklook_im(median_map, logAmp=True, show=False)
    # quicklook_im(interval_map, logAmp=True, show=False)

    if os.path.isfile(iop.DSFile):
        with open(iop.DSFile, 'rb') as handle:
            Dmap = pickle.load(handle)
    else:
        Dmap = get_Dmap(LCmap)
        with open(iop.DSFile, 'wb') as handle:
            pickle.dump(Dmap, handle, protocol=pickle.HIGHEST_PROTOCOL)

    quicklook_im(Dmap, logAmp=True, show=True)  # , vmax=25)#

def DISI_4_VIP(cube, angle_list, verbose, **kwargs):
    LCmap = np.transpose(cube)
    Lmap = DISI(LCmap, kwargs['thresh'])
    # quicklook_im(Lmap)
    Lmap = np.transpose(Lmap)
    # quicklook_im(Lmap)
    return Lmap

def DISI(LCmap, thresh=3e-6, plot=True):
    '''Dark I_s imaging'''
    Is_maps = []
    print(LCmap.shape)
    for i in range(10):
        SSD_maps = get_Iratio(LCmap[:,:,i*100:(i+1)*100])
        Is_maps.append(SSD_maps[1])
    Is_maps = np.array(Is_maps)
    Dmap = np.zeros_like((Is_maps[0]))
    nexps = Is_maps.shape[0]
    # print nexps
    for ie in range(nexps):
        # print ie
        exp = Is_maps[ie]
        darkmask = np.transpose(exp <= thresh)
        # quicklook_im(exp,logAmp=False)
        # quicklook_im(darkmask,logAmp=False)
        Dmap += darkmask
        if plot and ie % 1 == 0:
        #     # quicklook_im(exp, logAmp=True, vmin=0.1)
            quicklook_im(Dmap,logAmp=True, vmin=1)
    # quicklook_im(Dmap)
    # Dmap /= np.max(Dmap)
    # quicklook_im(Dmap)
    # # quicklook_im(1-Dmap)
    # finite = Dmap!=0
    # min_nonzero = np.min(Dmap[finite])
    # Lmap = 1./(Dmap+min_nonzero/100)
    # scale = np.sum(LCmap[0])/np.sum(Lmap)
    # Lmap *= scale
    # # Lmap = np.max(Dmap)-Dmap
    if plot:
        quicklook_im(Dmap, logAmp=True, vmin=1)
    return Dmap

def replaceNans(image):
    nan_mask = np.isnan(image)
    image[nan_mask] = np.random.normal(0, np.nanstd(image), size=np.count_nonzero(nan_mask))
    return image

def SSD_4_VIP(cube, angle_list, verbose, **kwargs):
    xlocs = list(range(0, 128))  # range(0,128)#65
    ylocs = list(range(0, 128))  # range(0,128)#85
    print(cube.shape, 'cube')
    LCmap = np.transpose(cube)
    print(LCmap.shape, 'lcmap')
    # LCmap = LCmap / np.mean(LCmap)
    # maps = get_Iratio(LCmap, xlocs, ylocs, None, None, None)
    maps = get_Iratio(LCmap, xlocs, ylocs, list(range(63,66)), list(range(63,66)), True)
    Iratio = maps[2]
    # Iratio= replaceNans(Iratio)
    Iratio = np.transpose(Iratio)
    # quicklook_im(Iratio)
    # print 'line 218', kwargs['SSD_starphot']
    # normed_Iratio = Iratio / np.mean(Iratio)

    normed_Iratio = Iratio# / kwargs['SSD_starphot']
    # quicklook_im(normed_Iratio)
    return normed_Iratio

def DSI_4_VIP(cube, angle_list, verbose, **kwargs):
    dprint(cube.shape)
    LCmap = np.transpose(cube)
    dprint(LCmap.shape)
    Lmap = get_Dmap(LCmap, kwargs['thresh'])
    # quicklook_im(Lmap)
    normed_Lmap = Lmap#/kwargs['DSI_starphot']
    Lmap = np.transpose(Lmap)
    # quicklook_im(Lmap)
    return normed_Lmap

def effint_4_VIP(cube, angle_list, verbose, **kwargs):
    dprint(cube.shape)

    # if kwargs['thru']:
    # diff_cube = cube
    print(cube.shape)
    # quicklook_im(np.mean(cube[:],axis=0), annos=['MKIDs'], title=  r'  $I_L / I^{*}$', mark_star=True)
    return np.mean(cube[:], axis=0)
    dprint(cube.shape)
    # else:
    #     cube = kwargs['full_target_cube']
    #     dprint(np.mean(cube[:,0],axis=0).shape)
    #     # quicklook_im(np.mean(cube[:,-2],axis=0), annos=['MKIDs'], title=r'  $I_L / I^{*}$', mark_star=True)
    #     return np.mean(cube[:, 0], axis=0)

    return np.mean(cube[:],axis=0)

def SDI_4_VIP(cube, angle_list, verbose, **kwargs):
    dprint(cube.shape)
    wsamples = np.linspace(ap.band[0], ap.band[1], ap.w_bins)
    scale_list = ap.band[0]/wsamples
    cube = np.mean(cube, axis=1)/ap.exposure_time
    # SDI = phot.SDI_each_exposure(cube, binning=len(cube))[0]
    print(len(angle_list))
    from vip_hci import pca
    SDI = pca.pca(cube, angle_list=np.zeros((len(cube))), scale_list=scale_list,
                                mask_center_px=None)
    # quicklook_im(SDI)
    return SDI

def RDI_4_VIP(cube, angle_list, verbose, **kwargs):
    dprint(cube.shape)

    # if kwargs['thru']:
    #     diff_cube = cube - kwargs['cube_ref'][:,-2]
    #     dprint(np.mean(diff_cube[:],axis=0).shape)
    #     return np.mean(diff_cube[:], axis=0)
    # else:
    diff_cube = cube  - np.mean(kwargs['cube_ref'], axis=0)
    dprint(diff_cube.shape)

    # quicklook_im(np.mean(diff_cube,axis=0), annos=['MKIDs'], title=  r'  $I_L / I^{*}$', mark_star=True)
    # dprint(np.mean(diff_cube[:,0],axis=0).shape)
    return np.mean(diff_cube[:],axis=0)

def RDSI_4_VIP(cube, angle_list, verbose, **kwargs):
    dprint(cube.shape)

    # diff_cube = cube - kwargs['cube_ref']
    if kwargs['thru']:
        diff_cube = cube - kwargs['cube_ref'][:, -2]
        LCcube = np.transpose(diff_cube,(1,2,0))
    else:
        diff_cube = kwargs['full_target_cube'] - kwargs['cube_ref']
        LCcube = np.transpose(diff_cube, (2, 3, 0, 1))
    dprint(diff_cube.shape)

    print(LCcube.shape)
    # quicklook_im(LCcube[:,:,0])
    LCcube = np.resize(LCcube,(LCcube.shape[0],LCcube.shape[1],LCcube.shape[2],1))
    print(LCcube.shape)
    algo_dict = {'thresh': 0}
    Lmap = get_Dmap(LCcube, algo_dict['thresh'], binning=2)
    quicklook_im(Lmap, annos=['MKIDs'], title=  r'  $I_L / I^{*}$', mark_star=True)
    dprint(LCcube.shape)
    # Lmap = get_Dmap(LCcube, kwargs['thresh'])
    # # quicklook_im(Lmap)
    # normed_Lmap = Lmap#/kwargs['DSI_starphot']
    # Lmap = np.transpose(Lmap)
    # quicklook_im(Lmap)
    return Lmap

# def SDI_each_exposure(obs_sequence, binning=10):
#     shape = obs_sequence.shape
#     timecube = np.zeros_like(obs_sequence[0,::binning])
#     dprint(timecube.shape)
#     dprint(obs_sequence.shape)
#     idx = np.arange(0,len(obs_sequence),binning)
#     for i in range(len(idx)-1):
#         timecube[i] = phot.do_SDI(np.mean(obs_sequence[:,idx[i]:idx[i+1]],axis=1), plot=True)
#     # for t in range(shape[0])[:1]:
#     #     timecube[t] = do_SDI(hypercube[t], plot=True)
#     loop_frames(timecube)
#     return timecube

def SDI_RDI_4_VIP(cube, angle_list, verbose, **kwargs):
    from vip_hci import pca
    wsamples = np.linspace(ap.band[0], ap.band[1], ap.w_bins)
    scale_list = ap.band[0]/wsamples
    # cube = np.mean(cube, axis=1)/ap.exposure_time

    SDI_tar = pca.pca(np.mean(cube, axis=1)/ap.exposure_time, angle_list=np.zeros((cube.shape[0])), scale_list=scale_list,
                                mask_center_px=None)
    SDI_ref = pca.pca(np.mean(kwargs['cube_ref'], axis=1)/ap.exposure_time, angle_list=np.zeros((cube.shape[0])), scale_list=scale_list,
                                mask_center_px=None)
    # quicklook_im(SDI)
    return SDI_tar-SDI_ref

def RDI_SDI_4_VIP(cube, angle_list, verbose, **kwargs):
    # if kwargs['thru']:
    diff_cube = cube - kwargs['cube_ref']#[:, -2]
    # else:
    # quicklook_im(np.mean(cube[:,-2], axis=0))
    # quicklook_im(np.mean(kwargs['cube_ref'][:,-2], axis=0))
    # quicklook_im(np.mean(diff_cube[:,-2], axis=0))
    # diff_cube = kwargs['full_target_cube'] - kwargs['cube_ref']
    diff_cube = np.transpose(diff_cube, (1, 0, 2, 3))
    time_cube = phot.SDI_each_exposure(diff_cube, binning=25)
    dprint(np.mean(time_cube[:], axis=0).shape)
    # quicklook_im(np.mean(time_cube[:],axis=0))
    return np.mean(time_cube[:],axis=0)

def RDI_SDI_DSI_4_VIP(cube, angle_list, verbose, **kwargs):
    # if kwargs['thru']:
    diff_cube = cube - kwargs['cube_ref']#[:, -2]
    # else:
    # quicklook_im(np.mean(cube[:,-2], axis=0))
    # quicklook_im(np.mean(kwargs['cube_ref'][:,-2], axis=0))
    # quicklook_im(np.mean(diff_cube[:,-2], axis=0))
    # diff_cube = kwargs['full_target_cube'] - kwargs['cube_ref']
    diff_cube = np.transpose(diff_cube, (1, 0, 2, 3))
    time_cube = phot.SDI_each_exposure(diff_cube, binning=25)
    time_cube = np.resize(time_cube, (time_cube.shape[0], 1, time_cube.shape[1], time_cube.shape[2]))
    # dprint(np.mean(time_cube[:], axis=0).shape)
    # quicklook_im(np.mean(time_cube[:],axis=0))
    dprint(time_cube.shape)
    LCcube = np.transpose(time_cube, (2, 3, 0, 1))
    Lmap = get_Dmap(LCcube, binning=2, plot=False)
    return Lmap

def RDI_DSI_4_VIP(cube, angle_list, verbose, **kwargs):
    from vip_hci import pca
    diff_cube = cube - kwargs['cube_ref']
    # loop_frames(cube[:,1])
    # loop_frames(cube[0, :])
    # quicklook_im(np.mean(cube[:,-2], axis=0))
    # quicklook_im(np.mean(simple_hypercube_2[:,-2], axis=0))
    # quicklook_im(np.mean(diff_cube[:,-2], axis=0))

    # Lmaps = np.zeros((diff_cube.shape[0], diff_cube.shape[2], diff_cube.shape[3]))
    # for iw in range(diff_cube.shape[0]):
    dprint(diff_cube.shape)
    diff_cube = np.resize(diff_cube, (diff_cube.shape[0],1, diff_cube.shape[1], diff_cube.shape[2]))
    dprint(diff_cube.shape)
    LCcube = np.transpose(diff_cube, (2, 3, 0, 1))
    dprint(LCcube.shape)
    Lmap = get_Dmap(LCcube, binning=1, plot=False)
    # Lmap = get_skew(LCcube)
    # quicklook_im(Lmap, logAmp=True)
    # loop_frames(Lmaps)
    # angle_list = np.zeros((len(Lmaps)))
    # SDI = phot.do_SDI(Lmaps)
    # # quicklook_im(SDI)
    return Lmap


def RDI_DSI_SDI_4_VIP(cube, angle_list, verbose, **kwargs):
    from vip_hci import pca
    diff_cube = cube - kwargs['cube_ref']
    # loop_frames(cube[:,1])
    # loop_frames(cube[0, :])
    # quicklook_im(np.mean(cube[:,-2], axis=0))
    # quicklook_im(np.mean(simple_hypercube_2[:,-2], axis=0))
    # quicklook_im(np.mean(diff_cube[:,-2], axis=0))

    Lmaps = np.zeros((diff_cube.shape[0], diff_cube.shape[2], diff_cube.shape[3]))
    for iw in range(diff_cube.shape[0]):
        # dprint((diff_cube.shape, iw))
        LCcube = np.transpose(diff_cube[iw:iw + 1], (2, 3, 1, 0))
        Lmaps[iw] = get_Dmap(LCcube, binning=1, plot=False)
        # Lmaps[iw] = get_skew(LCcube)
        # quicklook_im(Lmaps[iw], logAmp=True)
    # loop_frames(Lmaps)
    # angle_list = np.zeros((len(Lmaps)))
    SDI = np.mean(Lmaps, axis=0)
    # SDI = phot.do_SDI(Lmaps)
    # quicklook_im(SDI)
    return SDI

def RDI_DSI_BB_4_VIP(cube, angle_list, verbose, **kwargs):
    from vip_hci import pca
    diff_cube = cube - kwargs['cube_ref']
    # loop_frames(cube[:,1])
    # loop_frames(cube[0, :])
    # quicklook_im(np.mean(cube[:,-2], axis=0))
    # quicklook_im(np.mean(simple_hypercube_2[:,-2], axis=0))
    # quicklook_im(np.mean(diff_cube[:,-2], axis=0))

    LCcube = np.transpose(diff_cube, (2, 3, 1, 0))
    # Lmap = get_LmapBB(LCcube, binning=100, plot=False, threshold=0.01)
    Lmap = get_Dmap(LCcube, binning=1, plot=False)
    # Lmaps[iw] = get_skew(LCcube)
    # quicklook_im(Lmap, logAmp=True)
    # loop_frames(Lmaps)
    # angle_list = np.zeros((len(Lmaps)))
    # SDI = np.mean(Lmaps, axis=0)
    # SDI = phot.do_SDI(Lmaps)
    # quicklook_im(SDI)
    return Lmap

def SDI_RDI_DSI_4_VIP(cube, angle_list, verbose, **kwargs):
    from vip_hci import pca
    wsamples = np.linspace(ap.band[0], ap.band[1], ap.w_bins)
    scale_list = ap.band[0]/wsamples
    # cube = np.mean(cube, axis=1)/ap.exposure_time

    # SDI_tar = pca.pca(np.mean(cube, axis=1)/ap.exposure_time, angle_list=np.zeros((cube.shape[0])), scale_list=scale_list,
    #                             mask_center_px=None)
    # SDI_ref = pca.pca(np.mean(kwargs['cube_ref'], axis=1)/ap.exposure_time, angle_list=np.zeros((cube.shape[0])), scale_list=scale_list,
    #                             mask_center_px=None)

    cube = np.transpose(cube, (1, 0, 2, 3))
    kwargs['cube_ref'] = np.transpose(kwargs['cube_ref'], (1, 0, 2, 3))

    SDI_tar = phot.SDI_each_exposure(cube, binning=25)
    SDI_tar = np.resize(SDI_tar, (SDI_tar.shape[0], 1, SDI_tar.shape[1], SDI_tar.shape[2]))

    SDI_ref = phot.SDI_each_exposure(kwargs['cube_ref'], binning=25)
    SDI_ref = np.resize(SDI_ref, (SDI_ref.shape[0], 1, SDI_ref.shape[1], SDI_ref.shape[2]))
    # quicklook_im(SDI)
    dprint(SDI_ref.shape)
    diff_cube= SDI_tar-SDI_ref
    LCcube = np.transpose(diff_cube, (2, 3, 0, 1))
    Lmap = get_Dmap(LCcube, binning=2, plot=False)
    return Lmap

def time_collapse(cube, angle_list, verbose, **kwargs):
    image = np.sum(cube, axis=0) / cube.shape[0]
    return image

# def get_darkfrac(LCmap, xlocs=None, ylocs=None, xinspect=None, yinspect=None, inspect=None):
#     if xlocs == None or ylocs == None:
#         xlocs = range(LCmap.shape[0])
#         ylocs = range(LCmap.shape[1])
#
#     Dmap = np.zeros((len(xlocs), len(ylocs)))
#     for ix, xloc in enumerate(xlocs):
#         for iy, yloc in enumerate(ylocs):
#             # if (ix * len(ylocs) + iy) % 100 == 0: misc.progressBar(value=(ix * len(ylocs) + iy),
#             #                                                        endvalue=len(xlocs) * len(ylocs))
#             ints = LCmap[ix, iy]
#             # np.histogram(int)
#             plt.hist(ints, bins=25)
#             print Dmap[ix, iy]
#             plt.show()
#             if np.var(ints) != 0:
#                 Dmap[ix, iy] = np.mean(ints) / np.var(ints)
#             # print np.var(ints)
#
#             if inspect == True and xloc in yinspect and yloc in xinspect:
#                 plt.hist(ints, bins=25)
#                 print Dmap[ix, iy]
#                 plt.show()
#     return Dmap

def get_skew(LCmap, xlocs=None, ylocs=None, xinspect=None, yinspect=None, inspect=None):
    if xlocs == None or ylocs == None:
        xlocs = list(range(LCmap.shape[0]))
        ylocs = list(range(LCmap.shape[1]))

    skews = np.zeros((len(xlocs), len(ylocs)))
    for ix, xloc in enumerate(xlocs):
        for iy, yloc in enumerate(ylocs):
            if (ix * len(ylocs) + iy) % 100 == 0: misc.progressBar(value=(ix * len(ylocs) + iy),
                                                                   endvalue=len(xlocs) * len(ylocs))
            ints = LCmap[ix, iy]
            if np.var(ints) !=0:
                # skews[ix,iy] = np.mean(ints)/np.var(ints)
                skews[ix,iy] = stats.skew(ints)
                print(ix, iy, skews[ix,iy])

            if inspect == True and xloc in yinspect and yloc in xinspect:
                plt.hist(ints, bins = 25)
                print(skews[ix,iy])
                plt.show()
            # skews[skews>=10] = 10
            # skews[skews<=-10] = -10
    return skews

def get_Iratio(LCmap, xlocs=None, ylocs=None, xinspect=None, yinspect=None, inspect=None):
    if xlocs == None or ylocs == None:
        xlocs = list(range(LCmap.shape[0]))
        ylocs = list(range(LCmap.shape[1]))

    Iratio = np.zeros((len(xlocs), len(ylocs)))
    Ic = np.zeros((len(xlocs), len(ylocs)))
    Is = np.zeros((len(xlocs), len(ylocs)))
    mIratio = np.zeros((len(xlocs), len(ylocs)))
    # from medis.Utils.plot_tools import loop_frames
    # loop_frames(np.transpose(LCmap))
    for ix, xloc in enumerate(xlocs):
        for iy, yloc in enumerate(ylocs):
            if (ix * len(ylocs) + iy) % 100 == 0: misc.progressBar(value=(ix * len(ylocs) + iy),
                                                                   endvalue=len(xlocs) * len(ylocs))
            ints = LCmap[ix, iy]

            guessIc = np.mean(ints) * 0.7
            guessIs = np.mean(ints) * 0.3

            Imean = np.mean(ints)
            Istd = np.std(ints)
            if Imean < Istd:
                Ic[ix, iy] = 1e-5
            else:
                Ic[ix, iy] = np.sqrt(Imean ** 2 - Istd ** 2)
            Is[ix, iy] = Imean - Ic[ix, iy]
            Iratio[ix, iy] = Ic[ix, iy] / Is[ix, iy]
            m = (np.sum(ints) - (Ic[ix, iy] + Ic[ix, iy])) / (
                np.sqrt(Is[ix, iy] ** 2 + 2 * Ic[ix, iy] + Is[ix, iy]) * len(ints))
            mIratio[ix, iy] = m ** -1 * (Iratio[ix, iy])
            # if ix == 13 and iy == 13:
            #     print ints, Imean, Istd, Ic[ix, iy], Is[ix, iy], Iratio[ix, iy]
            if inspect == True and xloc in yinspect and yloc in xinspect:
                ID = pipe.get_intensity_dist(ints)
                bincent = (ID['binsS'] + np.roll(ID['binsS'], 1)) / 2.
                bincent = np.array(bincent)[1:]
                plt.figure()
                plt.plot(ints)
                print(xloc, yloc)
                plt.figure()
                plt.step(bincent, ID['histS'])
                # plt.plot(bincent, MR(bincent, Ic[ix, iy], Is[ix, iy]), 'r--')
                print(Imean, Istd, Ic[ix, iy], Is[ix, iy], Iratio[ix, iy], Imean, Istd)
                try:
                    popt, _ = curve_fit(MR, bincent, ID['histS'], p0=[guessIc, guessIs])
                    # Ic[ix, iy] = popt[0]
                    # Is[ix, iy] = popt[1]
                    # Iratio[ix, iy] = popt[0] / popt[1]
                    # m = (np.sum(ints) - (popt[0] + popt[0])) / (
                    #     np.sqrt(popt[1] ** 2 + 2 * popt[0] + popt[1]) * len(ints))
                    # mIratio[ix, iy] = m ** -1 * (Iratio[ix, iy])
                    plt.plot(bincent, MR(bincent, *popt), 'b--')
                    print(popt, popt[0] / popt[1])
                except RuntimeError:
                    pass

                plt.show()

    # LCmap_max = np.sum(np.argsort(-LCmap[:,:,0])[:100])
    # Iratio_max = np.sum(np.argsort(-Iratio)[:100])
    # print np.argsort(-LCmap[0])[:100]
    # LCmap_max = np.max(-LCmap[:,:,0])
    # Iratio_max = np.max(-Iratio)
    stacked = np.mean(LCmap, axis=2)
    LCmap_max = stacked[64,57]
    Iratio_max = Iratio[64,57]
    scale = LCmap_max/Iratio_max
    print(LCmap_max, Iratio_max, scale)
    # scale = np.max(LCmap)/np.max(Iratio)
    Iratio *= scale#np.mean(Is)
    return Ic, Is, Iratio, mIratio

def get_unoccult_SSDpsf(plot=False,  obs_seq='/SSDHyperUnOccult.pkl'):
    obs_sequence = phot.get_unoccult_hyper(obs_seq, numframes=1000)
    LCmap = np.transpose(obs_sequence[:, 0])
    xlocs = list(range(LCmap.shape[0]))
    ylocs = list(range(LCmap.shape[1]))
    images = get_Iratio(LCmap, xlocs, ylocs, xinspect=None, yinspect=None, inspect=None)
    Iratio = images[2]
    if plot:
        quicklook_im(Iratio)

    return Iratio

def get_unoccult_DSIpsf(plot=False, obs_seq='/SSDHyperUnOccult.pkl', thresh=1e-6):
    obs_sequence = phot.get_unoccult_hyper(obs_seq, numframes=1000)
    LCmap = np.transpose(obs_sequence[:, 0])
    Dmap = get_Dmap(LCmap, thresh)
    if plot:
        quicklook_im(Dmap)
    return Dmap

def _scale_func(output_coords, ref_xy=0, scaling=1.0,
                scale_y=None, scale_x=None):
    """
    For each coordinate point in a new scaled image (output_coords),
    coordinates in the image before the scaling are returned. This scaling
    function is used within geometric_transform which, for each point in the
    output image, will compute the (spline) interpolated value at the
    corresponding frame coordinates before the scaling.
    """
    ref_x, ref_y = ref_xy
    if scale_y is None:
        scale_y = scaling
    if scale_x is None:
        scale_x = scaling
    return (ref_y + ((output_coords[0] - ref_y) / scale_y),
            ref_x + ((output_coords[1] - ref_x) / scale_x))



def centroid_ref(target, ref, zoom_test=True):
    # https://stackoverflow.com/questions/29954153/finding-the-maximum-of-a-curve-scipy

    from scipy.ndimage.interpolation import geometric_transform, zoom
    import cv2

    zooms = np.linspace(0.9, 1.1, 7)
    xs = np.linspace(-30, 30, 15)
    ys = np.linspace(-30, 30, 15)
    scores = np.zeros((len(zooms), len(xs), len(ys)))
    frame_center = np.array([ref.shape[0]/2. - 0.5, ref.shape[1]/2. - 0.5])
    # print frame_center, frame_center+[0,0]
    for iz, z in enumerate(zooms):
        # zoom = clipped_zoom(ref, z)
        # print np.sum(zoom)
        # quicklook_im(shift, logAmp=False)
        for ix, x in enumerate(xs):
            for iy, y in enumerate(ys):
                # shift = np.roll(np.roll(ref, x, 0), y, 1)
                # quicklook_im(ref, logAmp=False)
                M = np.array([[z, 0, (1. - z) * (frame_center[0]+x)],
                              [0, z, (1. - z) * (frame_center[1]+y)]])

                intp = cv2.INTER_LANCZOS4
                trans = cv2.warpAffine(ref.astype(np.float32), M, ref.shape,
                                           flags=intp)
                # trans = geometric_transform(ref, _scale_func, order=0,
                #                                 output_shape=ref.shape,
                #                                 prefilter=False,
                #                                 extra_keywords={'ref_xy': frame_center + np.array([x,y]),
                #                                                 'scaling': z,
                #                                                 'scale_y': z,
                #                                                 'scale_x': z})
                trans = trans*np.max(ref)/np.max(trans)
                # shift = np.roll(np.roll(zoom,x,0),y,1)
                # quicklook_im(target, logAmp=False)
                # quicklook_im(trans, logAmp=False)
                # print z, x, y, np.max(np.abs(target - trans))
                scores[iz,ix,iy] = np.max(np.abs(target - trans))
                # print np.sum(trans), np.max(trans)
                # quicklook_im(np.abs(target - trans), logAmp=False, vmin=0, vmax=0.2)
        # print scores[iz]
        # swin  = np.unravel_index(scores[iz].argmin(), scores[iz].shape)
        # print swin
        # shift = np.roll(np.roll(zoom,xs[swin[0]],0),ys[swin[1]],1)
        # quicklook_im(target - trans, logAmp=False, vmin=-0.25, vmax=0.25)
        # zooms[iz] = np.sum(np.abs(target - shift))
    # print zooms
    # zwin = np.unravel_index(zooms.argmin(), zooms.shape)
    # print zwin
    # shift
    win = np.unravel_index(scores.argmin(), scores.shape)
    # print scores, win, scores[win]
    # zoom = clipped_zoom(ref, zooms[win[0]])
    # shift = np.roll(np.roll(zoom,xs[win[1]],0),ys[win[2]],1)
    M = np.array([[zooms[win[0]], 0, (1. - zooms[win[0]]) * (frame_center[0] + xs[win[1]])],
                  [0, zooms[win[0]], (1. - zooms[win[0]]) * (frame_center[1] + ys[win[2]])]])

    intp = cv2.INTER_LANCZOS4
    ref = cv2.warpAffine(ref.astype(np.float32), M, ref.shape,
                           flags=intp)
    # ref = geometric_transform(ref, _scale_func, order=0,
    #                             output_shape=ref.shape,
    #                             extra_keywords={'ref_xy': frame_center + (win[1],win[2]),
    #                                             'scaling': zooms[win[0]],
    #                                             'scale_y': zooms[win[0]],
    #                                             'scale_x': zooms[win[0]]})
    # quicklook_im(target - ref, logAmp=False,vmin=-0.2, vmax=0.2)
    # ref = shift

    # if zoom_test:
    #     shift = ref
    #     zooms = np.zeros((5))
    #     for iz, zoom in enumerate(np.linspace(0.95,1.05,5)):
    #         shift = clipped_zoom(ref,zoom)
    #         quicklook_im(target, logAmp=False)
    #         quicklook_im(shift, logAmp=False)
    #         print iz, zoom, np.sum(np.abs(target - shift))
    #         zooms[iz] =np.sum(np.abs(target - shift))
    #         quicklook_im(target - shift, logAmp=False)
    #     print zooms
    #     win = np.unravel_index(zooms.argmin(), zooms.shape)
    #     print win
    #     ref = clipped_zoom(ref, zooms[win])
    #     quicklook_im(target - ref, logAmp=False)
    return ref