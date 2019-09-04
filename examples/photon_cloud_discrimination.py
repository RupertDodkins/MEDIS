import os
from matplotlib.pylab import plt
from mpl_toolkits.mplot3d import Axes3D
import numpy as np
import random
import itertools
import random
import h5py
from medis.params import sp, ap, tp, iop, cp
from medis.get_photon_data import run_medis
import medis.Dashboard.helper as help
import medis.Detector.pipeline as pipe
from medis.Utils.misc import dprint
# from pointnet_mod.part_seg import train

import warnings
warnings.filterwarnings("ignore")

sp.use_gui = False
sp.show_cube = False

if sp.use_gui:
    sp.save_locs = np.array(['add_atmos', 'tiptilt','deformable_mirror',  'prop_mid_optics', 'coronagraph'])
    sp.gui_map_type = np.array(['phase','phase', 'phase', 'amp', 'amp'])

    sp.metric_funcs = [help.plot_counts]#, help.take_acf, help.plot_stats]
    locs = [[70,65], [65,83], [83,65], [65,70]]
    sp.metric_args = [locs]*len(sp.metric_funcs)
    sp.gui_samp = 1

ap.nwsamp = 1
ap.w_bins = 1
tp.include_tiptilt = True
tp.include_dm = True
tp.occulter_type = 'Vortex'
ap.companion = True

tp.beam_ratio = 0.5 #0.75
ap.grid_size = 128
tp.quick_ao = True
tp.servo_error = [0, 1]
tp.use_atmos = True
tp.aber_params['CPA'] = False
tp.aber_params['NCPA'] = False
tp.use_ao = True #AO off/on
tp.detector = 'MKIDs'

##set simulation parameters
sp.num_processes = 10
sp.save_obs = True
sp.save_fields =False

# iop.datadir = '/mnt/data0/dodkins/medis_save'
iop.update("AIPD/")

from medis.Dashboard.run_dashboard import run_dashboard

test_frac = 0.2

ap.contrast = [0.1]
ap.lods = [[-2.0, 2.0]]

starmultiplier = 1./ap.contrast[0]
reduction = 1./(1+starmultiplier)

ap.sample_time = 1e-2
ap.exposure_time = 1e-2
timesamp_per_cube = 100
point_num = 81920
throughput = 0.22 # the sum of the proper wavefront**2
star_photons_per_cube = point_num*reduction*starmultiplier/throughput  # per cube
dprint(star_photons_per_cube)
time_ratio = ap.sample_time * timesamp_per_cube
ap.star_photons_per_s = star_photons_per_cube/time_ratio  # if cube duration is 1s then this is same as star_photons_per_cube

# timesamples = 20
# num_images = 20
# ap.numframes = batches * timesamples * num_images # 32*20*50 # batches x timesamples per image x input images
num_cubes = 30
ap.numframes = num_cubes*timesamp_per_cube#2048  #2048 # 32*20*50 # batches x timesamples per image x input images


def plot_stats(data):
    starlocs = np.where(np.logical_and.reduce((data[:,:,1] >= 62., data[:,:,1] <= 70., data[:,:,2] >= 62., data[:,:,2] <= 70.)))
    inten = np.histogram(data[starlocs[0], starlocs[1], 0], bins=100)[0]
    plt.plot(inten)
    plt.figure()
    plt.hist(inten, bins=25)
    plt.figure()

    planetlocs = np.where(
        np.logical_and.reduce((data[:, :, 1] >= 36., data[:, :, 1] <= 44., data[:, :, 2] >= 76., data[:, :, 2] <= 84.)))
    inten = np.histogram(data[planetlocs[0], planetlocs[1], 0], bins=100)[0]
    plt.plot(inten)
    plt.figure()
    plt.hist(inten, bins=25)
    plt.figure()

    specklocs = np.where(
        np.logical_and.reduce((data[:, :, 1] >= 76., data[:, :, 1] <= 84., data[:, :, 2] >= 36., data[:, :, 2] <= 44.)))
    inten = np.histogram(data[specklocs[0], specklocs[1], 0], bins=100)[0]
    plt.plot(inten)
    plt.figure()
    plt.hist(inten, bins=25)
    plt.show(block=True)


    # plt.hist(np.logical_and(data[:,:,1] == 40., data[:,:,2] == 80.))
    # plt.show()


def reformat_obs_sem(plot=False, save=True, study_stats=False):
    """
    Reformat the obs files into the pointnet segmentation input data format
    :return:
    """
    if save:
        plot=False

    photons = pipe.read_obs()
    print(photons[0][:10])
    all_photons = np.empty((0,3))  #photonlist with both types of photon
    all_pids = np.empty((0,1))  #associated photon labels
    total_photons = len(photons[0]) + len(photons[1])

    for o in range(2):
        dprint((all_photons.shape, photons[o][:, [0,2,3]].shape))
        all_photons = np.concatenate((all_photons, photons[o][:, [0,2,3]]), axis=0)
        all_pids = np.concatenate((all_pids, np.ones_like((photons[o][:, [0]]))*o), axis=0)

    #sort by time so the planet photons slot amongst the star photons at the appropriate point
    time_sort = np.argsort(all_photons[:, 0]).astype(int)

    all_photons = all_photons[time_sort]
    all_pids = all_pids[time_sort]

    # remove residual photons that won't fit into a input cube for the network
    cut = int(total_photons % point_num)
    dprint(cut)
    rand_cut = random.sample(range(total_photons), cut)
    red_photons = np.delete(all_photons, rand_cut, axis=0)
    red_pids = np.delete(all_pids, rand_cut, axis=0)

    print(all_photons.shape, red_photons.shape, len(rand_cut))

    #raster the list so that every point_num start a new input cube
    ref_photons = red_photons.reshape(-1, point_num, 3)
    ref_pids = red_pids.reshape(-1, point_num, 1)

    if plot:
        fig = plt.figure()
        ax = fig.add_subplot(111, projection='3d')
        colors = ['blue', 'orange']
        # bounds = [0,len(photons[0]),data.shape[1]]
        # ax.scatter(data[:, bounds[i]:bounds[i + 1], 0], data[0, bounds[i]:bounds[i + 1], 1],
        #            data[0, bounds[i]:bounds[i + 1], 2], c=c)
        for t in range(10):
            for i, c in enumerate(colors):
                ax.scatter(ref_photons[t, [ref_pids[0]==i], 0], ref_photons[t, [ref_pids[0]==i], 1],
                           ref_photons[t, [ref_pids[0]==i], 2], c=c)#, marker=pids[0])
        plt.show()

    num_input = len(ref_photons)  # 16

    labels = np.zeros((num_input), dtype=int)

    reorder = np.apply_along_axis(np.random.permutation, 1,
                                  np.ones((num_input, point_num))*np.arange(point_num)).astype(np.int)

    data = np.array([ref_photons[o, order] for o, order in enumerate(reorder)])
    pids = np.array([ref_pids[o, order] for o, order in enumerate(reorder)])[:,:,0]
    # data = ref_photons
    # pids = ref_pids
    if study_stats:
        plot_stats(data)

    if save:
        trainfile = os.path.join(iop.testdir, 'trainfile_aber.h5')
        with h5py.File(trainfile, 'w') as hf:
            hf.create_dataset('data', data=data[:-int(test_frac * num_input)])
            hf.create_dataset('label', data=labels[:-int(test_frac * num_input)])
            hf.create_dataset('pid', data=pids[:-int(test_frac * num_input)])
        testfile = os.path.join(iop.testdir, 'testfile_aber.h5')
        with h5py.File(testfile, 'w') as hf:
            hf.create_dataset('data', data=data[-int(test_frac * num_input):])
            hf.create_dataset('label', data=labels[-int(test_frac * num_input):])
            hf.create_dataset('pid', data=pids[-int(test_frac * num_input):])

# def reformat_obs_class():
#     """
#     Reformat the obs files into the pointnet input data format
#     :return:
#     """
#
#     photons = pipe.read_obs()
#     print(photons[0][:10], len(photons[0]))
#     cut = int(len(photons[0])/ap.numframes % 2048)
#     print(cut)
#     data = []
#     for o in range(2):
#         obj_photons = photons[o][:-cut*ap.numframes, [0,2,3]]
#         # print(obj_photons[:10])
#         #TODO check how reshape does the ordering
#         data.append(obj_photons.reshape(ap.numframes,2048,3))
#         # print(data[o][:10])
#
#     labels = np.zeros(ap.numframes*2, dtype=int)
#
#     labels[-ap.numframes:] = 1
#
#     reorder = np.arange(ap.numframes*2)
#     np.random.shuffle(reorder)
#
#     labels = labels[reorder]
#
#     data = np.concatenate((data[0], data[1]),axis=0)
#
#     data = data[reorder]
#
#     trainfile = os.path.join(iop.testdir, 'trainfile.h5')
#     with h5py.File(trainfile, 'w') as hf:
#         hf.create_dataset('data', data=data[:-int(test_frac*ap.numframes*2)])
#         hf.create_dataset('label', data=labels[:-int(test_frac*ap.numframes*2)])
#     testfile = os.path.join(iop.testdir, 'testfile.h5')
#     with h5py.File(testfile, 'w') as hf:
#         hf.create_dataset('data', data=data[-int(test_frac*ap.numframes*2):])
#         hf.create_dataset('label', data=labels[-int(test_frac*ap.numframes*2):])

def make_input():
    """
    Make the train/test data for point cloud classification algorithm
    :return:
    """
    if sp.use_gui:
        run_dashboard()
    else:
        run_medis(realtime=False)



if __name__ == "__main__":
    # make_input()
    # reformat_obs_sem(save=True, plot=False)
    reformat_obs_sem(save=False, plot=True, study_stats=False)
    # train.train()