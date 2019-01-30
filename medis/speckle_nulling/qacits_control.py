import numpy as np
import astropy.io.fits as pf
from configobj import ConfigObj
import ipdb
import matplotlib.pyplot as plt
import medis.speckle_nulling.sn_hardware as hardware
from validate import Validator
import medis.speckle_nulling.sn_preprocessing as pre
import medis.speckle_nulling.sn_processing as pro
from scipy.interpolate import interp1d
import medis.speckle_nulling.sn_math as snm
import dm_registration as dm
import PID as pid

def fit_satellite_centers(image, spotcenters_init, window=20):
    """ Returns the center of the image given approximative spot centers """
    # fit satellite centers
    scs = np.zeros((len(spotcenters_init), 2))
    for idx,xy in enumerate(spotcenters_init):
        subim = pre.subimage(image, xy, window=window)
        popt = snm.image_centroid_gaussian1(subim)
        xcenp = popt[1]
        ycenp = popt[2]
        xcen = xy[0]-round(window/2)+xcenp
        ycen = xy[1]-round(window/2)+ycenp
        scs[idx,:] = xcen, ycen    
    
    return scs

def get_delta_I(image, cx = None, cy = None, 
                quad_width_pix = 7., inner_rad_pix = 0., 
                zone_type = None) :
    
    if zone_type == 'inner' : 
        image = image * pro.circle(image, cx, cy, inner_rad_pix)
    elif zone_type == 'outer' :
        image = image * (1 - pro.circle(image, cx, cy, inner_rad_pix))
    
    window = quad_width_pix*2.
    xs, ys = np.meshgrid(np.arange(image.shape[0]), np.arange(image.shape[1]))
    subim = pre.subimage(image, (round(cx), round(cy)), window=window)
    subx = pre.subimage(xs, (round(cx), round(cy)), window=window)
    suby = pre.subimage(ys, (round(cx), round(cy)), window=window)      
    
    cumx = np.cumsum(np.sum(subim, axis = 1))
    cumy = np.cumsum(np.sum(subim, axis = 0))
    
    f_interpx = interp1d(subx[0,:], cumx)
    f_interpy = interp1d(suby[:,0], cumy)

    deltaIx = max(cumx)-2*f_interpx(cx-1)
    deltaIy = max(cumy)-2*f_interpy(cy-1)
    
    #ipdb.set_trace()
    
    #plt.imshow(subim)
    #plt.show()
    
    #plt.plot(cumx)
    #plt.show()
    
    return deltaIy, deltaIx


def tiptiltestimator_circle(image, cx=None, cy= None, beta = None,
                     lambdaoverd=None, window = None):
    def cuberoot(x):
        if x<0:
            return -(-x)**(1.0/3)
        else:
            return x**(1.0/3)

    xs, ys = np.meshgrid(np.arange(image.shape[0]),
                         np.arange(image.shape[1]))
    subim = pre.subimage(image, (round(cx), round(cy)), window=window)
    subx = pre.subimage(xs, (round(cx), round(cy)), window=window)
    suby = pre.subimage(ys, (round(cx), round(cy)), window=window)
    
    cumx = np.cumsum(np.sum(subim, axis = 1))
    cumy = np.cumsum(np.sum(subim, axis = 0))
    
    f_interpx = interp1d(subx[0], cumx)
    f_interpy = interp1d(suby[:,0], cumy)

    deltaIx = max(cumx)-2*f_interpx(cx)
    deltaIy = max(cumy)-2*f_interpy(cy)

    Tx = cuberoot(deltaIx/beta)*cuberoot(deltaIx**2/(deltaIx**2+deltaIy**2))
    Ty = cuberoot(deltaIy/beta)*cuberoot(deltaIy**2/(deltaIx**2+deltaIy**2))
    return Tx, Ty

def tiptiltestimator(delat_i_x, delta_i_y, gamma = 0., rotangle = 0.):
    
    # tip-tilt estimation
    theta = np.arctan(delta_i_y/delta_i_x)
    delta_i_theta = np.sqrt(delta_i_x**2.+delta_i_y**2.)
    T_theta = delta_i_theta/gamma
    
    Tx = T_theta * np.cos(theta-rotangle)
    Ty = T_theta * np.sin(theta-rotangle)
    
    return Tx, Ty

if __name__ == "__main__":
    configfilename = 'qacits_config.ini'
    hardwareconfigfile = 'speckle_instruments.ini'
    configspecfile = 'qacits_config.spec'
    config = ConfigObj(configfilename, configspec=configspecfile)
    val = Validator()
    check = config.validate(val)
    
    pharo = hardware.fake_pharo()
    #p3k = hardware.P3K_COM('P3K', configfile = hardwareconfigfile)

    bgd = np.zeros((1024, 1024))
    flat = np.ones((1024, 1024))
    bpix = np.zeros((1024, 1024))

    # parameters defining the zone of interest
    spotcenters = np.resize(config['Image_params']['spotcenters_init'], (4,2))
    quad_width_pix = config['Image_params']['quad_width'] * config['Image_params']['lambdaoverd']
    inner_rad_pix = config['Image_params']['inner_rad'] * config['Image_params']['lambdaoverd']
    lambdaoverd_arc = config['Image_params']['lambdaoverd_arc']    
    # reference values    
    Itot_off = config['QACITS_params']['Itot_off']
    DIx_ref = config['QACITS_params']['DIx_ref']
    DIy_ref = config['QACITS_params']['DIy_ref']

    # PID loop gains
    Kp = config['PID']['Kp']
    Ki = config['PID']['Ki']
    Kd = config['PID']['Kd']
    
    #ipdb.set_trace()
    
    # PID loop        
    p = pid.PID(P=np.array([Kp,Kp]), 
                I=np.array([Ki,Ki]), 
                D=np.array([Kd,Kd]),
                Deadband=.001)
    p.setPoint(np.array[0.,0.])

    
    c=1
    while True:
        img = pharo.get_image()
        img = pre.equalize_image(img, 
                                 masterflat = flat,
                                 bkgd = bgd,
                                 badpix = bpix)
                                       
        # Derive center of the image from the satellite spots
#        if c == 1 :
#            spotcenters = dm.get_satellite_centroids(img)
#        else :
#            spotcenters = fit_satellite_centers(img, spotcenters, window=20)
              
              
        spotcenters = fit_satellite_centers(img, spotcenters, window=20)
         
        centerx, centery = np.mean(spotcenters, axis = 0)
        #centerx, centery = 512, 512

        print centerx, centery
        
        if c== 3 : ipdb.set_trace()
        
        delta_i_x, delta_i_y = get_delta_I(img, cx = centerx, cy=centery,
                                quad_width_pix = quad_width_pix,
                                inner_rad_pix = inner_rad_pix,
                                zone_type = "inner")

        delta_i_x = (delta_i_x - DIx_ref) / Itot_off  
        delta_i_y = (delta_i_y - DIy_ref) / Itot_off        

        # tip tilt estimator in lambda over D        
        Tx, Ty = tiptiltestimator(delta_i_x, delta_i_y, gamma = 1.)
        # conversion in arcsec to feed the P3K tip tilt mirror
        rx = Tx*lambdaoverd_arc
        ry = Ty*lambdaoverd_arc        
        
        offx, offy = snm.rotateXY(rx, ry, config['AO']['rotang'])
        
        # command value according to PID loop
        p.update([offx,offy])        
        
        print offx, offy
        print '-----------'
       
        c=c+1
        #offx and offy that you feed to p3k needs to be in arc seconds
        #p3k.sci_offset_up(offy)
        #p3k.sci_offset_left(offx)
