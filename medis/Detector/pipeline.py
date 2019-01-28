from medis.params import mp, ap, cp, tp
# import math
# import MKIDs
# import cPickle
# import medis.Utils.misc as misc
# import temporal as temp
import medis.Utils.misc as misc
from . import spectral as spec
import matplotlib.pyplot as plt
# import proper
import numpy as np
import os
import h5py
from medis.Utils.misc import dprint
import time
# import multiprocessing
# from functools import partial
# # from numba import njit

# def mp_worker(queue, t):
#     filename = mp.datadir + mp.obsfile
#     with h5py.File(filename, 'r') as hf:
#         # return hf.get('p%i' % t)
#         queue.put(hf.get('p%i' % t))

def read_obs(max_photons=1e8,start=0):
    filename = mp.datadir + mp.obsfile
    print('Getting %.0e photon packets from pseudo obsfile %s' % (max_photons,filename))
    contents = []
    with h5py.File(filename, 'r') as hf:
        print(ap.numframes)
        keys = list(hf.keys())[:ap.numframes]
        print(keys)
        numevents = len(hf.get(keys[0]))
        print(numevents)
        totevents = len(keys)*numevents
        print(totevents)
        # @njit
        packets = np.zeros((totevents,5))
        print(max_photons)
        for it, t in enumerate(range(len(keys))):#np.arange(0,10):
            print(t)
            packets[it*numevents:(it+1)*numevents] = hf.get('p%i' % t)
            # contents.append( hf.get(t))
            # contents = hf.get(group)
            # print contents
            # print packets
            # print np.shape(packets)
            # print int(start), int(start+max_photons)
        # packets = np.array(contents)
        # print packets
        # packets = np.array(contents[int(start):int(start+max_photons)])
    # packets = packets.reshape(-1,5)
    return packets

def arange_into_cube(packets, size):
    # print 'Sorting packets into xy grid (no phase or time sorting)'
    cube = [[[] for i in range(size[0])] for j in range(size[1])]
    # dprint(np.shape(cube))
    # plt.hist(packets[:,1], bins=100)
    # plt.show()
    for ip, p in enumerate(packets):
        x = np.int_(p[2])
        y = np.int_(p[3])
        cube[x][y].append([p[0],p[1]])
        if len(packets)>=1e7 and ip%10000==0: misc.progressBar(value = ip, endvalue=len(packets))
    # print cube[x][y]
    # cube = time_sort(cube)
    return cube

def isolate_interval(packets,times):
    print('Isolating all events between %f and %f secs' % (times[0], times[1]))
    locs = np.where((packets[:,2] >= times[0]) & (packets[:,2] < times[1]))[0]
    print('%.0e found in that interval' % len(locs))
    newpackets = packets[locs]
    return newpackets

# def get_lightcurve_2d(packets,xlocs,ylocs,start,end,bin_time=10e-3):
#     ind = np.lexsort((packets[:, 4], packets[:, 3]))
#     packets = packets[ind]
#     loc0 = np.where((packets[:, 3] == xlocs[0]) & (packets[:, 4] == ylocs[0]))[0]
#     loc1 = np.where((packets[:, 3] == xlocs[-1]) & (packets[:, 4] == ylocs[-1]))[0]
#     print packets[:50]
#     print loc0, loc1
#     print packets[loc0[0]:loc1[0]]
#     for xloc, yloc in zip(xlocs, ylocs):
#         locs = np.where((packets[:, 3] == xloc) & (packets[:, 4] == yloc))[0]
#         ts = packets[locs, 2]

# def get_lc_phase(packets,xloc,yloc, start, end, bin_time=10e-3):
#     t, x, y = 2, 3, 4
#     ts = packets[:, t]
#     np.digitize(ts, bins)
#     Counter()

def get_lightcurve(packets,xloc,yloc, start, end, bin_time=10e-3):#speed_up=True,
    # print 'Binning all the events in pixel (%s,%s)' % (xloc,yloc)
    # print packets.shape
    if packets.shape[1] == 3:
        t,x,y = 0,1,2
    else:
        t,x, y = 2, 3, 4
    # time0 = time.time()
    # locs = np.where((packets[:,x] == xloc) & (packets[:,y] == yloc))[0]
    # time1 = time.time()
    # print time1 - time0, 'first'
    ts = packets[:,t]
    # print len(ts)
    # print np.shape(packets)
    # bins = np.arange(-mp.frame_time/2 + start, cp.frame_time/2 + end, bin_time)
    # print start, end, cp.frame_time/2.

    bins = np.arange(start, end+cp.frame_time/2., bin_time)

    # print bins, len(bins), ap.numframes
    inten = np.histogram(ts, bins)[0]
    LC = {'time':bins, 'intensity':inten}

    # if speed_up == True:
    #     packets = np.delete(packets, locs, axis=0)
    #     return LC, packets
    # else:
    return LC

def get_intensity_dist(inten):
    intHist, binEdges = np.histogram(inten,bins=25)#,range=[0,25])
    intHist = np.array(intHist)/float(len(inten))
    ID = {'binsS':binEdges, 'histS':intHist}
    return ID
# def time_sort(cube):
#     new_cube = [[[] for i in range(mp.ynum)] for j in range(mp.xnum)]
#     for x in range(mp.xnum):
#         for y in range(mp.ynum):
#             # cube[x][y] = sorted(cube[x][y])
#             times=[]
#             for d in cube[x][y]:
#                 times.append(d['time'])
#             print x,y, cube[x][y]
#             order = np.argsort(times)
#             if len(order) == 0: order = [1]
#             sorted_ps = [v for _, v in sorted(zip(order,cube[x][y]))]
#             cube[x][y] = sorted_ps
#             print cube[x][y]
#     return cube

def make_intensity_map(cube, size, plot=False):
    # print 'Making a map of photon locations for all phases and times'
    int_map = np.zeros((size[1],size[0]))
    print(len(cube), len(cube[0]), int_map.shape)
    for x in range(size[1]):
        for y in range(size[0]):
            int_map[x,y]=len(cube[x][y])

    if plot:
        plt.figure()
        plt.imshow(np.log10(int_map), origin='lower', interpolation='none')
    return int_map
    # plt.show()

def make_intensity_map_packets(packets):
    print('Making a map of photon locations for all phases and times')
    int_map = np.zeros((mp.xnum,mp.ynum))
    for ip, p in enumerate(packets):
        x = np.int_(p[3])
        y = np.int_(p[4])
        int_map[x,y]+=1
        if len(packets)>=1e7 and ip%10000==0: misc.progressBar(value = ip, endvalue=len(packets))
    return int_map

def make_phase_map(cube, plot=False):
    phase_map = np.zeros((mp.xnum,mp.ynum))
    for x in range(mp.xnum):
        for y in range(mp.ynum):
            phase_map[x,y]=np.mean(cube[x][y])

    if plot:
        plt.figure()
        plt.imshow(np.log10(phase_map), origin='lower', interpolation='none')
    return phase_map

def make_datacube(cube, size):
    # print 'Making an xyw cube'
    # datacube = np.zeros((tp.nwsamp,size[0],size[1]))
    datacube = np.zeros((size[2],size[1],size[0]))
    phase_band = spec.phase_cal(tp.band)
    # dprint(phase_band)
    # bins = np.linspace(phase_band[0], phase_band[1], tp.nwsamp+1)
    bins = np.linspace(phase_band[0], phase_band[1], size[2]+1)
    # dprint(bins)
    # print np.array(cube[64][64])[0]
    # for i in range(-5,5):
    #     print i, np.array(cube[64][64+i])
    # if cube[64][64+3] != []:
    #     plt.hist(np.array(cube[64][65])[:,0])
    #     plt.show()
    for x in range(size[1]):
        for y in range(size[0]):
            if cube[x][y] == []:
                # datacube[:,x,y] = np.zeros((tp.nwsamp))
                datacube[:,x,y] = np.zeros((size[2]))
            else:
                # print np.array(cube[x][y])[:,0], np.histogram(np.array(cube[x][y])[:,0], bins=bins)
                # plt.figure()
                # plt.hist(np.array(cube[x][y])[:,0], bins=bins)

                datacube[:,x,y]=np.histogram(np.array(cube[x][y])[:,1], bins=bins)[0]#[::-1]
                # print x, y, np.array(cube[x][y])[:,0], len(np.where(np.array(cube[x][y])[:,0]<phase_band[0])[0]),
                datacube[0, x, y] += len(np.where(np.array(cube[x][y])[:,1]<phase_band[0])[0])
                # print len(np.where(np.array(cube[x][y])[:,0]>phase_band[1])[0])
                datacube[-1, x, y] += len(np.where(np.array(cube[x][y])[:,1]>phase_band[1])[0])
                # plt.figure()
                # plt.plot(datacube[:,x,y])
                # plt.show()
    # if plot:
    #     plt.figure()
    #     plt.imshow(np.log10(phase_map), origin='lower', interpolation='none')
    return datacube

def scale_to_luminos(hypercube):
    hypercube *= ap.star_photons*np.ones((tp.grid_size,tp.grid_size))
    return hypercube

def stack_hypercube(hypercube):
    '''Similar to take_exposure but makes a single frame for the intension of doing SDI rather than applying noise etc'''
    # datacube = np.zeros((1, hypercube.shape[1],hypercube.shape[2], hypercube.shape[3]))
    datacube = np.sum(hypercube, axis=0)
    return datacube