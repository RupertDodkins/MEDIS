'''This code handles the relevant functionality of a Hawaii 2RG camera'''
import sys
sys.path.append('D:/dodkins/MEDIS/MEDIS')
import numpy as np
import copy
import matplotlib.pyplot as plt
from vip_hci import phot, pca
from medis.params import ap, cp, tp, sp, mp, iop
from medis.Utils.plot_tools import loop_frames, quicklook_im,view_datacube, compare_images, indep_images
from medis.Utils.rawImageIO import clipped_zoom
import medis.Detector.readout as read
import medis.Analysis.phot
import medis.Analysis.stats
import pandas as pd
from medis.Utils.misc import dprint

# Global params
sp.save_obs = False
sp.show_cube = False
sp.save_obs = False
sp.return_cube = True
sp.show_wframe = False
ap.companion = True
ap.contrast = [4e-4,1e-4]#[0.1,0.1]
ap.star_photons = 1e8
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
                    'Amp': True,
                    'n_surfs': 4,
                    'OOPP': [16,8,8, 4]}#False}#
mp.date = '180416mkids/'
cp.date = '1804171hr8m/'
import os
iop.atmosdir= os.path.join(cp.rootdir,cp.data,cp.date)
iop.update(mp.date)
sp.num_processes = 40
tp.occulter_type = '8th_Order'
num_exp = 2000#500#1000#50#50#1000
ap.exposure_time = 0.001  # 0.001
cp.frame_time = 0.001
ap.numframes = int(num_exp * ap.exposure_time / cp.frame_time)
# ap.startframe=ap.numframes
tp.piston_error = True
xlocs = range(0, 128)  # range(0,128)#65
ylocs = range(0, 128)  # range(0,128)#85
tp.band = np.array([800, 1500])
tp.nwsamp = 1#8
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
    print rad_samp
    # Get unocculted PSF for intensity

    psf_template = Analysis.phot.get_unoccult_psf(hyperFile='/IntHyperUnOccult.pkl', plot=False)*10
    # star_phot = np.sum(psf_template)

    star_phot = phot.contrcurve.aperture_flux(psf_template,[64],[64],lod,1)[0]/ap.numframes
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

    # RDI
    ap_orig = copy.copy(ap)
    ap.numframes= ap.numframes/ 2
    ap.companion = False
    iop.hyperFile = iop.datadir + '/RDIrefHyper.pkl'
    ref_hypercube = read.get_integ_hypercube(plot=False)#/ap.numframes
    ap.startframe=ap.numframes
    # ap.companion = True
    ap.companion = False
    iop.hyperFile = iop.datadir + '/RDItarHyper.pkl'
    RDI_hypercube = read.get_integ_hypercube(plot=False)#/ap.numframes
    # ap.numframes = ap.numframes * 2
    ap.__dict__ = ap_orig.__dict__
    # star_phots = np.ones((len(RDI_hypercube))) * star_phot
    print RDI_hypercube.shape
    angle_list = np.zeros((len(RDI_hypercube)))
    algo_dict = {'cube_ref':ref_hypercube[:,0]}
    print star_phot, type(star_phot)
    method_out = eval_method(RDI_hypercube[:,0], pca.pca, angle_list, algo_dict)
    plotdata.append(method_out[0])
    maps.append(method_out[1])
    quicklook_im(method_out[1])
    #
    #
    #
    # ADI
    tp.rot_rate = 4.5  # deg/s
    iop.hyperFile = iop.datadir + '/ADIHyper.pkl'
    ADI_hypercube = read.get_integ_hypercube(plot=False)#/ap.numframes
    # star_phots =  np.ones((len(ADI_hypercube))) * star_phot
    algo_dict = {}
    angle_list = -1 * np.arange(0, num_exp * tp.rot_rate * cp.frame_time, tp.rot_rate * cp.frame_time)
    print angle_list.shape
    method_out = eval_method(ADI_hypercube[:,0], pca.pca, angle_list, algo_dict)
    plotdata.append(method_out[0])
    maps.append(method_out[1])
    quicklook_im(method_out[1])
    #
    annos = ['ADI','RDI']
    compare_images([maps[1],maps[0]],logAmp=True, scale = 1e3, annos=annos)
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


    # RDI (for SDI)
    ap.companion = True
    ap.contrast = [1e-5, 1e-6]  # [0.1,0.1]
    ap.lods = [[-2.5, 2.5], [-4.5, 4.5]]
    tp.detector =  'MKIDs'  #'ideal'#
    iop.hyperFile = iop.datadir + 'far_out1MKIDs7.pkl'  # 5
    # iop.hyperFile = iop.datadir + 'noWnoRollHyperWcomp1000cont_Aug_1stMKIDs2.pkl'#5
    simple_hypercube_1 = read.get_integ_hypercube(plot=False)#/ap.numframes

    ap.startframe = ap.numframes
    ap.companion =False
    iop.hyperFile = iop.datadir + 'far_out2MKIDs7.pkl'  # 5
    # iop.hyperFile = iop.datadir + 'noWnoRollHyperWcomp1000cont_Aug_2ndMKIDs2.pkl'#5
    simple_hypercube_2 = read.get_integ_hypercube(plot=False)#/ap.numframes

    loop_frames(simple_hypercube_1[::10,0], logAmp=True)
    loop_frames(simple_hypercube_2[:,0], logAmp=True)
    diff_cube = simple_hypercube_1[2:]-simple_hypercube_2[2:]
    loop_frames(diff_cube[:,0], logAmp=False)
    # quicklook_im(np.mean(diff_cube[:,0],axis=0), logAmp=False)
    quicklook_im(np.mean(diff_cube[:, 0], axis=0), logAmp=True)
    quicklook_im(np.median(diff_cube[:, 0], axis=0), logAmp=True)
    #
    LCcube = np.transpose(diff_cube, (2, 3, 0, 1))
    algo_dict = {'thresh': 0}
    Dmap = Analysis.stats.get_Dmap(LCcube, algo_dict['thresh'])
    # DSI
    indep_images([Dmap], vmins=[0.01], vmaxs=[0.5], logAmp=True)

    #SDI +DSI
    iop.hyperFile = iop.datadir + '/noWnoRollHyperWcomp1000cont_Aug_1st.pkl'#5
    simple_hypercube = read.get_integ_hypercube(plot=False)#/ap.numframes
    wsamples = np.linspace(tp.band[0],tp.band[1], tp.nwsamp)
    # scale_list = tp.band[0] / wsamples
    scale_list = wsamples/tp.band[0]


    angle_list = np.zeros((tp.nwsamp))
    print np.mean(simple_hypercube,axis=0).shape
    static_psf = pca.pca(np.mean(simple_hypercube,axis=0), angle_list=angle_list, scale_list=scale_list,
                  mask_center_px=None,full_output=True)
    # quicklook_im(pca.pca(np.mean(simple_hypercube,axis=0), angle_list=angle_list, scale_list=scale_list[::-1],
    #               mask_center_px=None))

    quicklook_im(np.sum(simple_hypercube,axis=(0,1)))
    loop_frames(np.sum(simple_hypercube, axis=0))
    # scale_list = np.linspace(scale_list[-1],scale_list[0],8)
    scale_list = tp.band[1] / wsamples
    # scale_list = scale_list[::-1]
    print scale_list
    # loop_frames(static_psf[0], logAmp=False)
    # loop_frames(static_psf[1], logAmp=False)
    # loop_frames(static_psf[2], logAmp=False)
    # loop_frames(static_psf[3], logAmp=False)
    static_psf = static_psf[1][0]
    import scipy.ndimage
    dprint(star_phot)
    static_psf =scipy.ndimage.zoom(static_psf, float(simple_hypercube.shape[-1])/static_psf.shape[-1], order=0)
    print static_psf.shape
    quicklook_im(static_psf)
    quicklook_im(static_psf, logAmp=False)
    static_cube = np.zeros((tp.nwsamp,mp.array_size[0],mp.array_size[1]))
    ref_vals = np.max(np.mean(simple_hypercube,axis=0),axis=(1,2))
    # loop_frames(simple_hypercube[:,0], logAmp=False)
    # loop_frames(np.mean(simple_hypercube,axis=0), logAmp=False)



    for iw,scale in enumerate(scale_list):
        print scale
        static_cube[iw] = clipped_zoom(static_psf,scale)
        # static_cube[iw] = np.roll(np.roll(static_cube[iw],-1,0),-1,1)
        # quicklook_im(np.mean(simple_hypercube,axis=0)[iw], logAmp=False)
        # quicklook_im(static_cube[iw], logAmp=False)



        # quicklook_im(static_cube[iw], logAmp=False)
        # quicklook_im(np.mean(simple_hypercube,axis=0)[iw] - static_cube[iw], logAmp=False)
        static_cube[iw] = Analysis.stats.centroid_ref(np.mean(simple_hypercube,axis=0)[iw], static_cube[iw])
        static_cube[iw] *= ref_vals[iw]/np.max(static_cube[iw])
        # quicklook_im(static_cube[iw], logAmp=False)
    # static_cube = np.asarray(static_cube)

    dprint(ref_vals)
    # loop_frames(static_cube)
    # algo_dict = {'DSI_starphot': DSI_starphot, 'thresh': 1e-5}
    algo_dict = {'thresh': 0}#1e-5}
    # method_out = eval_method(simple_hypercube[:,0], Analysis.stats.DSI_4_VIP,angle_list, algo_dict)
    # static_psf = np.mean(simple_hypercube,axis=0)#/len(simple_hypercube)
    # print static_psf.shape
    # static_psf = np.resize(static_psf,(50,8,129,129))
    # print static_psf.shape, simple_hypercube.shape

    # loop_frames(static_psf[0,:], logAmp=False)
    # loop_frames(simple_hypercube[0], logAmp=False)
    # loop_frames(simple_hypercube[:,0], logAmp=False)
    static_cube = np.resize(static_cube,(ap.numframes,8,129,129))
    simple_hypercube -= static_cube


    # loop_frames(simple_hypercube[0], logAmp=False)
    # loop_frames(simple_hypercube[:,0], logAmp=False)

    # ref_vals = np.max(np.mean(simple_hypercube,axis=0),axis=(1,2))
    # loop_frames(simple_hypercube[:,0], logAmp=False)
    loop_frames(np.mean(simple_hypercube,axis=0), logAmp=False)
    quicklook_im(np.mean(simple_hypercube,axis=(0,1)), logAmp=False)

    LCcube = np.transpose(simple_hypercube, (2, 3, 0, 1))
    Dmap = Analysis.stats.get_Dmap(LCcube, algo_dict['thresh'])

    indep_images([np.mean(simple_hypercube,axis=(0,1))/star_phot,Dmap/star_phot], logAmp=True, titles =[r'  $I / I^{*}$',r'  $I_L / I^{*}$'], annos=['Mean','DSI'])

    method_out = eval_method(simple_hypercube[:,0], Analysis.stats.DSI_4_VIP,angle_list, algo_dict)
    plotdata.append(method_out[0])
    maps.append(method_out[1])
    #
    quicklook_im(method_out[1], axis=None, title=r'  $I_r / I^{*}$', anno='DSI')
    #
    # SSD
    angle_list = np.zeros((len(simple_hypercube)))
    iop.hyperFile = iop.datadir + '/noWnoRollHyperWcomp1000cont.pkl'
    simple_hypercube = read.get_integ_hypercube(plot=False)#\ap.numframes
    algo_dict = {}
    method_out = eval_method(simple_hypercube[:,0], Analysis.stats.SSD_4_VIP,angle_list, algo_dict)
    plotdata.append(method_out[0])
    maps.append(method_out[1])
    quicklook_im(method_out[1])
    #
    # iop.hyperFile = iop.datadir + '/noWnoRollHyperWcomp1000cont.pkl'
    # simple_hypercube = read.get_integ_hypercube(plot=False)
    # LCmap = np.transpose(simple_hypercube[:,0])
    # SSD_maps = Analysis.stats.get_Iratio(LCmap, xlocs, ylocs, None, None, None)
    # SSD_maps = np.array(SSD_maps)[:-1]
    # # # SSD_maps[:2] /= star_phot
    # # # SSD_maps[2] /= SSD_starphot
    # SSD_maps /= star_phot
    #
    # #vmins = [2e-11, 2e-8, 1e-12], vmaxs = [5e-7, 1.5e-7, 1e-6]
    # indep_images(SSD_maps, titles =[r'  $I_C / I^{*}$',r'  $I_S / I^{*}$',r'  $I_r / I^{*}$'], annos=['Deterministic','Random','Beam Ratio'])
    #
    # Plotting
    plotdata = np.array(plotdata)
    rad_samp = np.linspace(0,tp.platescale/1000.*plotdata.shape[2],plotdata.shape[2])
    fig, axes = plt.subplots(nrows=1, ncols=3, figsize=(14, 3.4))
    for thruput in plotdata[:,0]:
        axes[0].plot(rad_samp,thruput)
    for noise in plotdata[:,1]:
        axes[1].plot(rad_samp,noise)
    for cont in plotdata[:,2]:
        axes[2].plot(rad_samp,cont)
    for ax in axes:
        ax.set_yscale('log')
        ax.set_xlabel('Radial Separation')
        ax.tick_params(direction='in',which='both', right=True, top=True)
    axes[0].set_ylabel('Throughput')
    axes[1].set_ylabel('Noise')
    axes[2].set_ylabel('5$\sigma$ Contrast')
    axes[2].legend(['RDI','ADI','SDI','DSI','SSD'])

    compare_images(maps, logAmp=True)
    plt.show()


