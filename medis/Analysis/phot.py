'''This code scipt handles the photon data once it has passed through the system'''

import numpy as np
from matplotlib import pyplot as plt
import copy
from medis.params import cp, mp, tp, iop, ap, sp
import medis.get_photon_data as gpd
from medis.Utils.plot_tools import quicklook_im, view_datacube
from medis.Utils.misc import dprint
from vip_hci import phot, metrics, pca
import inspect
from vip_hci.metrics.contrcurve import noise_per_annulus, aperture_flux
from vip_hci.var.shapes import get_ell_annulus
from scipy import stats
from scipy.interpolate import InterpolatedUnivariateSpline
from scipy.signal import savgol_filter

def annuli(inner, outer):
    mask = aperture(np.floor(ap.grid_size / 2) - 1, np.floor(ap.grid_size / 2), outer)
    dprint(ap.grid_size)
    if inner > 0:
        in_mask = aperture(np.floor(ap.grid_size / 2) - 1, np.floor(ap.grid_size / 2), inner)
        in_mask[in_mask == 0] = -1
        in_mask[in_mask == 1] = 0
        in_mask[in_mask == -1] = 1
        mask = mask * in_mask
    return mask

def aper_phot(image, inner, outer, plot=False):
    # mask = aperture(np.floor(ap.grid_size / 2) - 1, np.floor(ap.grid_size / 2), outer)
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

def aperture(startpx, startpy, radius, image=np.zeros((ap.grid_size,ap.grid_size)), plot=False):
    r = radius
    length = 2 * r
    height = length
    allx = np.arange(startpx - int(np.ceil(length / 2.0)), startpx + int(np.floor(length / 2.0)) + 1)
    ally = np.arange(startpy - int(np.ceil(height / 2.0)), startpy + int(np.floor(height / 2.0)) + 1)
    # mask=np.zeros((xnum,ynum))
    # mask = np.zeros((ap.grid_size, ap.grid_size))
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
    wsamples = np.linspace(ap.band[0], ap.band[1], ap.w_bins)
    scale_list = ap.band[0] / wsamples
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

def get_unoccult_hyper(fields = '/RefPSF_wLyotStop.pkl', numframes=1):
    import copy
    tp_orig = copy.copy(tp)
    ap_orig = copy.copy(ap)
    iop_orig = copy.copy(iop)

    # tp.detector = 'ideal'
    ap.companion = False
    iop.fields = iop.testdir + fields
    tp.occulter_type = 'None (Lyot Stop)'
    ap.numframes = numframes
    ap.sample_time = 1e-3
    # ap.nwsamp = 1
    # ap.w_bins = 1
    print(iop.obs_table, 'obs')
    dprint(ap.grid_size)
    fields = gpd.run_medis()
    tp.__dict__ = tp_orig.__dict__
    ap.__dict__ = ap_orig.__dict__
    iop.__dict__ = iop_orig.__dict__

    return fields


def get_unoccult_perf_psf(plot=False, obs_seq='/IntHyperUnOccult.pkl'):
    tp_orig = copy.copy(tp)
    ap_orig = copy.copy(ap)
    iop_orig = copy.copy(iop)

    tp.detector = 'ideal'
    ap.companion = False
    # tp.NCPA_type = 'Wave'

    iop.obs_seq = iop.datadir + '/perfIntHyperUnOccult.pkl'
    tp.occulter_type = 'None'
    num_exp = 1
    ap.sample_time = 0.001  # 0.001
    ap.numframes = int(num_exp * ap.exposure_time / ap.sample_time)
    tp.use_atmos = False
    ap.nwsamp = 1
    tp.CPA_type = None#'Quasi'# None
    tp.NCPA_type = None#'Wave'# #None
    tp.aber_params = {'CPA': False,
                        'NCPA': False,
                        'QuasiStatic': False,  # or 'Static'
                        'Phase': False,
                        'Amp': False,
                        'n_surfs': 2}
    # Yup this is 'if' is necessary
    obs_sequence = run_medis()
    # PSF = obs_sequence[0,0]
    PSF = (read.take_exposure(obs_sequence))[0,0]
    if plot:
        quicklook_im(PSF)

    tp.__dict__ = tp_orig.__dict__
    ap.__dict__ = ap_orig.__dict__
    iop.__dict__ = iop_orig.__dict__
    # # print tp.occulter_type

    return PSF

def get_unoccult_psf(plot=False, fields = '/IntHyperUnOccult.pkl', numframes=1000):
    sp_orig = copy.copy(sp)
    sp.save_fields = True
    fields = get_unoccult_hyper(fields, numframes=numframes)
    psf_template = np.abs(fields[0, -1, :, 0, 1:, 1:])**2
    if plot:
        view_datacube(psf_template, logAmp=True)
    sp.__dict__ = sp_orig.__dict__
    return psf_template


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


def SDI_each_exposure(obs_sequence, binning=10):
    shape = obs_sequence.shape
    timecube = np.zeros_like(obs_sequence[::binning,0])
    dprint(timecube.shape)
    dprint(obs_sequence.shape)
    idx = np.arange(0,len(obs_sequence),binning)
    for i in range(len(idx)-1):
        timecube[i] = do_SDI(np.mean(obs_sequence[idx[i]:idx[i+1]],axis=0), plot=False)
    # for t in range(shape[0])[:1]:
    #     timecube[t] = do_SDI(obs_sequence[t], plot=True)
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


def make_mosaic_cube(hyper):
    """ I eat other cubes for breakfast """
    moves = np.shape(tp.pix_shift)[0]
    tp.pix_shift = np.array(tp.pix_shift)

    super_obs_sequence = np.zeros((hyper.shape[0] // moves, hyper.shape[1], ap.grid_size, ap.grid_size))
    st = 0

    left = int(np.floor(float(ap.grid_size - mp.array_size[1]) / 2))
    right = int(np.ceil(float(ap.grid_size - mp.array_size[1]) / 2))
    top = int(np.floor(float(ap.grid_size - mp.array_size[0]) / 2))
    bottom = int(np.ceil(float(ap.grid_size - mp.array_size[0]) / 2))

    for t in range(hyper.shape[0]//moves):
        for m in range(moves):
            super_obs_sequence[t,:,
                            left - tp.pix_shift[m][0] : -right - tp.pix_shift[m][0],
                            bottom - tp.pix_shift[m][1] : -top- tp.pix_shift[m][1]] += hyper[st]
            st+=1

    return super_obs_sequence

def eval_method(cube, algo, psf_template, angle_list, algo_dict, fwhm=6, star_phot=1, dp=None):
    dprint(fwhm)
    fulloutput = metrics.contrcurve.contrast_curve(cube=cube, interp_order=2,
                                   angle_list=angle_list, psf_template=psf_template,
                                   fwhm=fwhm, pxscale=tp.platescale/1000, #wedge=(-45, 45), int(dp.lod[0])
                                   starphot=star_phot, algo=algo, nbranch=1,
                                    adimsdi = 'double', ncomp=7, ncomp2=None,
                                   debug=False, plot=False, theta=0, full_output=True, fc_snr=100, dp=dp, **algo_dict)
    plt.show()
    metrics_out = [fulloutput[0]['throughput'], fulloutput[0]['noise'], fulloutput[0]['sensitivity_student'],
                   fulloutput[0]['sigma corr'], fulloutput[0]['distance']]
    metrics_out = np.array(metrics_out)
    return metrics_out, fulloutput[2]

def sum_contrast(cube, algo_dict, fwhm=6, star_phot=1, dp=None):

    algo = pca.pca
    parangles = np.zeros((cube.shape[1]))
    # frame_nofc = algo(cube[0], angle_list=parangles, **algo_dict)
    dprint(cube.shape)
    dprint(parangles)
    # view_datacube(cube[0], logAmp=True, show=False)
    # view_datacube(cube[:,0], logAmp=True)
    frame = pca.pca(cube, angle_list=parangles, scale_list=algo_dict['scale_list'],
                  mask_center_px=None, adimsdi='double', ncomp=7, ncomp2=None,
                  collapse='median')
    # quicklook_im(frame, logAmp=True)
    nannuli = int(np.floor((mp.array_size[0]//2) / fwhm))
    dprint(nannuli)
    contrast = np.zeros((nannuli-1))
    for i, rad in enumerate(range(1, nannuli)):
        mask = get_ell_annulus(frame, rad*fwhm, rad*fwhm, 0, fwhm, mode='mask')
        # quicklook_im(mask)
        contrast[i] = np.var(mask)

    rad_vec = np.arange(1, nannuli)*fwhm
    return contrast, rad_vec


def contrcurve_old(objcube, fwhm=4, star_phot=0.5*10**-1, dp=None):
    wsamples = np.linspace(ap.band[0], ap.band[1], ap.w_bins)
    scale_list = wsamples / (ap.band[1] - ap.band[0])
    algo_dict = {'scale_list': scale_list}
    cont_data = contrast_curve_old(cube=objcube, interp_order=2,
                               fwhm=fwhm, pxscale=tp.platescale/1000,
                               starphot=star_phot, adimsdi = 'double', ncomp=7, ncomp2=None,
                               debug=False, plot=False, dp=dp, **algo_dict)

    return cont_data

def contrcurve(objcube, fwhm=4, star_phot=0.5*10**-1, dp=None):
    wsamples = np.linspace(ap.band[0], ap.band[1], ap.w_bins)
    scale_list = wsamples / (ap.band[1] - ap.band[0])
    algo_dict = {'scale_list': scale_list}
    cont_data = direct_contrast(cube=objcube, interp_order=2,
                               fwhm=fwhm, dp=dp, **algo_dict)

    return cont_data

def direct_contrast(cube, fwhm, interp_order=2, dp=None, **algo_dict):

    algo = pca.pca
    parangles = np.zeros((cube[0].shape[1]))
    mask = dp.QE_map == 0
    frame_nofc = algo(cube[0], angle_list=parangles, **algo_dict)
    frame_fc = algo(cube[1], angle_list=parangles, **algo_dict)

    fcy = np.array([75, 44, 75, 116, 75, 23, 75, 137])
    fcx = np.array([49, 75, 111, 75, 28, 75, 132, 75])
    vector_radd = np.sqrt((fcx-75)**2 + (fcy-75)**2)

    injected_flux = aperture_flux(np.mean(cube[1], axis=(0, 1)), fcy, fcx, np.mean(fwhm), ap_factor=1)
    recovered_flux = aperture_flux(frame_fc, fcy,
                                   fcx, np.mean(fwhm), ap_factor=1,)

    noise_samp, rad_samp = noise_per_annulus(frame_nofc, separation=10,
                                             fwhm=fwhm, init_rad=25, mask=mask)

    plt.plot(injected_flux)
    plt.plot(recovered_flux)
    plt.figure()
    plt.plot(recovered_flux/injected_flux)
    plt.figure()
    plt.plot(rad_samp, noise_samp)
    plt.show(block=True)

    # res_throug = throughput(cube, fwhm, dp=dp, inner_rad=1, **algo_dict)

def throughput(cube, fwhm, dp=None, inner_rad=1, **algo_dict):
    """ Adapted from vip_hci metrics.contrcurve"""

    array = cube
    algo = pca.pca
    parangles = np.zeros((cube[0].shape[1]))
    mask = dp.QE_map == 0

    #***************************************************************************
    # Compute noise in concentric annuli on the "empty frame"

    # frame_nofc = pca.pca(cube[0], angle_list=parangles, scale_list=algo_dict['scale_list'],
    #               mask_center_px=None, adimsdi='double', ncomp=7, ncomp2=None,
    #               collapse='median')
    # quicklook_im(frame_nofc, logAmp=True)

    frame_nofc = algo(array[0], angle_list=parangles, **algo_dict)
    frame_fc = algo(array[1], angle_list=parangles, **algo_dict)
    frame_diffc = algo(array[0] + array[2], angle_list=parangles, **algo_dict)
    # quicklook_im(frame_nofc, logAmp=True, show=False)

    # noise, vector_radd = noise_per_annulus(frame_nofc, separation=fwhm,
    #                                        fwhm=fwhm, mask=mask)
    # vector_radd = vector_radd[inner_rad-1:]
    # noise = noise[inner_rad-1:]

    w, n, y, x = array[0].shape
    if isinstance(fwhm, (int, float)):
        fwhm = [fwhm] * w
    #
    # fcy = np.array([75, 75, 23, 44, 75, 75, 116, 137])
    # fcx = np.array([28, 49, 75, 75, 111, 132, 75, 75])
    # vector_radd = np.sqrt((fcx-75)**2 + (fcy-75)**2)
    # order = np.argsort(vector_radd)
    # fcy = fcy[order]
    # fcx = fcx[order]
    fcy = np.array([75, 44, 75, 116, 75, 23, 75, 137])
    fcx = np.array([49, 75, 111, 75, 28, 75, 132, 75])
    vector_radd = np.sqrt((fcx-75)**2 + (fcy-75)**2)

    dprint((range(cube[1].shape[0]), cube[1].shape, fcy, fcx))
    # injected_flux = np.array([[aperture_flux(cube[1][j,i], fcy, fcx, fwhm[i], ap_factor=1)
    #                   for i in range(cube.shape[2])] for j in range(cube.shape[1])])
    # injected_flux = np.mean(injected_flux, axis=(0,1))
    injected_flux = aperture_flux(np.mean(cube[1], axis=(0,1)), fcy, fcx, np.mean(fwhm), ap_factor=1)
    dprint((injected_flux, injected_flux.shape))
    recovered_flux = aperture_flux(frame_fc, fcy,
                                   fcx, np.mean(fwhm), ap_factor=1,)

    thruput = recovered_flux / injected_flux
    print((injected_flux, recovered_flux, thruput))
    dprint(cube[0].shape)
    # view_datacube(cube[1,0], logAmp=True, show=False)
    # view_datacube(cube[1,:,0], logAmp=True, show=False)

    quicklook_im(np.mean(cube[1], axis=(0,1)), logAmp=True, show=False)
    fig, ax = quicklook_im(frame_fc, logAmp=True, show=False)
    # fig, ax = plt.subplots()
    for xx, yy in zip(fcx, fcy):
        dprint((xx, yy))
        aper = plt.Circle((xx, yy), radius=fwhm[0] / 2, color='r',
                          fill=False, alpha=0.8)
        ax.add_artist(aper)
    plt.show(block=True)
    plt.figure()
    plt.plot(injected_flux)
    plt.plot(recovered_flux)
    plt.figure()
    plt.plot(thruput)
    plt.show(block=True)
    base = 1e-3
    thruput[np.where(thruput < 0)] = base#0

    return (thruput, vector_radd, frame_nofc, frame_diffc)

def contrast_curve_old(cube, fwhm, pxscale, starphot,
                   sigma=5,  transmission=None,
                   interp_order=2, plot=True, debug=False, dp=None, **algo_dict):

    res_throug = throughput(cube, fwhm, dp=dp, inner_rad=1, **algo_dict)

    if not isinstance(fwhm, (int, float)):
        fwhm = np.mean(fwhm)
    dprint(fwhm)
    # for i in range(nbranch):
    #     plt.plot(res_throug[0][i])
    # plt.show(block=True)
    thruput_mean = res_throug[0]
    vector_radd = res_throug[1]
    frame_nofc = res_throug[2]
    # frame_fc = res_throug[3]
    frame_diffc = res_throug[3]

    mask = dp.QE_map == 0

    # noise measured in the empty frame with better sampling, every px
    # starting from 1*FWHM
    noise_samp, rad_samp = noise_per_annulus(frame_nofc, separation=1,
                                             fwhm=fwhm, init_rad=fwhm, mask=mask)
    dprint(noise_samp)
    radmin = vector_radd.astype(int).min()
    cutin1 = np.where(rad_samp.astype(int) == radmin)[0][0]
    noise_samp = noise_samp[cutin1:]
    rad_samp = rad_samp[cutin1:]
    radmax = vector_radd.astype(int).max()
    cutin2 = np.where(rad_samp.astype(int) == radmax)[0][0]
    noise_samp = noise_samp[:cutin2 + 1]
    rad_samp = rad_samp[:cutin2 + 1]

    # plt.figure()
    # plt.plot(thruput_mean)
    # plt.figure()
    # plt.plot(vector_radd)
    # plt.figure()
    # plt.plot(rad_samp)
    # dprint((vector_radd.shape, thruput_mean.shape))
    # plt.show(block=True)


    # interpolating the throughput vector, spline order 2
    f = InterpolatedUnivariateSpline(vector_radd, thruput_mean,
                                     k=interp_order)
    thruput_interp = f(rad_samp)

    # interpolating the transmission vector, spline order 1
    if transmission is not None:
        trans = transmission[0]
        radvec_trans = transmission[1]
        f2 = InterpolatedUnivariateSpline(radvec_trans, trans, k=1)
        trans_interp = f2(rad_samp)
        thruput_interp *= trans_interp

    rad_samp_arcsec = rad_samp * pxscale

    # smoothing the noise vector using a Savitzky-Golay filter
    win = min(noise_samp.shape[0] - 2, int(2 * fwhm))
    if win % 2 == 0:
        win += 1
    noise_samp_sm = savgol_filter(noise_samp, polyorder=2, mode='nearest',
                                  window_length=win)


    # calculating the contrast
    if isinstance(starphot, float) or isinstance(starphot, int):
        cont_curve_samp = ((sigma * noise_samp_sm) / thruput_interp) / starphot
    else:
        cont_curve_samp = (sigma * noise_samp_sm) / thruput_interp
    cont_curve_samp[np.where(cont_curve_samp < 0)] = 1
    cont_curve_samp[np.where(cont_curve_samp > 1)] = 1

    # calculating the Student corrected contrast
    n_res_els = np.floor(rad_samp / fwhm * 2 * np.pi)
    ss_corr = np.sqrt(1 + 1 / (n_res_els - 1))
    sigma_corr = stats.t.ppf(stats.norm.cdf(sigma), n_res_els) * ss_corr
    if isinstance(starphot, float) or isinstance(starphot, int):
        cont_curve_samp_corr = ((sigma_corr * noise_samp_sm) / thruput_interp
                                ) / starphot
    else:
        cont_curve_samp_corr = (sigma_corr * noise_samp_sm) / thruput_interp
    cont_curve_samp_corr[np.where(cont_curve_samp_corr < 0)] = 1
    cont_curve_samp_corr[np.where(cont_curve_samp_corr > 1)] = 1

    if debug:
        plt.rc("savefig")
        plt.figure()
        plt.plot(vector_radd * pxscale, thruput_mean, '.', label='computed',
                 alpha=0.6)
        plt.plot(rad_samp_arcsec, thruput_interp, ',-', label='interpolated',
                 lw=2, alpha=0.5)
        plt.grid('on', which='both', alpha=0.2, linestyle='solid')
        plt.xlabel('Angular separation [arcsec]')
        plt.ylabel('Throughput')
        plt.legend(loc='best')
        plt.xlim(0, np.max(rad_samp * pxscale))
        plt.figure()
        plt.plot(rad_samp_arcsec, noise_samp, '.', label='computed', alpha=0.6)
        plt.plot(rad_samp_arcsec, noise_samp_sm, ',-', label='noise smoothed',
                 lw=2, alpha=0.5)
        plt.grid('on', alpha=0.2, linestyle='solid')
        plt.xlabel('Angular separation [arcsec]')
        plt.ylabel('Noise')
        plt.legend(loc='best')
        plt.xlim(0, np.max(rad_samp_arcsec))

    # plotting
    if plot or debug:
        label = ['Sensitivity (Gaussian)',
                 'Sensitivity (Student-t correction)']


        plt.rc("savefig")
        fig = plt.figure()
        ax1 = fig.add_subplot(111)
        con1, = ax1.plot(rad_samp_arcsec, cont_curve_samp, '-',
                         alpha=0.2, lw=2, color='green')
        con2, = ax1.plot(rad_samp_arcsec, cont_curve_samp, '.',
                         alpha=0.2, color='green')
        con3, = ax1.plot(rad_samp_arcsec, cont_curve_samp_corr, '-',
                         alpha=0.4, lw=2, color='blue')
        con4, = ax1.plot(rad_samp_arcsec, cont_curve_samp_corr, '.',
                         alpha=0.4, color='blue')
        lege = [(con1, con2), (con3, con4)]
        plt.legend(lege, label, fancybox=True, fontsize='medium')
        plt.xlabel('Angular separation [arcsec]')
        plt.ylabel(str(sigma) + ' sigma contrast')
        plt.grid('on', which='both', alpha=0.2, linestyle='solid')
        ax1.set_yscale('log')
        ax1.set_xlim(0, np.max(rad_samp_arcsec))

        if debug:
            fig2 = plt.figure()
            ax3 = fig2.add_subplot(111)
            cc_mags = -2.5 * np.log10(cont_curve_samp)
            con4, = ax3.plot(rad_samp_arcsec, cc_mags, '-',
                             alpha=0.2, lw=2, color='green')
            con5, = ax3.plot(rad_samp_arcsec, cc_mags, '.', alpha=0.2,
                             color='green')
            cc_mags_corr = -2.5 * np.log10(cont_curve_samp_corr)
            con6, = ax3.plot(rad_samp_arcsec, cc_mags_corr, '-',
                             alpha=0.4, lw=2, color='blue')
            con7, = ax3.plot(rad_samp_arcsec, cc_mags_corr, '.',
                             alpha=0.4, color='blue')
            lege = [(con4, con5), (con6, con7)]

            plt.legend(lege, label, fancybox=True, fontsize='medium')
            plt.xlabel('Angular separation [arcsec]')
            plt.ylabel('Delta magnitude')
            plt.gca().invert_yaxis()
            plt.grid('on', which='both', alpha=0.2, linestyle='solid')
            ax3.set_xlim(0, np.max(rad_samp * pxscale))
            ax4 = ax3.twiny()
            ax4.set_xlabel('Distance [pixels]')
            ax4.plot(rad_samp, cc_mags, '', alpha=0.)
            ax4.set_xlim(0, np.max(rad_samp))

    # datafr = {'sensitivity_gaussian': cont_curve_samp,
    #                        'sensitivity_student': cont_curve_samp_corr,
    #                        'throughput': thruput_interp,
    #                        'distance': rad_samp,
    #                        'distance_arcsec': rad_samp_arcsec,
    #                        'noise': noise_samp_sm,
    #                        'sigma corr': sigma_corr}

    return [frame_diffc, rad_samp_arcsec, cont_curve_samp_corr]