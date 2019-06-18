import os
from matplotlib.pylab import plt
from mpl_toolkits.mplot3d import Axes3D
import numpy as np
import itertools
import random
import h5py
from medis.params import sp, ap, tp, iop, cp
from medis.get_photon_data import run_medis
import medis.Dashboard.helper as help
import medis.Detector.pipeline as pipe
from medis.Utils.misc import dprint

import warnings
warnings.filterwarnings("ignore")

sp.use_gui = True
sp.show_cube = False

# sp.save_locs = np.array(['add_atmos', 'tiptilt', 'closedloop_wfs', 'prop_mid_optics'])
# sp.gui_map_type = np.array(['phase', 'phase', 'phase', 'amp'])
sp.save_locs = np.array(['prop_mid_optics'])
sp.gui_map_type = np.array([ 'amp'])
# sp.save_locs = np.array(['add_atmos', 'closedloop_wfs', 'prop_mid_optics'])
# sp.gui_map_type = np.array(['phase', 'phase', 'amp'])

sp.metric_funcs = [help.plot_counts]#, help.take_acf, help.plot_stats]
locs = [[70,65], [65,83], [83,65], [65,70]]
sp.metric_args = [locs]*len(sp.metric_funcs)
ap.nwsamp = 1
ap.w_bins = 1
tp.include_dm = False
tp.include_tiptilt = True
tp.occulter_type = None
ap.companion = True
ap.contrast = [0.1]

starmultiplier = 1./ap.contrast[0]
reduction = 1./(1+starmultiplier)

point_num = 2048
num_photons = int(point_num*reduction*starmultiplier)
dprint(num_photons)

ap.sample_time = 1e-3
ap.exposure_time = 1e-3
ap.star_photons = num_photons/ap.sample_time/0.8 # to account for throughput
tp.beam_ratio = 0.5 #0.75
ap.grid_size = 128
# tp.detector = 'MKIDs'
tp.detector = 'ideal'
tp.quick_ao = False
tp.servo_error = [0, 1]
tp.use_atmos = False
tp.use_ao = False
tp.aber_params['CPA'] = False
tp.aber_params['NCPA'] = False


##set telescope parameters
tp.use_ao = True #AO off/on
# tp.detector = 'ideal'
tp.detector = 'MKIDs'

##set simulation parameters
sp.num_processes = 1
sp.gui_samp = 1
sp.save_obs = True
sp.save_fields =False

iop.update("AIPD/")

from medis.Dashboard.run_dashboard import run_dashboard

test_frac = 0.2
batches = 5
# timesamples = 20
# num_images = 20
# ap.numframes = batches * timesamples * num_images # 32*20*50 # batches x timesamples per image x input images
ap.numframes = 2048  #2048 # 32*20*50 # batches x timesamples per image x input images

# def disarange(array):
#     nrows, ncols = array.shape
#     all_perm = np.array((list(np.random.permutation(range(ncols)))))
#     b = all_perm[np.random.randint(0, all_perm.shape[0], size=nrows)]
#     return array.take((b+3*np.arange(nrows)[...,np.newaxis]).ravel()).reshape(array.shape)

def reformat_obs_sem(plot=False, save=True):
    """
    Reformat the obs files into the pointnet segmentation input data format
    :return:
    """

    photons = pipe.read_obs()
    print(photons[0][:10], len(photons[0]))
    data = np.empty((ap.numframes,0,3))
    true_num_photons = []
    for o in range(2):
        true_num_photons.append(int(len(photons[o])/ap.numframes))
        dprint((photons[o].shape, true_num_photons[o]))

        obj_photons = photons[o][:, [0,2,3]]
        ref_photons = obj_photons.reshape(ap.numframes, -1, 3)
        data = np.concatenate((data, ref_photons), axis=1)

    cut = int(data.shape[1] % point_num)
    rand_cut = np.random.uniform(0, data.shape[1], cut).astype(np.int)
    pids = np.zeros((ap.numframes, data.shape[1]), dtype=int)
    pids[:, true_num_photons[0]:] = 1

    if plot:
        fig = plt.figure()
        ax = fig.add_subplot(111, projection='3d')
        print(data.shape, pids.shape)
        # print(data[0, :, 0], data[0, :, 1], data[0, :, 2], pids[0])
        # c = np.chararray(len(pids[0]))
        # c[pids[0]==0] = 'o'
        # c[pids[0]==1] = 'b'
        colors = ['orange', 'orange']
        bounds = [0,true_num_photons[0],data.shape[1]]

        # ax.scatter(data[:, bounds[i]:bounds[i + 1], 0], data[0, bounds[i]:bounds[i + 1], 1],
        #            data[0, bounds[i]:bounds[i + 1], 2], c=c)
        for t in range(10):
            for i, c in enumerate(colors):
                print(i, c)
                ax.scatter(data[t, bounds[i]:bounds[i+1], 0], data[t, bounds[i]:bounds[i+1], 1], data[t, bounds[i]:bounds[i+1], 2], c=c)#, marker=pids[0])
        plt.show()

    data = np.delete(data, rand_cut, axis=1)
    pids = np.delete(pids, rand_cut, axis=1)



    labels = np.zeros((ap.numframes), dtype=int)

    reorder = np.apply_along_axis(np.random.permutation, 1, np.ones((ap.numframes,point_num))*np.arange(point_num)).astype(np.int)

    data = np.array([data[o, order] for o, order in enumerate(reorder)])
    pids = np.array([pids[o, order] for o, order in enumerate(reorder)])



    if save:
        trainfile = os.path.join(iop.testdir, 'trainfile_unorder.h5')
        with h5py.File(trainfile, 'w') as hf:
            hf.create_dataset('data', data=data[:-int(test_frac*ap.numframes)])
            hf.create_dataset('label', data=labels[:-int(test_frac*ap.numframes)])
            hf.create_dataset('pid', data=pids[:-int(test_frac*ap.numframes)])
        testfile = os.path.join(iop.testdir, 'testfile_unorder.h5')
        with h5py.File(testfile, 'w') as hf:
            hf.create_dataset('data', data=data[-int(test_frac*ap.numframes):])
            hf.create_dataset('label', data=labels[-int(test_frac*ap.numframes):])
            hf.create_dataset('pid', data=pids[-int(test_frac * ap.numframes):])

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

    run_medis(realtime=False)



if __name__ == "__main__":
    # make_input()
    reformat_obs_sem(save=False, plot=True)