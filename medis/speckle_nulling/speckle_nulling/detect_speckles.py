import numpy as np
import astropy.io.fits as pf
from configobj import ConfigObj
# import ipdb
import matplotlib.pyplot as plt
import sn_hardware as hardware
import sn_preprocessing as pre
import sn_processing as pro
import scipy.ndimage as sciim
import sn_math as snm
import scipy.ndimage.filters as filters
from scipy.ndimage.morphology import generate_binary_structure, binary_erosion

def colorfulcontours(im, contourlist):
    zeroim = im*0
    randomcolors = [(np.random.randint(0,255),
                     np.random.randint(0,255),
                     np.random.randint(0,255)) for x in range(len(contourlist))]
    cv2.drawContours(zeroim, contourlist, -1,1,-1)
    return zeroim

def boundary(binaryimage):
    """pass a binary image, it will return an image of the boundaries.
    this is useful when you pass the controlregion"""
    boundary = sciim.laplace(binaryimage)>0
    return boundary    

def threshold(image, region, 
              method = 'mean',
              window = 5, 
              offset = -3):
    """Uses an adaptive threshold to separate a region into two 
       parts of zeros and ones.  options:
       method: mean, gaussian
       window: 5
       offset: -3"""
    bound = boundary(region)
    innerbound = boundary(bound)
    inner2bound = boundary(innerbound)
    inner3bound = boundary(inner2bound)
    im2 = image*region
    clipimage = np.uint8(im2/np.max(im2)*255)

    if method == 'mean':
        th3 = cv2.adaptiveThreshold(clipimage,1,
                    cv2.ADAPTIVE_THRESH_MEAN_C,\
                    cv2.THRESH_BINARY,window,offset)
    elif method == 'gaussian':
        th3 = cv2.adaptiveThreshold(clipimage,1,
                    cv2.ADAPTIVE_THRESH_GAUSSIAN_C,\
                    cv2.THRESH_BINARY,window,offset)
    else:
        print(("WARNING: INVALID THRESHOLD ALGORITHM."+
              "  USING 'mean'." ))
        th3 = cv2.adaptiveThreshold(clipimage,1,
                    cv2.ADAPTIVE_THRESH_MEAN_C,\
                    cv2.THRESH_BINARY,window,offset)
    th3[bound]=0
    th3[innerbound]=0
    th3[inner2bound]=0
    th3[inner3bound]=0
    return th3

def filtercontours(image, contours,  N=60):
    """returns the top N brightest contours"""
    brightnessArray= []
    areaArray= []
    for i, c in enumerate(contours):
        mask = np.zeros(image.shape)
        #draws the speckle
        cv2.drawContours(mask, [c], 0, 1.0, -1)
        
        brightness = np.mean(image*mask)/np.sum(mask)
        brightnessArray.append(brightness)
        
        area = cv2.contourArea(c)
        areaArray.append(area)
    topNargs = np.argsort(brightnessArray)[::-1][:N]
    
    return [contours[x] for x in topNargs]

def detect_speckles3(image, configfile = None):
    """
    Takes an image and detect the peaks usingthe local maximum filter.
    Returns a boolean mask of the peaks (i.e. 1 when
    the pixel's value is the neighborhood maximum, 0 otherwise)
    """
    configfilename = 'speckle_null_config.ini'
    config = ConfigObj(configfilename)
    controlregion = pf.open(config['CONTROLREGION']['filename'])[0].data
    image = filters.median_filter(image, size=(3,3))
    # define an 8-connected neighborhood
    neighborhood = generate_binary_structure(2,2)

    #apply the local maximum filter; all pixel of maximal value 
    #in their neighborhood are set to 1
    local_max = filters.maximum_filter(image, footprint=neighborhood)==image
    local_min = filters.minimum_filter(image, footprint=neighborhood)==image
    #local_max is a mask that contains the peaks we are 
    #looking for, but also the background.
    #In order to isolate the peaks we must remove the background from the mask.

    #we create the mask of the background
    background = (image==local_min)

    #a little technicality: we must erode the background in order to 
    #successfully subtract it form local_max, otherwise a line will 
    #appear along the background border (artifact of the local maximum filter)
    eroded_background = binary_erosion(background, structure=neighborhood, border_value=1)

    #we obtain the final mask, containing only peaks, 
    #by removing the background from the local_max mask
    detected_peaks = local_max - eroded_background

    return detected_peaks 

def detect_speckles(image, configfile = None):
    """Returns a set of contours defining the speckles"""
    configfilename = 'speckle_null_config.ini'
    config = ConfigObj(configfilename)
    region = pf.open(config['CONTROLREGION']['filename'])[0].data
    bound = boundary(region)
    max_speckles = int(config['DETECTION']['max_speckles'])

    th_window = int(config['DETECTION']['window'])
    th_offset = int(config['DETECTION']['offset'])
    th_method = config['DETECTION']['method']
    
    thresholded = threshold(image, region,
                             method = th_method,
                             window = th_window,
                             offset = th_offset)
    speckles, _ = cv2.findContours(thresholded.copy(), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    fspeckles = filtercontours(image, speckles, N=max_speckles)
    return fspeckles

def detect_speckles2(image, configfile=None, speckle_positions=None, configspecfile=None):
    """ Returns a orderdered (brighter to fainter) list of pixels at speckle centers """
    """ Fit a gaussian profile on the speckle pattern to determine its center and amplitude """
    configfilename = 'speckle_null_config.ini'
    config = ConfigObj(configfilename,configspec=configspecfile)

    max_speckles = int(config['DETECTION']['max_speckles'])
    fwhm = float(config['IM_PARAMS']['lambdaoverd']) # pixels per lambda/D
    factor_subaperture = 1. # !!!!! set to 1 for a full aperture !!!!!!!
    speckle_rad = fwhm*2. * factor_subaperture
    cx = int(float(config['IM_PARAMS']['centerx']))
    cy = int(float(config['IM_PARAMS']['centery']))
    # Note: problem with the type of the retrieved variables (returned with quotes '')
    control_region = pf.open(config['CONTROLREGION']['filename'])[0].data

    # aperture mask defining the central circle of radius of 1 lambda over D centered on the central star
    nx, ny = image.shape[0], image.shape[1]
    x, y = np.meshgrid(np.arange(nx)-cx, np.arange(ny)-cy)
    r = np.sqrt(x**2.+y**2.)
    aperture = np.zeros((nx,ny))
    aperture[np.where(r < speckle_rad)] = 1.

    # amplitudes of the detected speckles
    speckle_amplitudes = np.zeros(max_speckles)
    
    mask = 1. - aperture 	# hides the central region
    mask *= control_region	# limits the area to the control region
    surf_ref = np.sum(aperture)	# surface area of the regular speckle

    pos_init = (speckle_positions == None)

    #ipdb.set_trace()

    on_edge = True
    if pos_init :
        print('----- DERIVE speckle positions')
        speckle_positions  = np.zeros((2, max_speckles))
        for k in range(max_speckles):
            while on_edge:
                # detect speckle position
                search_area = image*mask
                speckle_level = np.max(search_area)
                pos = np.argmax(search_area)
                speckle_positions[:,k] = np.unravel_index(pos, (nx,ny))

            # checking that the speckle is not on the edge of the control region
            shifted_aperture = create_speckle_mask(image, speckle_positions[:,k], cx, cy, speckle_rad)
            surf = np.sum(shifted_aperture*control_region)
            on_edge = (surf < surf_ref/2.)

            # mask update
            mask = mask * (1. - shifted_aperture) # hides the area around the speckle
        on_edge = True
        #ipdb.set_trace()

    #ipdb.set_trace()
    for k in range(max_speckles):
        print('----- FIT speckle positions')
        # gaussian fit of the speckle
        xg, yg = np.meshgrid(np.arange(nx), np.arange(ny))
        # Note: problem with the coordinates x, y

    #subim = pre.subimage(image, np.roll(speckle_positions[:,k],1,axis=0), window = speckle_rad)
        #subx  = pre.subimage(xg,  np.roll(speckle_positions[:,k], 1, axis=0), window = speckle_rad)
        #suby  = pre.subimage(yg,  np.roll(speckle_positions[:,k], 1, axis=0), window = speckle_rad)
        #gauss_params = snm.fitgaussian((subx, suby), subim)
    #speckle_amplitudes[k]  = gauss_params[0]

    # aperture photometry
    aperture = create_speckle_mask(image, speckle_positions[:,k], cx, cy, fwhm*3./2.)#set to *1 for full aperture
    speckle_amplitudes[k] = np.sum(image*aperture)/np.sum(aperture)

    print('speckle_positions init', speckle_positions[:,k])
        #print 'speckle_positions fit ', gauss_params[2], gauss_params[1]
        #print 'speckle_amplitudes fit', gauss_params[0]
    print('speckle_amplitudes     ', speckle_amplitudes[k])

    """
    if pos_init :
        speckle_positions[:,k] = gauss_params[2], gauss_params[1]
    else :
        # otherwise, we keep the given the positions and check that the fitted position is compatible with the previous
        # distance between the newly fitted maximum of the gaussian, and the input parameter
        d = np.sqrt((speckle_positions[0,k]-gauss_params[2])**2.+(speckle_positions[1,k]-gauss_params[1])**2.)
        if d > 1.:
            print 'WARNING the fitted position differs by '+str(d)+' pixels from input initial'
    """

    return speckle_positions, speckle_amplitudes

def get_speckle_photometry_old(image, aperture_mask):
    """returns the integrated flux of the speckle defined in the area of aperture mask"""
    """ TOO ROUGH, see fit of a gaussian profile in detect_speckles2 """
    # flux normalization
    norm_flux = np.sum(aperture_mask)
    return np.sum(aperture_mask*np.nan_to_num(image))/norm_flux

def get_speckle_photometry(image, aperture_mask):
    """returns the integrated flux of the speckle defined in the area of aperture mask"""
    # plt.figure()
    plt.imshow(image)
    plt.figure()
    plt.plot(image[64])
    plt.show()
    
    inds = np.where(aperture_mask)
    norm_flux = np.sum(aperture_mask[inds])
    ret = np.sum(image[inds])/norm_flux

    # ret = ret/0.57
    ret = np.max(image[inds])
    print('ret', ret)
    # print norm_flux, np.sum(image[inds]), ret
    # ans = raw_input('press enter')

    return ret

def create_speckle_aperture(im, cx, cy, rad):
    return pro.circle(im, cx, cy, rad)
    
def get_speckle_spatial_freq(image, pos, cx, cy, lambdaoverd, angle=None):
    """ returns the spatial frequency of the speckle defined in the area of aperture mask """
    """ lambdaoverd = nb of pixels per lambda/D """
    nx, ny =image.shape[0], image.shape[1]
    k_xy = (np.roll(pos,1,axis=0)-[cx,cy])/lambdaoverd     # fwhm is in pixels per lbd over D
    #k_mod = np.sqrt(k_sp[0]**2. + k_sp[1]**2.)
    k_xy = snm.rotateXY(k_xy[0], k_xy[1], thetadeg = -1.0*angle)
    ipdb.set_trace()
    return k_xy

def create_speckle_mask(image, pos, cx, cy, speckle_rad):
    """ returns a binary map with ones in the region of the speckle (circle of radius speckle_rad)"""
    # centered aperture mask of width 1 lambda over D
    nx, ny = image.shape[0], image.shape[1]
    x, y = np.meshgrid(np.arange(nx)-pos[1], np.arange(ny)-pos[0])
    r = np.sqrt(x**2.+y**2.)
    aperture = np.zeros((nx,ny))
    aperture[np.where(r<speckle_rad)] = 1.
    # shift the mask around the speckle position
    #shx, shy = int(cx-pos[0]), int(cy-pos[1])
    #aperture_mask = np.roll(np.roll(aperture, shx, axis=0),shy, axis=1)
    return aperture

if __name__ == "__main__":
    configfilename = 'speckle_null_config.ini'
    config = ConfigObj(configfilename)

    pharo = hardware.fake_pharo()
    image = pharo.get_image()
    #fspeckles = detect_speckles(image, configfile=configfilename)
    #
    #zeroim = image*0    
    #cv2.drawContours(zeroim, fspeckles, -1,1, -1)
    # 
    #vertsx = np.array(config['CONTROLREGION']['verticesx'], dtype = np.int16)
    #vertsy = np.array(config['CONTROLREGION']['verticesy'], dtype = np.int16)
    #
    #fig, ((ax1, ax2), (ax3, ax4) ) = plt.subplots(2, 2, figsize = (8,8))
    #
    #ax1.imshow(np.log(np.abs(image)))
    #ax1.set_xlim( (np.min(vertsx), np.max(vertsx)))
    #ax1.set_ylim( (np.min(vertsy), np.max(vertsy)))
    #
    #ax2.imshow(np.log(np.abs(image))*zeroim)
    #ax2.set_xlim( (np.min(vertsx), np.max(vertsx)))
    #ax2.set_ylim( (np.min(vertsy), np.max(vertsy)))
    #fig.tight_layout()
    #plt.show()
