import sys
sys.path.append('D:/dodkins/MEDIS/MEDIS')
from medis.params import tp, mp, cp, sp, ap
from get_photon_data import run
from medis.Utils.plot_tools import view_datacube, quicklook_im
import numpy as np
import matplotlib.pyplot as plt
from get_photon_data import run
import medis.Atmosphere.caos as caos

tp.detector = 'ideal'#
ap.numframes = 1
cp.frame_time = 0.001
tp.use_ao=True
tp.occulter_type = None#'GAUSSIAN'
sp.show_wframe = False
sp.return_cube=True
sp.show_cube=False
sp.num_processes=1
ap.companion = True
# ap.contrast = [0.5,0.5]#[0.1,0.1]
# ap.lods = [[-2.0,0.0],[1.0,0.0]]
ap.contrast = [0.1,0.1,0.1,0.1]#[0.1,0.1]
ap.lods = [[0.5,-0.5],[-1.0,1.0],[2.0,-2.0],[-3.0,3.0]]
tp.NCPA_type = None#'Wave'# #None
tp.CPA_type='Static'

tp.satelite_speck = True
tp.speck_peakIs = [0.025, 0.025]
tp.speck_phases = [np.pi / 2.,np.pi / 2.]
tp.speck_locs = [[50, 50], [100,100]]

if sp.show_wframe == 'continuous':
    sp.fig = plt.figure()
cp.vary_r0 = False # turn off the automatic variation
r0s = [0.004,0.102,0.200,0.465]


if __name__ == '__main__':
    datacube = []
    caos.get_r0s()
    all_r0s = cp.r0s
    for r0 in r0s:
        cp.r0s_idx = np.where(r0 == all_r0s)[0][0]
        print cp.r0s_idx, 'here'
        hypercube = run()
        # hypercube = np.array(hypercube)
        # print hypercube.shape
        image = hypercube[0,0]
        # quicklook_im(image)
        datacube.append(image)

tp.use_atmos = False
tp.use_ao = False
tp.CPA_type = None#'Quasi'# None


if __name__ == '__main__':
    hypercube = run()
    image = hypercube[0, 0]
    # quicklook_im(image)
    datacube.append((image))

    datacube = np.array(datacube)
    view_datacube(datacube, logAmp=True, axis=False)
    for i in range(len(datacube)):
        plt.plot(np.sum(datacube[i]*np.eye(tp.grid_size), axis=0))
    plt.figure()
    for i in range(len(datacube)):
        plt.plot(np.sum(datacube[i] * np.fliplr(np.eye(tp.grid_size)), axis=0))

    # plt.figure()
    # plt.plot(datacube[:, 64, 64])
    #
    # plt.figure()
    # plt.plot(datacube[:, 100, 100])
    # plt.plot(datacube[:,50,50])
    #
    # plt.figure()
    # plt.plot(datacube[:,46,81])
    # plt.plot(datacube[:,97,31])
    plt.show()