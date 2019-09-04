'''Example Code for conducting SDI with MKIDs'''

import os
import matplotlib as mpl
import numpy as np
mpl.use("Qt5Agg")
import matplotlib.pyplot as plt
from matplotlib.colors import LogNorm
# import warnings
# warnings.filterwarnings("ignore")
# mpl.rcParams['axes.prop_cycle'] = mpl.cycler(color=["r", "k", "c"])
import pickle as pickle
from vip_hci import phot, pca
from statsmodels.tsa.stattools import acf
from medis.params import tp, mp, cp, sp, ap, iop
import medis.get_photon_data as gpd
from medis.Utils.plot_tools import quicklook_im, indep_images, view_datacube
from medis.Utils.misc import dprint
import medis.Detector.readout as read
from medis.Detector import mkid_artefacts as MKIDs
# from medis.Detector import spectral as spec
from medis.Detector import pipeline as pipe
from medis.Analysis.phot import get_unoccult_psf, eval_method

# mpl.use('Qt5Agg')

# Renaming obs_sequence directory location
# iop.update(new_name='HCIdemo_onaxisdimmer10frames/')
iop.update(new_name='exptime_test1/')
iop.atmosdata = '190801'
iop.atmosdir = os.path.join(iop.datadir, iop.atmosroot, iop.atmosdata)  # full path to FITS files

iop.aberdir = os.path.join(iop.datadir, iop.aberroot, 'Palomar256')
iop.quasi = os.path.join(iop.aberdir, 'quasi')
iop.atmosdata = '190823'
iop.atmosdir = os.path.join(iop.datadir, iop.atmosroot, iop.atmosdata)  # full path to FITS files
iop.atmosconfig = os.path.join(iop.atmosdir, cp.model, 'config.txt')

# Parameters specific to this script
sp.show_wframe = False
sp.save_obs = False
sp.show_cube=False
sp.num_processes = 4

ap.companion = False
sp.get_ints=False
ap.star_photons_per_s = int(1e5)#1e6
# ap.contrast = [10**-3.5,10**-2.5,10**-2,10**-3]#,10**-3.1,10**-4,10**-4,10**-4]
# ap.lods = [[6,0.0],[-6,0.0],[0.0,6],[0.0,-6]]#,[-5,0.0],[1.6,0.0],[3.2,0.0],[5,0.0]]
ap.contrast = [10**-3.5, 10**-3.5, 10**-4.5, 10**-4]
ap.lods = [[6,0.0],[3,0.0],[0.0,6],[0.0,3]]#,[-5,0.0],[1.6,0.0],[3.2,0.0],[5,0.0]]

tp.save_locs = np.empty((0,1))

tp.diam=8.
ap.grid_size=256
tp.beam_ratio =0.5
tp.obscure = True
tp.use_ao = True
tp.ao_act = 50
tp.platescale = 10 # mas
tp.detector = 'ideal'
# tp.detector = 'MKIDs'
tp.use_atmos = True
tp.use_zern_ab = False
tp.occulter_type = 'Vortex'#"None (Lyot Stop)"
tp.aber_params = {'CPA': True,
                'NCPA': True,
                'QuasiStatic': False,  # or Static
                'Phase': True,
                'Amp': False,
                'n_surfs': 4,
                'OOPP': False}#[16,8,4,16]}#False}#
tp.aber_vals = {'a': [5e-18, 1e-19],#'a': [5e-17, 1e-18],
                'b': [2.0, 0.2],
                'c': [3.1, 0.5],
                'a_amp': [0.05, 0.01]}
tp.piston_error = False
ap.band = np.array([800, 1500])
ap.nwsamp = 4
ap.w_bins = 16#8
tp.rot_rate = 0  # deg/s
tp.pix_shift = [[15,30]]
# tp.pix_shift = [[0,0],[20,20]]

mp.bad_pix = True
mp.array_size = np.array([146,146])
num_exp = 10
ap.sample_time = 0.05
# date = '180828/'
# dprint((iop.datadir, date))
# iop.atmosdir= os.path.join(iop.datadir,'atmos',date)

mp.phase_uncertainty =True
mp.phase_background=False
mp.QE_var = True
mp.bad_pix = True
mp.hot_pix = None
mp.hot_bright = 1e3

mp.R_mean = 8
mp.g_mean = 0.2
mp.g_sig = 0.04
mp.bg_mean = -10
mp.bg_sig = 40
mp.pix_yield = 0.9#0.7 # check dis

lod = 6

make_figure = 4

def get_form_photons(fields, comps=True):
    dprint('Making new formatted photon data')
    # if not os.path.isfile(iop.device_params):
    MKIDs.initialize()

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
        pickle.dump((photons, stackcube), handle, protocol=pickle.HIGHEST_PROTOCOL)

    return photons, stackcube

def make_figure4(comps=False):
    if not comps and __name__ == '__main__':
        print(ap.__dict__)
        psf_template = get_unoccult_psf(fields='/IntHyperUnOccult.h5', plot=False, numframes=1)
        dprint((ap.grid_size//2, psf_template.shape))
        # quicklook_im(np.sum(psf_template,axis=0), logAmp=True)
        star_phot = phot.contrcurve.aperture_flux(np.sum(psf_template,axis=0),[mp.array_size[0]//2],[mp.array_size[0]//2],lod,1)[0]#/1e4#/ap.numframes * 500
        wsamples = np.linspace(ap.band[0], ap.band[1], ap.w_bins)
        scale_list = wsamples/(ap.band[1]-ap.band[0])
        # scale_list = scale_list[::-1]
        algo_dict = {'scale_list': scale_list}

    ap.companion = True
    ap.numframes = int(num_exp)
    iop.fields = iop.testdir + '/HR8799_phot_tag%i_tar_%i_comps_exp.h5' % (ap.numframes, np.log10(ap.star_photons_per_s))

    wsamples = np.linspace(ap.band[0], ap.band[1], ap.w_bins)
    scale_list = wsamples / (ap.band[1] - ap.band[0])

    iop.form_photons = iop.form_photons[:-4] +'_exp'
    iop.device_params = iop.device_params[:-4] + '_exp'
    tp.pix_shift = [[0, 0]]
    if __name__ == '__main__':
        fields = gpd.run_medis()

        maps, plotdata = [], []

        exptimes = np.array([1,2,5]) * ap.sample_time
        for exptime in exptimes:
            ap.exposure_time = exptime
            iop.form_photons = iop.form_photons.split('_exp')[0] + f'_exp={ap.exposure_time}_comps={comps}.pkl'
            iop.device_params = iop.device_params.split('_exp')[0] + f'_exp={ap.exposure_time}_comps={comps}.pkl'
            dprint(iop.form_photons)
            dprint(fields.shape)
            fields_collapse = read.take_fields_exposure(fields)
            dprint(fields_collapse.shape)
            if os.path.exists(iop.form_photons):
                dprint(f'Formatted photon data already exists at {iop.form_photons}')
                with open(iop.form_photons, 'rb') as handle:
                    photons, stackcube = pickle.load(handle)

            else:
                photons, stackcube = get_form_photons(fields_collapse, comps=comps)

            stackcube = stackcube[:len(fields_collapse)]
            view_datacube(stackcube[0], logAmp=True, show=False)
            view_datacube(stackcube[:, 0], logAmp=True, show=True)

            stackcube /= np.sum(stackcube)  # /ap.numframes
            stackcube = stackcube
            stackcube = np.transpose(stackcube, (1, 0, 2, 3))

            if comps:
                SDI = pca.pca(stackcube, angle_list=np.zeros((stackcube.shape[1])), scale_list=scale_list,
                              mask_center_px=None, adimsdi='double', ncomp=7, ncomp2=None,
                              collapse='median')  # , ncomp2=3)#,
                # quicklook_im(SDI, logAmp=True, show=False)
                maps.append(SDI)

            else:
                method_out = eval_method(stackcube, pca.pca, psf_template,
                                         np.zeros((stackcube.shape[1])), algo_dict,
                                         fwhm=lod, star_phot=star_phot)
                plotdata.append(method_out[0])
                maps.append(method_out[1])

        if not comps:
            plotdata = np.array(plotdata)
            # rad_samp = np.linspace(0,tp.platescale/1000.*plotdata.shape[2],plotdata.shape[2])
            rad_samp = np.linspace(0, tp.platescale / 1000. * 100, plotdata.shape[2])
            fig, axes = plt.subplots(nrows=1, ncols=3, figsize=(14, 3.4))

            dprint(plotdata.shape)
            # plotdata[:, 2] *= plotdata[:, 0]
            # plotdata[:, 2] /= np.mean(plotdata[:, 0], axis=0)
            # plotdata[:, 2][plotdata[:, 2] == 0] = 1
            plotdata[:, 2] = plotdata[:, 1]*plotdata[:, 3] / np.mean(plotdata[:, 0], axis=0)

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
            axes[2].legend([str(exptime) for exptime in exptimes])

        view_datacube(maps, logAmp=True, vmin=-1e-6, vmax=1e-6)

make_figure4()