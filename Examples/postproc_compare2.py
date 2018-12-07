'''This code handles the relevant functionality of a Hawaii 2RG camera'''
import sys
sys.path.append('D:/dodkins/MEDIS/MEDIS')
import numpy as np
import copy
import matplotlib.pyplot as plt
from vip_hci import phot, pca
from params import ap, cp, tp, sp, mp, iop
from Utils.plot_tools import loop_frames, quicklook_im,view_datacube, compare_images, indep_images
import Detector.readout as read
import Analysis.phot
import Analysis.stats
import pandas as pd

# Global params
sp.save_obs = False
sp.show_cube = False
sp.save_obs = False
sp.return_cube = True
sp.show_wframe = False
ap.companion = True
# ap.contrast = [1e-5, 1e-5]#[0.1,0.1]
# ap.lods = [[-2.5,2.5], [1.5,+1.5]]
ap.contrast = [1e-5]#[0.1,0.1]
ap.lods = [[1.5,-1.5]]
# tp.diam=8.
tp.use_spiders = False
tp.use_ao = True
tp.use_atmos = True
tp.ao_act=65
tp.servo_error= [1,3]#[1,2]#False#[1e-3,1e-3]#
tp.piston_error = True
cp.vary_r0 = False
tp.active_modulate=False
tp.detector = 'MKIDs'#'ideal'#
ap.star_photons*=100
# tp.NCPA_type = None#'Static'
# tp.CPA_type = None#'Static'
tp.NCPA_type = 'Static'
tp.CPA_type = 'Static'
mp.date = '180508/'
iop.update(mp.date)
sp.num_processes = 20
tp.occulter_type = '8th_Order'
# tp.occulter_type = 'None'
num_exp = 1000
tp.active_null = True
ap.exposure_time = 0.001  # 0.001
ap.numframes = int(num_exp * ap.exposure_time / cp.frame_time)

xlocs = range(0, 128)  # range(0,128)#65
ylocs = range(0, 128)  # range(0,128)#85
tp.band = np.array([860, 1250])
tp.nwsamp = 1
tp.rot_rate = 0  # deg/s
theta=45
lod = 8

def eval_method(cube, algo, angle_list, algo_dict):
    fulloutput = phot.contrcurve.contrast_curve(cube=cube,
                                   angle_list=angle_list, psf_template=psf_template,
                                   fwhm=lod, pxscale=tp.platescale/1000,
                                   starphot=star_phot, algo=algo,
                                   debug=True, plot=False, theta=theta,full_output=True,fc_snr=10, **algo_dict)
    plt.show()
    metrics = [fulloutput[0]['throughput'], fulloutput[0]['noise'], fulloutput[0]['sensitivity (Student)']]
    metrics = np.array(metrics)
    return metrics, fulloutput[3]

plotdata, maps = [], []
if __name__ == '__main__':
    rad_samp = np.linspace(0,tp.platescale/1000.*40,40)
    # print rad_samp
    # # Get unocculted PSF for intensity
    psf_template = Analysis.phot.get_unoccult_psf(hyperFile='/IntHyperUnOccult.pkl', plot=False)
    # # star_phot = np.sum(psf_template)
    star_phot = phot.contrcurve.aperture_flux(psf_template,[64],[64],lod,1)[0]/ap.numframes * 500
    psf_template = psf_template[:-1,:-1]

    # # Get unocculted PSF for DSI
    # DSI_psf_template = Analysis.stats.get_unoccult_DSIpsf(hyperFile='/SSDHyperUnOccult.pkl', plot=False)
    # DSI_starphot = np.sum(DSI_psf_template)
    # # DSI_starphot = phot.contrcurve.aperture_flux(DSI_psf_template,[64],[64],lod,1)
    # DSI_psf_template = DSI_psf_template[:-1,:-1]
    #
    # # Get unocculted PSF for Iratio
    # SSD_psf_template = Analysis.stats.get_unoccult_SSDpsf(hyperFile='/SSDHyperUnOccult.pkl',plot=False)
    # SSD_starphot = np.sum(SSD_psf_template)
    # # SSD_starphot = phot.contrcurve.aperture_flux(SSD_psf_template,[64],[64],lod,1)
    # SSD_psf_template = SSD_psf_template[:-1,:-1]

    # # RDI
    # ap_orig = copy.copy(ap)
    # ap.numframes= ap.numframes/ 2
    # ap.companion = False
    # iop.hyperFile = iop.datadir + '/RDIrefHyper.pkl'
    # ref_hypercube = read.get_integ_hypercube(plot=False)#/ap.numframes
    # ap.startframe=ap.numframes
    # # ap.companion = True
    # ap.companion = False
    # iop.hyperFile = iop.datadir + '/RDItarHyper.pkl'
    # RDI_hypercube = read.get_integ_hypercube(plot=False)#/ap.numframes
    # # ap.numframes = ap.numframes * 2
    # ap.__dict__ = ap_orig.__dict__
    # # star_phots = np.ones((len(RDI_hypercube))) * star_phot
    # print RDI_hypercube.shape
    # angle_list = np.zeros((len(RDI_hypercube)))
    # algo_dict = {'cube_ref':ref_hypercube[:,0]}
    # print star_phot, type(star_phot)
    # method_out = eval_method(RDI_hypercube[:,0], pca.pca, angle_list, algo_dict)
    # plotdata.append(method_out[0])
    # maps.append(method_out[1])
    # quicklook_im(method_out[1])
    # #
    # #
    # #
    # # ADI
    # tp.rot_rate = 4.5  # deg/s
    # iop.hyperFile = iop.datadir + '/ADIHyper.pkl'
    # ADI_hypercube = read.get_integ_hypercube(plot=False)#/ap.numframes
    # # star_phots =  np.ones((len(ADI_hypercube))) * star_phot
    # algo_dict = {}
    # angle_list = -1 * np.arange(0, num_exp * tp.rot_rate * cp.frame_time, tp.rot_rate * cp.frame_time)
    # print angle_list.shape
    # method_out = eval_method(ADI_hypercube[:,0], pca.pca, angle_list, algo_dict)
    # plotdata.append(method_out[0])
    # maps.append(method_out[1])
    # quicklook_im(method_out[1])
    #
    # # annos = ['ADI','RDI']
    # # compare_images([maps[1],maps[0]],logAmp=True, scale = 1e3, annos=annos)
    # #
    # # SDI
    # tp.rot_rate = 0  # deg/s
    # tp.nwsamp = 8
    # iop.hyperFile = iop.datadir + '/SDIHyper.pkl'
    # wsamples = np.linspace(tp.band[0], tp.band[1], tp.nwsamp)
    # scale_list = tp.band[0] / wsamples
    # SDI_hypercube = read.get_integ_hypercube(plot=False)
    # tp.nwsamp = 1
    # algo_dict = {'scale_list': scale_list}
    # ap.exposure_time = 1
    # # datacube = read.med_collapse(SDI_hypercube)
    # datacube = (read.take_exposure(SDI_hypercube)/ap.numframes)[0]
    # # star_phots = star_phot
    # angle_list = np.zeros((len(SDI_hypercube[0])))
    # method_out = eval_method(datacube, pca.pca, angle_list, algo_dict)
    # plotdata.append(method_out[0])
    # maps.append(method_out[1])
    # quicklook_im(method_out[1])

    # # #
    # # # # star_phots = np.ones((LCmap.shape[2])) * star_phot
    # # # angle_list =np.ones((LCmap.shape[2]))
    #
    # # SSD + DSI
    # # SSD_maps = Analysis.stats.DISI(LCmap, thresh=3e-6, plot=True)
    # angle_list = np.zeros((len(simple_hypercube)))
    # algo_dict = {'thresh': 3e-6}
    # method_out = eval_method(simple_hypercube[:,0], Analysis.stats.DISI_4_VIP,angle_list, algo_dict)
    # plotdata.append(method_out[0])
    # maps.append(method_out[1])
    # quicklook_im(method_out[1], axis=None, title=r'  DS$ / I^{*}$', anno='DISI')

    # # Integration
    # iop.hyperFile = iop.datadir + '/noWnoRollHyperWcomp1000cont3.pkl'
    # simple_hypercube = read.get_integ_hypercube(plot=False)#/ap.numframes
    # quicklook_im(np.sum(simple_hypercube[:,0], axis=0), axis=None, title=r'  $I_r / I^{*}$', anno='DSI')
    #
    # # DSI
    # iop.hyperFile = iop.datadir + '/nomodulate.pkl'
    # tp.active_modulate = False
    # simple_hypercube = read.get_integ_hypercube(plot=False)#/ap.numframes
    # angle_list = np.zeros((len(simple_hypercube)))
    # # algo_dict = {'DSI_starphot': DSI_starphot, 'thresh': 1e-5}
    # algo_dict = {'thresh': 1e-5}
    #
    # loop_frames(simple_hypercube[:,0])
    # plt.figure()
    # # plt.plot(simple_hypercube[:,0,53,53])
    # # plt.plot(simple_hypercube[:, 0, 54, 54])
    # # plt.plot(simple_hypercube[:, 0, 53, 54])
    # # plt.plot(simple_hypercube[:, 0, 54, 53])
    # # plt.plot(simple_hypercube[:, 0, 74, 63])
    # # plt.plot(simple_hypercube[:, 0, 75, 63])
    # # plt.plot(simple_hypercube[:, 0, 74, 64])
    # # plt.plot(simple_hypercube[:, 0, 75, 64])
    # plt.plot(simple_hypercube[:, 0, 74, 55])
    # plt.plot(simple_hypercube[:, 0, 75, 56])
    # plt.plot(simple_hypercube[:, 0, 74, 55])
    # plt.plot(simple_hypercube[:, 0, 75, 56])
    # # plt.show()
    #
    # plt.figure()
    # plt.plot(simple_hypercube[:,0,26,102])
    # plt.plot(simple_hypercube[:, 0, 25, 102])
    # plt.plot(simple_hypercube[:, 0, 26, 103])
    # plt.plot(simple_hypercube[:, 0, 25, 103])
    # plt.show()
    #
    # method_out = eval_method(simple_hypercube[:,0], Analysis.stats.DSI_4_VIP,angle_list, algo_dict)
    # plotdata.append(method_out[0])
    # maps.append(method_out[1])
    # #
    # quicklook_im(method_out[1], axis=None, title=r'  $I_r / I^{*}$', anno='DSI')


    conv_steps = 110
    # DSI
    iop.hyperFile = iop.datadir + '/modulate.pkl'
    # tp.active_modulate = True
    simple_hypercube = read.get_integ_hypercube(plot=False)#/ap.numframes
    print 'star_phot', star_phot
    quicklook_im(np.sum(simple_hypercube[conv_steps:,0], axis=0)/star_phot, axis=None, title=r'  $I / I^{*}$', anno='Integration')
    angle_list = np.zeros((len(simple_hypercube)-conv_steps))
    # algo_dict = {'DSI_starphot': DSI_starphot, 'thresh': 1e-5}
    algo_dict = {'thresh': 1e-5}

    loop_frames(simple_hypercube[:,0])
    plt.figure()
    # plt.plot(simple_hypercube[:,0,53,53])
    # plt.plot(simple_hypercube[:, 0, 54, 54])
    # plt.plot(simple_hypercube[:, 0, 53, 54])
    # plt.plot(simple_hypercube[:, 0, 54, 53])
    # plt.plot(simple_hypercube[:, 0, 74, 63])
    # plt.plot(simple_hypercube[:, 0, 75, 63])
    # plt.plot(simple_hypercube[:, 0, 74, 64])
    # plt.plot(simple_hypercube[:, 0, 75, 64])
    # plt.plot(simple_hypercube[:, 0, 74, 55])
    # plt.plot(simple_hypercube[:, 0, 75, 56])
    # plt.plot(simple_hypercube[:, 0, 74, 55])
    # plt.plot(simple_hypercube[:, 0, 75, 56])
    plt.plot(simple_hypercube[:, 0, 72, 57])
    plt.plot(simple_hypercube[:, 0, 71, 58])
    plt.plot(simple_hypercube[:, 0, 71, 57])
    plt.plot(simple_hypercube[:, 0, 72, 58])
    plt.axhline(np.mean(simple_hypercube[conv_steps:, 0, 71, 57]), linestyle = '--', color='k')
    plt.xlabel('Time (ms)')
    plt.ylabel('Intensity (cts)')
    # plt.show()

    plt.figure()
    # plt.plot(simple_hypercube[:,0,26,102])
    # plt.plot(simple_hypercube[:, 0, 25, 102])
    # plt.plot(simple_hypercube[:, 0, 26, 103])
    # plt.plot(simple_hypercube[:, 0, 25, 103])
    # plt.plot(simple_hypercube[:, 0, 46, 47])
    # plt.plot(simple_hypercube[:, 0, 46, 46])
    # plt.plot(simple_hypercube[:, 0, 47, 46])
    # plt.plot(simple_hypercube[:, 0, 47, 47])
    plt.plot(simple_hypercube[:, 0, 83, 46])
    plt.plot(simple_hypercube[:, 0, 82, 47])
    plt.plot(simple_hypercube[:, 0, 82, 46])
    plt.plot(simple_hypercube[:, 0, 83, 47])
    plt.axhline(np.mean(simple_hypercube[conv_steps:, 0, 82, 47]), linestyle = '--', color='k')
    plt.xlabel('Time (ms)')
    plt.ylabel('Intensity (cts)')
    plt.show()

    method_out = eval_method(simple_hypercube[conv_steps:,0], Analysis.stats.DSI_4_VIP,angle_list, algo_dict)
    plotdata.append(method_out[0])
    maps.append(method_out[1])
    #
    quicklook_im(method_out[1]/star_phot, axis=None, title=r'  $I_r / I^{*}$', anno='DSI')




    # method_out = eval_method(simple_hypercube[:,0], Analysis.stats.DSI_4_VIP,angle_list, algo_dict)
    # plotdata.append(method_out[0])
    # maps.append(method_out[1])
    # #
    # quicklook_im(method_out[1], axis=None, title=r'  $I_r / I^{*}$', anno='DSI')
    #
    # # SSD
    # angle_list = np.zeros((len(simple_hypercube)))
    # iop.hyperFile = iop.datadir + '/noWnoRollHyperWcomp1000cont2.pkl'
    # simple_hypercube = read.get_integ_hypercube(plot=False)#\ap.numframes
    # algo_dict = {}
    # method_out = eval_method(simple_hypercube[:,0], Analysis.stats.SSD_4_VIP,angle_list, algo_dict)
    # plotdata.append(method_out[0])
    # maps.append(method_out[1])
    # quicklook_im(method_out[1])
    #
    # iop.hyperFile = iop.datadir + '/noWnoRollHyperWcomp1000cont3.pkl'
    # simple_hypercube = read.get_integ_hypercube(plot=False)
    LCmap = np.transpose(simple_hypercube[conv_steps:,0])
    SSD_maps = Analysis.stats.get_Iratio(LCmap, xlocs, ylocs, range(63,66), range(63,66), True)
    SSD_maps = np.array(SSD_maps)[:-1]
    # # SSD_maps[:2] /= star_phot
    # # SSD_maps[2] /= SSD_starphot
    SSD_maps /= star_phot

    #vmins = [2e-11, 2e-8, 1e-12], vmaxs = [5e-7, 1.5e-7, 1e-6]
    indep_images(SSD_maps, logAmp=True, titles =[r'  $I_C / I^{*}$',r'  $I_S / I^{*}$',r'  $I_r / I^{*}$'], annos=['Deterministic','Random','Beam Ratio'])

    # # Plotting
    # plotdata = np.array(plotdata)
    # rad_samp = np.linspace(0,tp.platescale/1000.*plotdata.shape[2],plotdata.shape[2])
    # fig, axes = plt.subplots(nrows=1, ncols=3, figsize=(14, 3.4))
    # for thruput in plotdata[:,0]:
    #     axes[0].plot(rad_samp,thruput)
    # for noise in plotdata[:,1]:
    #     axes[1].plot(rad_samp,noise)
    # for cont in plotdata[:,2]:
    #     axes[2].plot(rad_samp,cont)
    # for ax in axes:
    #     ax.set_yscale('log')
    #     ax.set_xlabel('Radial Separation')
    #     ax.tick_params(direction='in',which='both', right=True, top=True)
    # axes[0].set_ylabel('Throughput')
    # axes[1].set_ylabel('Noise')
    # axes[2].set_ylabel('5$\sigma$ Contrast')
    # axes[2].legend(['RDI','ADI','SDI','DSI','SSD'])
    #
    # compare_images(maps, logAmp=True)
    # plt.show()
