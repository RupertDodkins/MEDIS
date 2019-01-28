import dm_functions as dm
import sn_preprocessing as pre
import os
import matplotlib.pyplot as plt
import astropy.io.fits as pf
# import ipdb
import sn_math as snm
import numpy as np
from configobj import ConfigObj
import sn_filehandling as flh
import sn_hardware as hardware
import flatmapfunctions as FM
from validate import Validator
import flatmapfunctions as fmf
import dm_functions as DM
import time

def recenter_satellites(image, spots, window=20):
    """centroid each satellite spot using a 2d gaussian"""
    #satellite centers
    scs = np.zeros((len(spots), 2))
    for idx,xy in enumerate(spots):
        subim = pre.subimage(image, xy, window=window)
        popt = snm.image_centroid_gaussian1(subim)
        xcenp = popt[1]
        ycenp = popt[2]
        xcen = xy[0]-round(window/2)+xcenp
        ycen = xy[1]-round(window/2)+ycenp
        scs[idx,:] = xcen, ycen
    return scs

def get_satellite_centroids(image, window=20):
    """centroid each satellite spot using a 2d gaussian"""
    spots = pre.get_spot_locations(image, eq=True,
            comment='SHIFT-Click on the satellites CLOCKWISE'+
                     'starting from 10 o clock,\n then close the window')
    #satellite centers
    scs = np.zeros((len(spots), 2))
    for idx,xy in enumerate(spots):
        subim = pre.subimage(image, xy, window=window)
        popt = snm.image_centroid_gaussian1(subim)
        xcenp = popt[1]
        ycenp = popt[2]
        xcen = xy[0]-round(window/2)+xcenp
        ycen = xy[1]-round(window/2)+ycenp
        scs[idx,:] = xcen, ycen
    return scs

def find_center(centers):
    """returns the mean of the centers"""
    return np.mean(centers, axis = 0)

def find_angle(centers):
    """uses the four centers, presumably square, to find the rotation angle of the DM"""
    center = np.mean(centers, axis = 0)
    reltocenter = centers-center
    angs = [np.arctan(reltocenter[i,1]/reltocenter[i,0])*180/np.pi for i in range(4)]
    for idx,ang in enumerate(angs):
        if ang<0:
            angs[idx]= ang+90.0

    print angs
    # assert np.std(angs)< 3.0
    angle = np.mean(angs)
    return angle

def get_lambdaoverd(centroids, cyclesperap):
    """Calcualtes lambda/d by taking the average 
    of the two diagonas of the square, then 
    divides by cycles per aperture (33 for a 66x66 dm, then divides by 2"""
    diag1dist = np.linalg.norm(centroids[0,:]
                              -centroids[2,:])
    diag2dist = np.linalg.norm(centroids[1,:]
                              -centroids[3,:])
    avgdiagdist = 0.5*(diag1dist+diag2dist)
    return avgdiagdist/2/cyclesperap

def dm_reg_autorun(cleanimage, configfilename, configspecfile):
    #configfilename = 'speckle_null_config.ini'
    config = ConfigObj(configfilename, configspec=configspecfile)
    val = Validator()
    check = config.validate(val)
    #initial spot guesses
    try:
        initialspots = [ config['CALSPOTS']['spot10oclock'],  
                         config['CALSPOTS']['spot1oclock'],  
                         config['CALSPOTS']['spot4oclock'],  
                         config['CALSPOTS']['spot7oclock'],]
    except:
        print "WARNING: SPOTS NOT FOUND IN CONFIGFILE. RECALCULATING"
        initialspots = pre.get_spot_locations(image, eq=True,
                comment='SHIFT-Click on the satellites CLOCKWISE'+
                         'starting from 10 o clock,\n then close the window')
    spotcenters = recenter_satellites(cleanimage, 
                                initialspots, window=20)
    
    print "updated spotcenters: ",  spotcenters
    print 'initial spots', initialspots

    plt.figure()
    plt.imshow(np.log(cleanimage))
    plt.show()
    ans = raw_input('placeholder')

    c =find_center(spotcenters)
    a =find_angle(spotcenters)
    
    config['IM_PARAMS']['centerx'] = c[0]
    config['IM_PARAMS']['centery'] = c[1]
    config['IM_PARAMS']['angle']  = a 
    #cyclesperap = int(config['AOSYS']['dmcyclesperap'])
    kvecr = 33
    lambdaoverd = get_lambdaoverd(spotcenters, kvecr)
    config['IM_PARAMS']['lambdaoverd'] = lambdaoverd
    
    config['CALSPOTS']['spot10oclock'] = [np.round(x) for x in spotcenters[0]]
    config['CALSPOTS']['spot1oclock'] = [np.round(x) for x in spotcenters[1]]
    config['CALSPOTS']['spot4oclock'] = [np.round(x) for x in spotcenters[2]]
    config['CALSPOTS']['spot7oclock'] = [np.round(x) for x in spotcenters[3]]
    print "Image center: " , c
    print "DM angle: ", a
    print "lambda/D: ", str(lambdaoverd)
    config.write() 
    print "Updating configfile"


def run(configfilename, configspecfile):
    #configfilename = 'speckle_null_config.ini'
    #config = ConfigObj(configfilename)
    #configfilename = 'speckle_null_config.ini'
    hardwareconfigfile = 'speckle_instruments.ini'
    #configspecfile = 'speckle_null_config.spec'
    config = ConfigObj(configfilename, configspec=configspecfile)
    val = Validator()
    check = config.validate(val)
    print "\n\n\n"
    print "This program performs DM registration"
    print "It takes a background image, then an image with satellites"
    print "It subtracts the two, asks you to click on the satellites and then figures out lambda/d, the center and rotation of the image"
    print "It then saves these values to the configuration file "+configfilename
    print "At the end, it reloads the initial flatmap, undoing the satellites"
    print "\n\n\n"
    
    apmask = False
    if not apmask:
        aperturemask = np.ones((66,66))
    if apmask:
        aperturemask = dm.annularmask(66, 12, 33) 

    #pharo = hardware.PHARO_COM('PHARO', 
    #            configfile = hardwareconfigfile)
    #p3k = hardware.P3K_COM('P3K_COM', configfile = hardwareconfigfile)
    
    pharo = hardware.fake_pharo()
    p3k   = hardware.fake_p3k()
    #LOAD CURRENT FLATMAP 
    print("\n\nBeginning DM REGISTRATION\n\n")
    time.sleep(2)
    print("Retrieving bgd, flat, badpix")
    #bgds = flh.setup_bgd_dict(config)
    
    fake_bgds = {'bkgd':np.zeros((1024, 1024)), 
            'masterflat':np.ones((1024, 1024)),
            'badpix': np.zeros((1024, 1024))}
    print "WARNING: USING FAKE BGDS"
    bgds = fake_bgds.copy() 
    
    use_centoffs = config['NULLING']['cent_off']

    if use_centoffs == False:
        initial_flatmap = p3k.grab_current_flatmap()
        p3k.safesend2('hwfp dm=off')
    if use_centoffs == True:
        initial_centoffs= p3k.grab_current_centoffs()
        p3k.safesend2('hwfp dm=on')
    
    #status = p3k.load_new_flatmap(FM.convert_hodm_telem(initial_flatmap))
    firstim = pharo.take_src_return_imagedata(exptime = 4)
    print("\nComputing satellites")
    if use_centoffs:
        DMamp = 10
    else:
        DMamp = 33
    kvecr = 33
    additionmapx = DM.make_speckle_kxy(kvecr, 0,DMamp , 0) 
    additionmapy = DM.make_speckle_kxy(0,kvecr, DMamp, 0) 
    additionmap = additionmapx + additionmapy 

    additionmap = additionmap*aperturemask
    print ("sending new flatmap to p3k")
    if use_centoffs == False:
        status = p3k.load_new_flatmap((initial_flatmap + additionmap))
    if use_centoffs == True:
        status = p3k.load_new_centoffs((initial_centoffs + 
                            fmf.convert_flatmap_centoffs(additionmap)))
    image = pharo.take_src_return_imagedata(exptime = 4) 

    image_res = image-firstim
    spotcenters = get_satellite_centroids(image_res)
    
    print spotcenters
    c =find_center(spotcenters)
    a =find_angle(spotcenters)
    
    config['IM_PARAMS']['centerx'] = c[0]
    config['IM_PARAMS']['centery'] = c[1]
    config['IM_PARAMS']['angle']  = a 
    config['CALSPOTS']['spot10oclock'] = [np.round(x) for x in spotcenters[0]]
    config['CALSPOTS']['spot1oclock'] = [np.round(x) for x in spotcenters[1]]
    config['CALSPOTS']['spot4oclock'] = [np.round(x) for x in spotcenters[2]]
    config['CALSPOTS']['spot7oclock'] = [np.round(x) for x in spotcenters[3]]
    #cyclesperap = int(config['AOSYS']['dmcyclesperap'])
    lambdaoverd = get_lambdaoverd(spotcenters, kvecr)
    config['IM_PARAMS']['lambdaoverd'] = lambdaoverd
   
    print "Image center: " , c
    print "DM angle: ", a
    print "lambda/D: ", str(lambdaoverd)
    config.write() 
    
    print "RELOADING INITIAL FLATMAP"
    if use_centoffs == False:
        status = p3k.load_new_flatmap(initial_flatmap)
    if use_centoffs == True:
        status = p3k.load_new_centoffs(initial_centoffs)

def test_recenter():
    configfilename = 'speckle_null_config.ini'
    config = ConfigObj(configfilename)
    configfilename = 'speckle_null_config.ini'
    hardwareconfigfile = 'speckle_instruments.ini'
    configspecfile = 'speckle_null_config.spec'
    config = ConfigObj(configfilename, configspec=configspecfile)
    val = Validator()
    check = config.validate(val)
    
    pharo = hardware.PHARO_COM('PHARO', 
                configfile = hardwareconfigfile)
    p3k = hardware.P3K_COM('P3K_COM', configfile = hardwareconfigfile)
    #LOAD CURRENT FLATMAP 
    print("\n\nBeginning DM REGISTRATION\n\n")
    time.sleep(2)
    print("Retrieving bgd, flat, badpix")
    bgds = flh.setup_bgd_dict(config)
    
    use_centoffs = config['NULLING']['cent_off']

    initial_flatmap = p3k.grab_current_flatmap()
    p3k.safesend2('hwfp dm=off')
    
    DMamp = 33
    kvecr = 33
    
    additionmapx = DM.make_speckle_kxy(kvecr, 0,DMamp , 0) 
    additionmapy = DM.make_speckle_kxy(0,kvecr, DMamp, 0) 
    additionmap = additionmapx + additionmapy 

    print ("sending new flatmap to p3k")
    status = p3k.load_new_flatmap((initial_flatmap + additionmap))
    while True:
        image = pharo.take_src_return_imagedata(exptime = 4) 
        dm_reg_autorun(image, configfilename, configspecfile)
        time.sleep(2)
    pass    

if __name__ == "__main__":
    configfilename = 'speckle_null_config.ini'
    configspecfile = 'speckle_null_config.spec'
    run(configfilename, configspecfile)
