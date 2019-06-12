import os
from matplotlib.pylab import plt
import numpy as np
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
ap.contrast = [1]
num_photons = 2048
ap.sample_time = 1e-3
ap.exposure_time = 1e-3
ap.star_photons = 1.5*num_photons/ap.sample_time # to account for throughput
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
timesamples = 10
num_images = 20
ap.numframes = batches * timesamples * num_images # 32*20*50 # batches x timesamples per image x input images

def reformat_obs():
    # for i in range(3):
    #     iop.obs_table = os.path.join(iop.testdir, 'ObsTable_i%i.h5' % i)
    photons = pipe.read_obs()
    print(photons[0][:10], len(photons[0]))
    cut = int(len(photons[0])/ap.numframes % 2048)
    print(cut)
    data = []
    for o in range(2):
        obj_photons = photons[o][:-cut*ap.numframes, [0,2,3]]
        # print(obj_photons[:10])
        #TODO check how reshape does the ordering
        data.append(obj_photons.reshape(ap.numframes,2048,3))
        # print(data[o][:10])

    labels = np.zeros(ap.numframes*2, dtype=int)
    labels[-ap.numframes:] = 1

    reorder = np.arange(ap.numframes*2)
    np.random.shuffle(reorder)

    labels = labels[reorder]

    data = np.concatenate((data[0], data[1]),axis=0)

    data = data[reorder]

    trainfile = os.path.join(iop.testdir, 'trainfile.h5')
    with h5py.File(trainfile, 'w') as hf:
        hf.create_dataset('data', data=data[:-int(test_frac*ap.numframes*2)])
        hf.create_dataset('label', data=labels[:-int(test_frac*ap.numframes*2)])
    testfile = os.path.join(iop.testdir, 'testfile.h5')
    with h5py.File(testfile, 'w') as hf:
        hf.create_dataset('data', data=data[-int(test_frac*ap.numframes*2):])
        hf.create_dataset('label', data=labels[-int(test_frac*ap.numframes*2):])

def make_images():
    # for i in range(3):
    #     iop.obs_table = os.path.join(iop.testdir, 'ObsTable_i%i.h5' % i)
        # if ap.numframes <= 20000 and not os.path.exists(iop.fields):
        #     run_dashboard()
        # else:
    run_medis(realtime=False)

if __name__ == "__main__":
    # make_images()
    reformat_obs()

    # photons = pipe.read_obs()
    # print(photons[0].shape)
    # print(photons[1].shape)
    # allphotons = np.vstack((photons[0], photons[1]))
    # # X = np.array([[1, 2], [1, 4], [1, 0],
    # #               [10, 2], [10, 4], [10, 0]])
    # kmeans = KMeans(n_clusters=2, random_state=0).fit(allphotons)
    # class1 = allphotons[kmeans.labels_ == 0]
    # class2 = allphotons[kmeans.labels_ == 1]
    #
    #
    # spectralcube = MKIDs.makecube(photons[0], mp.array_size)
    # plt.figure()
    # plt.imshow(spectralcube[0], norm=LogNorm())
    # spectralcube = MKIDs.makecube(photons[1], mp.array_size)
    # plt.figure()
    # plt.imshow(spectralcube[0], norm=LogNorm())
    # spectralcube = MKIDs.makecube(class1, mp.array_size)
    # plt.figure()
    # plt.imshow(spectralcube[0], norm=LogNorm())
    # spectralcube = MKIDs.makecube(class2, mp.array_size)
    # plt.figure()
    # plt.imshow(spectralcube[0], norm=LogNorm())
    # spectralcube = MKIDs.makecube(allphotons, mp.array_size)
    # plt.figure()
    # plt.imshow(spectralcube[0], norm=LogNorm())
    # plt.show()
    #
    # print(kmeans.predict([photons[1][0], photons[1][1]]))
    #
    # print(kmeans.cluster_centers_)
