from sklearn.cluster import KMeans
import numpy as np


import numpy as np
from PyQt5 import QtWidgets
from statsmodels.tsa.stattools import acf
# from vip_hci import phot, pca
from matplotlib.pylab import plt
from matplotlib.colors import LogNorm, SymLogNorm
from medis.Dashboard.run_dashboard import run_dashboard
from medis.params import sp, ap, tp, iop, mp
from medis.Utils.misc import dprint
import medis.Detector.readout as read
import medis.Detector.pipeline as pipe
import medis.Detector.mkid_artefacts as MKIDs


def take_acf(obs_sequence, locs=None, radius = 10):
    if locs is None:
        locs = [[65,65], [65,83], [83,65], [83,83]]

    corrs = []

    if len(obs_sequence) > 2:
        for (x,y) in locs:
            # print(my_round(np.mean(obs_sequence[:, :, x:x+radius, y:y+radius], axis=(1, 2, 3)), 3))
            corr = acf(np.mean(obs_sequence[:, :, x:x+radius, y:y+radius], axis=(1, 2, 3)), fft=True, nlags=20)
            corrs.append(corr)
    else:
        corrs = np.empty((len(locs)))
        corrs[:] = np.nan

    return corrs

sp.metric_args = [[[65,65], [65,83], [83,65], [83,83]]]

sp.metric_funcs = [take_acf]

sp.use_gui = True
# sp.save_locs = np.array(['coronagraph'])

ap.nwsamp = 1
ap.w_bins = 1
# ap.grid_size = 148
ap.companion = True
ap.contrast = [1e-2]
ap.star_photons = 1e8
ap.exposure_time = 1e-3
# tp.use_atmos = False
# tp.use_ao = False
ap.numframes = 5

##set telescope parameters
tp.use_ao = True #AO off/on
# tp.detector = 'ideal'
tp.detector = 'MKIDs'

##set simulation parameters
sp.num_processes = 1
# sp.save_locs = np.array(['coronagraph'])
# sp.return_E = True
sp.save_obs = True

iop.update("AIPD/")

import random

if __name__ == "__main__":
    # run_dashboard()

    photons = pipe.read_obs()
    print(photons[0].shape)
    print(photons[1].shape)
    allphotons = np.vstack((photons[0], photons[1]))
    # X = np.array([[1, 2], [1, 4], [1, 0],
    #               [10, 2], [10, 4], [10, 0]])
    kmeans = KMeans(n_clusters=2, random_state=0).fit(allphotons)
    class1 = allphotons[kmeans.labels_ == 0]
    class2 = allphotons[kmeans.labels_ == 1]


    spectralcube = MKIDs.makecube(photons[0], mp.array_size)
    plt.figure()
    plt.imshow(spectralcube[0], norm=LogNorm())
    spectralcube = MKIDs.makecube(photons[1], mp.array_size)
    plt.figure()
    plt.imshow(spectralcube[0], norm=LogNorm())
    spectralcube = MKIDs.makecube(class1, mp.array_size)
    plt.figure()
    plt.imshow(spectralcube[0], norm=LogNorm())
    spectralcube = MKIDs.makecube(class2, mp.array_size)
    plt.figure()
    plt.imshow(spectralcube[0], norm=LogNorm())
    spectralcube = MKIDs.makecube(allphotons, mp.array_size)
    plt.figure()
    plt.imshow(spectralcube[0], norm=LogNorm())
    plt.show()

    print(kmeans.predict([photons[1][0], photons[1][1]]))

    print(kmeans.cluster_centers_)
