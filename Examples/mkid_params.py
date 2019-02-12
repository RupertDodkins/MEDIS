'''This code handles the relevant functionality of a Hawaii 2RG camera'''
import sys
sys.path.append('D:/dodkins/MEDIS/MEDIS')
import numpy as np
import matplotlib.pyplot as plt
from vip_hci import phot, pca
from medis.params import ap, cp, tp, sp, mp, iop
from medis.Utils.plot_tools import loop_frames, quicklook_im,view_datacube, compare_images, indep_images
import medis.Detector.readout as read
import medis.Analysis.phot
import medis.Analysis.stats
from medis.Utils.misc import dprint

# Global params
sp.save_obs = False
sp.show_cube = False
sp.save_obs = False
sp.return_cube = True
sp.show_wframe = False
sp.num_processes = 45
tp.diam = 5.0  # telescope diameter in meters
ap.companion = False
ap.contrast = [1e-4]#[0.1,0.1]
ap.lods = [[-2.5,2.5]]
tp.use_spiders = True
tp.use_ao = True
tp.ao_act = 50
tp.diam = 8.
tp.detector = 'MKIDs'
# cp.date = '180630_30mins/'
# import os
# iop.atmosdir= os.path.join(cp.rootdir,cp.data,cp.date)
# cp.frame_time = 0.005
cp.frame_time = 0.001
# ap.star_photons*=1000
mp.R_mean = 20
mp.phase_uncertainty = True
# tp.NCPA_type = None#'Static'
# tp.CPA_type = None#'Static'
tp.NCPA_type = 'Static'
tp.CPA_type = 'Static'
mp.date = '180628testingMKIDs/'
iop.update(mp.date)
tp.occulter_type = 'Gaussian'
num_exp = 1000
ap.exposure_time = 0.001  # 0.005
ap.numframes = int(num_exp * ap.exposure_time / cp.frame_time)
tp.piston_error = False
xlocs = range(0, 128)  # range(0,128)#65
ylocs = range(0, 128)  # range(0,128)#85
tp.band = np.array([860, 1250])
# tp.nwsamp = 1
tp.rot_rate = 0  # deg/s
theta=45
lod = 8
mp.pix_yield=1.

def eval_method(cube, algo, angle_list, algo_dict):
    fulloutput = phot.contrcurve.contrast_curve(cube=cube,
                                   angle_list=angle_list, psf_template=psf_template,
                                   fwhm=lod, pxscale=tp.platescale/1000,
                                   starphot=star_phot, algo=algo,
                                   debug=False, plot=False, theta=theta,full_output=True,fc_snr=10, **algo_dict)
    plt.show()
    metrics = [fulloutput[0]['throughput'], fulloutput[0]['noise'], fulloutput[0]['sensitivity (Student)']]
    metrics = np.array(metrics)
    return metrics, fulloutput[3]

def interp_image(image):
    nan = np.nan
    # quicklook_im(image, logAmp=False)
    image[image == 0] = nan
    # quicklook_im(image, logAmp=False)
    ok = -np.isnan(image)
    xp = ok.ravel().nonzero()[0]
    fp = image[-np.isnan(image)]
    x = np.isnan(image).ravel().nonzero()[0]

    image[np.isnan(image)] = np.interp(x, xp, fp)

    # quicklook_im(image)

    return image

plotdata, maps, thrus, noises, conts = [], [], [], [], []
if __name__ == '__main__':
    #
    #

    rad_samp = np.linspace(0,tp.platescale/1000.*40,40)
    print rad_samp
    # Get unocculted PSF for intensity
    # psf_template = Analysis.phot.get_unoccult_psf(hyperFile='/IntHyperUnOccult2.pkl', plot=False)
    psf_template = Analysis.phot.get_unoccult_psf(hyperFile='/IntHyperUnOccult.h5', plot=False)
    # star_phot = np.sum(psf_template)
    star_phot = phot.contrcurve.aperture_flux(psf_template,[64],[64],lod,1)[0]#/1000.
    psf_template = psf_template[:-1,:-1]
    dprint(star_phot)
    # quicklook_im(psf_template)


    # # SDI
    # tp.rot_rate = 0  # deg/s
    # tp.nwsamp = 16
    # # for R in np.linspace(1,51,6):
    # # Rs = np.logspace(0,1.7,7)
    # Rs = np.logspace(0, 1.7, 3)
    # # Rs = [1,5,20]
    # for R in np.round(Rs):
    # # for R in [51]:
    #     mp.R_mean = R
    #     iop.hyperFile = iop.datadir + '/SDIHyper_C1e5_R%i_16w_1.pkl' % R
    #     iop.device_params = iop.datadir + '/deviceParams_R%i_16w_1.pkl' % R
    #     wsamples = np.linspace(tp.band[0], tp.band[1], tp.nwsamp)
    #     scale_list = tp.band[0] / wsamples
    #     print tp.nwsamp
    #     SDI_hypercube = read.get_integ_hypercube(plot=False)
    #     print SDI_hypercube.shape
    #     ap.exposure_time = 1.#0.1#1.
    #     datacube = read.take_exposure(SDI_hypercube)/ap.numframes
    #     # view_datacube(datacube[0])
    #     # datacube = read.med_collapse(SDI_hypercube)
    #     print datacube.shape
    #     # loop_frames(SDI_hypercube[0])
    #     # loop_frames(SDI_hypercube[:,0])
    #     # loop_frames(datacube[0], logAmp=False)
    #     print datacube.shape
    #     # view_datacube(datacube[0], logAmp=False)
    #     ap.exposure_time = 0.001
    #     # loop_frames(datacube[0])
    #     algo_dict = {'scale_list': scale_list[::-1]}
    #     # star_phots = star_phot
    #
    #     angle_list = np.zeros((len(SDI_hypercube[0])))
    #     method_out = eval_method(datacube[0], pca.pca, angle_list, algo_dict)
    #     plotdata.append(method_out[0])
    #     maps.append(method_out[1])
    #     # quicklook_im(method_out[1])
    #
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
    # axes[2].legend(Rs)
    #
    # maps = np.array(maps)
    # compare_images(maps, logAmp=False, scale=1e6)#[[0,1,-1]]
    # plt.show()
    #
    # plt.plot(Rs, plotdata[:,2,16])
    # plt.show()

    # # ***** Energy Resolution *****
    #
    # # SDI
    # tp.rot_rate = 0  # deg/s
    # tp.nwsamp = 5
    # # for R in np.linspace(1,51,6):
    # # Rs = np.logspace(0,1.7,7)
    # Rs = np.logspace(0, 1.7, 3)
    # # Rs = [50]
    # # Rs = [1,5,20]
    #
    # for R in np.round(Rs):
    # # for R in [51]:
    #     mp.R_mean = R
    #     iop.hyperFile = iop.datadir + '/SDIHyper_C1e5_R%i_5w_5.h5' % R
    #     iop.device_params = iop.datadir + '/deviceParams_R%i_5w_5.pkl' % R
    #     wsamples = np.linspace(tp.band[0], tp.band[1], tp.nwsamp)
    #     scale_list = tp.band[0] / wsamples
    #     # print tp.nwsamp
    #     SDI_hypercube = read.get_integ_hypercube(plot=False)
    #     # print SDI_hypercube.shape
    #     noncor_frames = np.zeros((10,128,128))
    #     thruputs = np.zeros((10, 41))
    #     for t in range(10):
    #         ap.exposure_time = 0.1#1.
    #         datacube = read.take_exposure(SDI_hypercube[t*100:(t+1)*100])/(ap.numframes/10)
    #         # view_datacube(datacube[0])
    #         # datacube = read.med_collapse(SDI_hypercube)
    #         # dprint(datacube.shape)
    #         # loop_frames(SDI_hypercube[0])
    #         # loop_frames(SDI_hypercube[:,0])
    #         # loop_frames(datacube[0], logAmp=False)
    #         # view_datacube(datacube[0], logAmp=False)
    #         # ap.exposure_time = 0.005
    #         ap.exposure_time = 0.001
    #         # loop_frames(datacube[0])
    #         algo_dict = {'scale_list': scale_list[::-1]}
    #         # star_phots = star_phot
    #
    #         angle_list = np.zeros((len(SDI_hypercube[0])))
    #         method_out = eval_method(datacube[0], pca.pca, angle_list, algo_dict)
    #         dprint(method_out[0].shape)
    #         thruputs[t] = method_out[0][0]
    #         noncor_frames[t] = method_out[1]
    #     # compare_images(noncor_frames, logAmp=True, scale=1e4)
    #     # maps.append(np.sum(noncor_frames,axis=0)/10)
    #     angle_list = np.zeros((len(noncor_frames)))
    #     method_out = eval_method(noncor_frames, Analysis.stats.time_collapse, angle_list, {})
    #     plotdata.append(method_out[0])
    #     maps.append(method_out[1])
    #     thrus.append(np.mean(thruputs, axis=0))
    #     quicklook_im(method_out[1])
    #
    #     # plt.imshow(np.sum(noncor_frames,axis=0)/10)
    #     # plt.show()
    #
    # # maps = np.array(maps)
    # # print maps.shape
    # # compare_images(maps, logAmp=False, scale=1e1)#[[0,1,-1]]
    # # plt.show()
    # # Plotting
    # plotdata = np.array(plotdata)
    # rad_samp = np.linspace(0,tp.platescale/1000.*plotdata.shape[2],plotdata.shape[2])
    # fig, axes = plt.subplots(nrows=1, ncols=3, figsize=(14, 3.4))
    # plotdata[:, 2] /= thrus
    # # for thruput in plotdata[:,0]:
    # for thruput in thrus:
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
    # axes[2].legend(Rs)
    #
    # maps = np.array(maps)
    # compare_images(maps, logAmp=True, scale=1e1)#[[0,1,-1]]
    # plt.show()
    #
    # plt.plot(Rs, plotdata[:,2,16])
    # plt.show()

    # ***** Energy Resolution stdev *****

    # SDI
    tp.rot_rate = 0  # deg/s
    tp.nwsamp = 5
    # for R in np.linspace(1,51,6):
    # Rs = np.logspace(0,1.7,7)
    # Rs = np.logspace(0, 1.7, 3)
    # Rs = [50]
    # Rs = [1,5,20]
    R_sigs = [0.1,2,5]

    for R in np.round(R_sigs):
    # for R in [51]:
        mp.R_sig = R
        iop.hyperFile = iop.datadir + '/SDIHyper_C1e5_Rsig%i_5w_5.h5' % R
        iop.device_params = iop.datadir + '/deviceParams_Rsig%i_5w_5.pkl' % R
        wsamples = np.linspace(tp.band[0], tp.band[1], tp.nwsamp)
        scale_list = tp.band[0] / wsamples
        # print tp.nwsamp
        SDI_hypercube = read.get_integ_hypercube(plot=False)
        # print SDI_hypercube.shape
        noncor_frames = np.zeros((10,128,128))
        thruputs = np.zeros((10, 41))
        for t in range(10):
            ap.exposure_time = 0.1#1.
            datacube = read.take_exposure(SDI_hypercube[t*100:(t+1)*100])/(ap.numframes/10)
            # view_datacube(datacube[0])
            # datacube = read.med_collapse(SDI_hypercube)
            # dprint(datacube.shape)
            # loop_frames(SDI_hypercube[0])
            # loop_frames(SDI_hypercube[:,0])
            # loop_frames(datacube[0], logAmp=False)
            # view_datacube(datacube[0], logAmp=False)
            # ap.exposure_time = 0.005
            ap.exposure_time = 0.001
            # loop_frames(datacube[0])
            algo_dict = {'scale_list': scale_list[::-1]}
            # star_phots = star_phot

            angle_list = np.zeros((len(SDI_hypercube[0])))
            method_out = eval_method(datacube[0], pca.pca, angle_list, algo_dict)
            dprint(method_out[0].shape)
            thruputs[t] = method_out[0][0]
            noncor_frames[t] = method_out[1]
        # compare_images(noncor_frames, logAmp=True, scale=1e4)
        # maps.append(np.sum(noncor_frames,axis=0)/10)
        angle_list = np.zeros((len(noncor_frames)))
        method_out = eval_method(noncor_frames, Analysis.stats.time_collapse, angle_list, {})
        plotdata.append(method_out[0])
        maps.append(method_out[1])
        thrus.append(np.mean(thruputs, axis=0))
        quicklook_im(method_out[1])

        # plt.imshow(np.sum(noncor_frames,axis=0)/10)
        # plt.show()

    # maps = np.array(maps)
    # print maps.shape
    # compare_images(maps, logAmp=False, scale=1e1)#[[0,1,-1]]
    # plt.show()
    # Plotting
    plotdata = np.array(plotdata)
    rad_samp = np.linspace(0,tp.platescale/1000.*plotdata.shape[2],plotdata.shape[2])
    fig, axes = plt.subplots(nrows=1, ncols=3, figsize=(14, 3.4))
    plotdata[:, 2] /= thrus
    # for thruput in plotdata[:,0]:
    for thruput in thrus:
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
    axes[2].legend(R_sigs)

    maps = np.array(maps)
    compare_images(maps, logAmp=True, scale=1e1)#[[0,1,-1]]
    plt.show()

    plt.plot(R_sigs, plotdata[:,2,16])
    plt.show()

    # # ***** pixel yield *****
    #
    # import copy
    # orig_psf_template = copy.deepcopy(psf_template)
    # # yields = np.logspace(0, 1.7, 3)
    # # Rs = [50]
    # yields = [0.8,0.9,0.95,0.99,0.999]#[0.05,0.2,0.4,0.8,0.995]#[0.99995,0.4]#0.4,0.8,
    # mp.R_mean = 50
    #
    # import medis.Detector
    # dp = Detector.MKIDs.initialize()
    # mp.bad_pix = True
    # bad_map = np.ones((tp.grid_size-1, tp.grid_size-1))
    # bad_map[dp.response_map[1:-1,1:-1]==0]=0
    # tp.nwsamp = 5
    # for py in yields:
    #     if py == 1:
    #         mp.bad_pix = False
    # # for R in [51]:
    # #     psf_template = orig_psf_template*bad_map
    # #     quicklook_im(psf_template)
    #     mp.pix_yield = py
    #     iop.hyperFile = iop.datadir + '/SDIHyper_%f.h5' % py
    #     iop.device_params = iop.datadir + '/deviceParams_%f.pkl' % py
    #     wsamples = np.linspace(tp.band[0], tp.band[1], tp.nwsamp)
    #     scale_list = tp.band[0] / wsamples
    #     dprint((py,scale_list,wsamples))
    #     # print tp.nwsamp
    #     dprint(mp.pix_yield)
    #     SDI_hypercube = read.get_integ_hypercube(plot=False)
    #     # print SDI_hypercube.shape
    #     # loop_frames(SDI_hypercube[:,0])
    #     noncor_frames = np.zeros((10,128,128))
    #     thruputs = np.zeros((10, 41))
    #     # for t in range(10):
    #     ap.exposure_time = 1#1.
    #     # print SDI_hypercube.shape
    #     dprint(ap.numframes)
    #     datacube = read.take_exposure(SDI_hypercube)/ap.numframes
    #     # loop_frames(datacube[0])
    #     print datacube.shape
    #     #     # SDI_hypercube[t][SDI_hypercube[t]==0] = np.nan
    #     #     # loop_frames(SDI_hypercube[t])
    #     #     # view_datacube(datacube[0])
    #     #     # datacube = read.med_collapse(SDI_hypercube)
    #     #     # dprint(datacube.shape)
    #     #     # loop_frames(SDI_hypercube[0])
    #     #     # loop_frames(SDI_hypercube[:,0])
    #     #     # loop_frames(datacube[0], logAmp=False)
    #     #     # view_datacube(datacube[0], logAmp=False)
    #     #     # ap.exposure_time = 0.005
    #     #     ap.exposure_time = 0.001
    #     #     # loop_frames(datacube[0])
    #     algo_dict = {'scale_list': scale_list[::-1]}
    #         # star_phots = star_phot
    #
    #     angle_list = np.zeros((len(SDI_hypercube[0])))
    #     method_out = eval_method(datacube[0], pca.pca, angle_list, algo_dict)
    #     # dprint(method_out[0].shape)
    #     # method_out[1] = interp_image(method_out[1])
    #     # thruputs[t] = method_out[0][0]
    #     # noncor_frames[t] = method_out[1]#interp_image(method_out[1])
    #     # noncor_frames[t] = interp_image(method_out[1])
    #     # noncor_frames[t][noncor_frames[t]==0] = np.nan
    #     # compare_images(noncor_frames, logAmp=True, scale=1e4)
    #     # maps.append(np.sum(noncor_frames,axis=0)/10)
    #     angle_list = np.zeros((len(noncor_frames)))
    #     # method_out = eval_method(noncor_frames, Analysis.stats.time_collapse, angle_list, {})
    #     dprint(method_out[0].shape)
    #     print method_out[0]
    #     plotdata.append(method_out[0])
    #     maps.append(method_out[1])
    #     thrus.append(np.mean(thruputs, axis=0))
    #     # quicklook_im(method_out[1], logAmp=True)
    #     # dprint(np.shape(plotdata))
    #
    #
    #     # plt.imshow(np.sum(noncor_frames,axis=0)/10)
    #     # plt.show()
    #
    # # maps = np.array(maps)
    # # print maps.shape
    # # compare_images(maps, logAmp=False, scale=1e1)#[[0,1,-1]]
    # # plt.show()
    # # Plotting
    # plotdata = np.array(plotdata)
    # rad_samp = np.linspace(0,tp.platescale/1000.*plotdata.shape[2],plotdata.shape[2])
    # fig, axes = plt.subplots(nrows=1, ncols=3, figsize=(14, 3.4))
    # # plotdata[:, 2] /= thrus
    # for thruput in plotdata[:,0]:
    # # for thruput in thrus:
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
    # axes[2].legend(yields)
    #
    # maps = np.array(maps)
    # compare_images(maps, logAmp=True, scale=1e1)#[[0,1,-1]]
    # plt.show()
    #
    # plt.plot(yields, plotdata[:,2,16])
    # plt.show()

    # # ***** pixel format *****
    #
    # # yields = np.logspace(0, 1.7, 3)
    # # Rs = [50]
    # formats = [128,256,512,1024]#[0.05,0.2,0.4,0.8,0.995]#[0.99995,0.4]#0.4,0.8,
    # mp.R_mean = 50
    # mp.bad_pix = False
    #
    # rad_samps = []
    # import medis.Detector
    # dp = Detector.MKIDs.initialize()
    # bad_map = np.ones((tp.grid_size-1, tp.grid_size-1))
    # bad_map[dp.response_map[1:-1,1:-1]==0]=0
    # tp.nwsamp = 5
    #
    # import cPickle as pickle
    # import os
    # SDI_reduced = 'SDI_images.pkl'
    # if os.path.isfile(SDI_reduced):
    #     with open(SDI_reduced, 'rb') as handle:
    #         (maps, thrus, noises, conts) =pickle.load(handle)
    #     # for f, format in enumerate(formats):
    #     #     rad_samps.append(np.linspace(0, tp.platescale / 1000. * formats[0] / format, format/2.))
    #     #     print rad_samps, len(rad_samps)
    # else:
    #     for f, format in enumerate(formats):
    #     # for R in [51]:
    #     #     psf_template = orig_psf_template*bad_map
    #     #     quicklook_im(psf_template)
    #         format += 1
    #         mp.array_size = [format,format]
    #         mp.res_elements= format
    #         mp.xnum = format
    #         mp.ynum = format
    #         mp.total_pix = format**2
    #         tp.grid_size = format - 1
    #         tp.beam_ratio *= 128./format
    #         rad_samp = np.linspace(0,tp.platescale/1000.*40,40)
    #         print rad_samp
    #         # Get unocculted PSF for intensity
    #         # psf_template = Analysis.phot.get_unoccult_psf(hyperFile='/IntHyperUnOccult2.pkl', plot=False)
    #         iop.device_params = iop.datadir + '/deviceParams_UnOccult_%f.pkl' % format
    #         psf_template = Analysis.phot.get_unoccult_psf(hyperFile='/IntHyperUnOccult_%f.h5' % format, plot=False)
    #         # quicklook_im(psf_template)
    #         # star_phot = np.sum(psf_template)
    #         star_phot = phot.contrcurve.aperture_flux(psf_template,[mp.xnum/2],[mp.ynum/2],lod*format/formats[0],1)[0]#/1000.
    #         if psf_template.shape[0] % 2 == 0:
    #             psf_template = psf_template[:-1,:-1]
    #         dprint((star_phot,lod*format/formats[0]))
    #
    #         iop.hyperFile = iop.datadir + '/SDIHyper_%f.h5' % format
    #         iop.device_params = iop.datadir + '/deviceParams_%f.pkl' % format
    #         wsamples = np.linspace(tp.band[0], tp.band[1], tp.nwsamp)
    #         scale_list = tp.band[0] / wsamples
    #         dprint((format,scale_list,wsamples))
    #         # print tp.nwsamp
    #         dprint(mp.pix_yield)
    #         SDI_hypercube = read.get_integ_hypercube(plot=False)
    #         print SDI_hypercube.shape
    #         # loop_frames(SDI_hypercube[:,0])
    #         # noncor_frames = np.zeros((10,128,128))
    #         # thruputs = np.zeros((10, 41))
    #         # for t in range(10):
    #         ap.exposure_time = 1#1.
    #         # print SDI_hypercube.shape
    #         dprint(ap.numframes)
    #         datacube = read.take_exposure(SDI_hypercube)/ap.numframes
    #
    #         # loop_frames(datacube[0])
    #         print datacube.shape
    #         #     # SDI_hypercube[t][SDI_hypercube[t]==0] = np.nan
    #         #     # loop_frames(SDI_hypercube[t])
    #         #     # view_datacube(datacube[0])
    #         #     # datacube = read.med_collapse(SDI_hypercube)
    #         #     # dprint(datacube.shape)
    #         #     # loop_frames(SDI_hypercube[0])
    #         #     # loop_frames(SDI_hypercube[:,0])
    #         #     # loop_frames(datacube[0], logAmp=False)
    #         #     # view_datacube(datacube[0], logAmp=False)
    #         #     # ap.exposure_time = 0.005
    #         ap.exposure_time = 0.001
    #         #     # loop_frames(datacube[0])
    #         algo_dict = {'scale_list': scale_list[::-1]}
    #             # star_phots = star_phot
    #
    #         angle_list = np.zeros((len(SDI_hypercube[0])))
    #         method_out = eval_method(datacube[0], pca.pca, angle_list, algo_dict)
    #         # dprint(method_out[0].shape)
    #         # method_out[1] = interp_image(method_out[1])
    #         # thruputs[t] = method_out[0][0]
    #         # noncor_frames[t] = method_out[1]#interp_image(method_out[1])
    #         # noncor_frames[t] = interp_image(method_out[1])
    #         # noncor_frames[t][noncor_frames[t]==0] = np.nan
    #         # compare_images(noncor_frames, logAmp=True, scale=1e4)
    #         # maps.append(np.sum(noncor_frames,axis=0)/10)
    #         # angle_list = np.zeros((len(noncor_frames)))
    #         # method_out = eval_method(noncor_frames, Analysis.stats.time_collapse, angle_list, {})
    #         dprint(method_out[0].shape)
    #         print method_out[0]
    #         # quicklook_im(method_out[1])
    #         thrus.append(method_out[0][0])
    #         noises.append(method_out[0][1])
    #         conts.append(method_out[0][2])
    #         maps.append(method_out[1])
    #         # thrus.append(np.mean(thruputs, axis=0))
    #         # quicklook_im(method_out[1], logAmp=True)
    #         # dprint(np.shape(plotdata))
    #         rad_samps.append(np.linspace(0, tp.platescale / 1000. * formats[0]/format, len(method_out[0][0])))
    #         dprint(tp.platescale / 1000. * len(method_out[0][0])*formats[0]/format)
    #         # plt.imshow(np.sum(noncor_frames,axis=0)/10)
    #         # plt.show()
    #
    #
    #     with open(SDI_reduced, 'wb') as handle:
    #         pickle.dump((maps, thrus, noises, conts), handle, protocol=pickle.HIGHEST_PROTOCOL)
    #
    # # maps = np.array(maps)
    # dprint(maps[0].shape)
    # for i in range(4):
    #     quicklook_im(maps[i], logAmp=True)
    # # dprint(maps[1].shape)
    # # compare_images(maps, logAmp=False, scale=1e1)#[[0,1,-1]]
    # # plt.show()
    # # Plotting
    # # plotdata = np.array(plotdata)
    # # rad_samps = np.linspace(0,tp.platescale/1000.*plotdata.shape[2],plotdata.shape[2])
    # fig, axes = plt.subplots(nrows=1, ncols=3, figsize=(14, 3.4))
    # # plotdata[:, 2] /= thrus
    # print np.shape(axes), np.shape(thrus), np.shape(rad_samps)
    # for rs, thruput in enumerate(thrus):
    # # for thruput in thrus:
    #     axes[0].plot(np.linspace(0, tp.platescale / 1000., len(thruput)),thruput)
    # for rs, noise in enumerate(noises):
    #     axes[1].plot(np.linspace(0, tp.platescale / 1000., len(noise)),noise)
    # for rs, cont in enumerate(conts):
    #     axes[2].plot(np.linspace(0, tp.platescale / 1000., len(cont)),cont)
    # for ax in axes:
    #     ax.set_yscale('log')
    #     ax.set_xlabel('Radial Separation')
    #     ax.tick_params(direction='in',which='both', right=True, top=True)
    # axes[0].set_ylabel('Throughput')
    # axes[1].set_ylabel('Noise')
    # axes[2].set_ylabel('5$\sigma$ Contrast')
    # axes[2].legend(formats)
    #
    # # maps = np.array(maps)
    # print np.shape(maps)
    # compare_images(maps, logAmp=True, scale=1)#[[0,1,-1]]
    # plt.show()
    #
    # plt.plot(formats, plotdata[:,2,16])
    # plt.show()