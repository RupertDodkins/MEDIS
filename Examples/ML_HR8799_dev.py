
import sys, os
# sys.path.append('D:/dodkins/MEDIS/MEDIS')
sys.path.append(os.environ['MEDIS_DIR'])
import numpy as np
import copy
import matplotlib.pyplot as plt
# from vip_hci import phot, pca
from medis.params import ap, cp, tp, sp, mp, iop
from medis.Utils.plot_tools import loop_frames, quicklook_im,view_datacube, compare_images, indep_images, grid
from medis.Utils.rawImageIO import clipped_zoom
import medis.Detector.readout as read
import medis.Analysis.phot
import medis.Analysis.stats
import pandas as pd
from medis.Utils.misc import dprint
import pickle as pickle



# Global params
sp.save_obs = True
sp.show_cube = True
sp.save_obs = False
sp.show_wframe = False
# ap.star_photons = 1e10#0.5e6# 1e9
ap.star_photons = 1e8#1e10#0.5e6# 1e9

# tp.beam_ratio = 0.6
tp.beam_ratio = 0.3#0.32
tp.servo_error= [0,1]#[0,1]#False # No delay and rate of 1/frame_time
tp.quick_ao=True
# tp.diam=8.
tp.use_spiders = True
tp.use_ao = True
# ap.star_photons*=1000
tp.diam = 8.0  # telescope diameter in meters
# tp.ao_act = 44
tp.ao_act = 44#50
tp.grid_size=256
mp.array_size = np.array([257,257])#
# mp.array_size = np.array([140,144])#

mp.total_pix = mp.array_size[0] * mp.array_size[1]
mp.xnum = mp.array_size[0]
mp.ynum = mp.array_size[1]

mp.R_mean = 20
mp.g_mean = 0.5
mp.g_sig = 0.05
mp.bg_mean = -10
mp.bg_sig = 40
mp.pix_yield = 0.95


# mp.hot_pix =True
mp.distort_phase =True
mp.phase_uncertainty =True
mp.phase_background=True
mp.respons_var = True
mp.bad_pix = True
mp.hot_pix = None



# tp.NCPA_type = None#'Static'
# tp.CPA_type = None#'Static'
# tp.NCPA_type = 'Static'
# tp.CPA_type = 'Static'
# tp.aber_params['OOPP'] = [8,4]
# tp.aber_vals['a'] = [8.0e-13, 4.0e-13]
# tp.aber_vals['a'] = [1.2e-13, 3e-14]
# tp.aber_vals['a'] = [7.2e-14, 3e-14]
tp.aber_vals['c'] = [3.0, 0.5]
ap.C_spec = 1.5
tp.aber_params = {'CPA': True,
                    'NCPA': True,
                    'QuasiStatic': False,  # or Static
                    'Phase': True,
                    'Amp': False,
                    'n_surfs': 4,
                    'OOPP': [16,8,8,16]}#False}#
# tp.aber_params['CPA'] = False
# tp.aber_params['NCPA'] = False
mp.date = '180930/'
import os
iop.update(mp.date)
# iop.aberdir = os.path.join(tp.rootdir, 'data/aberrations/180919e/')
# iop.aberdir = os.path.join(tp.rootdir, 'data/aberrations/180919b/')
# iop.aberdir = os.path.join(iop.rootdir, 'data/aberrations/180630_30mins')
# cp.date = '1804171hr8m/'
cp.date = '180828/'
iop.atmosdir= os.path.join(cp.rootdir,cp.data,cp.date)
sp.num_processes = 1
tp.occulter_type = 'Vortex'#'8th_Order'#
num_exp = 250#100#2000#1000#50#50#1000
ap.exposure_time = 1#0.1#05  # 0.001
cp.frame_time = 1#0.1#05
ap.numframes = int(num_exp * ap.exposure_time / cp.frame_time)
# ap.startframe=ap.numframes
ap.companion = False
# ap.contrast = [1e-4,1e-3,1e-5, 1e-6,1e-6,1e-7]  # [0.1,0.1]
# ap.lods = [[-1.5,1.5],[1,1],[-2.5,2.5],[-3,3],[3,3],[4.5,-4]]
# ap.contrast = [1e-5, 1e-6]  # [0.1,0.1]
# ap.lods = [[-2.5, 2.5], [-4.5, 4.5]]
ap.contrast = [10**-4.5,10**-4.2,10**-4.4,10**-4.4]  # [0.1,0.1]
ap.lods = [[3.64,-2.16],[-1,3.0],[-1.6,1.5],[-2,-1.6]]#[6,-4.5],
tp.detector = 'ideal'#'MKIDs'
# tp.platescale=10.
tp.platescale=5.
tp.piston_error = True
# tp.band = np.array([700, 1500])
# tp.nwsamp = 3#7#10#5#5#5#1.#
# tp.w_bins = 8#7#10#5#5#5#1.#
# tp.band = np.array([700, 1800])
tp.band = np.array([700, 1800])
tp.nwsamp = 1#4#5#3#7#10#5#5#5#1.#
tp.w_bins = 1#12#8#7#10#5#5#5#1.#

tp.rot_rate = 0  # deg/s
theta=45
lod = 8.
# iop.aberdir = 'D:/dodkins/MEDIS/data/aberrations/180902/'
# iop.aberdir = 'D:/dodkins/MEDIS/data/aberrations/180420/'
no_sauce = True
dprint(iop.aberdir)

if __name__ == '__main__':
    dprint(iop.aberdir)
    rad_samp = np.linspace(0,tp.platescale/1000.*128,50)
    print(rad_samp)


    ap.companion = True
    iop.hyperFile = iop.datadir + 'HR8799_phot_tag%i_tar_%i.pkl' % (num_exp, np.log10(ap.star_photons))
    dprint(iop.aberdir)
    simple_hypercube_1 = read.get_integ_hypercube(plot=False)[:, :]  # /ap.numframes

