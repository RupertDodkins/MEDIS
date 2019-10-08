from medis.params import mp, ap, cp, tp, iop, sp
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

def traverse_datasets(hdf_file):

    def h5py_dataset_iterator(g, prefix=''):
        for key in g.keys():
            item = g[key]
            path = f'{prefix}/{key}'
            if isinstance(item, h5py.Dataset): # test for dataset
                yield (path, item)
            elif isinstance(item, h5py.Group): # test for group (go down)
                yield from h5py_dataset_iterator(item, path)

    with h5py.File(hdf_file, 'r') as f:
        for path, _ in h5py_dataset_iterator(f):
            yield path

def make_sixcube():
    """
    Take the continuously saved sequence of fivecubes and load a sixcube into memory
    :return:
    """
    with h5py.File(iop.cont_fields, 'r') as hf:
        keys = list(hf.keys())
        step_shape = hf.get('t%i/data' % 0).shape
        fields = np.zeros((len(keys), step_shape[0], step_shape[1], step_shape[2], step_shape[3], step_shape[4]), dtype=np.complex64)
        for t in range(len(keys)):
            timestep = hf.get('t%i/data' % t)
            # from medis.Utils.plot_tools import view_datacube
            # view_datacube(np.abs(timestep[-1,:,0]) ** 2, logAmp=True)
            fields[t] = timestep



    return fields


def read_obs(max_photons=1e8, start=0):
    filename =iop.obs_table
    print('Getting max %.0e photon packets from pseudo obsfile %s' % (max_photons,filename))
    with h5py.File(filename, 'r') as hf:
        keys = list(hf.keys())#[:ap.numframes]
        assert len(ap.contrast) + 1 == len(hf.get('t0'))
        numobjects = len(ap.contrast) + 1
        allpackets = []
        for o in range(numobjects):
            guesstotevents = len(keys)*len(hf.get('t0/o%i' % o))*2
            packets = np.zeros((guesstotevents*2,4))
            current_loc = 0
            for it, t in enumerate(range(len(keys))):
                timestep = hf.get('t%i/o%i' % (t,o))
                numevents = len(timestep)
                packets[current_loc: current_loc+numevents] = timestep
                current_loc += numevents
            packets = np.delete(packets, np.where(np.sum(packets, axis=1) == 0)[0], axis=0)
            allpackets.append(packets)

    return allpackets


def make_datacube(cube, size):
    # print 'Making an xyw cube'
    datacube = np.zeros((size[2],size[1],size[0]))
    phase_band = spec.phase_cal(ap.band)
    bins = np.linspace(phase_band[0], phase_band[1], size[2]+1)

    for x in range(size[1]):
        for y in range(size[0]):
            if cube[x][y] == []:
                datacube[:, x, y] = np.zeros((size[2]))
            else:
                datacube[:, x, y] = np.histogram(np.array(cube[x][y])[:,1], bins=bins)[0]#[::-1]
                datacube[0, x, y] += len(np.where(np.array(cube[x][y])[:,1]<phase_band[0])[0])
                datacube[-1, x, y] += len(np.where(np.array(cube[x][y])[:,1]>phase_band[1])[0])

    return datacube

def make_datacube_from_list(packets, shape):
    phase_band = spec.phase_cal(ap.band)
    bins = [np.linspace(phase_band[0], phase_band[1], shape[0] + 1),
            range(shape[1]+1),
            range(shape[2]+1)]
    datacube, _ = np.histogramdd(packets[:,1:], bins)

    return datacube

def arange_into_stem(packets, size):
    # print 'Sorting packets into xy grid (no phase or time sorting)'
    stem = [[[] for i in range(size[0])] for j in range(size[1])]
    # dprint(np.shape(cube))
    # plt.hist(packets[:,1], bins=100)
    # plt.show()
    for ip, p in enumerate(packets):
        x = np.int_(p[2])
        y = np.int_(p[3])
        stem[x][y].append([p[0],p[1]])
        if len(packets)>=1e7 and ip%10000==0: misc.progressBar(value = ip, endvalue=len(packets))
    # print cube[x][y]
    # cube = time_sort(cube)
    return stem

def ungroup(stem):
    photons = np.empty((0, 4))
    for x in range(mp.array_size[1]):
        for y in range(mp.array_size[0]):
            # print(x, y)
            if len(stem[x][y]) > 0:
                events = np.array(stem[x][y])
                xy = [[x, y]] * len(events) if len(events.shape)== 2 else [x,y]
                events = np.append(events, xy, axis=1)
                photons = np.vstack((photons, events))
                # print(events, np.shape(events))
                # timesort = np.argsort(events[:, 0])
                # events = events[timesort]
                # sep = events[:, 0] - np.roll(events[:, 0], 1, 0)
    return photons.T

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
    # bins = np.arange(-mp.frame_time/2 + start, ap.sample_time/2 + end, bin_time)
    # print start, end, ap.sample_time/2.

    bins = np.arange(start, end+ap.sample_time/2., bin_time)

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
    # print(len(cube), len(cube[0]), int_map.shape)
    for x in range(size[1]):
        for y in range(size[0]):
            int_map[x, y] = len(cube[x][y])

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

def scale_to_luminos(obs_sequence):
    obs_sequence *= ap.star_photons_per_s*np.ones((ap.grid_size,ap.grid_size))
    return obs_sequence

def stack_obs_sequence(obs_sequence):
    '''Similar to take_exposure but makes a single frame for the intension of doing SDI rather than applying noise etc'''
    # datacube = np.zeros((1, obs_sequence.shape[1],obs_sequence.shape[2], obs_sequence.shape[3]))
    datacube = np.sum(obs_sequence, axis=0)
    return datacube