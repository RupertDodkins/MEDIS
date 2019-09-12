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
from medis.Utils.plot_tools import quicklook_im, indep_images, view_datacube, compare_images
from medis.Utils.misc import dprint
import medis.Detector.readout as read
from medis.Detector import mkid_artefacts as MKIDs
from medis.Detector import pipeline as pipe
from medis.Analysis.phot import get_unoccult_psf, eval_method

metric = __file__.split('/')[-1].split('.')[0]
iop.set_testdir(f'FirstPrincipleSim/{metric}_20/')
iop.set_atmosdata('190823')
iop.set_aberdata('Palomar512')
iop.fields = iop.testdir + 'fields_master.h5'
master_fields = iop.fields
iop.form_photons = os.path.join(iop.testdir, 'formatted_photons_master.pkl')
iop.device_params = os.path.join(iop.testdir, 'deviceParams_master.pkl')  # detector metadata

# dp = '/Users/dodkins/medis_save/observations/FirstPrincipleSim/master/deviceParams_master.pkl'
dp = iop.device_params

ap.sample_time = 0.05
ap.numframes = 20

def set_field_params():
    sp.show_wframe = False
    sp.save_obs = False
    sp.show_cube = False
    sp.num_processes = 1
    sp.save_fields = False
    sp.save_ints = True

    ap.companion = True
    ap.star_photons_per_s = int(1e5)
    # ap.contrast = [10 ** -3.5, 10 ** -3.5, 10 ** -4.5, 10 ** -4]
    # ap.lods = [[6, 0.0], [3, 0.0], [-6, 0], [-3, 0]]
    ap.contrast = [10 ** -3.5, 10 ** -3.5, 10 ** -4, 10 ** -4, 10 ** -4.5, 10 ** -4.5, 10 ** -5, 10 ** -5]
    ap.lods = [[6,0], [3,0], [0,3], [0,6], [-6,0], [-3,0], [0,-3],[0,-6]]
    # ap.grid_size = 256
    # tp.beam_ratio = 0.5
    ap.grid_size = 512
    tp.beam_ratio = 0.25
    ap.nwsamp = 8
    ap.w_bins = 16

    tp.save_locs = np.empty((0, 1))
    tp.diam = 8.
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

        run_dashboard()
        return None

    else:
        if __name__ == '__main__':
            fields = gpd.run_medis()
            tess = np.sum(fields, axis=2)
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
    mp.pix_yield = 0.9
    mp.bad_pix = True
    mp.array_size = np.array([150, 150])
    mp.lod = 6

def make_dp_master():
    """

    :return:
    """
    set_mkid_params()
    MKIDs.initialize()

def get_form_photons(fields, comps=True):
    dprint('Making new formatted photon data')

    with open(iop.device_params, 'rb') as handle:
        dp = pickle.load(handle)

    stackcube = np.zeros((len(fields), ap.w_bins, dp.array_size[1], dp.array_size[0]))
    for step in range(len(fields)):
        dprint(step)
        if comps:
            spectralcube = np.sum(fields[step], axis=1)
        else:
            spectralcube = fields[step, :, 0]

        step_packets = read.get_packets(spectralcube, step, dp, mp)
        cube = pipe.make_datacube_from_list(step_packets, (ap.w_bins,dp.array_size[0],dp.array_size[1]))
        stackcube[step] = cube

    with open(iop.form_photons, 'wb') as handle:
        dprint((iop.form_photons, stackcube.shape, dp))
        pickle.dump((stackcube, dp), handle, protocol=pickle.HIGHEST_PROTOCOL)

    return stackcube, dp

def get_stackcubes(metric_vals, metric_name, comps=True, plot=False):
    iop.device_params = iop.device_params[:-4] + '_'+metric_name
    iop.form_photons = iop.form_photons[:-4] +'_'+metric_name

    iop.fields = master_fields
    fields = gpd.run_medis()

    stackcubes, dps =  [], []
    for metric_val in metric_vals:
        iop.form_photons = iop.form_photons.split('_'+metric_name)[0] + f'_{metric_name}={metric_val}_comps={comps}.pkl'
        iop.device_params = iop.device_params.split('_'+metric_name)[0] + f'_{metric_name}={metric_val}.pkl'

        if os.path.exists(iop.form_photons):
            dprint(f'Formatted photon data already exists at {iop.form_photons}')
            with open(iop.form_photons, 'rb') as handle:
                stackcube, dp = pickle.load(handle)

        else:
            stackcube, dp = get_form_photons(fields, comps=comps)

        if plot:
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
    dprint(scale_list)
    maps, rad_samps, thruputs, noises, conts = [], [], [], [], []

    if comps:
        for stackcube in stackcubes:
            SDI = pca.pca(stackcube, angle_list=np.zeros((stackcube.shape[1])), scale_list=scale_list,
                          mask_center_px=None, adimsdi='double', ncomp=7, ncomp2=None,
                          collapse='median')
            maps.append(SDI)

    else:
        for stackcube, dp in zip(stackcubes, dps):
            psf_template = get_unoccult_psf(fields=f'/IntHyperUnOccult_arraysize={dp.array_size}.h5', plot=False, numframes=1)
            star_phot = phot.contrcurve.aperture_flux(np.sum(psf_template, axis=0), [dp.array_size[0] // 2],
                                                      [dp.array_size[0] // 2], mp.lod, 1)[0]
            algo_dict = {'scale_list': scale_list}
            # with open(iop.device_params, 'rb') as handle:
            #     dp = pickle.load(handle)
            # dprint(iop.device_params)

            method_out = eval_method(stackcube, pca.pca, psf_template,
                                     np.zeros((stackcube.shape[1])), algo_dict,
                                     fwhm=mp.lod, star_phot=star_phot, dp=dp)


            # plotdata.append(method_out[0])
            thruput, noise, cont, sigma_corr, dist = method_out[0]
            thruputs.append(thruput)
            noises.append(noise)
            conts.append(cont)
            rad_samp = dp.platescale * dist
            dprint((dist, len(dist)))
            dprint(rad_samp)
            rad_samps.append(rad_samp)
            maps.append(method_out[1])
            dprint(method_out[0].shape)
        # plotdata = np.array(plotdata)
        # dprint(plotdata.shape)
        # rad_samp = np.linspace(0,tp.platescale/1000.*plotdata.shape[2],plotdata.shape[2])

        fig, axes = plt.subplots(nrows=1, ncols=3, figsize=(14, 3.4))

        # plotdata[:, 2] = plotdata[:, 1]*plotdata[:, 3] / np.mean(plotdata[:, 0], axis=0)

        for rad_samp, thruput in zip(rad_samps, thruputs):
            axes[0].plot(rad_samp, thruput)
        for rad_samp, noise in zip(rad_samps, noises):
            axes[1].plot(rad_samp, noise)
        for rad_samp, cont in zip(rad_samps, conts):
            axes[2].plot(rad_samp, cont)
        for ax in axes:
            ax.set_yscale('log')
            ax.set_xlabel('Radial Separation')
            ax.tick_params(direction='in', which='both', right=True, top=True)
        axes[0].set_ylabel('Throughput')
        axes[1].set_ylabel('Noise')
        axes[2].set_ylabel('5$\sigma$ Contrast')
        axes[2].legend([str(metric_val) for metric_val in metric_vals])

    compare_images(maps, logAmp=True, vmin=-1e-7, vmax=1e-7)#vmins=np.ones((len(maps)))*[-1e-7], vmaxs=np.ones((len(maps)))*[1e-7])


if __name__ == '__main__':
    fields = make_fields_master()
    make_dp_master()
