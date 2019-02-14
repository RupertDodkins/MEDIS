import os
import numpy as np
import matplotlib as mpl
mpl.use('Qt5Agg')
from medis.params import tp, mp, cp, sp, ap, iop
import medis.Detector.get_photon_data as gpd
import matplotlib.pyplot as plt
from matplotlib.colors import LogNorm
from medis.Utils.plot_tools import loop_frames, quicklook_im, view_datacube, compare_images, indep_images, grid
import pickle
from medis.Utils.misc import dprint

sp.show_wframe = False
sp.save_obs = False
sp.show_cube=False
ap.companion = True
# ap.contrast = [5e-3, 1e-3]
ap.contrast = [0.1]
ap.star_photons = int(1e7) # # G type star 10ly away gives 1e6 cts/cm^2/s
ap.lods = [[-1.2, 4.5]] # initial location (no rotation)
tp.diam=5.
tp.grid_size=256
tp.beam_ratio =0.4
tp.use_spiders = True
tp.use_ao = True
tp.ao_act = 50
tp.detector = 'ideal'
tp.use_atmos = True
tp.use_zern_ab = True
tp.occulter_type = 'Vortex'#'None'
tp.aber_params = {'CPA': True,
                    'NCPA': True,
                    'QuasiStatic': False,  # or Static
                    'Phase': True,
                    'Amp': False,
                    'n_surfs': 8,
                    'OOPP': [16,8,8,16,4,4,8,16]}#False}#
#mp.date = '180916/'
mp.bad_pix = True
mp.array_size = np.array([80,125])
#iop.update(mp.date)
sp.num_processes = 1
num_exp =1 #5000
ap.exposure_time = 0.1  # 0.001
cp.frame_time = 0.1
ap.numframes = int(num_exp * ap.exposure_time / cp.frame_time)
tp.piston_error = True
tp.band = np.array([800, 1500])
tp.nwsamp = 4
tp.w_bins = 4
tp.rot_rate = 0  # deg/s
tp.pix_shift = [30,0]
lod = 8

# mp.hot_pix =True
mp.distort_phase = True
mp.phase_uncertainty = True
mp.phase_background = True
mp.respons_var = True
mp.bad_pix = True
mp.hot_pix = 1

mp.R_mean = 8
mp.g_mean = 0.2
mp.g_sig = 0.04
mp.bg_mean = -10
mp.bg_sig = 40
mp.pix_yield = 0.7  # check dis

if __name__ == '__main__':
    if os.path.exists(iop.int_maps):
        os.remove(iop.int_maps)

    ideal = gpd.take_obs_data()[0, :]

    # compare_images(ideal, logAmp=True, vmax = 0.01, vmin=1e-6, annos = ['Ideal 800 nm', '1033 nm', '1267 nm', '1500 nm'], title=r'$I$')
    with open(iop.int_maps, 'rb') as handle:
        int_maps = pickle.load(handle)

    int_maps = np.array(int_maps)
    # view_datacube(int_maps, logAmp=True)
    grid(int_maps[::-1][:4], titles=r'$\phi$', annos=['Entrance Pupil', 'After CPA', 'After AO', 'After NCPA'])
    grid(int_maps[::-1][4:], nrows =2, width=1, titles=r'$I$', annos=['Before Coron.', 'After Coron.'], logAmp=True)
    plt.show(block=True)

tp.detector = 'MKIDs'
tp.w_bins = 12


if __name__ == '__main__':
    mkid = gpd.take_obs_data()[0, :]
    compare_images(mkid[::2], vmax=200, logAmp=True, vmin=1, title=r'$I (cts)$', annos=['MKIDs 800 nm', '940 nm', '1080 nm', '1220 nm', '1360 nm', '1500 nm'])
    quicklook_im(np.mean(mkid[5:-1], axis=0), anno='MEDIS J Band', vmax=400, axis=None, title=r'$I (cts)$', logAmp=True, label='e')
    fig, axes = plt.subplots(nrows=1, ncols=2, figsize=(9, 3.8))
    labels = ['Ideal', 'MKID']
    # images = [ideal,mkid]
    titles = ['A.U.','cts']
    vmaxs = [0.01,100]


    for m, ax in enumerate(axes):
        im = ax.imshow(images[m], interpolation='none', origin='lower', cmap="YlGnBu_r", vmax=vmaxs[m])#norm= LogNorm(),
        props = dict(boxstyle='square', facecolor='w', alpha=0.7)
        ax.text(0.05, 0.05, labels[m], transform=ax.transAxes, fontweight='bold', color='k', fontsize=17,
                family='serif', bbox=props)
        ax.tick_params(direction='in', which='both', right=True, top=True)
        cax = fig.add_axes([0.44+ 0.485*m, 0.03, 0.02, 0.89])
        # cb = fig.colorbar(im, cax=cax, orientation='vertical',format=ticker.FuncFormatter(fmt))
        cb = fig.colorbar(im, cax=cax, orientation='vertical')
        cb.ax.set_title(titles[m], fontsize=16)
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
