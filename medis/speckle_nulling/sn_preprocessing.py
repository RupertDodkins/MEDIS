# import ipdb
import matplotlib.pyplot as plt
import numpy as np
import os
import astropy.io.fits as pf
# import image_registration as imreg
from scipy.ndimage import median_filter
from scipy.special import gamma
from scipy.optimize import curve_fit
import scipy.ndimage as sciim
import sn_math as snm

def linearize_and_align(image):
    """Not used: apply Stan Metchev's distortion correction to PHARO"""
    coeff=np.array([[0.9994,0.56e-7,-2.70e-11],  
                    [1.0033,-6.60e-7,-9.80e-12], 
                    [1.0010, -3.42e-7, -1.72e-11], 
                    [1.0011,-5.15e-7,-1.29e-11]])

def poissfunc(x, mu):
    """Poisson distribution"""
    return np.exp(-1*mu)*mu**(x)/gamma(x+1)

def gaussfunc(x,  mu, sig):
    """1-d Gaussian x, mu, sigma"""
    return (1.0/(sig*np.sqrt(2*np.pi))*
            np.exp(-(x-mu)**2/(2*sig**2)))

def combine_quadrants(image):
    """Take the 4 quadrants of PHARO and tile them as a single image of 1024x1024.
       Pass the raw fits data which is 4x512x512"""
    quad1=(image[0].data)[0,:,:]
    quad2=(image[0].data)[1,:,:]
    quad3=(image[0].data)[2,:,:]
    quad4=(image[0].data)[3,:,:]
    
    toprow=np.hstack((quad2, quad1))
    bottomrow=np.hstack((quad3, quad4))
    returnimage=np.vstack((toprow, bottomrow))
    #nb--in the reduction pipeline the following is commnented in 
    #in this program WYSIWYG with PHARO;s monitor
    #returnimage = returnimage[:,::-1]    
    return returnimage

def locate_badpix(data, sigmaclip = 5):
    """locates bad pixels by fitting a gaussian distribution to the 
       image intensity and then cutting outliers at the level of 'sigmaclip'"""
    xvals = np.arange(data.min(), data.max())
    yvals = np.histogram(data.ravel(), bins=xvals, density=True)[0]
    m1 = np.abs(np.cumsum(yvals)-0.0005).argmin()
    m2 = np.abs(np.cumsum(yvals)-0.9995).argmin()
    popt, pcov = curve_fit(gaussfunc, xvals[m1:m2], yvals[m1:m2], 
        p0 =( (0.5*(xvals[m1]+xvals[m2]),
               25 )))
    mean  = popt[0]
    stddev=(popt[1])
    cliplevel = sigmaclip*np.abs(stddev)
    cliphigh  = mean+cliplevel
    cliplow   = mean - cliplevel
    bpmask = np.round(data>cliphigh)+np.round(data<cliplow)
    plt.plot(xvals[0:-1], yvals)
    #plt.xlim((-10*cliplevel, 10*cliplevel))
    plt.plot(xvals[0:-1], gaussfunc(xvals[0:-1], *popt))
    plt.axvspan(cliplow, cliphigh, alpha=0.2, color='grey')
    plt.show()
    return np.array(bpmask, dtype=np.float32)

def histeq(im,nbr_bins=256):
    """histogram equalize an image"""
    #get image histogram
    im = np.abs(im)
    imhist,bins = np.histogram(im.flatten(),nbr_bins,normed=True)
    cdf = imhist.cumsum() #cumulative distribution function
    cdf = 255 * cdf / cdf[-1] #normalize

    #use linear interpolation of cdf to find new pixel values
    im2 = np.interp(im.flatten(),bins[:-1],cdf)

    return im2.reshape(im.shape)

def equalize_image(data, bkgd=None, masterflat=None, badpix=None):
     """removes bad pixels from data, remove bad pixels from background,
       subtracts the two, and divides by the master flat field"""
    #return removebadpix(data-bkgd, badpix)/masterflat
     return removebadpix(data-bkgd, badpix)/masterflat

#def removecosmicrays(data):
#    im = cosmics.cosmicsimage(data, readnoise = 10, gain =1)
#    im.run(verbose = False, maxiter = 3)
#    return im.cleanarray

def removebadpix(data, mask, kernelsize = 5):
    """removes bad pixels by replacing them with a 5x5 kernel median filter
       of the image where they exist"""
    data1=data.copy()
    medianed_image = median_filter(data, 
                            size=(kernelsize, kernelsize), 
                            mode='wrap')
    data1[np.where(mask>0)] = medianed_image[np.where(mask>0)]
    return data1

def buildcube(filelist):
    """Takes a file list (of fits files) and constructs a single
       data cube out of them"""
    xyshape = np.shape(pf.open(filelist[0])[0].data)
    precube = np.zeros( (len(filelist), xyshape[0], xyshape[1]))
    for idx, fitsfile in enumerate(filelist):
        with pf.open(fitsfile) as hdulist:
            precube[idx, :,:]=hdulist[0].data
    return precube

def quickalign(datacube, window=20):
    """quickly aligns a datacube to the first image 
       around a user-clicked subwindow"""
    #note this does this in the opposite order
    #from the calculate_offsets since this one 
    #assumes you don't care too much
    aligned_datacube = np.zeros(datacube.shape)
    firstimage = datacube[0,:,:]
    aligned_datacube[0,:,:]=firstimage

    spotlist = get_spot_locations(firstimage)
    for i in range(1, datacube.shape[0]):
        offsets = 'None' 
        for spot in spotlist:
            froi    = subimage(firstimage, spot, window=window)
            froi    = median_filter(froi, size = (3, 3), mode='wrap')
            roi    = subimage(datacube[i,:,:], spot, window=window)
            roi    = median_filter(roi, size = (3, 3), mode='wrap')
            offset = 'None'
            print('set offset to None here. needs checking')
            exit()
            # offset = np.array(imreg.chi2_shift(froi,roi))
            if offsets=='None':
                offsets = offset
            else:
                offsets = np.vstack((offsets, offset))
        if offsets.ndim >1:
            moffset = np.mean(offsets, axis = 1)
        else:
            moffset = offset
        shifted = sciim.interpolation.shift(datacube[i,:,:],
                             [-1*moffset[1],-1*moffset[0]], order = 1)
        aligned_datacube[i,:,:]=shifted
    return aligned_datacube

def crop(image, xmin, xmax, ymin, ymax):
    return image[xmin:xmax, ymin:ymax]

def subimage(imagedata, center, window = 20):
    """returns a subimage of size 'window' about a certain (x,y) pixel, 
       passed as 'center'"""
    y0 , x0 = center
    xmin = int(x0 - round(window/2))
    xmax = int(x0 + round(window/2))
    ymin = int(y0 - round(window/2))
    ymax = int(y0 + round(window/2))
    print(xmin,xmax, ymin,ymax)
    return imagedata[xmin:xmax, ymin:ymax]

def subimagecube(cubedata, cx, cy, window = 20):
    """returns a subcube of size 'window' about a certain (x,y) pixel, 
       passed as 'center'"""
    hw = round(window/2)
    xmin = cx - hw
    xmax = cx + hw
    ymin = cy - hw
    ymax = cy + hw
    return cubedata[:, xmin:xmax, ymin:ymax]

def unsubimagecube(cube, newcubedata, cx, cy, window=20):
    """reinserts a subcube into the original cube"""
    hw = round(window/2)
    copycube = cube.copy()
    copycube[:, cx-hw:cx+hw, cy-hw:cy+hw]=newcubedata
    return copycube

def unsubimage(oldim, newimdata, cx, cy, window= 20):
    """reinserts a image into the original cube"""
    hw = round(window/2)
    oldimcopy = oldim.copy()
    oldimcopy[cx-hw:cx+hw, cy-hw:cy+hw]=newimdata
    return oldimcopy


def threshold(imagedata):
    """crude threshold, don't do it"""
    maxl = np.max(imagedata)
    return imagedata*(imagedata>.8*maxl)

def quickcentroid(image, window = 20):
    """quick gaussian centroid of a spot"""
    xy = get_spot_locations(image, comment='Click Quick Centroid')[0]
    subim = subimage(image, xy, window=window)
    popt = plm.image_centroid_gaussian1(subim)
    xcenp = popt[1]
    ycenp = popt[2]
    xcen = xy[0]-round(window/2)+xcenp
    ycen = xy[1]-round(window/2)+ycenp
    return (xcen, ycen)

def quick2dgaussfit(image, window = 20, xy = None):
    """return the parameters of a 2d gaussian fit to an image.
       the gaussian model is in pl_math called image_centroid_gaussian1"""
    if xy is None:
        xy = get_spot_locations(image, comment='Click Quick Gaussian')[0]
       
    subim = subimage(image, xy, window=window)
    popt = plm.image_centroid_gaussian1(subim)
    xcenp = popt[1]
    ycenp = popt[2]
    xcen = xy[0]-round(window/2)+xcenp
    ycen = xy[1]-round(window/2)+ycenp
    #popt[1]=xcen
    #popt[2]=ycen
    return popt

def quick2dairyfit(image, window=20):
    """return the parameters of a 2d airy fit to an image.
       the airy model is in pl_math called image_centroid_airy1"""
    xy = get_spot_locations(image, comment = 'Click Quick Airy')[0]
    subim = subimage(image, xy, window=window)
    popt = plm.image_centroid_airy(subim)
    xcenp = popt[1]
    ycenp = popt[2]
    xcen = xy[0]-round(window/2)+xcenp
    ycen = xy[1]-round(window/2)+ycenp
    popt[1]=xcen
    popt[2]=ycen
    return popt

def get_spot_locations(refimage, comment=None, eq=True):
    """get the position of a click in an image; note this is in 
       imshow coordinates where the bottom left pixel is (-.5, -.5)"""
    class EventHandler:
        def __init__(self, spotlist):
            fig.canvas.mpl_connect('button_press_event', self.onpress)
            fig.canvas.mpl_connect('key_press_event', self.on_key_press)
            fig.canvas.mpl_connect('key_release_event', self.on_key_release)          
            self.shift_is_held = False
        def on_key_press(self, event):
           if event.key == 'shift':
               self.shift_is_held = True

        def on_key_release(self, event):
           if event.key == 'shift':
               self.shift_is_held = False

        def onpress(self, event):
            if event.inaxes!=ax:
                return
            if self.shift_is_held:
                xi, yi = (int(round(n)) for n in (event.xdata, event.ydata))
                value = im.get_array()[xi,yi]
                color = im.cmap(im.norm(value))
                print(xi, yi)
                spotlist.append((xi, yi))
                print(spotlist)
    if eq:
        im = plt.imshow(np.log(np.abs(refimage)), interpolation='nearest', origin='lower')
    else:
        im = plt.imshow(refimage, interpolation='nearest', origin='lower')
    if comment is None:
        comment = ('SHIFT-Click on spot(s) to align to. Close when finished')
    try:
        plt.title(comment)
    except:
        pass
    fig = plt.gcf()
    ax = plt.gca()

    spotlist = []
    #Pick initial spots
    handler=EventHandler(spotlist) 
    plt.show()
    return spotlist
