'''This code handles the relevant functionality of a Hawaii 2RG camera'''
import sys
sys.path.append('D:/dodkins/MEDIS/MEDIS')
import numpy as np
import copy
import matplotlib.pyplot as plt
from vip_hci import phot, pca
from medis.params import ap, cp, tp, sp, mp, iop
from medis.Utils.plot_tools import loop_frames, quicklook_im,view_datacube, compare_images, indep_images
from medis.Utils.rawImageIO import clipped_zoom
import medis.Detector.readout as read
import medis.Analysis.phot
import medis.Analysis.stats
import pandas as pd
from medis.Utils.misc import dprint

# Global params
sp.save_obs = False
sp.show_cube = False
sp.save_obs = False
sp.show_wframe = False
# ap.star_photons = 1e10#0.5e6# 1e9
ap.star_photons = 1e10#0.5e6# 1e9

tp.beam_ratio = 0.3
tp.servo_error= [0,1]#[0,1]#False # No delay and rate of 1/frame_time
tp.quick_ao=True
# tp.diam=8.
tp.use_spiders = True
tp.use_ao = True
# ap.star_photons*=1000
tp.diam = 8.0  # telescope diameter in meters
tp.ao_act = 44
tp.grid_size=256
mp.array_size = np.array([257,257])#
mp.total_pix = mp.array_size[0] * mp.array_size[1]
mp.xnum = mp.array_size[0]
mp.ynum = mp.array_size[1]
mp.R_mean = 30
mp.distort_phase =True
mp.phase_uncertainty =True
mp.phase_background=True
mp.respons_var = True
mp.bad_pix = True
mp.pix_yield = 0.95
# tp.NCPA_type = None#'Static'
# tp.CPA_type = None#'Static'
# tp.NCPA_type = 'Static'
# tp.CPA_type = 'Static'
# tp.aber_params['OOPP'] = [8,4]
tp.aber_params = {'CPA': True,
                    'NCPA': True,
                    'QuasiStatic': True,  # or Static
                    'Phase': True,
                    'Amp': False,
                    'n_surfs': 4,
                    'OOPP': [16,8,8, 4]}#False}#
mp.date = '180830/'
import os
iop.update(mp.date)
# iop.aberdir = os.path.join(iop.rootdir, 'data/aberrations/180630_30mins')
# cp.date = '1804171hr8m/'
cp.date = '180829/180828/'
iop.atmosdir= os.path.join(cp.rootdir,cp.data,cp.date)
sp.num_processes = 30
tp.occulter_type = 'None'
num_exp = 1000#2000#1000#50#50#1000
ap.exposure_time = 0.1#05  # 0.001
cp.frame_time = 0.1#05
ap.numframes = int(num_exp * ap.exposure_time / cp.frame_time)
# ap.startframe=ap.numframes
ap.companion = False

tp.detector = 'ideal'# 'MKIDs'#
tp.platescale=10
tp.piston_error = True
xlocs = range(0, 128)  # range(0,128)#65
ylocs = range(0, 128)  # range(0,128)#85
tp.band = np.array([800, 1500])
tp.nwsamp = 1#7#10#5#5#5#1.#
tp.rot_rate = 0  # deg/s
theta=45
lod = 8
tp.atmos_vary = True

plotdata, maps = [], []
if __name__ == '__main__':


    iop.hyperFile = iop.datadir + 'SSD_test.pkl'  # 5
    simple_hypercube_1 = read.get_integ_hypercube(plot=False)#/ap.numframes
    dprint(simple_hypercube_1.shape)
    plt.plot(simple_hypercube_1[:,0,128,128])
    plt.figure()
    plt.hist(simple_hypercube_1[:,0,128,128])
    plt.show()


