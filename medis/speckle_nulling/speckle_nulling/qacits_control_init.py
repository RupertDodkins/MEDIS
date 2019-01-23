import numpy as np
import sn_filehandling as flh
import astropy.io.fits as pf
from configobj import ConfigObj
import ipdb
import matplotlib.pyplot as plt
import sn_hardware as hardware
from validate import Validator
import sn_preprocessing as pre
#import sn_processing as pro
from scipy.interpolate import interp1d
import sn_math as snm
import qacits_control_v2 as qacits
import dm_registration as dmr
import dm_functions as dmf
import flatmapfunctions as FM
import time

if __name__ == "__main__":
    
    home = 0
    onsky = 1      
    
    data_dir = '/data1/home/aousr/Desktop/speckle_nulling/pharoimages/'
    ref_filename = data_dir + 'ph0108.fits'
    pos_filename = data_dir + 'ph0109.fits'
    off_filename = data_dir + 'ph0022.fits'
    Itot_corr_factor = 100. # because ref image has been taken with the 1% ND filter

    configfilename = 'qacits_config.ini'
    hardwareconfigfile = 'speckle_instruments.ini'
    configspecfile = 'qacits_config.spec'
    config = ConfigObj(configfilename, configspec=configspecfile)
    val = Validator()
    check = config.validate(val)
    
    #bgds = config['BACKGROUNDS_CAL']
    
    bgds = flh.setup_bgd_dict(config)
    
    if onsky :
        p3k = hardware.P3K_COM('P3K_COM', configfile = hardwareconfigfile)
        pharo = hardware.PHARO_COM('PHARO', configfile = hardwareconfigfile)
    
    # background, flat and bad pix map
    if onsky :
        #bgd_filename = config['Image_params']['background_file_name']
        #bgd = pre.combine_quadrants(pf.open(bgd_filename))
        #bgd = pf.open(bgd_filename)[0].data
        pass
    else :
        bgd_filename  = data_dir + 'ph0011.fits'
        bgd_filename1 = data_dir + 'ph0011.fits'
        bgd_filename2 = data_dir + 'ph0011.fits'
        
        bgd1 = pre.combine_quadrants(pf.open(bgd_filename1))
        bgd2 = pre.combine_quadrants(pf.open(bgd_filename2))
    
    
    # parameters of the image
    centerx         = config['Image_params']['centerx']
    centery         = config['Image_params']['centery']
    lambdaoverd     = config['Image_params']['lambdaoverd']
    lambdaoverd_arc = config['Image_params']['lambdaoverd_arc']    
    angle           = config['AO']['rotang']*np.pi/180. # in radians
    
    # background file    
    #background_file_name = config['Image_params']['background_file_name']
    #bgd = pre.combine_quadrants(pf.open(background_file_name))    
    #bgd = pf.open(background_file_name)[0].data

    # defining the zone of interest for QACITS
    quad_width      = config['QACITS_params']['quad_width'] # in lambda/D
    inner_rad       = config['QACITS_params']['inner_rad']  # in lambda/D
    quad_width_pix  = quad_width * lambdaoverd # in pixels    
    inner_rad_pix   = inner_rad * lambdaoverd  # in pixels    
    
    zone_type = config['QACITS_params']['type']


    # 1) Take an image with the centered coronagraph as reference
    
    
    if onsky:
        img_ref = pharo.take_src_return_imagedata()
        img_ref = pre.equalize_image(img_ref, **bgds)
    else:
        img_ref = pre.combine_quadrants(pf.open(ref_filename)) 
        img_ref = img_ref - bgd1
    
    ix_ref , iy_ref = qacits.get_delta_I(img_ref, cx=centerx, cy=centery,
                            quad_width_pix = quad_width_pix,
                            inner_rad_pix = quad_width_pix, 
                            zone_type=zone_type)       
    #ipdb.set_trace()
    
    # Apply sine waves
    if onsky :
        initial_flatmap = np.zeros((66, 66)) 
        initial_flatmap = p3k.grab_current_flatmap()
        status = p3k.load_new_flatmap(FM.convert_hodm_telem(initial_flatmap))
        DMamp = 60
        kvecr = 24
        additionmapx = dmf.make_speckle_kxy(kvecr, 0,DMamp , 0) 
        additionmapy = dmf.make_speckle_kxy(0,kvecr, DMamp, 0) 
        additionmap = additionmapx + additionmapy
        status = p3k.load_new_flatmap(FM.convert_hodm_telem(initial_flatmap + additionmap))
    	
        img_pos = pharo.take_src_return_imagedata()
        img_pos = pre.equalize_image(img_pos, **bgds)

        status = p3k.load_new_flatmap(FM.convert_hodm_telem(initial_flatmap))
    
    else :
        img_pos = pre.combine_quadrants(pf.open(pos_filename)) 
        img_pos = img_pos - bgd1
        #img_pos[np.where(img_ref<0.)]=0.
  

    # find the center by clicking on the spots
    spotcenters = dmr.get_satellite_centroids(img_pos)
    # spotcenters = np.resize(config['Image_params']['spotcenters_init'], (4,2)) 
    centerx, centery = np.mean(spotcenters, axis = 0)    
    
    # uses the spotcenters found and fitted previously as first guess
    #spotcenters = qacits.fit_satellite_centers(img_ref, spotcenters, window=20)
    #centerx, centery = np.mean(spotcenters, axis = 0)
    print centerx, centery
    
     
    
    #ipdb.set_trace()

    # 2) take an image without coron mask
    #    [offx and offy that you feed to p3k needs to be in arc seconds]
    offs = 2
    if onsky:
        p3k.sci_offset_up(offs) # up means South
        #ipdb.set_trace()
        while not(p3k.isReady()) :
            time.sleep(.1)
        img_off = pharo.take_src_return_imagedata()
        img_off = pre.equalize_image(img_off, **bgds)
        #ipdb.set_trace()
        p3k.sci_offset_up(-offs)
        #ipdb.set_trace()
    else :
        img_off = pre.combine_quadrants(pf.open(off_filename)) 
        img_off = img_off - bgd2
    
    
    
    # detect the position of the offseted image
    ipdb.set_trace()
    nx=img_off.shape[0]
    ny=img_off.shape[1]
    x, y = np.meshgrid(np.arange(nx),np.arange(ny))
    fun = pre.get_spot_locations(img_off)
    indmax = fun[0]
    subIm= pre.subimage(img_off, (indmax[0],indmax[1]), window=25)
    subx = pre.subimage(x, (indmax[0],indmax[1]), window=25)
    suby = pre.subimage(y, (indmax[0],indmax[1]), window=25)
    gauss_params = snm.fitgaussian((subx, suby), subIm)
    cx_off, cy_off = gauss_params[1], gauss_params[2]

    
    # calibrate pixel size
    D_pix = np.sqrt((cx_off-centerx)**2+(cy_off-centery)**2)
    lambdaoverd_arc = config['Image_params']['lambdaoverd_arc']    
    lambdaoverd = lambdaoverd_arc * D_pix / offs

    Itot = np.sum(pre.subimage(img_off, (cx_off,cy_off), window = 2*quad_width_pix))

    if home: 
        Itot *= Itot_corr_factor

    #ipdb.set_trace()
    
    # compute the angle
    angle = np.arctan(((cy_off-centery)/(cx_off-centerx)))*180./np.pi
    
    # display
    a_rad = angle * np.pi / 180.
    subim=pre.subimage(img_off+img_pos,(centerx,centery),window=D_pix*2.)
    plt.plot([D_pix, D_pix], [D_pix,D_pix], 'w*')
    plt.plot([D_pix*np.cos(a_rad+np.pi)+D_pix,D_pix*np.cos(a_rad)+D_pix],
              [D_pix*np.sin(a_rad+np.pi)+D_pix, D_pix*np.sin(a_rad)+D_pix],'w--')
    plt.imshow(subim)
    plt.show()
    
    # write these values in the init file
    config['QACITS_params']['Itot_off'] = Itot
    config['QACITS_params']['DIx_ref'] = ix_ref
    config['QACITS_params']['DIy_ref'] = iy_ref
    config['Image_params']['centerx'] = centerx
    config['Image_params']['centery'] = centery
    config['AO']['rotang'] = -1*angle
    config['Image_params']['lambdaoverd'] = lambdaoverd
    
    config.write()

    print 'Itot_off', Itot
    print 'DIx_ref', ix_ref
    print 'DIy_ref', iy_ref
    print 'centerx', centerx
    print 'centery', centery
    print 'angle  ', angle
