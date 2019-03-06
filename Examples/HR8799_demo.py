'''This code handles the relevant functionality of a Hawaii 2RG camera'''
import numpy as np
import copy
import matplotlib.pyplot as plt
from vip_hci import phot, pca
from medis.params import ap, cp, tp, sp, mp, iop
from medis.Utils.plot_tools import loop_frames, quicklook_im,view_datacube, compare_images, indep_images, grid
from medis.Utils.rawImageIO import clipped_zoom
import medis.Detector.readout as read
import medis.Analysis.phot
import medis.Analysis.stats
import pandas as pd
from medis.Utils.misc import dprint

# Rename Data Directory
iop.update("HR8799_demo")

# Global params
sp.save_obs = False
sp.show_cube = False
sp.save_obs = False
sp.show_wframe = False
ap.companion = True
ap.contrast = [1e-4,1e-4]#[0.1,0.1]
ap.star_photons = 1e9
ap.lods = [[-2.5,2.5],[-3,3]]
tp.beam_ratio = 0.6
tp.servo_error= [0,1]#[0,1]#False # No delay and rate of 1/frame_time
tp.quick_ao=True
# tp.diam=8.
tp.use_spiders = True
tp.use_ao = True
tp.detector = 'MKIDs'#'ideal'#
# ap.star_photons*=1000
tp.diam = 8.0  # telescope diameter in meters
tp.ao_act = 50
# tp.NCPA_type = None#'Static'
# tp.CPA_type = None#'Static'
# tp.NCPA_type = 'Static'
# tp.CPA_type = 'Static'
# tp.aber_params['OOPP'] = [8,4]
tp.aber_params = {'CPA': True,
                    'NCPA': True,
                    'QuasiStatic': False,  # or Static
                    'Phase': True,
                    'Amp': False,
                    'n_surfs': 4,
                    'OOPP': [16,8,8, 4]}#False}#
# mp.date = '180416mkids/'
# cp.date = '1804171hr8m/'
# import os
# iop.atmosdir= os.path.join(cp.rootdir,cp.data,cp.date)
# iop.update(mp.date)
sp.num_processes = 48
# tp.occulter_type = '8th_Order'
tp.occulter_type = 'Vortex'
# num_exp = 2000#500#1000#50#50#1000
# ap.exposure_time = 0.001  # 0.001
# cp.frame_time = 0.001
num_exp = 500#500#1000#50#50#1000
ap.exposure_time = 0.1  # 0.001
cp.frame_time = 0.1
ap.numframes = int(num_exp * ap.exposure_time / cp.frame_time)
# ap.startframe=ap.numframes
tp.piston_error = True
xlocs = range(0, 128)  # range(0,128)#65
ylocs = range(0, 128)  # range(0,128)#85
tp.band = np.array([800, 1500])
tp.nwsamp = 4#8
tp.w_bins = 8
tp.rot_rate = 0  # deg/s
theta=45
lod = 8

mp.distort_phase =True
mp.phase_uncertainty =True
mp.phase_background=True
mp.respons_var = True
mp.bad_pix = True
mp.hot_pix = 2

mp.R_mean = 10
mp.g_mean = 0.8
mp.g_sig = 0.2
mp.bg_mean = -10
mp.bg_sig = 40
mp.pix_yield = 0.8

def eval_method(cube, algo, angle_list, algo_dict, psf_template):
    dprint((cube.shape, len(angle_list), tp.platescale/1000, psf_template.shape))
    # wsamples = np.linspace(tp.band[0], tp.band[1], tp.w_bins)
    # scale_list = tp.band[0]/wsamples
    # scale_list = 1./scale_list[::-1]
    # dprint(scale_list)
    # fwhms = np.round(lod*scale_list)
    # dprint((fwhms, type(fwhms)))
    dprint('lol')
    fulloutput = phot.contrcurve.contrast_curve(cube=cube,
                                   angle_list=angle_list, psf_template=psf_template,
                                   fwhm=lod, pxscale=tp.platescale/1000,
                                   starphot=star_phot, algo=algo,# wedge=(60,30),
                                    nbranch=1, verbose=True,
                                   debug=False, plot=False, theta=theta,full_output=True,fc_snr=5, **algo_dict)
    plt.show()
    metrics = [fulloutput[0]['throughput'], fulloutput[0]['noise'], fulloutput[0]['sensitivity (Student)'], fulloutput[0]['distance']]
    metrics = np.array(metrics)
    return metrics, fulloutput[3]


plotdata, maps = [], []
ap.companion=False
if __name__ == '__main__':



    rad_samp = np.linspace(0,tp.platescale/1000.*40,40)
    print(rad_samp)
    # Get unocculted PSF for intensity
    psf_template = Analysis.phot.get_unoccult_psf(hyperFile='/IntHyperUnOccult.pkl', plot=False)
    # star_phot = np.sum(psf_template)
    star_phot = phot.contrcurve.aperture_flux(psf_template,[64],[64],lod,1)[0]/ap.numframes
    psf_template = psf_template[:-1,:-1]

    # RDI (for SDI)
    # ap.companion = True
    # ap.contrast = [1e-5, 1e-6]  # [0.1,0.1]
    # ap.lods = [[-2.5, 2.5], [-4.5, 4.5]]
    tp.detector =  'MKIDs'  #'ideal'#
    # iop.obs_seq = iop.datadir + 'small_no_source_tar_500.pkl'
    iop.obs_seq = iop.testdir + 'small_no_source_tar_500.pkl'
    simple_hypercube_1 = read.get_integ_obs_sequence(plot=False)#/ap.numframes

    ap.startframe = ap.numframes
    ap.companion =False
    # iop.hyperFile = iop.datadir + 'small_no_source_ref_500.pkl'  # 5
    iop.hyperFile = iop.testdir + 'small_no_source_ref_500.pkl'  # 5
    simple_hypercube_2 = read.get_integ_obs_sequence(plot=False)#/ap.numframes


    def RDI(simple_hypercube_1, simple_hypercube_2, psf_template):
        dprint('RDI')
        algo_dict = {'cube_ref': simple_hypercube_2[:, 0]}
        angle_list = np.zeros((len(simple_hypercube_1)))
        method_out = eval_method(simple_hypercube_1[:, 0], Analysis.stats.RDI_4_VIP, angle_list, algo_dict,
                                 psf_template=psf_template)
        return method_out

    def RDI_DSI_BB(simple_hypercube_1, simple_hypercube_2, psf_template):
        dprint('RDI_DSI_BB')
        wsamples = np.linspace(tp.band[0], tp.band[1], tp.w_bins)
        scale_list = tp.band[0] / wsamples
        simple_hypercube_1 = np.transpose(simple_hypercube_1, (1, 0, 2, 3))
        simple_hypercube_2 = np.transpose(simple_hypercube_2, (1, 0, 2, 3))
        psf_template = np.resize(psf_template, (tp.w_bins, psf_template.shape[0], psf_template.shape[1]))
        algo_dict = {'thresh': 0, 'full_target_cube': simple_hypercube_1, 'cube_ref': simple_hypercube_2, 'thru': True,
                     'scale_list': scale_list}
        angle_list = np.zeros((simple_hypercube_1.shape[1]))
        method_out = eval_method(simple_hypercube_1[:], Analysis.stats.RDI_DSI_BB_4_VIP, angle_list, algo_dict,
                                 psf_template=psf_template)
        return method_out

    method_out = RDI(simple_hypercube_1, simple_hypercube_2, psf_template)
    plotdata.append(method_out[0])
    maps.append(method_out[1])

    # method_out = RDI_DSI(simple_hypercube_1, simple_hypercube_2, psf_template)
    # plotdata.append(method_out[0])
    # maps.append(method_out[1])

    method_out = RDI_DSI_BB(simple_hypercube_1, simple_hypercube_2, psf_template)
    plotdata.append(method_out[0])
    maps.append(method_out[1])

    # Plotting
    dprint(np.shape(plotdata))
    plotdata = np.array(plotdata)
    # rad_samp = np.linspace(0,tp.platescale/1000.*mp.array_size[0]/2,plotdata.shape[2])
    rad_samp = plotdata[:, 3][0]
    fig, axes = plt.subplots(nrows=1, ncols=3, figsize=(14, 3.4))

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
    axes[2].legend(['Exp.', 'RDI', 'RDI DSI', 'RDI DSI SDI'])

    compare_images(maps, logAmp=True, vmin=0.01, vmax=100,  # vmins = [0.1,0.1,0.1,0.1], vmaxs = [100,100,0.5,0.5],
                   annos=['Exp.', 'RDI', 'RDI DSI', 'RDI DSI SDI'])  # ,
    # titles=[r'  $I / I^{*}$', r'  $I / I^{*}$', r'  $I_L / I^{*}$', r'  $I_L / I^{*}$'])
    # quicklook_im(maps[0], logAmp=True, vmin = 0.01, vmax = 1)
    plt.show()