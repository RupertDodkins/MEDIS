''' Make the master fields.h5 and device_params.pkl '''

import os
import matplotlib as mpl
import numpy as np
mpl.use("Qt5Agg")
import matplotlib.pyplot as plt
from matplotlib.colors import LogNorm
import pickle as pickle
from vip_hci import phot, pca
from statsmodels.tsa.stattools import acf
from medis.params import tp, mp, cp, sp, ap, iop
import medis.get_photon_data as gpd
from medis.Utils.plot_tools import quicklook_im, indep_images, view_datacube
from medis.Utils.misc import dprint
import medis.Detector.readout as read
from medis.Detector import mkid_artefacts as MKIDs
from medis.Detector import pipeline as pipe
from medis.Analysis.phot import get_unoccult_psf, eval_method

metric = __file__.split('/')[-1].split('.')[0]
iop.set_testdir(f'FirstPrincipleSim/{metric}/')
iop.set_atmosdata('190823')
iop.set_aberdata('Palomar256')
iop.fields = iop.testdir + 'fields_master.h5'
iop.form_photons = os.path.join(iop.testdir, 'formatted_photons_master.pkl')
iop.device_params = os.path.join(iop.testdir, 'deviceParams_master.pkl')  # detector metadata

# dp = '/Users/dodkins/medis_save/observations/FirstPrincipleSim/master/deviceParams_master.pkl'
dp = iop.device_params

ap.sample_time = 0.05
ap.numframes = 10

def set_field_params():
    sp.show_wframe = False
    sp.save_obs = False
    sp.show_cube = False
    sp.num_processes = 1
    sp.get_ints = False

    ap.companion = True
    ap.star_photons_per_s = int(1e5)
    ap.contrast = [10 ** -3.5, 10 ** -3.5, 10 ** -4.5, 10 ** -4]
    ap.lods = [[6, 0.0], [3, 0.0], [-6, 0], [-3, 0]]
    ap.grid_size = 256
    ap.nwsamp = 8
    ap.w_bins = 16  # 8

    tp.save_locs = np.empty((0, 1))
    tp.diam = 8.
    tp.beam_ratio = 0.5
    tp.obscure = True
    tp.use_ao = True
    tp.include_tiptilt = False
    tp.ao_act = 50
    tp.platescale = 10  # mas
    tp.detector = 'ideal'
    tp.use_atmos = True
    tp.use_zern_ab = False
    tp.occulter_type = 'Vortex'  # "None (Lyot Stop)"
    tp.aber_params = {'CPA': True,
                      'NCPA': True,
                      'QuasiStatic': False,  # or Static
                      'Phase': True,
                      'Amp': False,
                      'n_surfs': 4,
                      'OOPP': False}  # [16,8,4,16]}#False}#
    tp.aber_vals = {'a': [5e-18, 1e-19],  # 'a': [5e-17, 1e-18],
                    'b': [2.0, 0.2],
                    'c': [3.1, 0.5],
                    'a_amp': [0.05, 0.01]}
    tp.piston_error = False
    ap.band = np.array([800, 1500])
    tp.rot_rate = 0  # deg/s
    tp.pix_shift = [[0, 0]]

    return

def make_fields_master(monitor=False):
    """ The master fields file of which all the photons are seeded from according to their device_params

    :return:
    """

    set_field_params()

    if monitor:
        sp.save_locs = np.array(['add_atmos','deformable_mirror', 'prop_mid_optics', 'coronagraph'])
        sp.gui_map_type = np.array(['phase',  'phase', 'amp', 'amp'])
        from medis.Dashboard.run_dashboard import run_dashboard

        if __name__ == '__main__':
            run_dashboard()
        return None

    else:
        if __name__ == '__main__':
            fields = gpd.run_medis()
            tess = np.abs(np.sum(fields[:, -1, :, :], axis=2)) ** 2
            view_datacube(tess[0], logAmp=True, show=False)
            view_datacube(tess[:,0], logAmp=True, show=True)

    return fields

def set_mkid_params():
    mp.phase_uncertainty = True
    mp.phase_background = False
    mp.QE_var = True
    mp.bad_pix = True
    mp.hot_pix = None
    mp.hot_bright = 1e3
    mp.R_mean = 8
    mp.g_mean = 0.3
    mp.g_sig = 0.04
    mp.bg_mean = -10
    mp.bg_sig = 40
    mp.pix_yield = 0.9  # 0.7 # check dis
    mp.bad_pix = True
    mp.array_size = np.array([146, 146])
    mp.lod = 6

def make_dp_master():
    """

    :return:
    """
    set_mkid_params()
    MKIDs.initialize()

def get_form_photons(fields, comps=True):
    dprint('Making new formatted photon data')
    # if not os.path.isfile(iop.device_params):
    # MKIDs.initialize()

    with open(iop.device_params, 'rb') as handle:
        dp = pickle.load(handle)

    photons = np.empty((0, 4))
    dprint(len(fields))
    stackcube = np.zeros((len(fields), ap.w_bins, mp.array_size[1], mp.array_size[0]))
    for step in range(len(fields)):
        dprint(step)
        if comps:
            spectralcube = np.abs(np.sum(fields[step, -1, :, :], axis=1)) ** 2
        else:
            spectralcube = np.abs(fields[step, -1, :, 0]) ** 2

        step_packets = read.get_packets(spectralcube, step, dp, mp)
        stem = pipe.arange_into_stem(step_packets, (mp.array_size[0], mp.array_size[1]))
        cube = pipe.make_datacube(stem, (mp.array_size[0], mp.array_size[1], ap.w_bins))
        # quicklook_im(cube[0], vmin=1, logAmp=True)
        # datacube += cube[0]
        stackcube[step] = cube

        photons = np.vstack((photons, step_packets))

    # stem = pipe.arange_into_stem(photons, (mp.array_size[0], mp.array_size[1]))

    with open(iop.form_photons, 'wb') as handle:
        pickle.dump((photons, stackcube, dp), handle, protocol=pickle.HIGHEST_PROTOCOL)

    return photons, stackcube, dp

def get_stackcubes(metric_vals, metric_name, comps=True):
    iop.device_params = iop.device_params[:-4] + '_'+metric_name
    iop.form_photons = iop.form_photons[:-4] +'_'+metric_name

    iop.fields = '/Users/dodkins/medis_save/observations/FirstPrincipleSim/master/fields_master.h5'
    fields = gpd.run_medis()
    dprint((fields.shape, metric_name))

    stackcubes, dps =  [], []
    for metric_val in metric_vals:
        iop.form_photons = iop.form_photons.split('_'+metric_name)[0] + f'_{metric_name}={metric_val}_comps={comps}.pkl'
        iop.device_params = iop.device_params.split('_'+metric_name)[0] + f'_{metric_name}={metric_val}.pkl'
        dprint(iop.form_photons)

        if os.path.exists(iop.form_photons):
            dprint(f'Formatted photon data already exists at {iop.form_photons}')
            with open(iop.form_photons, 'rb') as handle:
                photons, stackcube, dp = pickle.load(handle)

        else:
            photons, stackcube, dp = get_form_photons(fields, comps=comps)

        plt.figure()
        plt.hist(stackcube[stackcube!=0].flatten(), bins=np.linspace(0,1e4, 50))
        plt.yscale('log')
        view_datacube(stackcube[0], logAmp=True, show=False)
        view_datacube(stackcube[:, 0], logAmp=True, show=False)

        stackcube /= np.sum(stackcube)  # /ap.numframes
        stackcube = stackcube
        stackcube = np.transpose(stackcube, (1, 0, 2, 3))
        stackcubes.append(stackcube)
        dps.append(dp)

    return stackcubes, dps

def eval_performance(stackcubes, dps, metric_vals, comps=True):
    wsamples = np.linspace(ap.band[0], ap.band[1], ap.w_bins)
    scale_list = wsamples / (ap.band[1] - ap.band[0])
    maps, plotdata = [], []

    if comps:
        for stackcube in stackcubes:
            SDI = pca.pca(stackcube, angle_list=np.zeros((stackcube.shape[1])), scale_list=scale_list,
                          mask_center_px=None, adimsdi='double', ncomp=7, ncomp2=None,
                          collapse='median')
            maps.append(SDI)

    else:
        psf_template = get_unoccult_psf(fields='/IntHyperUnOccult.h5', plot=False, numframes=1)
        star_phot = phot.contrcurve.aperture_flux(np.sum(psf_template, axis=0), [mp.array_size[0] // 2],
                                                  [mp.array_size[0] // 2], mp.lod, 1)[0]
        for stackcube, dp in zip(stackcubes, dps):
            algo_dict = {'scale_list': scale_list}
            # with open(iop.device_params, 'rb') as handle:
            #     dp = pickle.load(handle)
            # dprint(iop.device_params)
            # quicklook_im(dp.QE_map)
            method_out = eval_method(stackcube, pca.pca, psf_template,
                                     np.zeros((stackcube.shape[1])), algo_dict,
                                     fwhm=mp.lod, star_phot=star_phot, dp=dp)
            plotdata.append(method_out[0])
            maps.append(method_out[1])

        plotdata = np.array(plotdata)
        dprint(plotdata.shape)
        # rad_samp = np.linspace(0,tp.platescale/1000.*plotdata.shape[2],plotdata.shape[2])
        rad_samp = np.linspace(0, tp.platescale / 1000. * 100, plotdata.shape[2])
        fig, axes = plt.subplots(nrows=1, ncols=3, figsize=(14, 3.4))

        # plotdata[:, 2] = plotdata[:, 1]*plotdata[:, 3] / np.mean(plotdata[:, 0], axis=0)

        for thruput in plotdata[:, 0]:
            axes[0].plot(rad_samp, thruput)
        for noise in plotdata[:, 1]:
            axes[1].plot(rad_samp, noise)
        for cont in plotdata[:, 2]:
            axes[2].plot(rad_samp, cont)
        for ax in axes:
            ax.set_yscale('log')
            ax.set_xlabel('Radial Separation')
            ax.tick_params(direction='in', which='both', right=True, top=True)
        axes[0].set_ylabel('Throughput')
        axes[1].set_ylabel('Noise')
        axes[2].set_ylabel('5$\sigma$ Contrast')
        axes[2].legend([str(metric_val) for metric_val in metric_vals])

    view_datacube(maps, logAmp=True, vmin=-1e-7, vmax=1e-7)


if __name__ == '__main__':
    fields = make_fields_master()
    make_dp_master()
