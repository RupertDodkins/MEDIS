'''This code handles the relevant functionality of a Hawaii 2RG camera'''
import sys, os
sys.path.append('D:/dodkins/MEDIS/MEDIS')
import numpy as np
# import copy
import matplotlib.pyplot as plt
from vip_hci import phot, pca
from medis.params import ap, cp, tp, sp, mp, iop
from medis.Utils.plot_tools import loop_frames, quicklook_im,view_datacube, compare_images, indep_images
import medis.Utils.rawImageIO as rawImageIO
import medis.Telescope.adaptive_optics as ao
import medis.Detector.readout as read
import medis.Analysis.phot
# import medis.Analysis.stats
# import pandas as pd
from statsmodels.tsa.stattools import acf

# Global params
sp.save_obs = False
sp.show_cube = False
sp.save_obs = False
sp.return_cube = True
sp.show_wframe = False
ap.companion = True
ap.contrast = [1e-4,1e-2]#[0.1,0.1]
ap.lods = [[-2.5,2.5],[3.5,-3.5]]
tp.diam=8.
tp.use_spiders = True
tp.use_ao = False
tp.use_atmos = False
tp.ao_act = 25
tp.detector = 'ideal'
# ap.star_photons*=1000
# tp.NCPA_type = None#'Static'
# tp.CPA_type = None#'Static'
tp.NCPA_type = 'Quasi'#'Quasi'
tp.CPA_type = 'Static'
mp.date = '180507/'
iop.update(mp.date)
sp.num_processes = 45
tp.occulter_type = 'None'#'Gaussian'
num_exp =5000 #5000
ap.numframes = num_exp
# ap.exposure_time = 1  # 0.001
cp.frame_time = 0.1 # set in params
# ap.numframes = int(num_exp * ap.exposure_time / cp.frame_time)
tp.piston_error = True
xlocs = range(0, 128)  # range(0,128)#65
ylocs = range(0, 128)  # range(0,128)#85
tp.band = np.array([860, 1250])
tp.nwsamp = 1
tp.rot_rate = 0  # deg/s
theta=45
lod = 8

# cp.frame_time = 0.001
# ap.numframes = num_exp


plotdata, maps = [], []
if __name__ == '__main__':
    print(iop.aberdir)
    images=[]
    noises = []

    iop.aberdir = os.path.join(iop.rootdir, 'data/aberrations/longquasi3/')
    # ao.generate_maps()
    #
    #
    # for t in np.arange(0,5000,100):
    #     # atmos_map = iop.atmosdir + 'telz%f_%1.3f.fits' % (t * cp.frame_time, 0.2)
    #     abermap = iop.aberdir + 'telz%f.fits' % (t * cp.frame_time)
    #     print abermap
    #     image = rawImageIO.read_image(filename=abermap, prob_map=False)[0]
    #     # quicklook_im(image, logAmp=False)
    #     images.append(image)
    #     # quicklook_im(image-images[0], logAmp=False)
    #     noise, rrad = phot.noise_per_annulus(image-images[0], separation=1, fwhm=lod,
    #                                                       init_rad=lod, wedge=(0, 360))
    #     # plt.plot(rrad, noise)
    #     # plt.show()
    #     # print noise, np.shape(noise)
    #     residual = image - images[0]
    #     # noises.append([residual[70,70], residual[90,90], residual[110, 110]])
    #     noises.append([noise[21], noise[35], noise[50]])
    # noises = np.array(noises)
    # plt.plot(noises[:,0])
    # plt.plot(noises[:,1])
    # plt.plot(noises[:,2])
    # plt.show()


    noises = []
    iop.hyperFile = iop.datadir + '/abertest5noatmosquasispeckle2000_1s.pkl'
    # iop.hyperFile = iop.datadir + '/abertest5noatmosquasispeckle1000_100ms_ideal.pkl'


    import os
    # iop.aberdir = os.path.join(iop.rootdir, 'data/aberrations/180420b/')
    abertest = read.get_integ_hypercube(plot=False)# / ap.numframes
    # print np.shape(abertest)
    # quicklook_im(abertest[-1,0], logAmp=False)
    # loop_frames(abertest[:,0])
    # # print abertest.shape
    #
    # for x in [118,119]:
    #     for y in [9,10]:
    #         corr, ljb, pvalue = acf(abertest[:, 0, x, y], unbiased=False, qstat=True, nlags=len(range(ap.numframes)))
    #         # print abertest[:, 0, 9, 119]
    #         # corr, ljb, pvalue = acf(abertest[:, 0, 9, 119], unbiased=False, qstat=True, nlags=len(range(ap.numframes)))
    #         star_corr = corr
    #         # plt.figure()
    #         plt.plot(star_corr)
    # plt.xscale('log')
    # # plt.show()
    # plt.figure()
    #
    # for x in [64,65]:
    #     for y in [64,65]:
    #         corr, ljb, pvalue = acf(abertest[:, 0, x, y], unbiased=False, qstat=True, nlags=len(range(ap.numframes)))
    #         # print abertest[:, 0, 9, 119]
    #         # corr, ljb, pvalue = acf(abertest[:, 0, 9, 119], unbiased=False, qstat=True, nlags=len(range(ap.numframes)))
    #         star_corr = corr
    #         # plt.figure()
    #         plt.plot(star_corr)
    # plt.xscale('log')
    # # plt.show()
    # plt.figure()
    #
    # for y in [70, 85, 105, 120]:
    #     print y
    #     corr, ljb, pvalue = acf(abertest[:, 0, 64, y], unbiased=False, qstat=True, nlags=len(range(ap.numframes)))
    #     star_corr = corr
    #
    #     plt.plot(star_corr)
    #     plt.xscale('log')
    # plt.show()
    # #
    # # quicklook_im(abertest[0, 0, :, :])
    # # quicklook_im(abertest[1, 0, :, :]-abertest[0, 0, :, :])


    MEDIUM_SIZE = 14
    plt.rc('font', size=MEDIUM_SIZE)  # controls default text sizes

    from matplotlib import rcParams

    rcParams['axes.linewidth'] = 1.5  # set the value globally
    rcParams['font.family'] = 'STIXGeneral'  # 'Times New Roman'
    rcParams['mathtext.fontset'] = 'custom'
    rcParams['mathtext.fontset'] = 'stix'
    fig, ax = plt.subplots()

    from cycler import cycler
    rcParams['axes.prop_cycle'] = cycler('color', ['#0C5DA5', '#00B945', '#FF9500', '#FF2C00', '#845B97', '#474747', '#9e9e9e'])
    plt.rc('axes', prop_cycle=(cycler('color', ['#0C5DA5', '#00B945', '#FF9500', '#FF2C00', '#845B97', '#474747', '#9e9e9e'])))

    lod = 5
    Ic = np.sum(abertest, axis=0)[0]/5000
    # quicklook_im(Ic)
    for t in np.arange(0,ap.numframes/1,50):
        # quicklook_im(abertest[0,0], vmin=1)
        # residual = np.abs(np.sum(abertest[t:t+1,0],axis=0) - np.sum(abertest[0:1,0], axis=0))
        residual = np.abs(abertest[t,0] - abertest[0,0])
        # quicklook_im(residual, vmin=1)
        # noises.append([residual[70,70], residual[90,90], residual[110, 110]])
        # sig = np.sqrt(2*Ic*residual)
        # quicklook_im(sig/np.sqrt(Ic))
        noise = []
        for r in [2,4,9]:
            # Is = Analysis.phot.annuli(r*lod,(r+1)*lod)*np.std(residual)/np.sqrt(Ic)
            # Is = Analysis.phot.annuli(r*lod,(r+1)*lod)*sig/np.sqrt(Ic)
            Is = Analysis.phot.annuli(r*lod,(r+1)*lod)*residual
            # Ic = Analysis.phot.annuli(r*lod,(r+1)*lod)*Ic
        #     quicklook_im(Is)
            Is = Is[Is != 0]
            Imean = np.mean(Is)
            Ivar = np.var(Is)
        #     # Ic = np.sqrt(Imean ** 2)# - Istd ** 2)
        #     print Imean, Ivar
        #
            noise.append(np.sqrt(Ivar)*1e-6/(np.sqrt(Imean)*15.39))
        # noise, rrad = phot.noise_per_annulus(residual, separation=1, fwhm=lod,
        #                                                   init_rad=lod, wedge=(0, 360))
        #     noise.append(np.sum(Is))
        print t
        # noises.append([noise[21], noise[35], noise[50]])
        noises.append(noise)
    noises = np.array(noises)
    start = 6
    ax.plot(np.arange(0,ap.numframes/1,50)[start:], noises[:, 0][start:]*1e9, linewidth=2, label='2$\lambda/D$', color='#0C5DA5')
    ax.plot(np.arange(0,ap.numframes/1,50)[start:], noises[:, 1][start:]*1e9, linewidth=2, label='4$\lambda/D$', color='#00B945')
    ax.plot(np.arange(0,ap.numframes/1,50)[start:], noises[:, 2][start:]*1e9, linewidth=2, label='9$\lambda/D$', color='#FF9500')
    from scipy import stats
    slope, intercept, r_value, p_value, std_err = stats.linregress(np.arange(0,ap.numframes/1,50)[start:], noises[:, 0][start:]*1e9)
    ax.plot(np.arange(0,ap.numframes/1,50)[start:], np.arange(0,ap.numframes/1,50)[start:]*slope+intercept, color='#0C5DA5', linestyle='--')

    slope, intercept, r_value, p_value, std_err = stats.linregress(np.arange(0,ap.numframes/1,50)[start:], noises[:, 1][start:]*1e9)
    ax.plot(np.arange(0,ap.numframes/1,50)[start:], np.arange(0,ap.numframes/1,50)[start:]*slope+intercept, color='#00B945', linestyle='--')

    slope, intercept, r_value, p_value, std_err = stats.linregress(np.arange(0,ap.numframes/1,50)[start:], noises[:, 2][start:]*1e9)
    ax.plot(np.arange(0,ap.numframes/1,50)[start:], np.arange(0,ap.numframes/1,50)[start:]*slope+intercept, color='#FF9500', linestyle='--')
    # plt.xscale('log')
    ax.tick_params(direction='in', which='both', right=True, top=True, width=1.5, length=4)
    ax.set_xlabel('Time (s)')
    ax.set_ylabel('Quasi-static Wavefront Error (nm)')
    ax.set_yscale('log')
    plt.legend()
    plt.show()

    # # bunching
    # ap.companion = True
    # iop.hyperFile = iop.datadir + '/bunching_mkid_1hr.pkl'
    # bunch_hypercube = read.get_integ_hypercube(plot=False)# / ap.numframes
    #
    # times = np.arange(0,num_exp*cp.frame_time,cp.frame_time)
    # loop_frames(abertest[:,0])
    times = np.arange(0, num_exp,100)
    print times
    for i in range(0,len(times)-1):
        first_timecube = abertest[times[0]:times[1], 0]
        timecube = abertest[times[i]:times[i+1],0]
        # var = np.var(timecube[:,40,40])
        # quicklook_im(abertest[0,0], logAmp=True)
        # residual = abertest[t,0] - abertest[0,0]
        residual = np.abs(timecube- first_timecube)
        # loop_frames(first_timecube)
        # loop_frames(timecube)
        # loop_frames(residual+1e-9, logAmp=True)
        var = np.var(residual[:], axis=0)
        # quicklook_im(var,  logAmp=True)
        noises.append(var)
    noises = np.array(noises)
    # for i in range(5):
    #     for j in range(5):
    #         plt.plot(noises[:,i,j])
    # plt.plot(noises[:,10,10])
    plt.plot(noises[:, 20, 20])
    plt.plot(noises[:, 30, 30])
    # plt.plot(noises[:, 40, 40])
    plt.plot(noises[:, 50, 50])
    # plt.plot(noises[:, 60, 60])
    plt.show()