'''Implementation and Analysis plots from first principle simulator publication'''

import os, sys
import importlib
import numpy as np
import matplotlib as mpl
# mpl.use('Qt5Agg')
from matplotlib.colors import LogNorm, SymLogNorm
import medis.get_photon_data as gpd
import medis.save_photon_data as spd
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
import pickle as pickle
from medis.Utils.plot_tools import loop_frames, quicklook_im, view_datacube, compare_images, indep_images, grid
from medis.Utils.misc import dprint
from medis.Dashboard.twilight import sunlight, twilight
from medis.params import tp, mp, sp, ap, iop, cp
from medis.Detector import mkid_artefacts as MKIDs
from medis.Detector import temporal as temp
from medis.Detector import spectral as spec
from medis.Detector import pipeline as pipe

make_figure = 1

# sp.num_processes = 8
# sp.return_E = True
#
# # Astro Parameters
# ap.companion = False
# ap.star_photons_per_s = int(2e5)
# ap.lods = [[-1.2, 4.5]] # initial location (no rotation)
#
# # Telescope/optics Parameters
# ap.grid_size = 256
# tp.diam = 8.
# tp.beam_ratio = 0.5
# tp.obscure = True
# tp.use_ao = True
# tp.include_tiptilt= False
# tp.ao_act = 50
# tp.use_atmos = True
# # tp.use_zern_ab = True
# tp.occulter_type = 'Vortex'  # 'None'
# tp.aber_params = {'CPA': True,
#                   'NCPA': True,
#                   'QuasiStatic': False,  # or Static
#                   'Phase': True,
#                   'Amp': False,
#                   'n_surfs': 8,
#                   'OOPP': False}#[16,8,8,16,4,4,8,16]}#False}#
# # tp.aber_vals = {'a': [1e-17, 0.2e-17],
# #                'b': [0.8, 0.2],
# #                'c': [3.1,0.5],
# #                'a_amp': [0.05,0.01]}
# tp.aber_vals = {'a': [1e-18, 2e-20],#'a': [5e-17, 1e-18],
#                 'b': [2.0, 0.2],
#                 'c': [3.1, 0.5],
#                 'a_amp': [0.05, 0.01]}
# tp.legs_frac = 0.03
#
# tp.satelite_speck = True
#
# # Wavelength and Spectral Range
# ap.nwsamp = 8
# ap.w_bins = 8
# ap.sample_time = 0.1
# ap.numframes = 100 #100 #5000
# # tp.piston_error = True
# # tp.pix_shift = [[15,30],[-30,15],[-15,-30],[30,-15]]
# tp.pix_shift = [[15,30]]
#
# # MKID Parameters
# mp.phase_uncertainty = True
# mp.phase_background = True
# mp.QE_var = True
# mp.bad_pix = True
# mp.dark_counts = True
# mp.hot_pix = 1
# mp.dark_pix_frac = 0.5
# mp.array_size = np.array([142,146])
# mp.R_mean = 8
# mp.g_mean = 0.2
# mp.g_sig = 0.04
# mp.r_mean = 1
# mp.r_sig = 0.1
# mp.bg_mean = -10
# mp.bg_sig = 10
# mp.pix_yield = 0.8  # check dis
# mp.dark_bright = 5
# mp.hot_bright = 4e3
# mp.dead_time = 1e-5
# mp.wavecal_coeffs = [1./6, -250]

# sp.save_fields = False

def make_figure1():
    ap.nwsamp = 3
    ap.w_bins = 3
    ap.numframes = 1
    ap.contrast = [1e-3]
    ap.companion = True
    tp.obscure = True
    tp.use_ao = True
    tp.include_tiptilt= False
    tp.ao_act = 50
    tp.legs_frac = 0.03

    tp.satelite_speck = True
    ap.grid_size = 512
    tp.beam_ratio = 0.25
    tp.detector = 'ideal'
    tp.aber_params = {'CPA': True,
                        'NCPA': True,
                        'QuasiStatic': False,  # or 'Static'
                        'Phase': True,
                        'Amp': False,
                        'n_surfs': 2,
                        'OOPP': None}
    tp.aber_vals = {'a': [5e-10, 0],  # 'a': [5e-17, 1e-18],
                    'b': [0.0002, 0],
                    'c': [2, 0]}
    iop.update("first_principle/figure1")
    iop.set_atmosdata('190823')
    iop.set_aberdata('Palomar512')

    sp.save_locs = np.array(['add_atmos', 'add_aber', 'deformable_mirror', 'add_aber', 'prop_mid_optics', 'coronagraph'])
    sp.gui_map_type = np.array(['phase', 'phase', 'phase', 'phase', 'amp', 'amp'])
    sp.save_labels = np.array(['Entrance Pupil', 'After CPA', 'After AO', 'After NCPA', 'Before Coron.', 'After Coron.'])

    from medis.Dashboard.run_dashboard import run_dashboard

    if __name__ == '__main__':  # required for multiprocessing - make sure globals are set before though
        run_dashboard()
        # fields = spd.run_medis()

def make_figure2(normalize_spec=False):
    tp.detector = 'ideal'  #set ideal at first then do the mkid related stuff here
    iop.update("first_principle/figure2")
    iop.aberdir = os.path.join(iop.datadir, iop.aberroot, 'Palomar256')
    iop.quasi = os.path.join(iop.aberdir, 'quasi')
    iop.atmosdata = '190823'
    iop.atmosdir = os.path.join(iop.datadir, iop.atmosroot, iop.atmosdata)  # full path to FITS files
    iop.atmosconfig = os.path.join(iop.atmosdir, cp.model, 'config.txt')

    if __name__ == "__main__":  # required for multiprocessing - make sure globals are set before though
        fields = gpd.run_medis(realtime=False)[:ap.numframes]

        # spectralcube = np.abs(fields[0, -1, :, 0]) ** 2
        # throughput = np.sum(spectralcube, axis=(1, 2))
        # np.savetxt(iop.throughputfile, throughput)

        # if normalize_spec:
        #     throughput = np.loadtxt(iop.throughputfile)
        #     plt.plot(throughput)
        #     plt.figure()
        #     plt.plot(1./throughput)
        #     plt.show()

        if os.path.exists(iop.form_photons):
            print(f'loading formatted photon data from {iop.form_photons}')
            with open(iop.form_photons, 'rb') as handle:
                photons, stackcube, fig, stem = pickle.load(handle)

        else:
            dprint((fields.shape))
            if not os.path.isfile(iop.device_params):
                MKIDs.initialize()

            with open(iop.device_params, 'rb') as handle:
                dp = pickle.load(handle)

            photons = np.empty((0, 4))
            dprint(len(fields))
            stackcube = np.zeros((ap.numframes, ap.w_bins, mp.array_size[1], mp.array_size[0]))
            for step in range(len(fields)):
                dprint(step)
                spectralcube = np.abs(fields[step, -1, :, 0]) ** 2

                if normalize_spec:
                    spectralcube = spectralcube * sum(throughput/ap.w_bins) / throughput[:, np.newaxis, np.newaxis]

                if step == 0:
                    step_packets, fig = get_packets_plots(spectralcube, step, dp, mp, plot=True)
                else:
                    step_packets = get_packets_plots(spectralcube, step, dp, mp, plot=False)
                stem = pipe.arange_into_stem(step_packets, (mp.array_size[0], mp.array_size[1]))
                cube = pipe.make_datacube(stem, (mp.array_size[0], mp.array_size[1], ap.w_bins))
                # quicklook_im(cube[0], vmin=1, logAmp=True)
                # datacube += cube[0]
                stackcube[step] = cube

                photons = np.vstack((photons, step_packets))

            stem = pipe.arange_into_stem(photons, (mp.array_size[0], mp.array_size[1]))

            with open(iop.form_photons, 'wb') as handle:
                pickle.dump((photons, stackcube, fig, stem), handle, protocol=pickle.HIGHEST_PROTOCOL)


        ax6 = fig.add_subplot(336)

        # stem = pipe.arange_into_stem(photons.T, (mp.array_size[0], mp.array_size[1]))
        # cube = pipe.make_datacube(stem, (mp.array_size[0], mp.array_size[1], ap.w_bins))
        # quicklook_im(cube[0], vmin=1, logAmp=True)


        # cube = pipe.make_datacube(stem, (mp.array_size[0], mp.array_size[1], ap.w_bins))
        # quicklook_im(cube[0], vmin=1, logAmp=True):144
        # plt.figure()
        x = np.arange(55,61)
        y = np.arange(38,44)
        star_events = np.empty((0,2))
        for xp in x:
            for yp in y:
                if len(stem[xp][yp]) > 1:
                    star_events = np.vstack((star_events, np.array(stem[xp][yp])))
        # events = np.array(stem[58][41])
        times = np.sort(star_events[:, 0])
        dprint((np.shape(star_events)))

        # plt.figure()
        # plt.plot(times, marker='o')
        # plt.figure()
        # plt.hist(times, bins=5000)
        # plt.figure()
        ax6.hist(np.histogram(times, bins=np.linspace(0,len(fields)*ap.sample_time, 5000))[0], bins=range(40,100),
                 histtype='stepfilled', label='Original')
        ax6.hist(np.histogram(times, bins=np.linspace(0,len(fields)*ap.sample_time, 5000))[0], bins=range(40,100),
                 histtype='step', color='k')

        stem = MKIDs.remove_close(stem)
        # plt.figure()
        star_events = np.empty((0, 2))
        for xp in x:
            for yp in y:
                if len(stem[xp][yp]) > 1:
                    star_events = np.vstack((star_events, np.array(stem[xp][yp])))
        dprint((np.shape(star_events)))
        times = np.sort(star_events[:, 0])
        # plt.figure()
        # plt.hist(times, bins=5000)
        # plt.figure()
        ax6.hist(np.histogram(times, bins=np.linspace(0,len(fields)*ap.sample_time, 5000))[0],bins=range(40,100),
                 histtype='stepfilled', label='Observed', alpha=0.75)
        ax6.hist(np.histogram(times, bins=np.linspace(0,len(fields)*ap.sample_time, 5000))[0],bins=range(40,100),
                 histtype='step', color='k')
        # plt.show(block=True)
        cube = pipe.make_datacube(stem, (mp.array_size[0], mp.array_size[1], ap.w_bins))
        # events = np.array(stem[x][y])
        # print(events, np.shape(events))
        # timesort = np.argsort(events[:, 0])
        # ax6.hist(np.array(stem[72][72])[], bins=50, histtype='bar', rwidth=0.9, label='True')

        ax6.set_xlabel('Intensity (counts/0.1s)')
        # fig.tight_layout()
        ax6.legend(loc = 'lower left')

        # quicklook_im(cube[0], vmin=1, logAmp=True)


        # quicklook_im(cube[0], vmin=1, logAmp=True)

        dith_duration = np.floor(ap.numframes / len(tp.pix_shift))

        datacube = np.zeros((1,mp.array_size[1]+60, mp.array_size[0]+60))
        center_array_origin = (datacube.shape[1:] - mp.array_size[::-1]) // 2

        for step, cube in enumerate(stackcube):
            dith_idx = np.floor(step / dith_duration).astype(np.int32)
            dprint((dith_duration, dith_idx, tp.pix_shift[dith_idx]))


            left = center_array_origin[0]+tp.pix_shift[dith_idx][0]
            bottom = center_array_origin[1]+tp.pix_shift[dith_idx][1]
            dprint((center_array_origin, left, left+mp.array_size[1], bottom, bottom+mp.array_size[0]))
            datacube[0, left: left + mp.array_size[1], bottom: bottom + mp.array_size[0]] += cube[0]
            # quicklook_im(cube[0], logAmp=True, vmin=1)
            # quicklook_im(datacube[0], logAmp=True, vmin=1 )

        ax9 = fig.add_subplot(339)
        ax9.imshow(datacube[0], origin='lower', norm=LogNorm(), cmap='inferno', vmin=1)
        ax9.set_xlabel('xpix')
        ax9.set_ylabel('ypix')
        props = dict(boxstyle='square', facecolor='k', alpha=0.5)
        ax9.text(0.05, 0.075, 'Mosaic', transform=ax9.transAxes, fontweight='bold',
                 color='w', fontsize=16, bbox=props)

        # print(fields.shape)
        # plt.imshow(np.absolute(fields[0,0,0,0]))

        # fig.tight_layout()
        plt.show(block=True)

def make_figure3():
    sp.use_gui = True
    sp.show_cube = False

    sp.save_locs = np.array(['add_atmos', 'prop_mid_optics'])
    sp.gui_map_type = np.array(['phase', 'amp'])

    sp.metric_funcs = [help.plot_counts, help.take_acf, help.plot_stats, help.plot_psd]
    locs = [[70, 70], [80, 80], [90, 90], [100, 100]]
    sp.metric_args = [locs, locs, locs, locs]
    tp.include_dm = False
    tp.include_tiptilt = True
    tp.occulter_type = None
    ap.companion = False
    ap.contrast = []  # [1e-2]
    ap.star_photons = 1e8
    ap.sample_time = 1e-3
    ap.exposure_time = 1e-3
    tp.beam_ratio = 0.5  # 0.75
    ap.grid_size = 128
    tp.use_atmos = True
    tp.use_ao = True
    # tp.detector = 'MKIDs'
    tp.detector = 'ideal'
    tp.quick_ao = False
    tp.servo_error = [0, 1]
    tp.aber_params['CPA'] = True
    tp.aber_params['NCPA'] = True

    ap.numframes = 13000
    sp.num_processes = 1
    sp.gui_samp = sp.num_processes * 50  # display the field on multiples of this number
    cp.model = 'single'
    # iop.datadir = '/mnt/data0/dodkins/medis_save'
    iop.update('first_principle/figure3')

    # *** This has to go here. Don't put at top! ***
    from medis.Dashboard.run_dashboard import run_dashboard
    from scipy.signal import savgol_filter
    from statsmodels.tsa.stattools import acf

    if __name__ == "__main__":
        if os.path.exists(iop.fields):
            run_dashboard()
        else:
            e_fields_sequence = gpd.run_medis(realtime=False)
            fig = plt.figure()
            ax1 = fig.add_subplot(121)
            ax2 = fig.add_subplot(122)
            for loc in locs:
                print(loc)
                counts = np.mean(
                    np.abs(e_fields_sequence[:, -1, 0, 0, loc[0] - 3:loc[0] + 3, loc[1] - 3:loc[1] + 3]) ** 2,
                    axis=(1, 2))
                ax1.plot(acf(counts, nlags=1000), label='pix %i, %i' % (loc[0], loc[1]), linewidth=2)
                ax2.plot(help.plot_stats(counts), linewidth=2)
            ax1.xlabel(r'$\tau$ (ms)')
            ax1.ylabel(r'$C_1(\tau)$')
            ax2.xlabel(r'$I$ (counts)')
            # ax2.ylabel()
            ax1.legend(loc = 'lower left')
            plt.show()

def make_figure4():
    raise NotImplementedError

def get_packets_plots(datacube, step, dp, mp, plot=False):

    # quicklook_im(datacube[0], logAmp=True)
    # plt.plot(np.sum(datacube, axis=(1,2)))
    # plt.show(block=True)

    if (mp.array_size != datacube[0].shape + np.array([1,1])).all():
        left = int(np.floor(float(ap.grid_size-mp.array_size[0])/2))
        right = int(np.ceil(float(ap.grid_size-mp.array_size[0])/2))
        top = int(np.floor(float(ap.grid_size-mp.array_size[1])/2))
        bottom = int(np.ceil(float(ap.grid_size-mp.array_size[1])/2))

        dith_duration = np.floor(ap.numframes/len(tp.pix_shift))
        print(ap.numframes, len(tp.pix_shift), dith_duration)
        dith_idx = np.floor(step/dith_duration).astype(np.int32)
        dprint((dith_duration, dith_idx, tp.pix_shift[dith_idx]))

        dprint(f"left={left},right={right},top={top},bottom={bottom}")
        datacube = datacube[:, tp.pix_shift[dith_idx][0]+bottom:tp.pix_shift[dith_idx][0]-top,
                   tp.pix_shift[dith_idx][1]+left:tp.pix_shift[dith_idx][1]-right]

    # fig, axes = plt.subplots(nrows=2, ncols=3, figsize=(14, 8))
    # axes = axes.reshape(2, 3)

    if plot:
        fig = plt.figure(figsize=(11,10))
        ax1 = fig.add_subplot(331)
        ax1.imshow(datacube[0], origin='lower', norm=LogNorm(), cmap='inferno', vmin=1e-7)
        ax1.set_ylabel(r'ypix')
        ax1.set_xlabel(r'xpix')
        props = dict(boxstyle='square', facecolor='k', alpha=0.5)
        ax1.text(0.05, 0.075, 'PROPER\n section', transform=ax1.transAxes, fontweight='bold',
                 color='w', fontsize=16, bbox=props)

    if mp.QE_var:
        datacube *= dp.QE_map[:datacube.shape[1],:datacube.shape[1]]
    # if mp.hot_pix:
    #     datacube = MKIDs.add_hot_pix(datacube, dp, step)

    # quicklook_im(datacube[0], logAmp=True, vmin=1)
    if plot:
        ax2 = fig.add_subplot(332)
        ax2.imshow(datacube[0], origin='lower', norm=LogNorm(), cmap='inferno', vmin=1e-7)
        ax2.set_ylabel(r'ypix')
        ax2.set_xlabel(r'xpix')
        ax2.text(0.05, 0.075, 'Responsivity\n correction', transform=ax2.transAxes, fontweight='bold',
                 color='w', fontsize=16, bbox=props)

    num_events = int(ap.star_photons_per_s * ap.sample_time * np.sum(datacube))
    dprint(num_events)

    photons = temp.sample_cube(datacube, num_events)
    photons = spec.calibrate_phase(photons)
    photons = temp.assign_calibtime(photons, step)

    if plot:
        ax3 = fig.add_subplot(333, projection='3d')
        ax3.scatter(photons[1], photons[2], photons[3], s=1, alpha=0.25, color='#d62728')
        ax3.view_init(elev=25., azim=-25)
        ax3.xaxis.set_pane_color((1.0, 1.0, 1.0, 0.0))
        ax3.yaxis.set_pane_color((1.0, 1.0, 1.0, 0.0))
        ax3.zaxis.set_pane_color((1.0, 1.0, 1.0, 0.0))
        ax3.set_xlabel('$\phi$')
        ax3.set_ylabel('xpix')
        ax3.set_zlabel('ypix')
        # fig.tight_layout()
        # plt.show(block=True)

    # stem = pipe.arange_into_stem(photons.T, (mp.array_size[0], mp.array_size[1]))
    # cube = pipe.make_datacube(stem, (mp.array_size[0], mp.array_size[1], ap.w_bins))
    # quicklook_im(cube[0], logAmp=True, vmin=1)
    if plot:
        ax4 = fig.add_subplot(334)
        ax4.hist(photons[1], bins=range(-120,0,2), histtype='stepfilled', color='#d62728', alpha=0.95, label='Real')
        ax4.hist(photons[1], bins=range(-120,0,2), histtype='step', color='k', alpha=0.95)

    if mp.dark_counts:
        dark_photons = MKIDs.get_dark_packets(dp, step)
        photons = np.hstack((photons, dark_photons))
        # photons = MKIDs.add_dark(photons)

    if mp.hot_pix:
        hot_photons = MKIDs.get_hot_packets(dp, step)
        photons = np.hstack((photons, hot_photons))
        # stem = MKIDs.add_hot(stem)

    if plot:
        ax4.hist(dark_photons[1], bins=range(-120,0,2), alpha=0.75, color='#1f77b4', histtype='stepfilled', label='Dark')
        ax4.hist(dark_photons[1], bins=range(-120,0,2), histtype='step', color='k')
        # plt.show(block=True)
        ax4.hist(hot_photons[1], bins=range(-120,0,2), alpha=0.5, color='#ff7f0e', histtype='stepfilled', label='Hot')
        ax4.hist(hot_photons[1], bins=range(-120,0,2), histtype='step', color='k')
        ax4.legend(loc = 'lower left')
        ax4.set_xlabel('Phase (deg)')

    # stem = pipe.arange_into_stem(photons.T, (mp.array_size[0], mp.array_size[1]))
    # cube = pipe.make_datacube(stem, (mp.array_size[0], mp.array_size[1], ap.w_bins))
    # quicklook_im(cube[0], logAmp=True, vmin=1)

    if mp.phase_uncertainty:
        photons = MKIDs.apply_phase_offset_array(photons, dp.sigs)
        photons[1] *= dp.responsivity_error_map[np.int_(photons[2]), np.int_(photons[3])]

    if plot:
        ax5 = fig.add_subplot(335)
        ax5.hist(photons[1], bins=range(-120,0,2), alpha=0.5, histtype='stepfilled', color='#2ca02c', label='Degraded')
        ax5.hist(photons[1], bins=range(-120,0,2), histtype='step', color='k')

    # stem = pipe.arange_into_stem(photons.T, (mp.array_size[0], mp.array_size[1]))
    # cube = pipe.make_datacube(stem, (mp.array_size[0], mp.array_size[1], ap.w_bins))
    # quicklook_im(cube[0], vmin=1, logAmp=True)
    # plt.figure()
    # plt.imshow(cube[0], origin='lower', norm=LogNorm(), cmap='inferno', vmin=1)
    # plt.show(block=True)

    thresh =  photons[1] < dp.basesDeg[np.int_(photons[3]),np.int_(photons[2])]
    photons = photons[:, thresh]
    # print(thresh)

    # stem = pipe.arange_into_stem(photons.T, (mp.array_size[0], mp.array_size[1]))
    # cube = pipe.make_datacube(stem, (mp.array_size[0], mp.array_size[1], ap.w_bins))
    # quicklook_im(cube[0], vmin=1, logAmp=True)
    # plt.figure()
    # plt.imshow(cube[0], origin='lower', norm=LogNorm(), cmap='inferno', vmin=1)
    # plt.show(block=True)

    if plot:
        ax5.hist(photons[1], bins=range(-120, 0, 2), alpha=0.95, histtype='stepfilled', rwidth=0.9, color= '#9467bd', label='Detect')
        ax5.hist(photons[1], bins=range(-120, 0, 2), histtype='step', color='k')
        ax5.set_xlabel('Phase (deg)')
        ax5.legend(loc = 'lower left')

    dprint(photons.shape)

    stem = pipe.arange_into_stem(photons.T, (mp.array_size[0], mp.array_size[1]))
    cube = pipe.make_datacube(stem, (mp.array_size[0], mp.array_size[1], ap.w_bins))
    # ax7.imshow(cube[0], origin='lower', norm=LogNorm(), cmap='inferno', vmin=1)
    cube /= dp.QE_map
    photons = pipe.ungroup(stem)

    dprint(photons.shape)
    if plot:
        ax7 = fig.add_subplot(337)
        # ax8.imshow(dp.QE_map, origin='lower', norm=LogNorm(), cmap='inferno')
        ax7.imshow(cube[0], origin='lower', norm=LogNorm(), cmap='inferno', vmin=1)
        ax7.set_xlabel('xpix')
        ax7.set_ylabel('ypix')
        ax7.text(0.05, 0.075, 'Flatfield', transform=ax7.transAxes, fontweight='bold',
                 color='w', fontsize=16, bbox=props)

    if plot:
        ax8 = fig.add_subplot(338)
        photons[1] /= dp.responsivity_error_map[np.int_(photons[2]), np.int_(photons[3])]
        photons[1] = spec.wave_cal(photons[1])
        ax8.hist(photons[1], bins=60, alpha=0.5, histtype='stepfilled', color='#2ca02c', label='Wave Cal.')
        ax8.hist(photons[1], bins=60, histtype='step', color='k')
        ax8.legend(loc = 'lower left')
        ax8.set_xlabel('Wavelength (m)')
        # stem = pipe.arange_into_stem(photons.T, (mp.array_size[0], mp.array_size[1]))
        # cube = pipe.make_datacube(stem, (mp.array_size[0], mp.array_size[1], ap.w_bins))
        # ax8.imshow(cube[0], origin='lower', norm=LogNorm(), cmap='inferno', vmin=1)

    dprint("Completed Readout Loop")

    if plot:
        return photons.T, fig
    else:
        return photons.T

def find_nearest(array, value):
    array = np.asarray(array)
    idx = (np.abs(array - value)).argmin()
    return idx

def config_images(num_tests):
    plt.rcParams["axes.prop_cycle"] = plt.cycler("color", plt.cm.viridis(np.linspace(0, 1, num_tests)))

def parse_cont_data(all_cont_data, p):
    rad_samps = all_cont_data[0, p, 0]  # both repeats should be equivalent
    all_conts = np.array(all_cont_data[:, p, 1].tolist())
    mean_conts = np.mean(all_conts, axis=0)
    if len(all_conts.shape)==3:
        err_conts = np.std(all_conts, axis=0)
    else:
        err_conts = [np.std(all_conts[:,i])/np.sqrt(len(all_conts)) for i in range(len(all_conts[0]))]  #can't do std if one axis is different size (unlike mean)

    return rad_samps, mean_conts, err_conts

def param_compare():

    repeats = 3  # number of medis runs to average over for the cont plots
    param_names = ['array_size', 'array_size_(rebin)', 'numframes', 'pix_yield', 'dark_bright', 'R_mean', 'R_sig', 'g_mean', 'g_sig']#'g_mean_sig']# 'star_photons_per_s'

    all_cont_data = []
    for r in range(repeats):

        # each repeat has new fields, device params and noise data
        iop.set_testdir(f'FirstPrincipleSim_numframes50_repeat{r}/master/')
        # iop.set_testdir(f'FirstPrincipleSim_repeat{r}_quantize_fcs/master/')
        import master
        master_dp, master_fields = master.config_cache()
        master.make_fields_master()
        master.make_dp_master()

        if not os.path.exists(iop.median_noise):
            master.get_median_noise(master_dp)

        dprint(iop.testdir)

        comp_images, cont_data, metric_multi_list, metric_vals_list = [], [], [], []
        for param_name in param_names:
            param = importlib.import_module(param_name)
            if param_name in sys.modules:  # if the module has been loaded before it would be skipped and the params not initialized
                dprint(param_name)
                param = importlib.reload(param)
            config_images(len(param.metric_multiplier))  # the line colors and map inds depend on the amount
            # being plotted
            param_data = master.form(param.metric_vals, param.metric_name, master_cache=(master_dp, master_fields),
                                     debug=False)
            comp_images.append(param_data[0])
            cont_data.append(param_data[1:])

            # store the mutlipliers but flip those that achieve better contrast when the metric is decreasing
            if param_name in ['dark_bright', 'R_sig', 'g_sig']:
                metric_multi_list.append(param.metric_multiplier[::-1])
                metric_vals_list.append(param.metric_vals[::-1])
            else:
                metric_multi_list.append(param.metric_multiplier)
                metric_vals_list.append(param.metric_vals)

        cont_data = np.array(cont_data)
        dprint(cont_data.shape)
        all_cont_data.append(cont_data)
    all_cont_data = np.array(all_cont_data)  # (repeats x num_params x rad+cont x num_multi (changes)

    three_lod_sep = 0.3
    six_lod_sep = 2*three_lod_sep
    fhqm = 0.03
    for p, param_name in enumerate(param_names):
        metric_multi = metric_multi_list[p]
        metric_vals = metric_vals_list[p]
        rad_samps, mean_conts, err_conts = parse_cont_data(all_cont_data, p)

        three_lod_conts = np.zeros((len(metric_multi)))
        six_lod_conts = np.zeros((len(metric_multi)))
        three_lod_errs = np.zeros((len(metric_multi)))
        six_lod_errs = np.zeros((len(metric_multi)))
        for i in range(len(mean_conts)):
            three_lod_ind = np.where((np.array(rad_samps[i]) > three_lod_sep-fhqm) & (np.array(rad_samps[i]) < three_lod_sep+fhqm))
            three_lod_conts[i] = np.mean(mean_conts[i][three_lod_ind])
            three_lod_errs[i] = np.sqrt(np.sum(err_conts[i][three_lod_ind]**2))

            six_lod_ind = np.where((np.array(rad_samps[i]) > six_lod_sep - fhqm) & (np.array(rad_samps[i]) < six_lod_sep + fhqm))
            six_lod_conts[i] = np.mean(mean_conts[i][six_lod_ind])
            six_lod_errs[i] = np.sqrt(np.sum(err_conts[i][six_lod_ind] ** 2))

        maps = comp_images[p]
        master.combo_performance(maps, rad_samps, mean_conts, metric_vals, param_name, [0,-1], err_conts, metric_multi,
                                 three_lod_conts, three_lod_errs, six_lod_conts, six_lod_errs)

    return

if __name__ == '__main__':
    if make_figure == 1:
        make_figure1()
    elif make_figure == 2:
        make_figure2()
    elif make_figure == 8:
        param_compare()


