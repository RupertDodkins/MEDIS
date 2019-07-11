'''Implementation and Analysis plots from first principle simulator publication'''

import os
import numpy as np
import matplotlib as mpl
mpl.use('Qt5Agg')
from medis.params import tp, mp, cp, sp, ap, iop
import medis.get_photon_data as gpd
import matplotlib.pyplot as plt
from matplotlib.colors import LogNorm
from medis.Utils.plot_tools import loop_frames, quicklook_im, view_datacube, compare_images, indep_images, grid
import pickle
from medis.Utils.misc import dprint
from medis.Dashboard.twilight import sunlight, twilight

sp.return_E = True

# Astro Parameters
ap.companion = False
ap.star_photons_per_s = int(1e7)
ap.lods = [[-1.2, 4.5]] # initial location (no rotation)

# Telescope/optics Parameters
ap.grid_size = 256
tp.diam = 8.
tp.beam_ratio = 0.5
tp.obscure = True
tp.use_ao = True
# tp.include_tiptilt= False
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
tp.aber_vals = {'a': [1e-17, 0.2e-17],
               'b': [0.8, 0.2],
               'c': [3.1,0.5],
               'a_amp': [0.05,0.01]}
tp.legs_frac = 0.03

# Wavelength and Spectral Range
ap.nwsamp = 1
ap.w_bins = 1
num_exp = 1 #5000
ap.sample_time = 0.1
ap.numframes = int(num_exp * ap.sample_time / ap.sample_time)
# tp.piston_error = True
tp.pix_shift = [30,0]

# MKID Parameters
mp.phase_uncertainty = True
mp.phase_background = True
mp.respons_var = True
mp.bad_pix = True
mp.hot_pix = 1
mp.array_size = np.array([142,146])
mp.R_mean = 8
mp.g_mean = 0.2
mp.g_sig = 0.04
mp.bg_mean = -10
mp.bg_sig = 40
mp.pix_yield = 0.7  # check dis

# sp.get_ints = {'w': [0], 'c': [0]}

# ***** These need to be outside the if statement to have an effect!! ****
iop.aberdata = 'Palomar' # Rename Data Directory
iop.update("first_principle/")
if os.path.exists(iop.int_maps):
    os.remove(iop.int_maps)

tp.detector = 'ideal'

sp.save_locs = np.array(['add_atmos', 'add_aber', 'deformable_mirror', 'add_aber', 'prop_mid_optics'])
sp.gui_map_type = np.array(['phase', 'phase', 'phase', 'phase', 'amp'])
phase_ind = range(4)


if __name__ == '__main__':

    # Starting the Simulation
    print("Starting ideal-detector example")
    fields = gpd.run_medis()[0, :, 0, 0, ap.grid_size//4:-ap.grid_size//4, ap.grid_size//4:-ap.grid_size//4]
    print("finished Ideal-loop")

    pupils = np.angle(fields[phase_ind], deg=False)
    focals = np.absolute(fields[4:])
    grid(pupils, logAmp=False, colormap=twilight, vmins=[-np.pi]*len(sp.save_locs), vmaxs=[np.pi]*len(sp.save_locs))
    grid(focals, logAmp=True, colormap='viridis')


if __name__ == "__main__":

    fields = gpd.run_medis(realtime=False)