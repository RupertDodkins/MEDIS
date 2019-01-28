'''Apparently cannot communicate between queues on Windows. This may work on U(/Li)nux'''
import sys, os

sys.path.append('D:/dodkins/MEDIS/MEDIS')
import glob
import numpy as np
# np.set_printoptions(threshold=np.inf)
import multiprocessing
import matplotlib.pylab as plt
from medis.params import ap, cp, tp, mp, sp, iop
# import medis.Detector.analysis as ana
import medis.Detector.pipeline as pipe
# import medis.Detector.temporal as temp
import medis.Detector.spectral as spec
from scipy.optimize import curve_fit
import medis.Utils.misc as misc
import medis.Detector.get_photon_data as gpd
import Examples.SSD_example as SSD
import medis.Analysis.stats as stats
import traceback
import itertools

# os.system("taskset -p 0xfffff %d" % os.getpid())
ap.star_photons = int(1e5)
ap.companion = True
ap.contrast = [0.01]#[0.1,0.1]
ap.lods = [[-2.5,2.5]]
ap.numframes = 500
tp.detector = 'MKIDs'
sp.save_obs = True
mp.date = '180406b/'
iop.update('180406b/')
sp.show_cube = False
sp.return_cube = False
cp.vary_r0 = True
tp.use_atmos = True
tp.ao_act = 29 #odd numbers appear to remove the cross pattern
tp.use_ao = True  # True
# tp.occulter_type = 'None'  #
tp.occulter_type = '8TH_ORDER'  #
tp.NCPA_type = 'Static'
tp.CPA_type = 'Static'
tp.nwsamp = 1
tp.satelite_speck = False
tp.speck_peakIs = [0.05]#[0.01, 0.0025]
tp.speck_phases = [np.pi/2]#[np.pi / 2.,np.pi / 2.]
tp.speck_locs = [[64,30]]#[[50, 50], [100,100]]
sp.show_wframe = False  # 'continuous'
tp.piston_error = True
if sp.show_wframe == 'continuous':
    sp.fig = plt.figure()
sp.num_processes = 30

ints = np.empty(0)
times = np.empty(0)
max_photons = 5e7  # 5e7 appears to be the max Pool can handle irrespective of machine capability?
# ap.numframes=200
num_chunks = int(ap.star_photons * ap.numframes / max_photons)
if num_chunks < 1:
    num_chunks = 1
print num_chunks

mp.bin_time = 2e-3
num_ints = int(cp.frame_time * ap.numframes / mp.bin_time)

xlocs = range(0, 129)
ylocs = range(0, 129)


# # preview mode
# sp.num_processes = 1
# tp.detector = 'ideal'
# sp.show_wframe = True  # 'continuous'
# mp.date = 'placeholder/'
# mp.datadir = os.path.join(mp.rootdir, mp.data, mp.date)



if __name__ == '__main__':

    if not os.path.isfile(mp.datadir + mp.obsfile):
        gpd.take_obs_data()

    if not os.path.isfile(iop.LCmapFile):
        LCmap = stats.get_LCmap()

    stats.plot_DSI(xlocs, ylocs, iop.LCmapFile)
