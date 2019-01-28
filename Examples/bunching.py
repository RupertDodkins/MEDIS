
'''This code handles the relevant functionality of a Hawaii 2RG camera'''
import sys
sys.path.append('D:/dodkins/MEDIS/MEDIS')
import numpy as np
import copy
import matplotlib.pyplot as plt
from vip_hci import phot, pca
from medis.params import ap, cp, tp, sp, mp, iop
from medis.Utils.plot_tools import loop_frames, quicklook_im,view_datacube, compare_images, indep_images
import medis.Detector.readout as read
import medis.Analysis.phot
import medis.Analysis.stats
import pandas as pd

# Global params
ap.star_photons = int(1e3)
sp.save_obs = False
sp.show_cube = False
sp.save_obs = False
sp.return_cube = True
sp.show_wframe = False
ap.companion = True
ap.contrast = [1e-1,1e-2]#[0.1,0.1]
ap.lods = [[-1.5,1.5],[3.5,-3.5]]
tp.diam=8.
tp.use_spiders = True
tp.use_ao = True
tp.ao_act = 50
tp.detector = 'MKIDs'
# ap.star_photons*=1000
# tp.NCPA_type = None#'Static'
# tp.CPA_type = None#'Static'
tp.NCPA_type = 'Static'
tp.CPA_type = 'Static'
mp.date = '180421/'
iop.update(mp.date)
sp.num_processes = 45
tp.occulter_type = 'None'#'Gaussian'
num_exp =2000 #5000
ap.exposure_time = 0.001  # 0.001
ap.numframes = int(num_exp * ap.exposure_time / cp.frame_time)
tp.piston_error = True
xlocs = range(0, 128)  # range(0,128)#65
ylocs = range(0, 128)  # range(0,128)#85
tp.band = np.array([860, 1250])
tp.nwsamp = 1
tp.rot_rate = 0  # deg/s
theta=45
lod = 8
cp.frame_time = 0.001
tp.satelite_speck = True
tp.speck_locs = [[40, 40]]


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


    # rad_samp = np.linspace(0,tp.platescale/1000.*40,40)
    # print rad_samp
    # # Get unocculted PSF for intensity
    # psf_template = Analysis.phot.get_unoccult_psf(hyperFile='/IntHyperUnOccult.pkl', plot=False)
    # # star_phot = np.sum(psf_template)
    # star_phot = phot.contrcurve.aperture_flux(psf_template,[64],[64],lod,1)[0]/ap.numframes
    # psf_template = psf_template[:-1,:-1]


    # bunching
    ap.companion = True
    iop.hyperFile = iop.datadir + '/bunchingOldAtmos_ArteficialSpecksDim2sec.pkl'
    bunch_hypercube = read.get_integ_hypercube(plot=False)# / ap.numframes
    print bunch_hypercube.shape

    loop_frames(bunch_hypercube[:,0], axis=None)

    def sub_sums_ophion(arr, ncols):
        arr = arr.reshape(1,-1)
        nrows = 1
        h, w = arr.shape
        h = (h // nrows) * nrows
        w = (w // ncols) * ncols
        arr = arr[:h, :w]
        return np.einsum('ijkl->ik', arr.reshape(h // nrows, nrows, -1, ncols))


    full_counts = np.zeros((2,num_exp))
    full_counts[0] = bunch_hypercube[:,0,40,40]
    full_counts[1] = bunch_hypercube[:,0,41,88]

    print full_counts, 'lol'
    fig, axes = plt.subplots(nrows=1, ncols=2, figsize=(10, 3.9))
    titles = ['Speckle', 'Exoplanet']
    for loc in range(2):

        # hist, bins = np.histogram(full_counts, bins=range(0, int(np.max(full_counts)) + 1))
        # print hist, bins
        # plt.plot(bins[:-1], hist)
        # plt.show()
        # plt.figure()
        for scale in range(1,6):#[1,2,3,4,10,40,100]:

            binned = sub_sums_ophion(full_counts[loc],scale)
            print binned
            hist, bins = np.histogram(binned, bins=range(int(np.min(binned)), int(np.max(binned)) + 1))
            print hist, bins
            axes[loc].step(bins[:-1], hist, label='Bin interval: %i ms' % scale)
            axes[loc].set_xlabel('Photons/bin')
            axes[loc].set_ylabel('# Number of Bins')
            axes[loc].set_title(titles[loc])
            axes[loc].legend()
    plt.show()
    # binned = sub_sums_ophion(counts, 3)
    # print binned
    # hist, bins = np.histogram(binned, bins=range(0, int(np.max(binned)) + 1))
    # plt.plot(bins[:-1], hist)
    # plt.show()

    LCmap = np.transpose(bunch_hypercube[:,0])
    SSD_maps = Analysis.stats.get_Iratio(LCmap, xlocs, ylocs, None, None, None)
    SSD_maps = np.array(SSD_maps)[:-1]
    # # SSD_maps[:2] /= star_phot
    # # SSD_maps[2] /= SSD_starphot
    # SSD_maps #/= star_phot

    #vmins = [2e-11, 2e-8, 1e-12], vmaxs = [5e-7, 1.5e-7, 1e-6]
    indep_images(SSD_maps, logAmp = True, titles =[r'  $I_C / I^{*}$',r'  $I_S / I^{*}$',r'  $I_r / I^{*}$'], annos=['Deterministic','Random','Beam Ratio'])


    print 'here'
    # quicklook_im(bunch_hypercube[0,0])
    ap.exposure_time = 1
    stacked = read.take_exposure(bunch_hypercube)
    quicklook_im(stacked[0,0])


    from statsmodels.tsa.stattools import acovf, acf, ccf

    mask = Analysis.phot.aperture(64,64, 1)
    aper_idx = np.where(mask)
    print aper_idx
    # quicklook_im(mask)

    star_corr = 0
    # for x, y in np.transpose(aper_idx):
    #     # for y in aper_idx[0]:
    #     print x, y
    #     corr, ljb, pvalue = acf(bunch_hypercube[:, 0, x, y], unbiased=False, qstat=True, nlags=len(range(5000)))
    #     # plt.plot(range(4999), corr[:-1])
    #     # plt.show()
    #     star_corr += corr
    # star_corr /= 5
    corr, ljb, pvalue = acf(bunch_hypercube[:, 0, 64, 65], unbiased=False, qstat=True, nlags=len(range(num_exp)))
    star_corr = corr
    plt.figure()
    plt.plot(star_corr)
    plt.show()
    #
    # for x in range(63,66):
    #     for y in range(117,119):
    #         corr, ljb, pvalue = acf(bunch_hypercube[:, 0, x, y], unbiased=False, qstat=True, nlags=len(range(num_exp)))
    #         # print x, y, corr[1000]
    #         plt.plot(range(num_exp-1), corr[:-1])
    #         plt.show()
    #         print 'cross corr', x, y, (corr- star_corr)**2#np.corrcoef(corr, star_corr)[0,1]
    #         # crosscorr = ccf(corr, star_corr, unbiased=False)
    #         # plt.plot(crosscorr)
    #         # plt.show()
    #
    # for x in range(63, 66):
    #     for y in range(73, 77):
    #         corr, ljb, pvalue = acf(bunch_hypercube[:, 0, x, y], unbiased=False, qstat=True,
    #                                 nlags=len(range(num_exp)))
    #         # print x, y, corr[1000]
    #         plt.plot(range(num_exp-1), corr[:-1])
    #         plt.show()
    #         print 'cross corr', x, y, np.sum((corr- star_corr)**2)#np.corrcoef(corr, star_corr)[0,1]
    #         crosscorr = ccf(corr, star_corr, unbiased=False)
    #         # plt.plot(crosscorr)
    #         # plt.show()
    #
    # for x in range(63, 66):
    #     for y in range(83, 87):
    #         corr, ljb, pvalue = acf(bunch_hypercube[:, 0, x, y], unbiased=False, qstat=True,
    #                                 nlags=len(range(num_exp)))
    #         # print x, y, corr[1000]
    #         plt.plot(range(num_exp-1), corr[:-1])
    #         plt.show()
    #         print 'cross corr', x, y, np.sum((corr- star_corr)**2)#np.corrcoef(corr, star_corr)[0,1]
    #         crosscorr = ccf(corr, star_corr, unbiased=False)
    #         # plt.plot(crosscorr)
    #         # plt.show()
    #
    # for x in range(63, 66):
    #     for y in range(93, 97):
    #         corr, ljb, pvalue = acf(bunch_hypercube[:, 0, x, y], unbiased=False, qstat=True,
    #                                 nlags=len(range(num_exp)))
    #         # print x, y, corr[1000]
    #         plt.plot(range(num_exp-1), corr[:-1])
    #         plt.show()
    #         print 'cross corr', x, y, np.sum((corr- star_corr)**2)#np.corrcoef(corr, star_corr)[0,1]
    #         crosscorr = ccf(corr, star_corr, unbiased=False)
    #         plt.plot(crosscorr)
    #         plt.show()
    # for x in range(63,66):
    #     for y in range(63,66):
    #         corr, ljb, pvalue = acf(bunch_hypercube[:, 0, x, y], unbiased=False, qstat=True, nlags=len(range(5000)))
    #         # print x, y, corr[1000]
    #         plt.plot(range(4999), corr[:-1])
    #         plt.show()
    #         print 'cross corr', x, y, np.corrcoef(corr, star_corr)[0,1]
    #         crosscorr = ccf(corr, star_corr, unbiased=False)
    #         plt.plot(crosscorr)
    #         plt.show()
            # corrs+= corr
    #
    # for x in range(84,87):
    #     for y in range(97,100):
    #         corr, ljb, pvalue = acf(bunch_hypercube[:, 0, x, y], unbiased=False, qstat=True, nlags=len(range(5000)))
    #         # print x, y, corr[1000]
    #         plt.plot(range(4999), corr[:-1])
    #         plt.show()
    #         print 'cross corr', x, y, np.corrcoef(corr, star_corr)[0,1]
    #         crosscorr = ccf(corr, star_corr, unbiased=False)
    #         plt.plot(crosscorr)
    #         plt.show()
    #         # corrs+= corr
    #
    # # plt.figure()
    # # plt.plot(corrs)
    # # quicklook_im(stacked[0, 0, 80:95, 92:105])
    # # plt.figure()
    #
    #
    # for x in range(117,119):
    #     for y in range(9,11):
    #         corr, ljb, pvalue = acf(bunch_hypercube[:, 0, x, y], unbiased=False, qstat=True, nlags=len(range(5000)))
    #         # print x, y, corr[1000]
    #         plt.plot(range(4999), corr[:-1])
    #         plt.show()
    #         print 'cross corr', x, y, np.corrcoef(corr, star_corr)[0,1]
    #         crosscorr = ccf(corr, star_corr, unbiased=False)
    #         plt.plot(crosscorr)
    #         plt.show()
    #         # corrs+= corr
    #
    #
    #
    # for x in range(24,27):
    #     for y in range(101,104):
    #         corr, ljb, pvalue = acf(bunch_hypercube[:, 0, x, y], unbiased=False, qstat=True, nlags=len(range(5000)))
    #         # print x, y, corr[1000]
    #         plt.plot(range(4999), corr[:-1])
    #         plt.show()
    #         print 'cross corr', x, y, np.corrcoef(corr, star_corr)[0,1]
    #         crosscorr = ccf(corr, star_corr, unbiased=False)
    #         plt.plot(crosscorr)
    #         plt.show()
    #         # corrs+= corr
    #
    # for x in range(44,47):
    #     for y in range(44,47):
    #         corr, ljb, pvalue = acf(bunch_hypercube[:, 0, x, y], unbiased=False, qstat=True, nlags=len(range(5000)))
    #         # print x, y, corr[1000]
    #         plt.plot(range(4999), corr[:-1])
    #         plt.show()
    #         print 'cross corr', x, y, np.corrcoef(corr, star_corr)[0,1]
    #         crosscorr = ccf(corr, star_corr, unbiased=False)
    #         plt.plot(crosscorr)
    #         plt.show()
    #         # corrs+= corr


    corrs = np.zeros((128,128))
    for x in range(128):
        for y in range(128):
            corr, ljb, pvalue = acf(bunch_hypercube[:, 0, x, y], unbiased=False, qstat=True, nlags=len(range(num_exp)))
            # crosscorr = np.abs(np.corrcoef(bunch_hypercube[:, 0, x, y], star_corr)[0, 1])
            # crosscorr = np.corrcoef(corr, star_corr)[0, 1]
            # # crosscorr = np.sum(corr**2)
            # print x, y, corr[1660]
            # plt.plot(range(5000), corr[:-1])
            crosscorr = np.sum((corr- star_corr)**2)
            print 'cross corr', x, y,crosscorr
            corrs[x,y] = crosscorr
    # corrs[x,y] = corr[1000]

    quicklook_im(corrs)
    # corr, ljb, pvalue = acf(bunch_hypercube[:, 0, 20, 20], unbiased=False, qstat=True, nlags=len(range(5000)))
    # # plot correlation as function of lag time
    # plt.plot(range(5000), corr[:-1])
    # corr, ljb, pvalue = acf(bunch_hypercube[:, 0, 21, 21], unbiased=False, qstat=True, nlags=len(range(5000)))
    # plt.plot(range(5000), corr[:-1])
    # # plt.show()
    # #
    # # corr, ljb, pvalue = acf(bunch_hypercube[:, 0, 64, 64], unbiased=False, qstat=True, nlags=len(range(1000)))
    # # # plot correlation as function of lag time
    # # plt.plot(range(1000), corr[:-1])
    # # corr, ljb, pvalue = acf(bunch_hypercube[:, 0, 65, 65], unbiased=False, qstat=True, nlags=len(range(1000)))
    # # plt.plot(range(1000), corr[:-1])
    # # plt.show()
    # #
    # corr, ljb, pvalue = acf(bunch_hypercube[:, 0, 80, 40], unbiased=False, qstat=True, nlags=len(range(5000)))
    # # plot correlation as function of lag time
    # plt.plot(range(5000), corr[:-1])
    # corr, ljb, pvalue = acf(bunch_hypercube[:, 0, 80, 41], unbiased=False, qstat=True, nlags=len(range(5000)))
    # plt.plot(range(5000), corr[:-1])
    # # plt.show()
    #
    # corr, ljb, pvalue = acf(bunch_hypercube[:, 0, 25, 103], unbiased=False, qstat=True, nlags=len(range(5000)))
    # # plot correlation as function of lag time
    # plt.plot(range(5000), corr[:-1])
    # corr, ljb, pvalue = acf(bunch_hypercube[:, 0, 26, 102], unbiased=False, qstat=True, nlags=len(range(5000)))
    # plt.plot(range(5000), corr[:-1])
    # plt.show()
    from scipy import signal
    # Pxs = 0
    # for x in range(76,79):
    #     for y in range(82,85):
    #         f, Px = signal.periodogram(bunch_hypercube[:, 0, x, y])
    #         plt.plot(f, Px)
    #         Pxs += Px
    # plt.show()
    # plt.plot(f, Pxs)
    # plt.show()
    # Pxs = 0
    # for x in range(24,27):
    #     for y in range(101,104):
    #         f, Px = signal.periodogram(bunch_hypercube[:, 0, x, y])
    #         plt.plot(f, Px)
    #         Pxs += Px
    # plt.show()
    # plt.plot(f, Pxs)
    # plt.show()

    map = np.zeros((128,128))
    # max_h = np.array([100,50,25,10,5,2,1])
    max_h = np.array([100,200,400,1000,2000,5000,10000])
    min_h = np.array([0, 0, 0,0,0,0,0])
    binslen = [100,100,100,100,100,100,100]
    repeat = max_h/max_h[0]
    exp_cube = []
    for ie, exp in enumerate([0.001, 0.002, 0.004, 0.01, 0.02, 0.05, 0.1]):
        ap.exposure_time = exp
        binned_hypercube = read.take_exposure(bunch_hypercube)
        exp_cube.append(binned_hypercube)
    exp_cube = np.array(exp_cube)
    for x in range(128):
        for y in range(128):
            running = 0
            print x,y
            for ie in range(7):
                cube = exp_cube[ie]
                hist, bins = np.histogram(cube[:,0,x,y],bins=np.linspace(min_h[ie],max_h[ie],binslen[ie]+1))
                running += np.float_(hist)*repeat[ie]

            if y in range(102,106) and x in range(22,28):
                print x, y, np.argmax(running)
                plt.figure()
                plt.plot(running)
                plt.xlabel('Photons/10ms')
                plt.show()
            map[x,y] = np.argmax(running)
    quicklook_im(map)
    plt.show()
