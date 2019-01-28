'''This code handles the relevant functionality of a Hawaii 2RG camera'''
import sys
sys.path.append('D:/dodkins/MEDIS/MEDIS')
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

# Global params
sp.save_obs = False
sp.show_cube = False
sp.save_obs = False
sp.show_wframe = False
ap.companion = True
ap.contrast = [1e-4,1e-4]#[0.1,0.1]
ap.star_photons = 1e10
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
mp.date = '180416mkids/'
cp.date = '1804171hr8m/'
import os
cp.atmosdir= os.path.join(cp.rootdir,cp.data,cp.date)
iop.update(mp.date)
sp.num_processes = 48
# tp.occulter_type = '8th_Order'
tp.occulter_type = 'Vortex'
# num_exp = 2000#500#1000#50#50#1000
# ap.exposure_time = 0.001  # 0.001
# cp.frame_time = 0.001
num_exp = 300#500#1000#50#50#1000
ap.exposure_time = 0.01  # 0.001
cp.frame_time = 0.01
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
    psf_template = Analysis.phot.get_unoccult_psf(hyperFile='/IntHyperUnOccult.pkl', plot=False)
    # star_phot = np.sum(psf_template)
    star_phot = phot.contrcurve.aperture_flux(psf_template,[64],[64],lod,1)[0]/ap.numframes
    psf_template = psf_template[:-1,:-1]

    # RDI (for SDI)
    ap.companion = True
    ap.contrast = [1e-5, 1e-6]  # [0.1,0.1]
    ap.lods = [[-2.5, 2.5], [-4.5, 4.5]]
    tp.detector =  'MKIDs'  #'ideal'#
    # iop.hyperFile = iop.datadir + 'far_out1MKIDs7_w6_.pkl'  # 5
    iop.hyperFile = iop.datadir + 'MEC_tar_500_highcount.pkl'  # 5
    # iop.hyperFile = iop.datadir + 'noWnoRollHyperWcomp1000cont_Aug_1stMKIDs2.pkl'#5
    simple_hypercube_1 = read.get_integ_hypercube(plot=False)#/ap.numframes

    ap.startframe = ap.numframes
    ap.companion =False
    # iop.hyperFile = iop.datadir + 'far_out2MKIDs7_w6_.pkl'  # 5
    iop.hyperFile = iop.datadir + 'MEC_ref_500_highcount.pkl'  # 5
    # iop.hyperFile = iop.datadir + 'noWnoRollHyperWcomp1000cont_Aug_2ndMKIDs2.pkl'#5
    simple_hypercube_2 = read.get_integ_hypercube(plot=False)#/ap.numframes

    # loop_frames(simple_hypercube_1[::10,0], logAmp=True)
    # loop_frames(simple_hypercube_2[:,0], logAmp=True)
    diff_cube = simple_hypercube_1-simple_hypercube_2
    # loop_frames(diff_cube[:,0], logAmp=False)
    # quicklook_im(np.mean(diff_cube[:,0],axis=0), logAmp=False)
    # quicklook_im(np.mean(diff_cube[:, 0], axis=0), logAmp=True)
    # quicklook_im(np.median(diff_cube[:, 0], axis=0), logAmp=True)
    #
    LCcube = np.transpose(diff_cube, (2, 3, 0, 1))[:,:,:,:1]
    dprint(LCcube.shape)
    algo_dict = {'thresh': 0}
    Dmaps, Dmap = Analysis.stats.get_Dmap(LCcube, algo_dict['thresh'], verb_output=True, plot=False, binning=10)
    # DSI
    # # grid([Dmaps[0], Dmaps[1], Dmaps[2], Dmaps[3], Dmap, np.mean(diff_cube,axis=(0,1))],
    # #              annos= ['0.01s Exp.', '0.01s Dark', '0.1s Dark', '2s Dark', '2s Light', '2s Exp.'],
    # #              vmins=[1,0.1,1,10,0.01,0.001], vmaxs=[100,1,10,100, 0.5,10], logAmp=True)


    # grid([Dmaps[0], Dmaps[1], Dmaps[2], Dmaps[3], Dmap, np.mean(diff_cube,axis=(0,1))],
    #              annos= ['0.1s Exp.', '0.1s Dark', '1s Dark', '3s Dark', '3s DSI', '3s Exp.'],
    #              vmins=[1,0.1,0.1,0.1,0.01,0.01], vmaxs=[1000,10,10,10, 100,100], logAmp=True)



    wsamples = np.linspace(tp.band[0], tp.band[1], tp.w_bins)
    scale_list = tp.band[0] / wsamples


    datacube = np.mean(diff_cube, axis=0) / ap.exposure_time
    # dprint(datacube.shape)
    # loop_frames(datacube)

    SDI = pca.pca(datacube, angle_list=np.zeros((len(diff_cube[0]))), scale_list=scale_list,
                  mask_center_px=None)

    LCcube = np.transpose(diff_cube, (2, 3, 0, 1))
    algo_dict = {'thresh': 0}
    # Lmap = Analysis.stats.get_Dmap(LCcube, algo_dict['thresh'], plot=False, binning=1)
    # Lmap = Analysis.stats.get_Dmap(LCcube, algo_dict['thresh'], plot=False, binning=2)
    # Lmap = Analysis.stats.get_Dmap(LCcube, algo_dict['thresh'], plot=False, binning=5)
    Lmap = Analysis.stats.get_Dmap(LCcube, algo_dict['thresh'], plot=False, binning=50)
    # Lmap = Analysis.stats.get_Dmap(LCcube, algo_dict['thresh'], plot=False, binning=20)
    # rmap = Analysis.stats.get_skew(LCcube)
    BBmap = Analysis.stats.get_LmapBB(LCcube, binning=50, plot=False)

    # phot.snr.snrmap(Lmap, lod, plot=True)
    # phot.snr.snrmap(SDI, lod, plot=True)
    # phot.snr.snrmap(rmap, lod, plot=True)
    #
    # quicklook_im(Lmap, show=False)
    # quicklook_im(SDI, show=False)
    # quicklook_im(rmap)

    # quicklook_im(np.mean(datacube, axis= 0), logAmp=True)
    # quicklook_im(SDI, logAmp=True)
    # quicklook_im(Lmap, logAmp=True)
    cube = []



    tar_SDI = pca.pca(np.mean(simple_hypercube_1, axis=0) / ap.exposure_time, angle_list=np.zeros((len(diff_cube[0]))), scale_list=scale_list,
                  mask_center_px=None)

    ref_SDI = pca.pca(np.mean(simple_hypercube_2, axis=0) / ap.exposure_time, angle_list=np.zeros((len(diff_cube[0]))), scale_list=scale_list,
                  mask_center_px=None)

    # quicklook_im(tar_SDI, logAmp=True)
    # quicklook_im(ref_SDI, logAmp=True)
    # quicklook_im(tar_SDI-ref_SDI, logAmp=True)
    cube.append(Lmap)
    cube.append(BBmap)
    cube.append(SDI)
    # cube.append(tar_SDI-ref_SDI)

    indep_images(cube, logAmp=True, vmins =[0.01,1,10], vmaxs=[6,6,1e3], annos=['BB DSI', 'BB Sim DSI', 'SDI'], titles=['$I_\mathrm{L}$','$I_\mathrm{L}$','$I$'])


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
    static_cube = np.zeros((tp.nwsamp,mp.array_size[0],mp.array_size[1]))
    ref_vals = np.max(np.mean(simple_hypercube,axis=0),axis=(1,2))
    # loop_frames(simple_hypercube[:,0], logAmp=False)
    # loop_frames(np.mean(simple_hypercube,axis=0), logAmp=False)

    def _scale_func(output_coords, ref_xy=0, scaling=1.0,
                    scale_y=None, scale_x=None):
        """
        For each coordinate point in a new scaled image (output_coords),
        coordinates in the image before the scaling are returned. This scaling
        function is used within geometric_transform which, for each point in the
        output image, will compute the (spline) interpolated value at the
        corresponding frame coordinates before the scaling.
        """
        ref_x, ref_y = ref_xy
        if scale_y is None:
            scale_y = scaling
        if scale_x is None:
            scale_x = scaling
        return (ref_y + ((output_coords[0] - ref_y) / scale_y),
                ref_x + ((output_coords[1] - ref_x) / scale_x))


    from scipy.ndimage.interpolation import geometric_transform, zoom
    import cv2

    def centroid_ref(target, ref, zoom_test=True):
        # https://stackoverflow.com/questions/29954153/finding-the-maximum-of-a-curve-scipy

        zooms = np.linspace(0.9, 1.1, 7)
        xs = np.linspace(-30, 30, 15)
        ys = np.linspace(-30, 30, 15)
        scores = np.zeros((len(zooms), len(xs), len(ys)))
        frame_center = np.array([ref.shape[0]/2. - 0.5, ref.shape[1]/2. - 0.5])
        # print frame_center, frame_center+[0,0]
        for iz, z in enumerate(zooms):
            # zoom = clipped_zoom(ref, z)
            # print np.sum(zoom)
            # quicklook_im(shift, logAmp=False)
            for ix, x in enumerate(xs):
                for iy, y in enumerate(ys):
                    # shift = np.roll(np.roll(ref, x, 0), y, 1)
                    # quicklook_im(ref, logAmp=False)
                    M = np.array([[z, 0, (1. - z) * (frame_center[0]+x)],
                                  [0, z, (1. - z) * (frame_center[1]+y)]])

                    intp = cv2.INTER_LANCZOS4
                    trans = cv2.warpAffine(ref.astype(np.float32), M, ref.shape,
                                               flags=intp)
                    # trans = geometric_transform(ref, _scale_func, order=0,
                    #                                 output_shape=ref.shape,
                    #                                 prefilter=False,
                    #                                 extra_keywords={'ref_xy': frame_center + np.array([x,y]),
                    #                                                 'scaling': z,
                    #                                                 'scale_y': z,
                    #                                                 'scale_x': z})
                    trans = trans*np.max(ref)/np.max(trans)
                    # shift = np.roll(np.roll(zoom,x,0),y,1)
                    # quicklook_im(target, logAmp=False)
                    # quicklook_im(trans, logAmp=False)
                    # print z, x, y, np.max(np.abs(target - trans))
                    scores[iz,ix,iy] = np.max(np.abs(target - trans))
                    # print np.sum(trans), np.max(trans)
                    # quicklook_im(np.abs(target - trans), logAmp=False, vmin=0, vmax=0.2)
            # print scores[iz]
            # swin  = np.unravel_index(scores[iz].argmin(), scores[iz].shape)
            # print swin
            # shift = np.roll(np.roll(zoom,xs[swin[0]],0),ys[swin[1]],1)
            # quicklook_im(target - trans, logAmp=False, vmin=-0.25, vmax=0.25)
            # zooms[iz] = np.sum(np.abs(target - shift))
        # print zooms
        # zwin = np.unravel_index(zooms.argmin(), zooms.shape)
        # print zwin
        # shift
        win = np.unravel_index(scores.argmin(), scores.shape)
        # print scores, win, scores[win]
        # zoom = clipped_zoom(ref, zooms[win[0]])
        # shift = np.roll(np.roll(zoom,xs[win[1]],0),ys[win[2]],1)
        M = np.array([[zooms[win[0]], 0, (1. - zooms[win[0]]) * (frame_center[0] + xs[win[1]])],
                      [0, zooms[win[0]], (1. - zooms[win[0]]) * (frame_center[1] + ys[win[2]])]])

        intp = cv2.INTER_LANCZOS4
        ref = cv2.warpAffine(ref.astype(np.float32), M, ref.shape,
                               flags=intp)
        # ref = geometric_transform(ref, _scale_func, order=0,
        #                             output_shape=ref.shape,
        #                             extra_keywords={'ref_xy': frame_center + (win[1],win[2]),
        #                                             'scaling': zooms[win[0]],
        #                                             'scale_y': zooms[win[0]],
        #                                             'scale_x': zooms[win[0]]})
        # quicklook_im(target - ref, logAmp=False,vmin=-0.2, vmax=0.2)
        # ref = shift

        # if zoom_test:
        #     shift = ref
        #     zooms = np.zeros((5))
        #     for iz, zoom in enumerate(np.linspace(0.95,1.05,5)):
        #         shift = clipped_zoom(ref,zoom)
        #         quicklook_im(target, logAmp=False)
        #         quicklook_im(shift, logAmp=False)
        #         print iz, zoom, np.sum(np.abs(target - shift))
        #         zooms[iz] =np.sum(np.abs(target - shift))
        #         quicklook_im(target - shift, logAmp=False)
        #     print zooms
        #     win = np.unravel_index(zooms.argmin(), zooms.shape)
        #     print win
        #     ref = clipped_zoom(ref, zooms[win])
        #     quicklook_im(target - ref, logAmp=False)
        return ref

    for iw,scale in enumerate(scale_list):
        print scale
        static_cube[iw] = clipped_zoom(static_psf,scale)
        # static_cube[iw] = np.roll(np.roll(static_cube[iw],-1,0),-1,1)
        # quicklook_im(np.mean(simple_hypercube,axis=0)[iw], logAmp=False)
        # quicklook_im(static_cube[iw], logAmp=False)



        # quicklook_im(static_cube[iw], logAmp=False)
        # quicklook_im(np.mean(simple_hypercube,axis=0)[iw] - static_cube[iw], logAmp=False)
        static_cube[iw] = centroid_ref(np.mean(simple_hypercube,axis=0)[iw], static_cube[iw])
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

