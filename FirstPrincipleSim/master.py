''' Make the master fields.h5 and device_params.pkl '''

import os
import matplotlib as mpl
import numpy as np
mpl.use("Qt5Agg")
import matplotlib.pyplot as plt
from matplotlib.colors import LogNorm, SymLogNorm
import matplotlib.ticker as ticker
from mpl_toolkits.axes_grid1 import make_axes_locatable
import pickle as pickle
from vip_hci import phot, pca
from medis.params import tp, mp, sp, ap, iop
import medis.get_photon_data as gpd
from medis.Utils.plot_tools import view_datacube, compare_images, fmt, quicklook_im
from medis.Utils.misc import dprint
import medis.Detector.readout as read
from medis.Detector import mkid_artefacts as MKIDs
from medis.Detector import pipeline as pipe
from medis.Analysis.phot import get_unoccult_psf, eval_method, sum_contrast

metric = __file__.split('/')[-1].split('.')[0]
iop.set_testdir(f'FirstPrincipleSim3/{metric}_old/')
iop.set_atmosdata('190823')
iop.set_aberdata('Palomar512')
iop.fields = iop.testdir + 'fields_master_reform.h5'
master_fields = iop.fields
iop.form_photons = os.path.join(iop.testdir, 'formatted_photons_master.pkl')
iop.device_params = os.path.join(iop.testdir, 'deviceParams_master.pkl')
iop.median_noise= os.path.join(iop.testdir, 'median_noise_master.txt')

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
    # ap.contrast = [10 ** -3.5, 10 ** -3.5, 10 ** -4, 10 ** -4, 10 ** -4.5, 10 ** -4.5, 10 ** -5, 10 ** -5]
    # ap.contrast = [10 ** -4]*8
    ap.contrast = 10**np.array([-3.5, -4, -4.5, -5] * 2)
    # ap.lods = [[4.5,0], [2.5,0], [0,3], [0,5], [-5.5,0], [-3.5,0], [0,-4],[0,-6]]
    ap.lods = [[2.5,0], [0,3], [-3.5,0], [0,-4], [4.5,0], [0,5], [-5.5,0],[0,-6]]
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
    tp.occulter_type = 'Vortex'
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
        fields = gpd.run_medis()
        dprint(fields.shape)
        # tess = np.sum(fields, axis=2)
        # view_datacube(tess[0], logAmp=True, show=False)
        # view_datacube(tess[:,0], logAmp=True, show=True)
        dprint(fields.shape)
        plt.plot(np.sum(fields, axis = (0,1,3,4)))
        plt.show()
        if fields.shape[2] == len(ap.contrast)+1:
            fields = reformat_planets(fields)
        else:
            view_datacube(fields[0, :, 0], logAmp=True, show=False)
            view_datacube(fields[0, :, 1], logAmp=True, show=True)
            # view_datacube(fields[:, -1, 2], logAmp=True, show=False)

    return fields

def set_mkid_params():
    mp.phase_uncertainty = True
    mp.phase_background = False
    mp.QE_var = True
    mp.bad_pix = True
    mp.dark_counts = True
    mp.dark_pix_frac = 0.1
    mp.dark_bright = 20
    mp.hot_pix = None
    mp.hot_bright = 2.5*10**3
    mp.R_mean = 8
    mp.R_sig = 2
    mp.g_mean = 0.3
    mp.g_sig = 0.04
    mp.bg_mean = -10
    mp.bg_sig = 40
    mp.pix_yield = 0.9
    mp.array_size = np.array([150, 150])
    mp.lod = 6
    mp.quantize_FCs = True

def make_dp_master():
    """

    :return:
    """
    set_field_params()
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

        dprint(iop.device_params)
        step_packets = read.get_packets(spectralcube, step, dp, mp)
        cube = pipe.make_datacube_from_list(step_packets, (ap.w_bins,dp.array_size[0],dp.array_size[1]))
        stackcube[step] = cube

    with open(iop.form_photons, 'wb') as handle:
        dprint((iop.form_photons, stackcube.shape, dp))
        pickle.dump((stackcube, dp), handle, protocol=pickle.HIGHEST_PROTOCOL)

    return stackcube, dp

def get_obj_photons(fields):
    dprint('Making new formatted photon data')

    with open(iop.device_params, 'rb') as handle:
        dp = pickle.load(handle)

    objcube = np.zeros((2, len(fields), ap.w_bins, dp.array_size[1], dp.array_size[0]))
    for step in range(len(fields)):
        dprint(step)
        obj = range(2)
        for o in obj:
            spectralcube = fields[step, :, o]
            step_packets = read.get_packets(spectralcube, step, dp, mp)
            cube = pipe.make_datacube_from_list(step_packets, (ap.w_bins,dp.array_size[0],dp.array_size[1]))
            objcube[o, step] = cube

    with open(iop.form_photons, 'wb') as handle:
        dprint((iop.form_photons, objcube.shape, dp))
        pickle.dump((objcube, dp), handle, protocol=pickle.HIGHEST_PROTOCOL)

    return objcube, dp

def detect_obj_photons(metric_vals, metric_name, plot=False):
    iop.device_params = iop.device_params[:-4] + '_'+metric_name
    iop.form_photons = iop.form_photons[:-4] +'_'+metric_name

    iop.fields = master_fields
    fields = gpd.run_medis()

    objcubes, dps =  [], []
    for metric_val in metric_vals:
        iop.form_photons = iop.form_photons.split('_'+metric_name)[0] + f'_{metric_name}={metric_val}_comps={comps}.pkl'
        iop.device_params = iop.device_params.split('_'+metric_name)[0] + f'_{metric_name}={metric_val}.pkl'

        if os.path.exists(iop.form_photons):
            dprint(f'Formatted photon data already exists at {iop.form_photons}')
            with open(iop.form_photons, 'rb') as handle:
                objcube, dp = pickle.load(handle)

        else:
            objcube, dp = get_obj_photons(fields)

        if plot:
            dprint(objcube.shape)
            for o in range(2):
                plt.figure()
                plt.hist(objcube[o, objcube[o]!=0].flatten(), bins=np.linspace(0,1e4, 50))
                plt.yscale('log')
                view_datacube(objcube[o,0], logAmp=True, show=False)
                view_datacube(objcube[o, :, 0], logAmp=True, show=False)

        objcube /= np.sum(objcube)  # /ap.numframes
        objcube = objcube
        objcube = np.transpose(objcube, (1, 0, 2, 3))
        objcubes.append(objcube)
        dps.append(dp)

    return objcubes, dps

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
            view_datacube(stackcube[:, 0], logAmp=True, show=True)

        stackcube /= np.sum(stackcube)  # /ap.numframes
        stackcube = np.transpose(stackcube, (1, 0, 2, 3))
        stackcubes.append(stackcube)
        dps.append(dp)

    return stackcubes, dps

def pca_stackcubes(stackcubes, dps, comps=True):
    wsamples = np.linspace(ap.band[0], ap.band[1], ap.w_bins)
    scale_list = wsamples / (ap.band[1] - ap.band[0])
    maps = []

    if comps:
        for stackcube in stackcubes:
            SDI = pca.pca(stackcube, angle_list=np.zeros((stackcube.shape[1])), scale_list=scale_list,
                          mask_center_px=None, adimsdi='double', ncomp=7, ncomp2=None,
                          collapse='median')
            maps.append(SDI)
        return maps

    else:
        rad_samps, thruputs, noises, conts = [], [], [], []
        for stackcube, dp in zip(stackcubes, dps):
            psf_template = get_unoccult_psf(fields=f'/IntHyperUnOccult_arraysize={dp.array_size}.h5', plot=False, numframes=1)
            star_phot = phot.contrcurve.aperture_flux(np.sum(psf_template, axis=0), [dp.array_size[0] // 2],
                                                      [dp.array_size[0] // 2], mp.lod, 1)[0]*10**1.5
            algo_dict = {'scale_list': scale_list}
            # temp for those older format cache files
            if hasattr(dp, 'lod'):
                fwhm = dp.lod
            else:
                fwhm = mp.lod
            method_out = eval_method(stackcube, pca.pca, psf_template,
                                     np.zeros((stackcube.shape[1])), algo_dict,
                                     fwhm=fwhm, star_phot=star_phot, dp=dp)

            thruput, noise, cont, sigma_corr, dist = method_out[0]
            thruputs.append(thruput)
            noises.append(noise)
            conts.append(cont)
            rad_samp = dp.platescale * dist
            rad_samps.append(rad_samp)
            maps.append(method_out[1])
        plt.show(block=True)
        return maps, rad_samps, thruputs, noises, conts

def eval_performance(stackcubes, dps, metric_vals, comps=True):
    pca_products = pca_stackcubes(stackcubes, dps, comps)
    if comps:
        maps = pca_products
    else:
        maps, rad_samps, thruputs, noises, conts = pca_products
        contrcurve_plot(metric_vals, rad_samps, thruputs, noises, conts)

    compare_images(maps, logAmp=True, vmin=-1e-7, vmax=1e-7)
    # from medis.Utils.plot_tools import quicklook_im
    # new_maps = []
    # for map in maps:
    #     quicklook_im(map, logAmp=True)
    #     dprint(map.shape)
    #     map = phot.snrmap_fast(map, 5, plot=True)
    #     new_maps.append(map)
    # compare_images(new_maps)

def eval_performance_sum(stackcubes, dps, metric_vals, comps=True):
    wsamples = np.linspace(ap.band[0], ap.band[1], ap.w_bins)
    scale_list = wsamples / (ap.band[1] - ap.band[0])
    algo_dict = {'scale_list': scale_list}
    star_phot = 1
    for stackcube, dp in zip(stackcubes, dps):
        dprint(np.sum(stackcube))
        if hasattr(dp, 'lod'):
            fwhm = dp.lod
        else:
            fwhm = mp.lod
        contrast, rad_vec = sum_contrast(stackcube, algo_dict, fwhm=fwhm, star_phot=star_phot, dp=dp)
        plt.plot(rad_vec, contrast)
    plt.show()
    # compare_images(maps, logAmp=True, vmin=-1e-7, vmax=1e-7)

def contrcurve_plot(metric_vals, rad_samps, thruputs, noises, conts):
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

def combo_performance(maps, rad_samps, conts, annos, plot_inds=[0,3,6]):
    labels = ['a', 'b', 'c', 'd', 'e']
    title = r'  $I / I^{*}$'
    vmin = -1e-8
    vmax = 1e-6

    fig, axes = plt.subplots(nrows=1, ncols=4, figsize=(13, 3.4))
    for rad_samp, cont in zip(rad_samps, conts):
        axes[0].plot(rad_samp, cont)

    axes[0].set_yscale('log')
    axes[0].set_xlabel('Radial Separation')
    axes[0].tick_params(direction='in', which='both', right=True, top=True)
    axes[0].set_ylabel('5$\sigma$ Contrast')
    planet_seps = np.arange(2.5,6.5,0.5)*0.1
    # contrast = np.array([[e,e] for e in np.arange(-3.5,-5.5,-0.5)]).flatten()
    contrast = np.array([-3.5, -4, -4.5, -5] * 2)
    axes[0].scatter(planet_seps, 10**contrast, marker='o', color='k')
    axes[0].legend([str(metric_val) for metric_val in annos], ncol=4, fontsize=8)
    axes[0].text(0.04, 0.9, labels[0], transform=axes[0].transAxes, fontweight='bold', color='k', fontsize=22, family='serif')

    for m, ax in enumerate(axes[1:]):
        im = ax.imshow(maps[plot_inds[m]], interpolation='none', origin='lower', vmin=vmin, vmax=vmax,
                       norm=SymLogNorm(linthresh=1e-8), cmap="inferno")
        ax.text(0.05, 0.05, annos[plot_inds[m]], transform=ax.transAxes, fontweight='bold', color='w', fontsize=16)
        ax.text(0.04, 0.9, labels[m+1], transform=ax.transAxes, fontweight='bold', color='w', fontsize=22, family='serif')
        ax.axis('off')

    axes[1].text(0.84, 0.9, '0.2"', transform=axes[1].transAxes, fontweight='bold', color='w', ha='center', fontsize=14,
                 family='serif')
    # axes[1].plot([114, 134], [130, 130], color='w', linestyle='-', linewidth=3)
    axes[1].plot([0.76, 0.89], [0.87, 0.87], transform=axes[1].transAxes, color='w', linestyle='-', linewidth=3)

    divider = make_axes_locatable(axes[3])
    cax = divider.append_axes("right", size="5%", pad=0.05)
    cb = fig.colorbar(im, cax=cax, orientation='vertical', norm=LogNorm(), format=ticker.FuncFormatter(fmt))
    cb.ax.set_title(title, fontsize=16)  #
    # cbar_ticks = np.logspace(np.log10(vmin), np.log10(vmax), num=5, endpoint=True)
    cbar_ticks = [-1e-8, 0, 1e-8, 1e-7, 1e-6]
    cb.set_ticks(cbar_ticks)

    # plt.tight_layout()
    plt.subplots_adjust(left=0.055, bottom=0.135, right=0.95, top=0.88, wspace=0.105)
    plt.show(block=True)

def reformat_planets(fields):
    obs_seq = fields
    dprint(fields.shape)
    tess = np.sum(obs_seq[:,:,1:], axis=2)
    view_datacube(tess[0], logAmp=True, show=False)
    double_cube = np.zeros((ap.numframes, ap.w_bins, 2, ap.grid_size, ap.grid_size))
    double_cube[:, :, 0] = obs_seq[:, :, 0]
    collapse_comps = np.sum(obs_seq[:, :, 1:], axis=2)
    double_cube[:, :, 1] = collapse_comps
    view_datacube(double_cube[0,:,0], logAmp=True, show=False)
    view_datacube(double_cube[0,:,1], logAmp=True, show=True)
    print(f"Reduced shape of obs_seq = {np.shape(double_cube)} (numframes x nwsamp x 3 x grid x grid)")
    read.save_fields(double_cube, fields_file=iop.fields)
    return double_cube

def get_median_noise(master_dp):
    from vip_hci.metrics.contrcurve import noise_per_annulus
    wsamples = np.linspace(ap.band[0], ap.band[1], ap.w_bins)
    scale_list = wsamples / (ap.band[1] - ap.band[0])

    fields = gpd.run_medis()

    comps = False
    if os.path.exists(iop.form_photons):
        dprint(f'Formatted photon data already exists at {iop.form_photons}')
        with open(iop.form_photons, 'rb') as handle:
            stackcube, dp = pickle.load(handle)
    else:
        stackcube, dp = get_form_photons(fields, comps=comps)

    stackcube /= np.sum(stackcube)  # /ap.numframes
    stackcube = np.transpose(stackcube, (1, 0, 2, 3))

    frame_nofc = pca.pca(stackcube, angle_list=np.zeros((stackcube.shape[1])), scale_list=scale_list,
                  mask_center_px=None, adimsdi='double', ncomp=7, ncomp2=None,
                  collapse='median')

    quicklook_im(frame_nofc, logAmp=True)
    fwhm = mp.lod
    with open(master_dp, 'rb') as handle:
        dp = pickle.load(handle)

    mask = dp.QE_map == 0
    median_noise, vector_radd = noise_per_annulus(frame_nofc, separation=fwhm, fwhm=fwhm, mask=mask)
    np.savetxt(iop.median_noise, median_noise)

def form(metric_vals, metric_name, plot=True, plot_inds=[0,3,6]):
    iop.perf_data = os.path.join(iop.testdir, 'performance_data.pkl')
    dprint(iop.perf_data)
    if not os.path.exists(iop.perf_data):
        import importlib

        param = importlib.import_module(metric_name)

        if not os.path.exists(f'{iop.device_params[:-4]}_{metric_name}={metric_vals[0]}.pkl'):
            param.adapt_dp_master()

        comps_ = [True, False]
        pca_products = []
        for comps in comps_:
            if 'get_stackcubes' in dir(param):
                stackcubes, dps = param.get_stackcubes(metric_vals, metric_name, comps=comps, plot=False)
            else:
                stackcubes, dps = get_stackcubes(metric_vals, metric_name, comps=comps, plot=False)

            if 'pca_stackcubes' in dir(param):
                pca_products.append(param.pca_stackcubes(stackcubes, dps, comps))
            else:
                pca_products.append(pca_stackcubes(stackcubes, dps, comps))

        maps = pca_products[0]
        rad_samps = pca_products[1][1]
        conts = pca_products[1][4]

        with open(iop.perf_data, 'wb') as handle:
            pickle.dump((maps, rad_samps, conts, metric_vals), handle, protocol=pickle.HIGHEST_PROTOCOL)
    else:
        with open(iop.perf_data, 'rb') as handle:
            maps, rad_samps, conts, metric_vals = pickle.load(handle)

    if plot:
        combo_performance(maps, rad_samps, conts, metric_vals, plot_inds)

    return rad_samps, conts

def check_contrast_contriubtions(metric_vals, metric_name, comps = False):
    import importlib

    param = importlib.import_module(metric_name)

    if not os.path.exists(f'{iop.device_params[:-4]}_{metric_name}={metric_vals[0]}.pkl'):
        param.adapt_dp_master()
    stackcubes, dps = get_stackcubes(metric_vals, metric_name, comps=comps)
    # plt.show(block=True)
    eval_performance(stackcubes, dps, metric_vals, comps=comps)

if __name__ == '__main__':
    # fields = make_fields_master()
    make_dp_master()
