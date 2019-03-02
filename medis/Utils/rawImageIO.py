# -*- coding: utf-8 -*-

'''This script contains the functions for FITS file and raw image manipulations'''

import numpy as np
from glob import glob
import astropy.io.fits as pyfits
import re, os
# from matplotlib import pyplot as plt
# from matplotlib.ticker import MultipleLocator
import pickle as pickle
from medis.Detector.distribution import *
from medis.params import mp, cp
import medis.Utils.misc as misc

def read_folder(wvlFrames_dir = '/Volumes/Data2/dodkins/FITS files/Wvl Frames (corrected) 26th March/',
                width = 147, height = 144, out_folder = '../FITS files/neb-20141021-cube.fits',
                savecube=True):
    """
    Created on Tue Nov 13 15:05:36 2012
    @author: stuart
    Problem from SunPy mailing list. Save a MASSIVE array to a fits file
    """

    numbers = re.compile(r'(\d+)')
    def numericalSort(value):
        parts = numbers.split(value)
        parts[1::2] = list(map(int, parts[1::2]))
        return parts 

    #wvlFrames_dir = '/Volumes/Data2/dodkins/FITS files/Wvl Frames (corrected) 26th March/'
    
    files = sorted(glob(wvlFrames_dir+"*fits"), key=numericalSort)

    n = len(files)
     
    return files 

def read_image(filename = 'focalplane_1.fits', prob_map=True):
    #hdulist = pyfits.open(directory + filename)
    hdulist = pyfits.open(filename)
    header = hdulist[0].header
    scidata = hdulist[0].data

    xnum = np.shape(scidata)[0]
    ynum = np.shape(scidata)[1]

    if prob_map:
        correction_factor = 1/np.max(scidata) #* 10
        #print correction_factor
        prob_array = scidata * correction_factor
        #print prob_array, np.shape(prob_array)
        return prob_array
    
    else:
        return scidata*1., header

def add_header(self, fromfile = 'telescope_obj1.fits', tofile='telescope_obj_p0.fits'):
    os.chdir('/home/dodkins/')
    hdu = pyfits.open(fromfile)
    hdr = hdu[0].header
    if fromfile == tofile: print(fromfile == tofile)
    hdu = pyfits.open(tofile, mode='update')
    scidata = hdu[0].data
    pyfits.update(tofile, scidata, hdr,0)
    print(hdu[0].header)
    print('done')

def save_wf(wf, filename):
    with open(filename, 'wb') as handle:
        pickle.dump(wf, handle, protocol=pickle.HIGHEST_PROTOCOL)

def load_wf(filename):
    with open(filename, 'rb') as handle:
        wf = pickle.load(handle)
    return wf

#pyfits.update(outFile, scidata, header,0)
#print '%s created' % outFile

# def make_packet(basesDeg, phases, timestamp, Id, xCoord, yCoord):
# # def make_packet(loc,toa,p=80):
#     '''If used alone assumes 100% QE '''
#     packet = np.append(loc,[toa,p], axis=0)
#     # packet {'loc': loc, 'toa': toa, 'phase': p, 'bg', p/10}
#     return packet

def resize_image(image, newsize=(125,125), warn=True):
    if warn:
        print('Using interpolation to resample wavefront - may lead to uncertainties')
    import skimage.transform
    newimage = skimage.transform.resize(image, newsize)
    return newimage


def clipped_zoom(img, zoom_factor, **kwargs):
    from scipy.ndimage import zoom
    h, w = img.shape[:2]

    # For multichannel images we don't want to apply the zoom factor to the RGB
    # dimension, so instead we create a tuple of zoom factors, one per array
    # dimension, with 1's for any trailing dimensions after the width and height.
    zoom_tuple = (zoom_factor,) * 2 + (1,) * (img.ndim - 2)

    # Zooming out
    if zoom_factor < 1:

        # Bounding box of the zoomed-out image within the output array
        zh = int(np.round(h * zoom_factor))
        zw = int(np.round(w * zoom_factor))
        top = (h - zh) // 2
        left = (w - zw) // 2

        # Zero-padding
        out = np.zeros_like(img)
        out[top:top+zh, left:left+zw] = zoom(img, zoom_tuple, **kwargs)

    # Zooming in
    elif zoom_factor > 1:

        # Bounding box of the zoomed-in region within the input array
        zh = int(np.round(h / zoom_factor))
        zw = int(np.round(w / zoom_factor))
        top = (h - zh) // 2
        left = (w - zw) // 2
        from medis.Utils.plot_tools import quicklook_im
        out = zoom(img[top:top+zh, left:left+zw], zoom_tuple, **kwargs)
        # quicklook_im(out, logAmp=True)
        # `out` might still be slightly larger than `img` due to rounding, so
        # trim off any extra pixels at the edges
        trim_top = ((out.shape[0] - h) // 2)
        trim_left = ((out.shape[1] - w) // 2)
        # print top, zh, left, zw
        # print out.shape[0], trim_top, h, trim_left, w
        if trim_top < 0 or trim_left < 0:
            temp = np.zeros_like(img)
            temp[:out.shape[0],:out.shape[1]] = out
            out = temp
        else:
            out = out[trim_top:trim_top+h, trim_left:trim_left+w]
        # quicklook_im(out, logAmp=False)
    # If zoom_factor == 1, just return the input array
    else:
        out = img

    # import matplotlib.pyplot as plt
    # plt.hist(out.flatten(), bins =100, alpha =0.5)
    # plt.hist(img.flatten(), bins =100, alpha=0.5)
    # plt.show()

    print(np.sum(img), np.sum(out))
    # out = out*np.sum(img)/np.sum(out)
    # out = out*4
    return out

def get_MR_pdf():
    res_elements = 1000
    I = np.linspace(0.1, 200, res_elements)

    ratios = [2]#[0,0.5,1,2,7]
    for ratio in ratios:
        Is = 10
        pdf = MR(Is*ratio,Is,I)
        pdf = pdf/ np.sum(pdf)

    return pdf

# def plot_pix_time(cube, x=50, y=50):
#     plt.figure()
#     print cube[x][y], np.shape(cube[x][y])
#     hist, bins = np.histogram(cube[x][y], bins='auto')
#     #plt.xlabel('Time ms')
#     #plt.plot(bins[:-1], hist)

def saveFITS(image, name):
    header = pyfits.Header()
    header["PIXSIZE"] = (0.16, " spacing in meters")

    hdu = pyfits.PrimaryHDU(image, header=header)
    hdu.writeto(name)

def scale_image(filename, scalefactor):
    scidata, hdr = read_image(filename, prob_map=False)
    scidata = scidata*scalefactor
    pyfits.update(filename, scidata, hdr,0)

# def scale_phasemaps():
#     filenames = read_folder(iop.atmosdir)
#     scidata, hdr = read_image(filenames[0], prob_map=False)
#     scalefactor = np.pi/np.max(np.abs(scidata)) * 2./3 #kludge for now until you include AO etc
#     print 'Scaling the phase maps by a factor %s' % scalefactor

#     for ifn, filename in enumerate(filenames):
#         # scidata, hdr = read_image(filename, prob_map=False)
#         # scidata = scidata*scalefactor
#         # pyfits.update(filename, scidata, hdr,0)
#         scale_image(filename, scalefactor)
#         if ifn%100 ==0: misc.progressBar(value = ifn, endvalue=len(filenames))

# def makeFrameFITS(self,frame, fn):
#     if os.path.isfile(fn)==True:
#         os.remove(fn)
#         print '%s removed' % fn
#     hdu = pyfits.PrimaryHDU(frame)
#     hdu.writeto(fn)
#     print "Made %s" % fn

# def plot_hist(self,data):
#     plt.hist(data)
#     plt.xlabel("Probability")
#     plt.ylabel("Amount")
#     plt.show()

# def make_time_cube_frame(self,t_frames,plot=False):
#     # essentially sends a wave of photons at the same time (not ideal)
#     image = np.zeros((xnum,ynum))
#     #[ [frame[x,y] + 1 for x in range(xnum)] for y in range(ynum) if seeds[x,y] <= prob_array[x,y] ]
#     iterations = 100
#     #for iteration in iterations
#     for frame in range(t_frames):
#         seeds = np.random.rand(xnum,ynum)
#         #seeds = np.zeros((xnum,ynum))
#         for x in range(xnum):
#             for y in range(ynum):
#                 if seeds[x,y] <= prob_array[x,y]:
#                     image[x,y] =  image[x,y] +1

#     if plot == True:
#         plt.matshow(image)
#         plt.show()

#     return image

# def send_photon(plot=False):
#     # like make_time_frame except photons arrive at random times as well as location (one is possibly redundant)
#     # the only way to do this I think is parrallel calculations using something like subprocess
#     image = np.zeros((xnum,ynum))
#     #seeds = np.random.rand(xnum,ynum)
#     max_counts = 1000
#     count_array = prob_array * max_counts
#     max_pix = np.where(count_array == count_array.max())
#     while image[ max_pix[0], max_pix[1] ] < max_counts:
#         rand_event_specifier = float(np.random.random(1))
#         seeds = np.random.rand(xnum,ynum)
#         for x in range(xnum):
#             for y in range(ynum):
# #               print x,y
#                 if rand_event_specifier <= prob_array[x,y]:
#                     #print x,y, prob_array[x,y], rand_event_specifier, seeds[x,y]
#                     if seeds[x,y] <= prob_array[x,y]:#np.ones((xnum,ynum))[x,y]/2:
# #                       print x,y, seeds[x,y,]
#                         image[x,y] =  image[x,y] +1
#     if plot == True:
#         plt.matshow(image)
#         plt.show()

# def make_time_cube():
#     ''' uses make_time_cube_frame() '''
#     save_tmp = np.zeros((t_frames,xnum,ynum))

#     exposure_time = 10
#     for frame_no in range(t_frames):
#         frame = make_time_cube_frame(frame_no*exposure_time)
#         save_tmp[frame_no] = frame

#     print "saving"
#     hdu = pyfits.PrimaryHDU(save_tmp)
#     hdulist = pyfits.HDUList([hdu])
#     fn = '/home/dodkins/Documents/proper/examples/cube.fits'
#     if os.path.isfile(fn)==True:
#         os.remove(fn)
#         print '%s removed' % fn
#     hdulist.writeto(fn)

# def make_wavelength_cube(self):
#     read_folder('../test/',100,100,'./cube_test.fits')

# def make_rotation_cube(self):
#     read_folder('../rotation/',100,100,'./cube_rotation.fits')

# def blend_between_frames(self, frame1name = 'focalplane1.fits', frame2name= 'focalplane2.fits', seed=True, savecube=True):
#     # Creates the time frames based on the evolution of the speckles and creates a cube if specified

#     frame1 = read_image(frame1name) #* central_count_rate/t_frames
#     frame2 = read_image(frame2name) #* central_count_rate/t_frames
#     print type(frame1), type(xnum), type(ynum)

#     av_counts = sum(sum(frame1))/(xnum*ynum)
#     iterations=100
#     if seed: difference = (frame2 - frame1)/(t_frames * iterations)
#     else: difference = (frame2 - frame1)/(t_frames)
#     save_tmp = np.zeros((t_frames,xnum,ynum))

#     image = frame1

#     for frame in range(t_frames):
#         if seed:
#             for iteration in range(iterations):
#                 seeds = np.random.rand(xnum,ynum)*av_counts
#                 events_table = seeds < frame2
#                 image[events_table] =  image[events_table] + difference[events_table]
#                 #image = image + difference
#             save_tmp[frame] = image

#         else:
#             image =  image + difference
#             save_tmp[frame] = image

#         if not savecube:
#             makeFrameFITS(save_tmp[frame], '/home/dodkins/Documents/proper/examples/telescope_obj_p%i.fits' % frame)
#             add_header(tofile = '/home/dodkins/Documents/proper/examples/telescope_obj_p%i.fits' % frame)
#     if savecube:
#         print "saving"
#         hdu = pyfits.PrimaryHDU(save_tmp)
#         hdulist = pyfits.HDUList([hdu])
#         fn = '/home/dodkins/Documents/proper/examples/blend_cube.fits'
#         if os.path.isfile(fn)==True:
#             os.remove(fn)
#             print '%s removed' % fn
#         hdulist.writeto(fn)

#     return save_tmp


# def make_evolving_obs_sequence(self):
#     #creates a hyper cube based on wavelength and speckle evolution only. No rotation
#     print 'obj/focalplane_%s.fits' % str(5*2 + 70)
#     read_image()

#     obs_sequence = np.zeros((w_frames,t_frames,xnum,ynum))
#     for w in range(w_frames):
#         obs_sequence[w,:,:,:] = blend_between_frames('obj/focalplane_%s.fits' % (5*w + 70), 'obj1/focalplane_%s.fits' % str(5*w + 70), False, False )
#         #obs_sequence[w,:,:,:] = make_rotation_cube()

#     print "saving"
#     hdu = pyfits.PrimaryHDU(obs_sequence)
#     hdulist = pyfits.HDUList([hdu])
#     fn = '/home/dodkins/Documents/proper/examples/hypercube.fits'
#     if os.path.isfile(fn)==True:
#         os.remove(fn)
#         print '%s removed' % fn
#         hdulist.writeto(fn)
#     else: hdulist.writeto(fn)

# def make_rotating_obs_sequence(self):
#     #creates a hyper cube based on wavelength and rotation
#     wave_slices = 7
#     time_slices = 41

#     read_image()
#     obs_sequence = np.zeros((wave_slices,time_slices,xnum,ynum))
#     save_tmp= []
#     #for i,fname in enumerate(files):
#     #    fits = pyfits.open(fname)
#     #    save_tmp[i] = fits[0].data
#     #    fits.close()#

#     os.chdir('/home/dodkins/Documents/proper/hypercube')

#     for w in range(wave_slices):
#         for t in range(time_slices):
#             fname = 'focalplane_%.2f_%.2f.fits' % (w*0.1 + 0.7, round(t*0.833/40 * 100)/100)
#             print w,t, fname
#             fits = pyfits.open(fname)
#             print 'data ', fits[0].data[50,50]
#             obs_sequence[w,t,:,:] = fits[0].data

#             print 'obs_sequence ', obs_sequence[w,t,50,50]
#             #fits.close()
#         #read_folder('../hypercube/',100,100,'./obs_sequence_rotation.fits', savecube=False)

#     print np.shape(obs_sequence)
#     #obs_sequence = np.zeros((w_frames,t_frames,xnum,ynum))
#     #for w in range(w_frames):
#     # obs_sequence[w,:,:,:] = blend_between_frames('obj/focalplane_%s.fits' % (5*w + 70), 'obj1/focalplane_%s.fits' % str(5*w + 70), False, False )
#         #obs_sequence[w,:,:,:] = make_rotation_cube()

#     print "saving"
#     hdu = pyfits.PrimaryHDU(obs_sequence)
#     hdulist = pyfits.HDUList([hdu])
#     fn = '/home/dodkins/Documents/proper/hypercube/hypercube.fits'
#     if os.path.isfile(fn)==True:
#         os.remove(fn)
#         print '%s removed' % fn
#         hdulist.writeto(fn)
#     else: hdulist.writeto(fn)

# if __name__ == "__main__":
#     # DC = datacube()
#     num_events = 10000

#     prob_array = read_image(datadir+'focalplane_telescope_obj1.fits')

#     print 'plotting'
#     # plt.imshow(prob_array)
#     # plt.show()

#     dist = Distribution(prob_array, interpolation=False)
#     locs = dist(num_events)

#     pdf = get_MR_pdf()
#     dist = Distribution(pdf, interpolation=True)
#     toas = dist(num_events)[0]

#     fig = plt.figure()
#     ax = fig.add_subplot(111)
#     ax.scatter(*locs)
#     packets = []
#     for loc, toa in zip(locs.T, toas):
#         packet = make_packet(loc,toa)
#         packets.append(packet)

#     # with open('obs.pkl', 'ab') as obs:
#     #     pickle.dump(packets, obs)

#     cube = arange_into_cube(packets)
#     make_intensity_map(cube)

#     # spacing = 1
#     # minorLocator = MultipleLocator(spacing)
#     # ax.xaxis.set_minor_locator(minorLocator)
#     # ax.yaxis.set_minor_locator(minorLocator)
#     # ax.grid(which='minor')

#     plt.show()
