'''Implementation and Analysis plots from first principle simulator publication'''

import os
import numpy as np
import matplotlib as mpl
# mpl.use('Qt5Agg')
from matplotlib.colors import LogNorm, SymLogNorm
import medis.get_photon_data as gpd
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
# from matplotlib.colors import LogNorm
import pickle as pickle
from medis.Utils.plot_tools import loop_frames, quicklook_im, view_datacube, compare_images, indep_images, grid
from medis.Utils.misc import dprint
from medis.Dashboard.twilight import sunlight, twilight
from medis.params import tp, mp, sp, ap, iop, cp
from medis.Detector import mkid_artefacts as MKIDs
from medis.Detector import temporal as temp
from medis.Detector import spectral as spec
from medis.Detector import pipeline as pipe

make_figure = 0

sp.num_processes = 8
sp.return_E = True

# Astro Parameters
ap.companion = False
ap.star_photons_per_s = int(2e6)
ap.lods = [[-1.2, 4.5]] # initial location (no rotation)

# Telescope/optics Parameters
ap.grid_size = 256
tp.diam = 8.
tp.beam_ratio = 0.5
tp.obscure = True
tp.use_ao = True
tp.include_dm = True
tp.include_tiptilt = False
tp.ao_act = 50
tp.use_atmos = True
# tp.use_zern_ab = True
tp.occulter_type = 'Vortex'  # 'None'
tp.aber_params = {'CPA': True,
                  'NCPA': True,
                  'QuasiStatic': False,  # or Static
                  'Phase': True,
                  'Amp': False,
                  'n_surfs': 8,
                  'OOPP': False}#[16,8,8,16,4,4,8,16]}#False}#
# tp.aber_vals = {'a': [1e-17, 0.2e-17],
#                'b': [0.8, 0.2],
#                'c': [3.1,0.5],
#                'a_amp': [0.05,0.01]}
tp.aber_vals = {'a': [1e-18, 2e-20],#'a': [5e-17, 1e-18],
                'b': [2.0, 0.2],
                'c': [3.1, 0.5],
                'a_amp': [0.05, 0.01]}
tp.legs_frac = 0.03

tp.satelite_speck = True

# Wavelength and Spectral Range
ap.sample_time = 0.1
# tp.piston_error = True
# tp.pix_shift = [[15,30],[-30,15],[-15,-30],[30,-15]]
tp.pix_shift = [[15,30]]

# MKID Parameters
mp.phase_uncertainty = True
mp.phase_background = True
mp.QE_var = True
mp.bad_pix = True
mp.dark_counts = True
mp.hot_pix = 1
mp.dark_pix_frac = 0.5
mp.array_size = np.array([142,146])
mp.R_mean = 8
mp.g_mean = 0.2
mp.g_sig = 0.04
mp.r_mean = 1
mp.r_sig = 0.1
mp.bg_mean = -10
mp.bg_sig = 10
mp.pix_yield = 0.8  # check dis
mp.dark_bright = 5e4
mp.hot_bright = 4e3
mp.dead_time = 1e-5
mp.wavecal_coeffs = [1./6, -250]

# sp.save_fields = False
ap.nwsamp = 3
ap.w_bins = 3
ap.numframes = 5

sp.save_locs = np.array(['add_atmos', 'add_aber', 'deformable_mirror', 'add_aber', 'prop_mid_optics'])
sp.gui_map_type = np.array(['phase', 'phase', 'phase', 'phase', 'amp'])

from medis.Dashboard.run_dashboard import run_dashboard

tp.detector = 'ideal'

def make_figure0():

    # iop.update("first_principle/figure0")
    # iop.aberdir = os.path.join(iop.datadir, iop.aberroot, 'Palomar256')
    # iop.quasi = os.path.join(iop.aberdir, 'quasi')
    # iop.atmosdata = '190823'
    # iop.atmosdir = os.path.join(iop.datadir, iop.atmosroot, iop.atmosdata)  # full path to FITS files
    # iop.atmosconfig = os.path.join(iop.atmosdir, 'config.txt')

    filename = __file__.split('/')[-1].split('.')[0]
    iop.set_testdir(f'{filename}/')
    iop.set_atmosdata('190823')
    iop.set_aberdata(f'Palomar{ap.grid_size}')


    phase_ind = range(4)

    if __name__ == '__main__':  # required for multiprocessing - make sure globals are set before though
        run_dashboard()
        fields = gpd.run_medis()
        for i in range(6):
            spectralcube = np.abs(fields[0, i, :, 0]**2)
            throughput = np.sum(spectralcube, axis=(1, 2))
            dprint(spectralcube.shape)
            if i >=4:
                logAmp = True
            else:
                logAmp = False
            view_datacube(spectralcube,logAmp=logAmp)
            plt.figure()
            plt.plot(throughput)
            plt.show(block=True)

if make_figure == 0:
    make_figure0()