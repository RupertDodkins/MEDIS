'''This code scipt handles the photon data once it has passed through the system'''

print 'Depreciated. You should now be running Analysis.phot'
exit()
# import pyfits
import astropy.io.fits as pyfits
import numpy as np
import os
from matplotlib import pyplot as plt
from matplotlib.ticker import MultipleLocator
import sys
# sys.path.append('/Volumes/Data2/dodkins/scripts/')
# from datacube import read_folder
from distribution import *
#import subprocess
import vip_hci as vip
from medis.params import cp, mp, tp#, ap
#import medis.Detector.pipeline as pipe
import temporal
# import MKIDs


plots = vip.var.pp_subplots

def aper_phot(image, inner, outer):
    mask = aperture(np.floor(ynum/2)-1,np.floor(xnum/2), outer)
    # image = image * mask
    if inner > 0:
        in_mask = aperture(np.floor(ynum/2)-1,np.floor(xnum/2), inner)
        in_mask[in_mask==0] = -1
        in_mask[in_mask==1] = 0
        in_mask[in_mask==-1] = 1
        mask = mask*in_mask

    image = image*mask

    # plt.imshow(image)
    # plt.show()

    photometry = np.sum(image)/np.sum(mask)
    return photometry

# def truncate_array(image):
#     '''Make non-square array'''
#     orig_shape = np.shape(image)
#     diff = orig_shape - array_size
#     image = image[:, :-diff[1]]

#     return image

def aperture(startpx,startpy,radius):
    r = radius
    length = 2*r
    height = length
    allx = np.arange(startpx-int(np.ceil(length/2.0)),startpx+int(np.floor(length/2.0))+1)
    ally = np.arange(startpy-int(np.ceil(height/2.0)),startpy+int(np.floor(height/2.0))+1)
    # mask=np.zeros((xnum,ynum))
    mask=np.zeros((xnum,xnum))

    for x in allx:
        for y in ally:
            if (np.abs(x-startpx))**2+(np.abs(y-startpy))**2 <= (r)**2 and 0 <= y and y < xnum and 0 <= x and x < xnum:
                mask[int(y),int(x)]=1.

    mask = truncate_array(mask)
    # plt.imshow(mask)
    # plt.show()
    return mask

def mask_companion(image, startpx, startpy, radius):
    outer = int(np.sqrt((startpx-ynum/2)**2 + (startpy-xnum/2)**2) + radius/2)
    inner = int(np.sqrt((startpx-ynum/2)**2 + (startpy-xnum/2)**2) - radius/2)

    print startpx, xnum, ynum, outer, inner
    mask = aperture(np.floor(ynum/2)-1,np.floor(xnum/2), outer)
    # image = image * mask
    if inner > 0:
        in_mask = aperture(np.floor(ynum/2)-1,np.floor(xnum/2), inner)
        in_mask[in_mask==0] = -1
        in_mask[in_mask==1] = 0
        in_mask[in_mask==-1] = 1
        mask = mask*in_mask

    annulus = image*mask

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

    annulus_mean = np.sum(annulus)/ np.sum(mask)
    print annulus_mean

    comp_mask = np.int_(comp_mask)

    image[comp_mask==1] = annulus_mean
    plt.imshow(image)
    plt.show()

    return image


def do_SDI(datacube, plot=False):
    wsamples = np.linspace(tp.band[0], tp.band[1], tp.nwsamp)
    scale_list = tp.band[0]/wsamples
    print scale_list
    fr_pca1 = np.abs(vip.pca.pca(datacube, angle_list = np.zeros((len(scale_list))), scale_list=scale_list, mask_center_px=None))
    if plot:
        plots(fr_pca1)    

    return fr_pca1

def make_SNR_plot(datacube):
    '''No clever datareduction done here yet, just looking at a few frames and the PCA'''
    fr_pca1 = do_SDI(datacube)
    # fr_pca1 = np.abs(vip.pca.pca(frames, angle_list = np.zeros((cp.numframes)), scale_list=np.ones((cp.numframes)), mask_center_px=None))

    blue = datacube[0]
    bolometric = np.sum(datacube, axis = 0)

    sep = np.arange(mp.nlod)+1
    sepAS = (sep*0.025*2)/8

    #pixel coords of center of images
    centerx=int(mp.xnum/2)
    centery=int(mp.ynum/2)
    norm = 1. #center intensity hard coded for now

    images = [fr_pca1, blue, bolometric]
    labels = ['SDI', 'Blue', 'Bolometric']

    '''This function is untested but should work'''
    # make_cont_plot(images, labels)

    radii = np.arange(mp.nlod)+1
    psfMeans = np.zeros((len(images),len(radii)))

    for ir, r in enumerate(radii):
        for im, image in enumerate(images):
            psf_an = vip.phot.snr_ss(image,(centerx+r*mp.lod,centery), fwhm=mp.lod, plot=False,seth_hack=True)
            psfMeans[im, ir] = psf_an[3]

    fig,ax1 = plt.subplots()
    for im in range(len(images)):
        ax1.plot(sep,psfMeans[im]/norm,linewidth=2,label=r'%s'%labels[im], alpha=0.7)

    # ax1.set_xlim([10**-8,10**-1])
    # ax1.errorbar(sep,spMeans/norm,yerr=spStds/norm,linestyle='-.',linewidth=2,label=r'Mean Coronagraphic Raw Contrast')
    # ax1.errorbar(sep,psfMeans/norm+5*psfStds/norm,linewidth=2,label=r'5-$\sigma$ Unocculted PSF Contrast')
    # ax1.errorbar(sep,spMeans/norm+5*spStds/norm,linestyle='-.',linewidth=2,label=r'5-$\sigma$ Coronagraphic Raw Contrast')

    ax1.axvline(x=2,linestyle='--',color='black',linewidth=2,label = 'FPM Radius')
    ax1.set_xlabel(r'Separation ($\lambda$/D)',fontsize=14)
    ax1.set_ylabel(r'Contrast',fontsize=14)
    #ax1.set_xlim(1,12)
    # ax1.set_ylim(1e-9,0.1)
    ax1.set_yscale('log')

    ax2 = ax1.twiny()
    ax2.plot(sepAS,psfMeans[0],alpha=0)
    ax2.set_xlabel(r'Separation (as)',fontsize=14)

    ax1.legend()
    plt.show()

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

def make_cont_plot(images, labels, sigma = 5, norms=None, student=True):
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
    print len(radii)
    # for ir, r in enumerate(radii):

    for im, image in enumerate(images):
        noise_samp, rad_samp = vip.phot.noise_per_annulus(image, separation=1, fwhm=fwhm,
                                                          init_rad=fwhm, wedge=(0, 360))
        # curves[im] = noise_samp / (50e6 * 1000 * norms[im])  # star brightness 1000 x less with coron
        curves[im] = noise_samp / (50e6 *10 * norms[im])  # star brightness 1000 x less with coron

    from scipy import stats
    if student:
        n_res_els = np.floor(rad_samp/fwhm*2*np.pi)
        ss_corr = np.sqrt(1 + 1/(n_res_els-1))
        sigma = stats.t.ppf(stats.norm.cdf(sigma), n_res_els)*ss_corr
    print 'sigma', sigma

    fig, ax1 = plt.subplots()
    for im in range(len(images)):
        curves[im] = curves[im]*sigma
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
    print mp.lod
    # plt.show()

def make_SNR_plot(images, labels):
    '''No clever datareduction done here yet, just looking at a few frames and the PCA'''

    sep = np.arange(1, mp.nlod + 1)  # +1
    sepAS = (sep * 0.025 * 2) / 8

    # pixel coords of center of images
    centerx = int(mp.xnum / 2)
    centery = int(mp.ynum / 2)
    print centerx
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

def SDI_each_exposure(obs_sequence):
    shape = obs_sequence.shape
    timecube = np.zeros_like(obs_sequence[0])
    for t in range(shape[0])[:1]:
        timecube[t] = do_SDI(obs_sequence[t], plot=True)
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