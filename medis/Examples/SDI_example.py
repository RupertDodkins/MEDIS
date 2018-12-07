'''This code handles the relevant functionality of a Hawaii 2RG camera'''
import sys
sys.path.append('D:/dodkins/MEDIS/MEDIS')
import numpy as np
from params import ap, cp, tp, sp, mp, iop
import cPickle as pickle
import os
from Utils.plot_tools import loop_frames, quicklook_im, view_datacube, compare_images, grid
from Utils.misc import debug_program
from Examples.get_photon_data import run
import Detector.readout as read
import Detector.H2RG as H2RG
from Utils.rawImageIO import clipped_zoom
import Analysis.phot as phot
from Utils.misc import dprint
# import proper
#
# def get_hypercube(plot=False):
#     print os.path.isfile(binnedHyperCubeFile), binnedHyperCubeFile
#     if os.path.isfile(binnedHyperCubeFile):
#         hypercube = read.open_hypercube(HyperCubeFile=binnedHyperCubeFile)
#     else:
#         hypercube = run()
#         print 'finished run'
#         print np.shape(hypercube)
#         if plot: view_datacube(hypercube[0], logAmp=True)
#
#         if tp.detector == 'H2RG':
#             hypercube = H2RG.scale_to_luminos(hypercube)
#             if plot: view_datacube(hypercube[0], logAmp=True)
#
#         hypercube = read.take_exposure(hypercube)
#         if tp.detector == 'H2RG':
#              hypercube = H2RG.add_readnoise(hypercube)
#              # if plot: view_datacube(hypercube[0], logAmp=True)
#
#         if plot: view_datacube(hypercube[0], logAmp=True)
#         # datacube = pipe.stack_hypercube(hypercube)
#         # if plot: view_datacube(datacube, logAmp=True)
#         read.save_hypercube(hypercube, HyperCubeFile=binnedHyperCubeFile)
#     # hypercube = take_exposure(hypercube)
#     print np.shape(hypercube)
#     # quicklook_im(hypercube[0,0])
#     # hypercube = H2RG.add_readnoise(hypercube)
#     if plot: view_datacube(hypercube[0], logAmp=True)
#     if plot: loop_frames(hypercube[:, 0])
#     if plot: loop_frames(hypercube[0])
#     return hypercube
# debug_program()

# mp.date = '180411/'
mp.date = '180415mkids/'
iop.update(mp.date)
if __name__ == '__main__':
    psf_template = phot.get_unoccult_psf(hyperFile='/IntHyperUnOccult.pkl', plot=False)
    psf_template = psf_template[:-1,:-1]
    # quicklook_im(psf_template)

sp.save_obs = False
sp.show_cube = False
sp.show_wframe = False
ap.companion=True
sp.num_processes = 40
ap.companion = True
ap.contrast = [10**-4,10**-6]#[0.1,0.1]
ap.lods = [[-1.75,1.75], [-4,-4]]
ap.star_photons = 1e9#1e10
# tp.detector = 'ideal'
tp.detector = 'MKIDs'
# tp.NCPA_type = 'Static'
tp.aber_params = {'CPA': True,
                    'NCPA': True,
                    'QuasiStatic': False,  # or Static
                    'Phase': True,
                    'Amp': False,
                    'n_surfs': 4,
                    'OOPP': [16,8,8, 4]}#False}#
# tp.occulter_type = 'Gaussian'
tp.occulter_type = 'Vortex'
tp.piston_error = False
tp.band = np.array([860,1250])
tp.w_bins = 8
tp.nwsamp = 4
num_exp = 100
# ap.star_photons *= tp.nwsamp
ap.exposure_time = 0.1#0.001
cp.frame_time = 0.1
cp.date = '180829/180828/'
cp.atmosdir= os.path.join(cp.rootdir,cp.data,cp.date)
ap.numframes = int(num_exp * ap.exposure_time / cp.frame_time)

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



# binnedHyperCubeFile = os.path.join(mp.rootdir,mp.proc_dir, mp.date, './BinH2RG_with_coron_hyper.pkl')
# iop.hyperFile = iop.datadir + '/BinH2RG_with_coron_hyper.pkl'

# iop.hyperFile = iop.datadir + '/SDIHyper2.pkl'
# iop.hyperFile = iop.datadir + '/SDIHyper12.pkl'
iop.hyperFile = iop.datadir + '/SDIHyper13.pkl'
# iop.hyperFile = iop.datadir + '/SDIHyper13_hp.pkl'
wsamples = np.linspace(tp.band[0], tp.band[1], tp.w_bins)
scale_list = tp.band[0]/wsamples


if __name__ == '__main__':
    hypercube = read.get_integ_hypercube(plot=False)

    import matplotlib.pyplot as plt

    # psf_template = hypercube[0,0,20:31,98:109]
    # print scale_list[5], 'SL'

    # quicklook_im(hypercube[0,0])
    # quicklook_im(psf_template)

    from vip_hci import phot, pca
    star_phot = phot.contrcurve.aperture_flux(psf_template,[64],[64],8,1)
    star_phots = np.ones((hypercube.shape[1]))*star_phot
    print star_phots, 'star_phots'
    algo_dict = {'scale_list':scale_list}
    # res_throug = phot.contrcurve.throughput(hypercube[0], angle_list=np.zeros((len(hypercube[0]))), psf_template=psf_template, fwhm=10, pxscale=0.13,
    #                         algo = pca.pca,full_output=True, **algo_dict)
    # print res_throug[3].shape
    # loop_frames(res_throug[3][0])
    # loop_frames(res_throug[3][:,0])
    # plt.plot(res_throug[0][0])
    # plt.show()
    # phot.contrcurve.contrast_curve(cube=hypercube[0], angle_list=np.zeros((len(hypercube[0]))), psf_template=psf_template, fwhm=10, pxscale=0.13, starphot=star_phots, algo=pca.pca, debug=True, **algo_dict)


    # from vip_hci import pca
    # loop_frames(hypercube[:,0])
    # hypercube[:,:,56,124] = 0
    # hypercube[:,:,119,104] = 0
    datacube = np.mean(hypercube, axis=0)/ap.exposure_time
    # datacube = np.transpose(np.transpose(datacube) / np.max(datacube, axis=(1, 2))) / float(tp.nwsamp)
    dprint(np.sum(datacube, axis=(1,2)))
    loop_frames(datacube)

    dprint(scale_list)

    SDI = pca.pca(datacube, angle_list=np.zeros((len(hypercube[0]))), scale_list=scale_list,
                  mask_center_px=None)

    # dprint(SDI.shape)
    print hypercube.shape
    # SDI[SDI<=0] = 1e-5
    # quicklook_im(np.sum(hypercube, axis=(0,1)), logAmp=True)
    # quicklook_im(SDI, logAmp=True)
    SDI = SDI.reshape(1,SDI.shape[0],SDI.shape[1])

    # wsamples = np.linspace(tp.band[0], tp.band[1], tp.nwsamp)
    # scale_list = wsamples/tp.band[0]
    dprint(scale_list)
    print scale_list, scale_list[-1], 'SL', 1./scale_list[-1]
    wframe = clipped_zoom(datacube[0], scale_list[0])
    # quicklook_im(wframe)
    wframe = wframe.reshape(1,wframe.shape[0],wframe.shape[1])
    cube = np.vstack((datacube[[0,-1]],wframe,SDI))
    print star_phot, 'star_phot'
    cube = cube / star_phot
    for c in cube:
        print np.max(c), np.sum(c), np.max(c*c), np.sum(c*c)
    # cube = np.dstack((hypercube[0,0],wframe,hypercube[0,-1],SDI)).transpose()
    annos = ['$\mathbf{\lambda_0}$=860 nm','$\mathbf{\lambda_8}$=1250 nm','$\mathbf{\lambda_0}$ Scaled','SDI Residual']
    # view_datacube(cube, logAmp=True,)
    # compare_images(cube, logAmp=True, annos=annos, scale=1e4, vmin=0.5e-6, vmax = 2e-4)

    iop.hyperFile = iop.datadir + '/SDIHyper13_hp.pkl'
    hypercube = read.get_integ_hypercube(plot=False)
    datacube = np.mean(hypercube, axis=0) / ap.exposure_time
    scale_list = tp.band[0] / wsamples
    dprint(scale_list)
    SDI = pca.pca(datacube, angle_list=np.zeros((len(hypercube[0]))), scale_list=scale_list,
                  mask_center_px=None)
    SDI = SDI.reshape(1,SDI.shape[0],SDI.shape[1])
    wframe = clipped_zoom(datacube[0], scale_list[0])
    wframe = wframe.reshape(1,wframe.shape[0],wframe.shape[1])
    cube_hp = np.vstack((datacube[[0,-1]],wframe,SDI))
    cube_hp = cube_hp / star_phot
    # compare_images(cube_hp, logAmp=True, annos=annos, scale=1e4, vmin=0.5e-6, vmax=2e-4)

    cube = np.vstack((cube,cube_hp))
    annos = ['$\mathbf{\lambda_0}$','$\mathbf{\lambda_8}$','$\mathbf{\lambda_0}$ Scaled','SDI']*2

    grid(cube, logAmp=True, annos=annos, scale=1e4, vmins=[0.5e-6]*len(cube), vmaxs = [2e-4]*len(cube), width=4)

    # angle_list = np.zeros((tp.nwsamp))
    # print np.mean(hypercube,axis=0).shape
    # static_psf = pca.pca(np.mean(hypercube,axis=0), angle_list=angle_list, scale_list=scale_list,
    #               mask_center_px=None,full_output=True)
    # quicklook_im(np.sum(hypercube,axis=(0,1)))
    # scale_list = np.linspace(scale_list[-1],scale_list[0],8)
    #
    # import scipy.ndimage
    # static_psf = static_psf[1][0]
    # static_psf =scipy.ndimage.zoom(static_psf, float(hypercube.shape[-1])/static_psf.shape[-1], order=0)
    # print static_psf.shape
    # quicklook_im(static_psf)
    # static_cube = np.zeros((tp.nwsamp,mp.array_size[0],mp.array_size[1]))
    # ref_vals = np.max(np.mean(hypercube,axis=0),axis=(1,2))
    # for iw,scale in enumerate(scale_list):
    #     print scale
    #     static_cube[iw] = clipped_zoom(static_psf,scale)
    #     quicklook_im(np.mean(hypercube,axis=0)[iw], logAmp=False)
    #     quicklook_im(static_cube[iw], logAmp=False)
    #     static_cube[iw] *= ref_vals[iw]/np.max(static_cube[iw])
    #     quicklook_im(static_cube[iw], logAmp=False)
    #     quicklook_im(np.mean(hypercube,axis=0)[iw] - static_cube[iw], logAmp=False)
    # # static_cube = np.asarray(static_cube)
    #
    # algo_dict = {'thresh': 0}  # 1e-5}
    # # method_out = eval_method(simple_hypercube[:,0], Analysis.stats.DSI_4_VIP,angle_list, algo_dict)
    # # static_psf = np.mean(simple_hypercube,axis=0)#/len(simple_hypercube)
    # # print static_psf.shape
    # # static_psf = np.resize(static_psf,(50,8,129,129))
    # # print static_psf.shape, simple_hypercube.shape
    #
    # # loop_frames(static_psf[0,:], logAmp=False)
    # loop_frames(hypercube[0], logAmp=False)
    # loop_frames(hypercube[:, 0], logAmp=False)
    # static_cube = np.resize(static_cube, (500, 8, 129, 129))
    # hypercube -= static_cube
    #
    # loop_frames(hypercube[0], logAmp=False)
    # loop_frames(hypercube[:, 0], logAmp=False)
    # LCcube = np.transpose(hypercube, (2, 3, 0, 1))
    # import Analysis.stats
    # Dmap = Analysis.stats.get_Dmap(LCcube, algo_dict['thresh'])


