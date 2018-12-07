'''This code handles the relevant functionality of a Hawaii 2RG camera'''
import sys
sys.path.append('D:/dodkins/MEDIS/MEDIS')
import numpy as np
import copy
import matplotlib.pyplot as plt
from vip_hci import phot, pca
from params import ap, cp, tp, sp, mp, iop
from Utils.plot_tools import loop_frames, quicklook_im,view_datacube, compare_images, indep_images
from Utils.rawImageIO import clipped_zoom
import Detector.readout as read
import Analysis.phot
import Analysis.stats
import pandas as pd
from Utils.misc import dprint

# Global params
sp.save_obs = False
sp.show_cube = False
sp.save_obs = False
sp.show_wframe = False
ap.star_photons = 0.5e10#0.5e6# 1e9

tp.beam_ratio = 0.5
tp.servo_error= [0,1]#[0,1]#False # No delay and rate of 1/frame_time
tp.quick_ao=True
# tp.diam=8.
tp.use_spiders = True
tp.use_ao = True
# ap.star_photons*=1000
tp.diam = 8.0  # telescope diameter in meters
tp.ao_act = 44
tp.grid_size=256
mp.array_size = np.array([257,257])#
mp.total_pix = mp.array_size[0] * mp.array_size[1]
mp.xnum = mp.array_size[0]
mp.ynum = mp.array_size[1]
mp.R_mean = 10
mp.distort_phase =True
mp.phase_uncertainty =True
mp.phase_background=True
mp.respons_var = True
mp.bad_pix = True
mp.pix_yield = 0.84
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
mp.date = '180828/'
import os
iop.update(mp.date)
# iop.aberdir = os.path.join(iop.rootdir, 'data/aberrations/180630_30mins')
# cp.date = '1804171hr8m/'
cp.date = '180829/180828/'
cp.atmosdir= os.path.join(cp.rootdir,cp.data,cp.date)
sp.num_processes = 45
tp.occulter_type = '8th_Order'
num_exp = 4000#2000#1000#50#50#1000
ap.exposure_time = 0.1#05  # 0.001
cp.frame_time = 0.1#05
ap.numframes = int(num_exp * ap.exposure_time / cp.frame_time)
# ap.startframe=ap.numframes
ap.companion = True
# ap.contrast = [1e-4,1e-3,1e-5, 1e-6,1e-6,1e-7]  # [0.1,0.1]
# ap.lods = [[-1.5,1.5],[1,1],[-2.5,2.5],[-3,3],[3,3],[4.5,-4]]
# ap.contrast = [1e-5, 1e-6]  # [0.1,0.1]
# ap.lods = [[-2.5, 2.5], [-4.5, 4.5]]
# ap.contrast = [10**-4.5,10**-4.5,10**-4.5,1*10**-5,1e-5]  # [0.1,0.1]
ap.contrast = [10**-4.8,10**-5.15,10**-5.1,10**-4.9,10**-6.4]  # [0.1,0.1]
ap.lods = [[2.2,-1.8],[-3,2.5],[-2.2,4.8],[-5,-5],[2.5,2.5]]#[6,-4.5],
tp.detector = 'MKIDs'  #'ideal'#
tp.platescale=10
tp.piston_error = True
xlocs = range(0, 128)  # range(0,128)#65
ylocs = range(0, 128)  # range(0,128)#85
tp.band = np.array([800, 1500])
tp.nwsamp = 1#5#5#5#1.#
tp.rot_rate = 0  # deg/s
theta=45
lod = 8

def eval_method(cube, algo, angle_list, algo_dict):
    fulloutput = phot.contrcurve.contrast_curve(cube=cube,
                                   angle_list=angle_list, psf_template=psf_template,
                                   fwhm=lod, pxscale=tp.platescale/1000,
                                   starphot=star_phot, algo=algo,  wedge=(-150,-90),#nbranch=3,#
                                   debug=False, plot=False, theta=theta,full_output=True,fc_snr=10, **algo_dict)
    plt.show()
    metrics = [fulloutput[0]['throughput'], fulloutput[0]['noise'], fulloutput[0]['sensitivity (Student)']]
    metrics = np.array(metrics)
    return metrics, fulloutput[3]

plotdata, maps = [], []
if __name__ == '__main__':

    rad_samp = np.linspace(0,tp.platescale/1000.*40,40)
    print rad_samp
    # Get unocculted PSF for intensity
    # ap.star_photons = 1e8
    lod = 10
    psf_template = Analysis.phot.get_unoccult_psf(hyperFile='/IntHyperUnOccult2.pkl', plot=False, numframes=1)
    # psf_template = np.resize(psf_template, (tp.nwsamp, psf_template.shape[0],psf_template.shape[1]))
    # star_phot = np.sum(psf_template)
    # star_phot = phot.contrcurve.aperture_flux(psf_template,[tp.grid_size/2],[tp.grid_size/2],lod,1)[0]*1000#/ap.numframes
    star_phot = np.max(psf_template) / 100#1000  # /ap.numframes
    if psf_template.shape[1] % 2 == 0:
        psf_template = psf_template[-1,:-1]
    dprint(star_phot)
    print psf_template.shape
    # quicklook_im(psf_template)
    #
    # # iop.hyperFile = iop.datadir + 'IntHyperUnOccult2.pkl'  # 5
    # # psf_hyper = read.get_integ_hypercube(plot=False)#/ap.numframes
    # # # loop_frames(psf_hyper[::10,0], logAmp=True)

    # iop.hyperFile = iop.datadir + 'HR8799_MKIDs5_nosource.pkl'  # 5
    # iop.hyperFile = iop.datadir + 'HR8799_MKIDs5.pkl'  # 5
    iop.hyperFile = iop.datadir + 'HR8799_MKIDs400sstar_realPs1w.pkl'  # 5
    # iop.hyperFile = iop.datadir + 'noWnoRollHyperWcomp1000cont_Aug_1stMKIDs2.pkl'#5
    simple_hypercube_1 = read.get_integ_hypercube(plot=False)#/ap.numframes

    # loop_frames(simple_hypercube_1[:,0], logAmp=True)
    # # loop_frames(simple_hypercube_1[0,:], logAmp=True)
    # quicklook_im(np.sum(simple_hypercube_1[:100,0],axis=0), logAmp=True)
    ap.startframe = ap.numframes #+3010
    ap.companion =False
    iop.hyperFile = iop.datadir + 'HR8799_2_MKIDs400sref_realPs1w.pkl'  # 5
    # iop.hyperFile = iop.datadir + 'HR8799_2_MKIDs5.pkl'  # 5
    # # iop.hyperFile = iop.datadir + 'noWnoRollHyperWcomp1000cont_Aug_2ndMKIDs2.pkl'#5
    simple_hypercube_2 = read.get_integ_hypercube(plot=False)#/ap.numframes
    #
    diff_cube = simple_hypercube_1-simple_hypercube_2
    quicklook_im(np.sum(diff_cube[:, 0], axis=0), logAmp=True)
    # loop_frames(simple_hypercube_2[:,0], logAmp=True)
    # quicklook_im(np.sum(simple_hypercube_2[:100,0],axis=0), logAmp=True)
    # loop_frames(simple_hypercube_2[:,0], logAmp=True)q
    # diff_cube = simple_hypercube_1#-simple_hypercube_2

    Analysis.stats.Dmap_quad(simple_hypercube_1,simple_hypercube_2,binning=2)
    # factor = 1000
    # diff_cube = np.zeros(((simple_hypercube_1.shape[0]/factor)**2,1,mp.array_size[0],mp.array_size[1]))
    # k = 0
    # for a in simple_hypercube_1[::factor,0]:
    #     for b in simple_hypercube_2[::factor,0]:
    #         # quicklook_im(a)
    #         # quicklook_im(b)
    #         diff_cube[k] = a - b
    #         print k
    #         k += 1
    # # diff_cube = np.array([[i-j] for i in simple_hypercube_1[::10,0] for j in simple_hypercube_2[::10,0]])
    dprint(np.shape(diff_cube))
    loop_frames(diff_cube[:,0], logAmp=False)
    # # quicklook_im(np.mean(diff_cube[:,0],axis=0), logAmp=False)
    # quicklook_im(np.mean(diff_cube[:, 0], axis=0), logAmp=True)
    # quicklook_im(np.median(diff_cube[:, 0], axis=0), logAmp=True)
    # #
    LCcube = np.transpose(diff_cube, (2, 3, 0, 1))
    algo_dict = {'thresh': 0}
    Dmap = Analysis.stats.get_Dmap(LCcube, algo_dict['thresh'], binning=2)
    # quicklook_im(Dmap, annos=['MKIDs'], title=  r'  $I_L / I^{*}$', mark_star=True)
    # # indep_images([np.mean(diff_cube[:, 0], axis=0) / star_phot, Dmap / star_phot], logAmp=True,
    # #              titles=[r'  $I / I^{*}$', r'  $I_L / I^{*}$'], annos=['Mean', 'MKIDs'])
    #

    algo_dict = {'full_target_cube': simple_hypercube_1, 'thru':True}
    angle_list = np.zeros((len(simple_hypercube_1)))

    # simple_hypercube_1 = np.transpose(simple_hypercube_1, (1, 0, 2, 3))
    # simple_hypercube_2 = np.transpose(simple_hypercube_2, (1, 0, 2, 3))
    # loop_frames(simple_hypercube_1[:,0])
    # loop_frames(simple_hypercube_1[0])
    method_out = eval_method(simple_hypercube_1[:,-1], Analysis.stats.effint_4_VIP,angle_list, algo_dict)
    plotdata.append(method_out[0])
    maps.append(method_out[1])
    # quicklook_im(method_out[1])


    algo_dict = {'full_target_cube': simple_hypercube_1, 'cube_ref': simple_hypercube_2, 'thru':True}
    angle_list = np.zeros((len(simple_hypercube_1)))

    method_out = eval_method(simple_hypercube_1[:,-1], Analysis.stats.RDI_4_VIP,angle_list, algo_dict)
    plotdata.append(method_out[0])
    maps.append(method_out[1])
    # quicklook_im(method_out[1])

    algo_dict = {'thresh': 0,'full_target_cube': simple_hypercube_1, 'cube_ref': simple_hypercube_2, 'thru':True}
    angle_list = np.zeros((len(simple_hypercube_1)))

    method_out = eval_method(simple_hypercube_1[:,-1], Analysis.stats.RDSI_4_VIP,angle_list, algo_dict)
    plotdata.append(method_out[0])
    maps.append(method_out[1])
    # quicklook_im(method_out[1])

    plotdata = np.array(plotdata)
    import cPickle as pickle
    with open('save.pkl', 'wb') as handle:
        pickle.dump(plotdata, handle, protocol=pickle.HIGHEST_PROTOCOL)
    # for cont in plotdata[:,2]:
    #     plt.plot(rad_samp,cont)

    # print plotdata
    # print plotdata[:,2]

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
