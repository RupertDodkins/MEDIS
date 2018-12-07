import sys, os
sys.path.append('D:/dodkins/MEDIS/MEDIS')
from params import tp, mp, cp, sp, ap
from Examples.get_photon_data import run
import matplotlib.pyplot as plt
import time
import numpy as np
import Detector.readout as read
from Utils.plot_tools import loop_frames, quicklook_im

ap.numframes = 1000
tp.detector = 'MKIDs'#
sp.save_obs = True
mp.date = '180324/'
mp.datadir= os.path.join(mp.rootdir,mp.data, mp.date)
mp.obsfile = 'test.h5'
print mp.datadir
sp.show_cube = False
sp.return_cube = False
cp.vary_r0 = True

sp.show_wframe = False#'continuous'
if sp.show_wframe == 'continuous':
    sp.fig = plt.figure()

mp.frame_time = 0.001#0.001
HyperCubeFile = 'hyper.pkl'

# def get_ref_psf():
#     ap.numframes = 1
#
#     print tp.occulter_type
#     hypercube = run()
#     frame = hypercube[0,0]
#     quicklook_im(frame)
#     with open('ref_psf.pkl', 'wb') as handle:
#         pickle.dump(frame, handle, protocol=pickle.HIGHEST_PROTOCOL)
#     return frame


if __name__ == '__main__':
    # tp.occulter_type = 'None'
    # get_ref_psf()

    # if os.path.isfile(HyperCubeFile):
    #     hypercube = read.open_hypercube(HyperCubeFile)
    # else:
    begin = time.time()
    run()
    # print np.shape(hypercube)
    # hypercube = read.take_exposure(hypercube)
    # read.save_hypercube(hypercube)
    end = time.time()
    # print end-begin
    # print hypercube.shape
    # loop_frames(hypercube[0])
    # loop_frames(hypercube[:,0])
    # ap.exposure_time = 0.05
    # hypercube = read.take_exposure(hypercube)
    # print hypercube.shape
    # HyperCubeFile = 'hyper_red.pkl'
    # hypercube = read.save_hypercube(hypercube, HyperCubeFile)