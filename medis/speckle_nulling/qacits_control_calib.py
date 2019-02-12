import numpy as np
import astropy.io.fits as pf
from configobj import ConfigObj
import ipdb
import matplotlib.pyplot as plt
import medis.speckle_nulling.sn_hardware as hardware
from validate import Validator
import medis.speckle_nulling.sn_preprocessing as pre
#import medis.speckle_nulling.sn_processing as pro
from scipy.interpolate import interp1d
import medis.speckle_nulling.sn_math as snm
import qacits_control as qacits
import dm_registration as DM
import time

if __name__ == "__main__":
    configfilename = 'qacits_config.ini'
    hardwareconfigfile = 'speckle_instruments.ini'
    configspecfile = 'qacits_config.spec'
    config = ConfigObj(configfilename, configspec=configspecfile)
    val = Validator()
    check = config.validate(val)

    home = 0
    lab = 1   
    
    #pharo = hardware.fake_pharo()
    if lab:
        p3k = hardware.P3K_COM('P3K_COM', configfile = hardwareconfigfile)
        pharo = hardware.PHARO_COM('PHARO', configfile = hardwareconfigfile)


    # background, flat and bad pix map    
    #bgd = np.zeros((1024, 1024))
    #flat = np.ones((1024, 1024))
    #bpix = np.zeros((1024, 1024))
    
    
    
    # parameters defining the zone of interest
    centerx = config['Image_params']['centerx']
    centery = config['Image_params']['centery']
    spotcenters = np.resize(config['Image_params']['spotcenters_init'], (4,2))
    quad_width_pix = config['Image_params']['quad_width'] * config['Image_params']['lambdaoverd']
    inner_rad_pix = config['Image_params']['inner_rad'] * config['Image_params']['lambdaoverd']
    lambdaoverd_arc = config['Image_params']['lambdaoverd_arc']    
    # reference values    
    Itot_off = config['QACITS_params']['Itot_off']
    DIx_ref = config['QACITS_params']['DIx_ref']
    DIy_ref = config['QACITS_params']['DIy_ref']
    background_file_name = config['Image_params']['background_file_name']
    rotang = config['AO']['rotang']
    
    
    bgd = pre.combine_quadrants(pf.open(background_file_name))

    
    # take a set of images with varying tip-tilt
    # [offx and offy that you feed to p3k needs to be in arc seconds]
    Nstep = 10
    tip_tilt_max = 1. * lambdaoverd_arc #* 135./270
    pitch = -tip_tilt_max/(Nstep-1)
    print 'pitch', pitch    

    total_offset = 0.
    tip_tilt = np.zeros(Nstep)
    all_delta_i_x = np.zeros(Nstep)
    all_delta_i_y = np.zeros(Nstep)
    
    
    k0=98
    
    for k in range(0,Nstep):
        print("k="+str(k)) 
        print 'total offset', total_offset/lambdaoverd_arc, 'lbd/D'
        
        if lab:
            if k > 0 : 
                p3k.sci_offset_left(pitch)
                while not(p3k.isReady()) :
                    time.sleep(.1)
            img = pharo.take_src_return_imagedata()
            img = pre.equalize_image(img, bkgd = bgd)
        else :
            dir = '/home/ehuby/dev/repos/speckle_nulling/pharoimages/'
            img_file_name = dir + 'ph'+str(k+k0).zfill(4)+'.fits'
            img = pre.combine_quadrants(pf.open(img_file_name))

        total_offset = k * pitch
        tip_tilt[k] = total_offset/lambdaoverd_arc
               
        
        # derive center
        # spotcenters = qacits.fit_satellite_centers(img, spotcenters, window=20)
        # centerx, centery = np.mean(spotcenters, axis = 0)
        # centerx, centery = 512, 512
        
        delta_i_x, delta_i_y = qacits.get_delta_I(img, cx = centerx, cy=centery,
                                quad_width_pix = quad_width_pix,
                                inner_rad_pix = inner_rad_pix) #zone_type = "inner")

        #all_delta_i_x[k] = (delta_i_x - DIx_ref) / Itot_off  
        #all_delta_i_y[k] = (delta_i_y - DIy_ref) / Itot_off       

        if k==0 :
            all_delta_i_x[0] = delta_i_x / Itot_off
            all_delta_i_y[0] = delta_i_y / Itot_off
        all_delta_i_x[k] = (delta_i_x) / Itot_off - all_delta_i_x[0]
        all_delta_i_y[k] = (delta_i_y) / Itot_off - all_delta_i_y[0]



    # derive the parameter value from fit
    a = np.arctan(all_delta_i_x[1:]/all_delta_i_y[1:])*180./np.pi
    theta = np.mean(a[-1:])
    #print 'theta', theta
    all_delta_theta = np.sqrt(all_delta_i_y**2.+all_delta_i_x**2.)
    
    #with theoretical theta
    theta = -118. #rotang*np.pi/180.
    all_delta_theta = all_delta_i_y * np.sin(theta) + all_delta_i_x * np.cos(theta)
    
    
    # for the fit, discard tiptilt>0.8
    ttlim = .6
    yi =all_delta_theta[np.where(np.abs(tip_tilt)<ttlim)]
    xi = tip_tilt[np.where(np.abs(tip_tilt)<ttlim)]**3.
    beta = np.sum(xi * yi)/np.sum(xi**2.)
    
    # write the parameter value in the init file
    config['QACITS_params']['beta'] = beta
    
    config.write() 
    
    if lab: 
        p3k.sci_offset_left(-total_offset)
    
    #display
    ttdisp = -np.arange(Nstep*10.)/(Nstep*10.)*tip_tilt_max/lambdaoverd_arc
    plt.plot(tip_tilt, all_delta_theta, 'k*')
    plt.plot(ttdisp, beta*ttdisp**3., 'r')
    plt.title('beta ='+str(beta))
    plt.show()

    Ith = all_delta_i_y * np.sin(theta) + all_delta_i_x * np.cos(theta)
    Ith_ortho = all_delta_i_y * np.cos(theta) - all_delta_i_x * np.sin(theta)
    plt.plot(tip_tilt, Ith)
    plt.plot(tip_tilt, Ith_ortho)
    plt.show()
    
    
    #plt.plot(tip_tilt[1:], a, 'bo')
    #plt.show()

    print 'beta =', beta
