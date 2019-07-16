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


sp.show_wframe = False
sp.save_obs = False
sp.show_cube = False
sp.num_processes = 1
sp.return_E = True

# Astro Parameters
ap.companion = False
# ap.contrast = [5e-3, 1e-3]
ap.star_photons_per_s = int(1e7) # # G type star 10ly away gives 1e6 cts/cm^2/s
ap.lods = [[-1.2, 4.5]] # initial location (no rotation)
ap.exposure_time = 0.1  # 0.001

# Telescope/optics Parameters
tp.diam = 5.
tp.beam_ratio = 0.4
tp.obscure = True
tp.use_ao = True
tp.ao_act = 50
tp.use_atmos = True
tp.use_zern_ab = True
tp.occulter_type = 'Vortex'  # 'None'
tp.aber_params = {'CPA': True,
                  'NCPA': True,
                  'QuasiStatic': False,  # or Static
                  'Phase': True,
                  'Amp': False,
                  'n_surfs': 8,
                  'OOPP': [16,8,8,16,4,4,8,16]}#False}#

# Wavelength and Spectral Range
ap.band = np.array([800, 1500])
ap.nwsamp = 1
ap.w_bins = 1

num_exp = 1 #5000
ap.sample_time = 0.1
ap.numframes = int(num_exp * ap.exposure_time / ap.sample_time)
tp.piston_error = True
tp.rot_rate = 0  # deg/s
tp.pix_shift = [30,0]
lod = 8

# MKID Parameters
mp.distort_phase = True
mp.phase_uncertainty = True
mp.phase_background = True
mp.QE_var = True
mp.bad_pix = True
mp.hot_pix = 1
mp.array_size = np.array([80,125])
mp.R_mean = 8
mp.g_mean = 0.2
mp.g_sig = 0.04
mp.bg_mean = -10
mp.bg_sig = 40
mp.pix_yield = 0.7  # check dis

# sp.get_ints = {'w': [0], 'c': [0]}

# ***** These need to be outside the if statement to have an effect!! ****
iop.aberdata = 'Palomar' # Rename Data Directory
iop.update("MKID_pic-ideal/")
if os.path.exists(iop.int_maps):
    os.remove(iop.int_maps)

tp.detector = 'ideal'

sp.save_locs = np.array(['add_obscurations', 'add_aber', 'quick_ao', 'dummy'])
sp.gui_map_type = np.array(['phase', 'phase', 'phase', 'dummy'])
phase_ind = range(4)


if __name__ == '__main__':

    # Starting the Simulation
    print("Starting MKID_pic ideal-detector example")
    fields = gpd.run_medis()[0, :, 0, 0]
    print("finished Ideal-loop of MKID_pic Example File")

    fields = np.angle(fields[phase_ind], deg=False)
    grid(fields, logAmp=False)

# **** dito *****
iop.update("MKID_pic-ideal2/")
tp.detector = 'MKIDs'

if __name__ == '__main__':

    print("*****************************************************")
    print("*****************************************************")
    print("*****************************************************")
    print("Starting MKID_pic MKID detector example ")
    mkid = gpd.run_medis()[0, :]
    print("finished MKID-loop of MKID_pic Example File")


    compare_images(mkid[::2], vmax=200, logAmp=True, vmin=1, title=r'$I (cts)$', annos=['MKIDs 800 nm', '940 nm', '1080 nm', '1220 nm', '1360 nm', '1500 nm'])
    quicklook_im(np.mean(mkid[5:-1], axis=0), anno='MEDIS J Band', vmax=400, axis=None, title=r'$I (cts)$', logAmp=True, label='e')
    fig, axes = plt.subplots(nrows=1, ncols=2, figsize=(9, 3.8))
    labels = ['Ideal', 'MKID']
    # images = [ideal,mkid]
    vmaxs = [0.01, 100]


    for m, ax in enumerate(axes):
        im = ax.imshow(images[m], interpolation='none', origin='lower', cmap="YlGnBu_r", vmax=vmaxs[m])#norm= LogNorm(),
        props = dict(boxstyle='square', facecolor='w', alpha=0.7)
        ax.text(0.05, 0.05, labels[m], transform=ax.transAxes, fontweight='bold', color='k', fontsize=17,
                family='serif', bbox=props)
        ax.tick_params(direction='in', which='both', right=True, top=True)
        cax = fig.add_axes([0.44+ 0.485*m, 0.03, 0.02, 0.89])
        # cb = fig.colorbar(im, cax=cax, orientation='vertical',format=ticker.FuncFormatter(fmt))
        cb = fig.colorbar(im, cax=cax, orientation='vertical')
        ax.axis('off')
        # ax.set_xlabel('Radial Separation')
    # ax.set_yscale('log')
    # if p == 0:
    #     ax.set_ylabel('Intensity Ratio')
    #     ax.legend()
    plt.subplots_adjust(left=0.01, right=0.95, top=0.93, bottom=0.02)
    # plt.savefig(str(p) + '.pdf')
    # plt.show()

    plt.show()


