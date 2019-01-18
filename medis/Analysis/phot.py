'''This code scipt handles the photon data once it has passed through the system'''

# import pyfits
import astropy.io.fits as pyfits
import numpy as np
import os
from matplotlib import pyplot as plt
from matplotlib.ticker import MultipleLocator
import sys
# sys.path.append('/Volumes/Data2/dodkins/scripts/')
# from datacube import read_folder
# from distribution import *
# import subprocess
# import vip_hci as vip
# plots = vip.var.pp_subplots
from params import cp, mp, tp, iop, ap
# import Detector.pipeline as pipe
import Detector.readout as read
from Utils.plot_tools import quicklook_im, loop_frames
from Utils.misc import dprint
from vip_hci import phot, metrics

# import MKIDs

def annuli(inner, outer):
    mask = aperture(np.floor(tp.grid_size / 2) - 1, np.floor(tp.grid_size / 2), outer)

    if inner > 0:
        in_mask = aperture(np.floor(tp.grid_size / 2) - 1, np.floor(tp.grid_size / 2), inner)
        in_mask[in_mask == 0] = -1
        in_mask[in_mask == 1] = 0
        in_mask[in_mask == -1] = 1
        mask = mask * in_mask
    return mask

def aper_phot(image, inner, outer, plot=False):
    # mask = aperture(np.floor(tp.grid_size / 2) - 1, np.floor(tp.grid_size / 2), outer)
    mask = aperture(np.floor(image.shape[0] / 2 - 0.5), np.floor(image.shape[1] / 2 - 0.5), outer, image, plot=plot)
    # image = image * mask
    if inner > 0:
        in_mask = aperture(np.floor(image.shape[0] / 2 - 0.5), np.floor(image.shape[1] / 2 - 0.5), inner, image, plot)
        in_mask[in_mask == 0] = -1
        in_mask[in_mask == 1] = 0
        in_mask[in_mask == -1] = 1
        mask = mask * in_mask

    image = image * mask

    if plot:
        plt.imshow(image)
        plt.show()

    photometry = np.sum(image) / np.sum(mask)
    return photometry


# def truncate_array(image):
#     '''Make non-square array'''
#     orig_shape = np.shape(image)
#     diff = orig_shape - array_size
#     image = image[:, :-diff[1]]

#     return image

def aperture(startpx, startpy, radius, image=np.zeros((tp.grid_size,tp.grid_size)), plot=False):
    r = radius
    length = 2 * r
    height = length
    allx = np.arange(startpx - int(np.ceil(length / 2.0)), startpx + int(np.floor(length / 2.0)) + 1)
    ally = np.arange(startpy - int(np.ceil(height / 2.0)), startpy + int(np.floor(height / 2.0)) + 1)
    # mask=np.zeros((xnum,ynum))
    # mask = np.zeros((tp.grid_size, tp.grid_size))
    mask = np.zeros_like(image)

    for x in allx:
        for y in ally:
            if (np.abs(x - startpx)) ** 2 + (np.abs(y - startpy)) ** 2 <= (
            r) ** 2 and 0 <= y and y < mask.shape[0] and 0 <= x and x < mask.shape[1]:
                mask[int(y), int(x)] = 1.

    # mask = truncate_array(mask)
    if plot:
        plt.imshow(mask, origin='lower')
        plt.show()
    return mask


def mask_companion(image, startpx, startpy, radius):
    outer = int(np.sqrt((startpx - ynum / 2) ** 2 + (startpy - xnum / 2) ** 2) + radius / 2)
    inner = int(np.sqrt((startpx - ynum / 2) ** 2 + (startpy - xnum / 2) ** 2) - radius / 2)

    print(startpx, xnum, ynum, outer, inner)
    mask = aperture(np.floor(ynum / 2) - 1, np.floor(xnum / 2), outer)
    # image = image * mask
    if inner > 0:
        in_mask = aperture(np.floor(ynum / 2) - 1, np.floor(xnum / 2), inner)
        in_mask[in_mask == 0] = -1
        in_mask[in_mask == 1] = 0
        in_mask[in_mask == -1] = 1
        mask = mask * in_mask

    annulus = image * mask

    plt.imshow(annulus)
    plt.show()

    comp_mask = aperture(startpx, startpy, radius)
    plt.imshow(comp_mask)
    plt.show()

    mask = mask - (mask * comp_mask)
    annulus = image * mask
    # annulus = annulus - (annulus * comp_mask)

    # plt.imshow(annulus)
    # plt.show()

    annulus_mean = np.sum(annulus) / np.sum(mask)
    print(annulus_mean)

    comp_mask = np.int_(comp_mask)

    image[comp_mask == 1] = annulus_mean
    plt.imshow(image)
    plt.show()

    return image


def do_SDI(datacube, plot=False):
    wsamples = np.linspace(tp.band[0], tp.band[1], tp.w_bins)
    scale_list = tp.band[0] / wsamples
    # print scale_list
    from vip_hci import pca
    dprint((datacube.shape, scale_list.shape))
    fr_pca1 = pca.pca(datacube, angle_list=np.zeros((len(scale_list))), scale_list=scale_list, mask_center_px=None)
    # fr_pca1 = fr_pca1[:,:-4]
    if plot:
        quicklook_im(fr_pca1)
    # dprint(fr_pca1.shape)
    return fr_pca1


def make_SNR_plot(datacube):
    '''No clever datareduction done here yet, just looking at a few frames and the PCA'''
    fr_pca1 = do_SDI(datacube)
    # fr_pca1 = np.abs(vip.pca.pca(frames, angle_list = np.zeros((cp.numframes)), scale_list=np.ones((cp.numframes)), mask_center_px=None))

    blue = datacube[0]
    bolometric = np.sum(datacube, axis=0)

    sep = np.arange(mp.nlod) + 1
    sepAS = (sep * 0.025 * 2) / 8

    # pixel coords of center of images
    centerx = int(mp.xnum / 2)
    centery = int(mp.ynum / 2)
    norm = 1.  # center intensity hard coded for now

    images = [fr_pca1, blue, bolometric]
    labels = ['SDI', 'Blue', 'Bolometric']

    '''This function is untested but should work'''
    # make_cont_plot(images, labels)

    radii = np.arange(mp.nlod) + 1
    psfMeans = np.zeros((len(images), len(radii)))

    for ir, r in enumerate(radii):
        for im, image in enumerate(images):
            psf_an = vip.phot.snr_ss(image, (centerx + r * mp.lod, centery), fwhm=mp.lod, plot=False, seth_hack=True)
            psfMeans[im, ir] = psf_an[3]

    fig, ax1 = plt.subplots()
    for im in range(len(images)):
        ax1.plot(sep, psfMeans[im] / norm, linewidth=2, label=r'%s' % labels[im], alpha=0.7)

    # ax1.set_xlim([10**-8,10**-1])
    # ax1.errorbar(sep,spMeans/norm,yerr=spStds/norm,linestyle='-.',linewidth=2,label=r'Mean Coronagraphic Raw Contrast')
    # ax1.errorbar(sep,psfMeans/norm+5*psfStds/norm,linewidth=2,label=r'5-$\sigma$ Unocculted PSF Contrast')
    # ax1.errorbar(sep,spMeans/norm+5*spStds/norm,linestyle='-.',linewidth=2,label=r'5-$\sigma$ Coronagraphic Raw Contrast')

    ax1.axvline(x=2, linestyle='--', color='black', linewidth=2, label='FPM Radius')
    ax1.set_xlabel(r'Separation ($\lambda$/D)', fontsize=14)
    ax1.set_ylabel(r'Contrast', fontsize=14)
    # ax1.set_xlim(1,12)
    # ax1.set_ylim(1e-9,0.1)
    ax1.set_yscale('log')

    ax2 = ax1.twiny()
    ax2.plot(sepAS, psfMeans[0], alpha=0)
    ax2.set_xlabel(r'Separation (as)', fontsize=14)

    ax1.legend()
    plt.show()

def get_unoccult_hyper(hyperFile = '/RefPSF_wLyotStop.pkl', numframes=1):
    import copy
    tp_orig = copy.copy(tp)
    ap_orig = copy.copy(ap)
    iop_orig = copy.copy(iop)

    # tp.detector = 'ideal'
    ap.companion = False
    iop.hyperFile = iop.datadir + hyperFile
    tp.occulter_type = 'None (Lyot Stop)'
    ap.numframes = numframes
    ap.exposure_time = 1e-3
    # tp.nwsamp = 1
    # tp.w_bins = 1
    print(iop.obsfile, 'obs')
    hypercube = read.get_integ_hypercube()

    tp.__dict__ = tp_orig.__dict__
    ap.__dict__ = ap_orig.__dict__
    iop.__dict__ = iop_orig.__dict__
    return hypercube


def get_unoccult_perf_psf(plot=False, hyperFile='/IntHyperUnOccult.pkl'):
    import copy
    tp_orig = copy.copy(tp)
    ap_orig = copy.copy(ap)
    iop_orig = copy.copy(iop)

    tp.detector = 'ideal'
    ap.companion = False
    # tp.NCPA_type = 'Wave'

    iop.hyperFile = iop.datadir + '/perfIntHyperUnOccult.pkl'
    tp.occulter_type = 'None'
    num_exp = 1
    ap.exposure_time = 0.001  # 0.001
    ap.numframes = int(num_exp * ap.exposure_time / cp.frame_time)
    tp.use_atmos = False
    tp.nwsamp = 1
    tp.CPA_type = None#'Quasi'# None
    tp.NCPA_type = None#'Wave'# #None
    tp.aber_params = {'CPA': False,
                        'NCPA': False,
                        'QuasiStatic': False,  # or 'Static'
                        'Phase': False,
                        'Amp': False,
                        'n_surfs': 2}
    # Yup this is 'if' is necessary
    hypercube = read.get_integ_hypercube()
    # PSF = hypercube[0,0]
    PSF = (read.take_exposure(hypercube))[0,0]
    if plot:
        quicklook_im(PSF)

    tp.__dict__ = tp_orig.__dict__
    ap.__dict__ = ap_orig.__dict__
    iop.__dict__ = iop_orig.__dict__
    # # print tp.occulter_type

    return PSF

def get_unoccult_psf(plot=False, hyperFile = '/IntHyperUnOccult.pkl', numframes=1000):
    # import copy
    # tp_orig = copy.copy(tp)
    # ap_orig = copy.copy(ap)
    # iop_orig = copy.copy(iop)
    #
    # tp.detector = 'ideal'
    # ap.companion = False
    # # tp.NCPA_type = 'Wave'
    #
    # iop.hyperFile = iop.datadir + '/IntHyperUnOccult.pkl'
    # tp.occulter_type = 'None'
    # num_exp = 1
    # ap.exposure_time = 0.001  # 0.001
    # ap.numframes = int(num_exp * ap.exposure_time / cp.frame_time)
    # tp.nwsamp = 1
    # # Yup this is 'if' is necessary
    # hypercube = read.get_integ_hypercube()
    hypercube = get_unoccult_hyper(hyperFile, numframes=numframes)
    # PSF = hypercube[0,0]
    # PSF = (read.take_exposure(hypercube))[0,0]
    # PSF = (read.take_exposure(hypercube))
    PSF = hypercube
    if plot:
        quicklook_im(PSF)

    # tp.__dict__ = tp_orig.__dict__
    # ap.__dict__ = ap_orig.__dict__
    # iop.__dict__ = iop_orig.__dict__
    # # print tp.occulter_type

    return PSF


# def make_cont_plot(images, labels):
#     '''No clever datareduction done here yet, just looking at a few frames and the PCA'''
#
#     sep = np.arange(mp.nlod)+1
#     sepAS = (sep*0.025*2)/8
#
#     #pixel coords of center of images
#     centerx=int(mp.xnum/2)
#     centery=int(mp.ynum/2)
#     print centerx
#     norm = np.zeros((len(images))) #center intensity hard coded for now
#
#     radii = np.arange(mp.nlod)+1
#     psfMeans = np.zeros((len(images),len(radii)))
#
#
#     for ir, r in enumerate(radii):
#         for im, image in enumerate(images):
#             psf_an = vip.phot.snr_ss(image,(centerx+r*mp.lod,centery), fwhm=mp.lod, plot=False,seth_hack=True)
#             # print psf_an
#             psfMeans[im, ir] = psf_an[3]
#     # print type(images[0]), np.shape(images[0])
#     for im, image in enumerate(images):
#         norm[im] = np.sum(image[centerx-2:centerx+2,centery-2:centery+2])/16 #psfMeans[:, 0]
#
#     fig,ax1 = plt.subplots()
#     for im in range(len(images)):
#         ax1.plot(sep,psfMeans[im]/norm[im],linewidth=2,label=r'%s'%labels[im], alpha=0.7)
#
#     # ax1.set_xlim([10**-8,10**-1])
#     # ax1.errorbar(sep,spMeans/norm,yerr=spStds/norm,linestyle='-.',linewidth=2,label=r'Mean Coronagraphic Raw Contrast')
#     # ax1.errorbar(sep,psfMeans/norm+5*psfStds/norm,linewidth=2,label=r'5-$\sigma$ Unocculted PSF Contrast')
#     # ax1.errorbar(sep,spMeans/norm+5*spStds/norm,linestyle='-.',linewidth=2,label=r'5-$\sigma$ Coronagraphic Raw Contrast')
#
#     ax1.axvline(x=3.2,linestyle='--',color='black',linewidth=2,label = 'FPM Radius')
#     ax1.set_xlabel(r'Separation ($\lambda$/D)',fontsize=14)
#     ax1.set_ylabel(r'Contrast',fontsize=14)
#     #ax1.set_xlim(1,12)
#     ax1.set_ylim([1e-5,1.])
#     ax1.set_yscale('log')
#
#     ax2 = ax1.twiny()
#     ax2.plot(sepAS,psfMeans[0],alpha=0)
#     ax2.set_xlabel(r'Separation (as)',fontsize=14)
#
#     ax1.legend()
#     plt.show()

def make_cont_plot(images, labels, sigma=5, norms=None, student=True):
    # sep = np.arange(mp.lod,images.shape[1]/2 mp.nlod+1)#+1
    # sepAS = (sep*0.025*2)/8
    if norms == None:
        norms = np.ones((len(images)))
    # pixel coords of center of images
    centerx = int(mp.xnum / 2)
    centery = int(mp.ynum / 2)
    # norm = np.zeros((len(images))) #center intensity hard coded for now

    radii = np.arange(1, mp.nlod) + 1
    psfMeans = np.ones((len(images), len(radii) + 1))

    fwhm = mp.lod
    curves = np.zeros((len(images), 63))
    print(len(radii))
    # for ir, r in enumerate(radii):

    for im, image in enumerate(images):
        noise_samp, rad_samp = vip.phot.noise_per_annulus(image, separation=1, fwhm=fwhm,
                                                          init_rad=fwhm, wedge=(0, 360))
        # curves[im] = noise_samp / (50e6 * 1000 * norms[im])  # star brightness 1000 x less with coron
        curves[im] = noise_samp / (50e6 * 10 * norms[im])  # star brightness 1000 x less with coron

    from scipy import stats
    if student:
        n_res_els = np.floor(rad_samp / fwhm * 2 * np.pi)
        ss_corr = np.sqrt(1 + 1 / (n_res_els - 1))
        sigma = stats.t.ppf(stats.norm.cdf(sigma), n_res_els) * ss_corr
    print('sigma', sigma)

    fig, ax1 = plt.subplots()
    for im in range(len(images)):
        curves[im] = curves[im] * sigma
        ax1.plot(rad_samp, curves[im], linewidth=2, label=r'%s' % labels[im], alpha=0.5)

    ax1.axvline(x=16, linestyle='--', color='black', linewidth=2, label='FPM Radius')
    # ax1.set_xlabel(r'Separation ($\lambda$/D)',fontsize=14)
    # ax1.set_ylabel(r'SNR',fontsize=14)
    # ax1.set_xlim(0,8)
    # ax1.set_ylim([1e-5,1.])
    ax1.set_yscale('log')

    # ax2 = ax1.twiny()
    # ax2.plot(sepAS,psfMeans[0],alpha=0)
    # ax2.set_xlabel(r'Separation (as)',fontsize=14)

    ax1.legend()
    print(mp.lod)
    # plt.show()


def make_SNR_plot(images, labels):
    '''No clever datareduction done here yet, just looking at a few frames and the PCA'''

    sep = np.arange(1, mp.nlod + 1)  # +1
    sepAS = (sep * 0.025 * 2) / 8

    # pixel coords of center of images
    centerx = int(mp.xnum / 2)
    centery = int(mp.ynum / 2)
    print(centerx)
    # norm = np.zeros((len(images))) #center intensity hard coded for now

    radii = np.arange(1, mp.nlod) + 1
    psfMeans = np.ones((len(images), len(radii) + 1))

    for ir, r in enumerate(radii):
        for im, image in enumerate(images):
            psf_an = vip.phot.snr_ss(image, (centerx + r * mp.lod, centery), fwhm=mp.lod, plot=False,
                                     seth_hack=True)
            # print psf_an
            psfMeans[im, ir + 1] = psf_an[3]
    # print type(images[0]), np.shape(images[0])
    # for im, image in enumerate(images):
    #     norm[im] = np.sum(image[centerx-2:centerx+2,centery-2:centery+2])/16 #psfMeans[:, 0]
    # psfMeans[:, 0] = 1*norms
    fig, ax1 = plt.subplots()
    for im in range(len(images)):
        ax1.plot(sep, psfMeans[im], linewidth=2, label=r'%s' % labels[im], alpha=0.7)

    # ax1.set_xlim([10**-8,10**-1])
    # ax1.errorbar(sep,spMeans/norm,yerr=spStds/norm,linestyle='-.',linewidth=2,label=r'Mean Coronagraphic Raw Contrast')
    # ax1.errorbar(sep,psfMeans/norm+5*psfStds/norm,linewidth=2,label=r'5-$\sigma$ Unocculted PSF Contrast')
    # ax1.errorbar(sep,spMeans/norm+5*spStds/norm,linestyle='-.',linewidth=2,label=r'5-$\sigma$ Coronagraphic Raw Contrast')

    ax1.axvline(x=2, linestyle='--', color='black', linewidth=2, label='FPM Radius')
    ax1.set_xlabel(r'Separation ($\lambda$/D)', fontsize=14)
    ax1.set_ylabel(r'SNR', fontsize=14)
    ax1.set_xlim(0, 8)
    ax1.set_ylim([1e-5, 1.])
    ax1.set_yscale('log')

    ax2 = ax1.twiny()
    ax2.plot(sepAS, psfMeans[0], alpha=0)
    ax2.set_xlabel(r'Separation (as)', fontsize=14)

    ax1.legend()
    plt.show()


def SDI_each_exposure(hypercube, binning=10):
    shape = hypercube.shape
    timecube = np.zeros_like(hypercube[::binning,0])
    dprint(timecube.shape)
    dprint(hypercube.shape)
    idx = np.arange(0,len(hypercube),binning)
    for i in range(len(idx)-1):
        timecube[i] = do_SDI(np.mean(hypercube[idx[i]:idx[i+1]],axis=0), plot=False)
    # for t in range(shape[0])[:1]:
    #     timecube[t] = do_SDI(hypercube[t], plot=True)
    # loop_frames(timecube)
    return timecube

    # if __name__ == "__main__":
    #     frames = temporal.read_time_images(datadir)
    #     # frames = uniform_cube()

    #     frames = MKIDs.truncate_array(frames)

    #     plt.imshow(frames[0])
    #     plt.show()

    #     image = mask_companion(frames[0], 19, 42, 4)
    #     plt.imshow(image, interpolation='none')
    #     plt.show()

    #     rad_res = 1
    #     rad_background = np.zeros((ynum))
    #     for ir, r in enumerate(np.arange(0,ynum,rad_res)):
    #         rad_background[ir] = aper_phot(frames[0], r, r+rad_res)

    #     plt.plot(rad_background)
    #     plt.plot(20,0.144, 'o')
    #     plt.show()

def eval_method(cube, algo, psf_template, angle_list, algo_dict, fwhm=4, star_phot=1):
    fulloutput = metrics.contrcurve.contrast_curve(cube=cube,
                                   angle_list=angle_list, psf_template=psf_template,
                                   fwhm=fwhm, pxscale=tp.platescale/1000,
                                   starphot=star_phot, algo=algo, nbranch=3,
                                    adimsdi = 'double', ncomp = 7, ncomp2=None,
                                   debug=True, plot=False, theta=0,full_output=True, fc_snr=10, **algo_dict)
    plt.show()
    metrics_out = [fulloutput[0]['throughput'], fulloutput[0]['noise'], fulloutput[0]['sensitivity_student']]
    metrics_out = np.array(metrics_out)
    return metrics_out, fulloutput[2]

def make_mosaic_cube(hyper):
    """ I eat other cubes for breakfast """
    moves = np.shape(tp.pix_shift)[0]
    tp.pix_shift = np.array(tp.pix_shift)

    super_hypercube = np.zeros((hyper.shape[0] // moves, hyper.shape[1], tp.grid_size, tp.grid_size))
    st = 0

    left = int(np.floor(float(tp.grid_size - mp.array_size[1]) / 2))
    right = int(np.ceil(float(tp.grid_size - mp.array_size[1]) / 2))
    top = int(np.floor(float(tp.grid_size - mp.array_size[0]) / 2))
    bottom = int(np.ceil(float(tp.grid_size - mp.array_size[0]) / 2))

    for t in range(hyper.shape[0]//moves):
        for m in range(moves):
            super_hypercube[t,:,
                            left - tp.pix_shift[m][0] : -right - tp.pix_shift[m][0],
                            bottom - tp.pix_shift[m][1] : -top- tp.pix_shift[m][1]] += hyper[st]
            st+=1

    return super_hypercube