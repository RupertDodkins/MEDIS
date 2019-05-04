# import pyfits
# import astropy.io.fits as pyfits
import numpy as np
import os
from matplotlib import pyplot as plt
from matplotlib.ticker import MultipleLocator
import sys
# sys.path.append('/Volumes/Data2/dodkins/scripts/')
# from cubes import read_folder
from .distribution import *
#import subprocess
from medis.params import mp, cp, tp, ap
import math
# import cubes
#import dynamic_cube_v2 as dc
# import MKIDs as MKIDs
import pickle
from scipy.interpolate import interp1d
np.set_printoptions(threshold=np.inf)
from medis.Utils.misc import dprint

# def read_time_images(location):
#     filenames = cubes.read_folder(location)
#     # print filenames
    
#     input_shape = np.shape(cubes.read_image(filenames[0]))
#     frames=np.zeros((len(filenames), input_shape[0], input_shape[1]))

#     for ifn, filename in enumerate(filenames):
#         # cube = cubes.datacube()
#         frames[ifn] = cubes.read_image(filename)

#     return frames

# def cut_during_read(location, array_size=np.array([250,160])):
#     filenames = cubes.read_folder(location)
#     print filenames, len(filenames)

#     frames=np.zeros((len(filenames), array_size[0], array_size[1]))
#     def truncate_frame(frame):
#         orig_shape = np.shape(frame)
#         diff = orig_shape - array_size
#         resid = np.array([np.int_(np.ceil(diff/2.)), np.int_(np.floor(diff/2.))])
#         frame = frame[resid[0,0]:orig_shape[0]-resid[1,0], resid[0,1]:orig_shape[1]-resid[1,1]]
#         return frame

#     for ifn, filename in enumerate(filenames):
#         # cube = cubes.datacube()
#         temp_frame = cubes.read_image(filename)
#         frames[ifn] = truncate_frame(temp_frame)

#     frames = frames[:,::2, ::2]
# #    print np.shape(frames), frames
#     return frames

def downsample(LCmap, factor=2):
    size = LCmap.shape
    newmap = np.zeros((size[0],size[1],int(size[2]/factor)))

    for inew,iorig in enumerate(range(0,size[2],factor)):
        newmap[:,:,inew] = np.sum(LCmap[:,:,iorig:iorig+factor],axis=2)

    return newmap

def uniform_cube():
    frames = np.ones((1000,xnum,ynum))
    return frames

def plot_pix_hist(frames):
    for i in [0,25,50,75]:
        for j in [0,25,50,75]:
            print(i, j)
            plt.hist(frames[:,i,j], bins='auto', alpha =0.5)#'auto'
            plt.show()

def show_time_spat(frames):
    plt.imshow(frames[:,0,:], aspect='auto', interpolation='none')
    plt.show()

def create_PDFs(frames):
    res_elements = 25
    PDFs = np.zeros((res_elements, array_size[0], array_size[0]))
    for x in range(array_size[0]):
        for y in range(array_size[1]):
            PDFs[:,x,y], _ = np.histogram(frames[x,y], bins=np.linspace(0,1,res_elements+1))
            plt.plot(PDFs[:,x,y])
            plt.show()
    print(np.shape(PDFs))

def sample_cube(datacube, num_events):
    # print 'creating photon data from reference cube'

    # dist = Distribution(datacube, interpolation=mp.interp_sample)
    # if mp.interp_sample:
    #     wave_samps = np.linspace(0, 1, ap.nwsamp)
    #     f_out = interp1d(wave_samps, datacube, axis=0)
    #     new_heights = np.linspace(0, 1, ap.w_bins)
    #     datacube = f_out(new_heights)
    #     dprint(datacube.shape)

    # dist = Distribution(datacube, interpolation=mp.interp_sample)
    dist = Distribution(datacube, interpolation=True)

    photons = dist(num_events)
    # photons[1:3] = np.round_(photons[1:3])
    return photons

def eff_exposure(cube, start = 0, exp=20.*ap.sample_time):
    image = np.zeros((xnum,ynum))
    for x in range(xnum):
        for y in range(ynum):
            events = np.array(cube[x][y])
            # print events
            try:
                begin = np.where(events > start)[0][0]
                end = np.where(events > (start + exp))[0][0]
                image[x,y] = end-begin
            except IndexError:
                image[x,y] = 0
    print('sum', np.sum(image))
    return image

def assign_calibtime(photons, step):
    time = step*ap.sample_time
    print(time, 'time')
    # photons = photons.astype(float)#np.asarray(photons[0], dtype=np.float64)
    # photons[0] = photons[0] * ps.mp.frame_time
    photons = np.vstack((np.ones_like(photons[0])*time,photons))
    return photons



# if __name__ == "__main__":
#     if os.path.isfile('obs.pkl'):
#         with open('obs.pkl', 'rb') as obs:
#             packets = cPickle.load(obs)

#     else:
#         frames = read_time_images(datadir)
#         # frames = MKIDs.truncate_array(frames)

#         # frames = cut_during_read(datadir)
#         print np.shape(frames)
#         # frames = MKIDs.bad_feedline(frames)

#         # cubes.frame_look(frames, 0)
#         # if ps.mp.bad_pix == True:
#         response = MKIDs.array_response()

#         cubes.loop_frames(frames)
#         response = MKIDs.create_bad_pix(response)
#         response = MKIDs.create_bad_pix_center(response)

#         plt.imshow(response, interpolation='none')
#         plt.show()
#         exit()
#         frames = MKIDs.remove_bad(frames, response)

#         Rs = MKIDs.assign_spectral_res()

        
#         photons = sample_cube(frames, 5000000)

#         photons = assign_time(photons)

#         packets=[]
#         for ip, photon in enumerate(photons.T):
#             if ip%10000 ==0: progressBar(value = ip, endvalue=5000000)
#             R = Rs[int(photon[1]), int(photon[2])]
#             pix_background = MKIDs.get_phase_background(R, 1)
#             # print pix_background
#             pix_response = photon_phase*response[int(photon[1]), int(photon[2])]
#             # print pix_response
#             if pix_background + pix_response < threshold_phase:#photon[3]
#                 #print 'photon detected'
#                 packet = cubes.make_packet([photon[1], photon[2]], photon[0])
#                 packets.append(packet)
#         print packets[:50]
#         #exit()
#         with open('obs.pkl', 'ab') as obs:
#             cPickle.dump(packets, obs)
#     # exit()
#     cube = cubes.arange_into_cube(packets)
#     # cube = remove_close_photons(cube)

#     # print cube
#     frames = np.zeros((9, xnum, ynum))
#     for f in range(9):
#         frames[f] = eff_exposure(cube, start = f*0.001, exp=0.001)

#     # cubes.loop_frames(frames)

#     cubes.plot_pix_time(cube, 40, 62)
#     cubes.plot_pix_time(cube, 40, 42)
#     cubes.plot_pix_time(cube, 40, 22)
    
#     image = cubes.make_intensity_map(cube)
#     # cubes.saveFITS(image)
#     # cubes.make_energy_map(cube)

#     frames2 = np.zeros((2,xnum, ynum))
#     for f in range(2):
#         frames2[f] = eff_exposure(cube, start = f*0.01, exp=0.01)    

#     # cubes.loop_frames(frames)

#     image2 = np.abs(frames2[1] - frames2[0])
#     plt.imshow(image2)
    
#     plt.show()
#     import vip

#     fr_pca1 = np.abs(vip.pca.pca(frames, angle_list = np.zeros((9)), scale_list=np.ones((9)), mask_center_px=None))
#     plt.imshow(fr_pca1)

#     print sep
#     print sepAS


#     psfMeans = []
#     psfStds = []
#     psfSNRs = []
#     psfMeans2 = []
#     psfStds2 = []
#     psfSNRs2 = []

#     for i in np.arange(nlod)+1:
#         psf_an = vip.phot.snr_ss(fr_pca1,(centerx+i*lod,centery), fwhm=lod,plot=False,seth_hack=True)
#         psfMeans.append(psf_an[3])
#         psfStds.append(psf_an[4])
#         psfSNRs.append(psf_an[5])

#         psf_an2 = vip.phot.snr_ss(image,(centerx+i*lod,centery), fwhm=lod,plot=False,seth_hack=True)
#         psfMeans2.append(psf_an2[3])
#         psfStds2.append(psf_an2[4])
#         psfSNRs2.append(psf_an2[5])



#     psfMeans = np.array(psfMeans)
#     psfStds = np.array(psfStds)
#     psfSNRs = np.array(psfSNRs)
#     psfMeans2 = np.array(psfMeans2)
#     psfStds2 = np.array(psfStds2)
#     psfSNRs2 = np.array(psfSNRs2)

#     print psfMeans/norm, psfMeans2/norm, psfMeans/(norm*10)

#     fig,ax1 = plt.subplots()
#     ax1.plot(sep,psfMeans2/norm,linewidth=2,label=r'Integrated')
#     ax1.plot(sep,psfMeans/norm,linewidth=2,label=r'Differential Imaging')
#     ax1.plot(sep,psfMeans/(norm*10),linewidth=2,label=r'DI + SSD')
#     # ax1.set_xlim([10**-8,10**-1])
#     # ax1.errorbar(sep,spMeans/norm,yerr=spStds/norm,linestyle='-.',linewidth=2,label=r'Mean Coronagraphic Raw Contrast')

#     # ax1.errorbar(sep,psfMeans/norm+5*psfStds/norm,linewidth=2,label=r'5-$\sigma$ Unocculted PSF Contrast')
#     # ax1.errorbar(sep,spMeans/norm+5*spStds/norm,linestyle='-.',linewidth=2,label=r'5-$\sigma$ Coronagraphic Raw Contrast')

#     ax1.axvline(x=2,linestyle='--',color='black',linewidth=2,label = 'FPM Radius')
#     ax1.set_xlabel(r'Separation ($\lambda$/D)',fontsize=14)
#     ax1.set_ylabel(r'Contrast',fontsize=14)
#     #ax1.set_xlim(1,12)
#     ax1.set_ylim(1e-9,0.1)
#     ax1.set_yscale('log')

#     ax2 = ax1.twiny()
#     ax2.plot(sepAS,psfMeans/(norm*10),alpha=0)
#     ax2.set_ylim(1e-9,0.1)
#     ax2.set_xlabel(r'Separation (as)',fontsize=14)

#     ax1.legend()

#     plt.show()

#         # plt.show()
