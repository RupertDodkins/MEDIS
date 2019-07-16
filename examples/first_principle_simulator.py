'''Implementation and Analysis plots from first principle simulator publication'''

import os
import numpy as np
import matplotlib as mpl
mpl.use('Qt5Agg')
import medis.get_photon_data as gpd
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
# from matplotlib.colors import LogNorm
import pickle as pickle
from medis.Utils.plot_tools import loop_frames, quicklook_im, view_datacube, compare_images, indep_images, grid
from medis.Utils.misc import dprint
from medis.Dashboard.twilight import sunlight, twilight
from medis.params import tp, mp, sp, ap, iop
from medis.Detector import mkid_artefacts as MKIDs
from medis.Detector import temporal as temp
from medis.Detector import spectral as spec
from medis.Detector import pipeline as pipe

make_figure = 2

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
tp.pix_shift = [0,0]

# MKID Parameters
mp.phase_uncertainty = True
mp.phase_background = True
mp.QE_var = True
mp.bad_pix = True
mp.dark_counts = True
mp.hot_pix = 1
mp.array_size = np.array([142,146])
mp.R_mean = 8
mp.g_mean = 0.2
mp.g_sig = 0.04
mp.bg_mean = -10
mp.bg_sig = 40
mp.pix_yield = 0.7  # check dis

def make_figure1():
    tp.detector = 'ideal'
    iop.update("first_principle/figure1")
    sp.save_locs = np.array(['add_atmos', 'add_aber', 'deformable_mirror', 'add_aber', 'prop_mid_optics'])
    sp.gui_map_type = np.array(['phase', 'phase', 'phase', 'phase', 'amp'])
    phase_ind = range(4)

    if __name__ == '__main__':  # required for multiprocessing - make sure globals are set before though
        fields = gpd.run_medis()[0, :, 0, 0, ap.grid_size//4:-ap.grid_size//4, ap.grid_size//4:-ap.grid_size//4]
        pupils = np.angle(fields[phase_ind], deg=False)
        focals = np.absolute(fields[4:])
        grid(pupils, logAmp=False, colormap=twilight, vmins=[-np.pi]*len(sp.save_locs), vmaxs=[np.pi]*len(sp.save_locs))
        grid(focals, logAmp=True, colormap='viridis')

def make_figure2():
    tp.detector = 'ideal'  #set ideal at first then do the mkid related stuff here
    iop.update("first_principle/figure2")

    if __name__ == "__main__":  # required for multiprocessing - make sure globals are set before though
        fields = gpd.run_medis(realtime=False)

        spectralcube = np.abs(fields[-1, :, 0]) ** 2

        if not os.path.isfile(iop.device_params):
            MKIDs.initialize()

        with open(iop.device_params, 'rb') as handle:
            dp = pickle.load(handle)

        for step in range(len(fields)):
            get_packets_plots(spectralcube[step], step, dp, mp)

        # print(fields.shape)
        # plt.imshow(np.absolute(fields[0,0,0,0]))
        # plt.show()

def get_packets_plots(datacube, step, dp,mp):

    # quicklook_im(datacube[0], logAmp=True)

    if (mp.array_size != datacube[0].shape + np.array([1,1])).all():
        left = int(np.floor(float(ap.grid_size-mp.array_size[0])/2))
        right = int(np.ceil(float(ap.grid_size-mp.array_size[0])/2))
        top = int(np.floor(float(ap.grid_size-mp.array_size[1])/2))
        bottom = int(np.ceil(float(ap.grid_size-mp.array_size[1])/2))

        dprint(f"left={left},right={right},top={top},bottom={bottom}")
        datacube = datacube[:, tp.pix_shift[0]+bottom:tp.pix_shift[0]-top,
                            tp.pix_shift[1]+left:tp.pix_shift[1]-right]

    # quicklook_im(datacube[0], logAmp=True)

    if mp.QE_var:
        datacube *= dp.QE_map[:datacube.shape[1],:datacube.shape[1]]
    # if mp.hot_pix:
    #     datacube = MKIDs.add_hot_pix(datacube, dp, step)

    # quicklook_im(datacube[0], logAmp=True)

    num_events = int(ap.star_photons_per_s * ap.sample_time * np.sum(datacube))

    photons = temp.sample_cube(datacube, num_events)

    photons = spec.calibrate_phase(photons)
    photons = temp.assign_calibtime(photons, step)

    fig = plt.figure()
    ax = fig.add_subplot(111, projection='3d')
    ax.scatter(photons[1], photons[2], photons[3], s=4, alpha=0.35)
    ax.view_init(elev=25., azim=-45)
    ax.xaxis.set_pane_color((1.0, 1.0, 1.0, 0.0))
    ax.yaxis.set_pane_color((1.0, 1.0, 1.0, 0.0))
    ax.zaxis.set_pane_color((1.0, 1.0, 1.0, 0.0))
    fig.tight_layout()
    plt.show(block=True)

    stem = pipe.arange_into_stem(photons.T, (mp.array_size[0], mp.array_size[1]))
    cube = pipe.make_datacube(stem, (mp.array_size[0], mp.array_size[1], ap.w_bins))
    quicklook_im(cube[0], logAmp=True, vmin=1)

    if mp.dark_counts:
        dark_photons = MKIDs.get_dark_packets(dp)
        photons = np.hstack((photons, dark_photons))
        # photons = MKIDs.add_dark(photons)

    if mp.hot_pix:
        hot_photons = MKIDs.get_hot_packets(dp)
        photons = np.hstack((photons, hot_photons))
        # stem = MKIDs.add_hot(stem)

    stem = pipe.arange_into_stem(photons.T, (mp.array_size[0], mp.array_size[1]))
    cube = pipe.make_datacube(stem, (mp.array_size[0], mp.array_size[1], ap.w_bins))
    quicklook_im(cube[0], logAmp=True, vmin=1)

    if mp.phase_uncertainty:
        photons = MKIDs.apply_phase_offset_array(photons, dp.sigs)
    thresh = dp.basesDeg[np.int_(photons[3]),np.int_(photons[2])] < -1 * photons[1]
    photons = photons[:, thresh]

    stem = pipe.arange_into_stem(photons.T, (mp.array_size[0], mp.array_size[1]))
    stem = MKIDs.remove_close(stem)
    cube = pipe.make_datacube(stem, (mp.array_size[0], mp.array_size[1], ap.w_bins))
    quicklook_im(cube[0], vmin=1)

    photons = pipe.ungroup(stem)

    # todo implement flatcal and wavecal here
    # photons = assign_id(photons, obj_ind=o)

    # print(photons.shape)
    # packets = np.vstack((packets, np.transpose(photons)))
    packets = np.transpose(photons)

    # dprint("Completed Readout Loop")

    return packets  #[1:]  #first element from empty would otherwise be included

if make_figure == 1:
    make_figure1()
elif make_figure == 2:
    make_figure2()
