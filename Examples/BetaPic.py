'''This code handles the relevant functionality of a Hawaii 2RG camera'''
import numpy as np
import matplotlib.pyplot as plt
from vip_hci import phot, pca
from medis.params import ap, cp, tp, sp, mp, iop
from medis.Utils.plot_tools import loop_frames, quicklook_im,view_datacube, compare_images, indep_images
from medis.Utils.rawImageIO import clipped_zoom
import medis.Detector.readout as read
import medis.Analysis.phot
import medis.Analysis.stats
from medis.Utils.misc import dprint

# Global params
sp.save_obs = False
sp.show_cube = False
sp.save_obs = False
sp.show_wframe = False
ap.star_photons = 1e8


tp.servo_error= [0,1]#[0,1]#False # No delay and rate of 1/frame_time
tp.quick_ao=True
# tp.diam=8.
tp.use_spiders = True
tp.use_ao = True
tp.detector = 'ideal'#'MKIDs'#'ideal'#
# ap.star_photons*=1000
tp.diam = 10
tp.beam_ratio = 0.5
tp.ao_act = 50
tp.grid_size=256
mp.array_size = np.array([257,257])#
mp.total_pix = mp.array_size[0] * mp.array_size[1]
mp.xnum = mp.array_size[0]
mp.ynum = mp.array_size[1]
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
sp.num_processes = 40
tp.occulter_type = '8th_Order'

num_exp = 2000#2000#1000#50#50#1000
ap.exposure_time = 0.01  # 0.001
cp.frame_time = 0.01
ap.numframes = int(num_exp * ap.exposure_time / cp.frame_time)
# ap.startframe=ap.numframes
ap.companion = True
# ap.contrast = [1e-4,1e-3,1e-5, 1e-6,1e-6,1e-7]  # [0.1,0.1]
# ap.lods = [[-1.5,1.5],[1,1],[-2.5,2.5],[-3,3],[3,3],[4.5,-4]]
# ap.contrast = [1e-5, 1e-6]  # [0.1,0.1]
# ap.lods = [[-2.5, 2.5], [-4.5, 4.5]]
ap.contrast = [10**-4.5,10**-4,10**-6,10**-7,10**-8]  # [0.1,0.1]
ap.lods = [[1,-1],[-2.2,1.7],[-6,-6],[6,6],[-6,6]]
mp.R_mean = 25
tp.piston_error = True
xlocs = range(0, 128)  # range(0,128)#65
ylocs = range(0, 128)  # range(0,128)#85
tp.band = np.array([800, 1500])
tp.nwsamp = 8#30
tp.rot_rate = 0  # deg/s
theta=45
lod = 8

# def eval_method(cube, algo, angle_list, algo_dict):
#     fulloutput = phot.contrcurve.contrast_curve(cube=cube,
#                                    angle_list=angle_list, psf_template=psf_template,
#                                    fwhm=lod, pxscale=tp.platescale/1000,
#                                    starphot=star_phot, algo=algo,
#                                    debug=True, plot=False, theta=theta,full_output=True,fc_snr=10, **algo_dict)
#     plt.show()
#     metrics = [fulloutput[0]['throughput'], fulloutput[0]['noise'], fulloutput[0]['sensitivity (Student)']]
#     metrics = np.array(metrics)
#     return metrics, fulloutput[3]

plotdata, maps = [], []
if __name__ == '__main__':


    # rad_samp = np.linspace(0,tp.platescale/1000.*40,40)
    # print rad_samp
    # # Get unocculted PSF for intensity
    # psf_template = Analysis.phot.get_unoccult_psf(hyperFile='/IntHyperUnOccult.pkl', plot=False)
    # # star_phot = np.sum(psf_template)
    # star_phot = phot.contrcurve.aperture_flux(psf_template,[64],[64],lod,1)[0]/ap.numframes
    # # psf_template = psf_template[:-1,:-1]
    #
    # iop.hyperFile = iop.datadir + 'IntHyperUnOccult.pkl'  # 5
    # psf_hyper = read.get_integ_hypercube(plot=False)#/ap.numframes
    # # loop_frames(psf_hyper[::10,0], logAmp=True)
    # # RDI (for SDI)

    ###################################################################################################
    # Running the Example
    iop.obs_seq = iop.datadir + 'BpicSource5.pkl'
    simple_hypercube_1 = read.get_integ_obs_sequence(plot=False)  #/ap.numframes
    ###################################################################################################

    # Checking against another run with no companion
    ap.startframe = ap.numframes
    ap.companion = False
    simple_hypercube_2 = read.get_integ_obs_sequence(plot=False)  #/ap.numframes
    #

    # loop_frames(simple_hypercube_1[:,0], logAmp=True)
    # loop_frames(simple_hypercube_2[:,0], logAmp=True)
    diff_cube = simple_hypercube_1[2:]-simple_hypercube_2[2:]
    # loop_frames(diff_cube[:,0], logAmp=False)
    # loop_frames(diff_cube[0,:], logAmp=False)
    # quicklook_im(np.mean(diff_cube[:,0],axis=0), logAmp=False)
    # quicklook_im(np.mean(diff_cube[:, 0], axis=0), logAmp=True)
    # quicklook_im(np.median(diff_cube[:, 0], axis=0), logAmp=True)
    #


    LCcube = np.transpose(diff_cube, (2, 3, 0, 1))
    algo_dict = {'thresh': 0}
    Dmap = Analysis.stats.get_Dmap(LCcube, algo_dict['thresh'], binning=499, plot=True)
    quicklook_im(Dmap, annos=['MKIDs'], title=  r'  $I_L / I^{*}$', mark_star=True)
    # indep_images([np.mean(diff_cube[:, 0], axis=0) / star_phot, Dmap / star_phot], logAmp=True,
    #              titles=[r'  $I / I^{*}$', r'  $I_L / I^{*}$'], annos=['Mean', 'MKIDs'])



    #
    # wsamples = np.linspace(tp.band[0], tp.band[1], tp.nwsamp)
    # # scale_list = tp.band[0] / wsamples
    # scale_list = wsamples / tp.band[0]
    #
    # angle_list = np.zeros((tp.nwsamp))
    # print np.mean(diff_cube, axis=0).shape
    # static_psf = pca.pca(np.mean(diff_cube, axis=0), angle_list=angle_list, scale_list=scale_list,
    #                      mask_center_px=None, full_output=True)
    # # quicklook_im(pca.pca(np.mean(diff_cube,axis=0), angle_list=angle_list, scale_list=scale_list,
    # #               mask_center_px=None))
    #
    # # quicklook_im(np.sum(diff_cube, axis=(0, 1)))
    # loop_frames(np.mean(diff_cube, axis=0), logAmp=False)
    # # loop_frames(np.mean(diff_cube, axis=1), logAmp=False)
    # quicklook_im(diff_cube[0,0], logAmp=False)
    # # scale_list = np.linspace(scale_list[-1],scale_list[0],8)
    # scale_list = tp.band[1] / wsamples
    # # scale_list = scale_list[::-1]
    # print scale_list, len(static_psf)
    # loop_frames(static_psf[0], logAmp=False)
    # loop_frames(static_psf[1], logAmp=False)
    # loop_frames(static_psf[2], logAmp=False)
    # loop_frames(static_psf[3], logAmp=False)
    # quicklook_im(static_psf[4], logAmp=False)
    # loop_frames(static_psf[1], logAmp=False)
    # static_psf = static_psf[1]#[112:369,112:369]
    # dprint(static_psf.shape)
    # # quicklook_im(static_psf)
    #
    # import scipy.ndimage
    #
    # static_cube = np.zeros((tp.nwsamp, mp.array_size[0], mp.array_size[1]))
    #
    # ref_vals = np.max(np.mean(diff_cube, axis=0), axis=(1, 2))
    # # loop_frames(simple_hypercube[:,0], logAmp=False)
    # # loop_frames(np.mean(simple_hypercube,axis=0), logAmp=False)
    #
    #
    #
    # for iw, scale in enumerate(scale_list):
    #     static_psf[iw] = scipy.ndimage.zoom(static_psf[iw], float(diff_cube.shape[-1]) / static_psf.shape[-1], order=0)
    #     dprint(static_psf.shape)
    #     loop_frames(static_psf)
    #     print scale
    #     print static_cube[iw].shape, static_psf.shape
    #     static_cube[iw] = clipped_zoom(static_psf[iw], scale)
    #     print static_cube[iw].shape
    #     # static_cube[iw] = np.roll(np.roll(static_cube[iw],-1,0),-1,1)
    #     # quicklook_im(np.mean(simple_hypercube,axis=0)[iw], logAmp=False)
    #     quicklook_im(static_cube[iw], logAmp=False)
    #
    #
    #
    #     # quicklook_im(static_cube[iw], logAmp=False)
    #     # quicklook_im(np.mean(simple_hypercube,axis=0)[iw] - static_cube[iw], logAmp=False)
    #     static_cube[iw] = Analysis.stats.centroid_ref(np.mean(diff_cube, axis=0)[iw], static_cube[iw])
    #     static_cube[iw] *= ref_vals[iw] / np.max(static_cube[iw])
    #     # quicklook_im(static_cube[iw], logAmp=False)
    # # static_cube = np.asarray(static_cube)
    #
    # dprint(ref_vals)
    # # loop_frames(static_cube)
    # # algo_dict = {'DSI_starphot': DSI_starphot, 'thresh': 1e-5}
    # algo_dict = {'thresh': 0}  # 1e-5}
    # # method_out = eval_method(simple_hypercube[:,0], Analysis.stats.DSI_4_VIP,angle_list, algo_dict)
    # # static_psf = np.mean(simple_hypercube,axis=0)#/len(simple_hypercube)
    # # print static_psf.shape
    # # static_psf = np.resize(static_psf,(50,8,129,129))
    # # print static_psf.shape, simple_hypercube.shape
    #
    # # loop_frames(static_psf[0,:], logAmp=False)
    # # loop_frames(simple_hypercube[0], logAmp=False)
    # # loop_frames(simple_hypercube[:,0], logAmp=False)
    # static_cube = np.resize(static_cube, (ap.numframes-2, tp.nwsamp, mp.array_size[0], mp.array_size[1]))
    # diff_cube -= static_cube
    # loop_frames(np.mean(diff_cube,axis=0), logAmp=False)
    # quicklook_im(np.mean(diff_cube,axis=(0,1)), logAmp=False)


