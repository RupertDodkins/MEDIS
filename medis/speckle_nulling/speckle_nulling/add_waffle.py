import sn_preprocessing as pre
import cv2
import os
import matplotlib.pyplot as plt
import pyfits as pf
import ipdb
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




if __name__ == "__main__":
    #configfilename = 'speckle_null_config.ini'
    #config = ConfigObj(configfilename)
    configfilename = 'speckle_null_config.ini'
    hardwareconfigfile = 'speckle_instruments.ini'
    configspecfile = 'speckle_null_config.spec'
    config = ConfigObj(configfilename, configspec=configspecfile)
    val = Validator()
    check = config.validate(val)
    
    print "\n\n\n"
    print "This program adds satellites to the flatmap or centroid offset"
    print "\n\n\n"
    
    while True:
        uc = raw_input('Do you wish to use centroid offsets? (Y/N)')
        if uc == 'Y':
            use_centoffs =  True
            break
        elif uc == 'N':
            use_centoffs = False
            break
        else:
            "Please enter Y or N"
    
    while True:
        dma = raw_input('Please enter the DM amplitude you want(30 is nice)')
        try:
            DMamp = int(dma) 
            break
        except:
            continue 
    
    while True:
        kvr = raw_input('Please enter the radial k_vector you want (33 is max)')
        try:
            kvecr = float(kvr) 
            break
        except:
            continue 
    #DMamp = 30
    #kvecr = 33
    pharo = hardware.PHARO_COM('PHARO', 
                configfile = hardwareconfigfile)
    p3k = hardware.P3K_COM('P3K_COM', configfile = hardwareconfigfile)
    #LOAD CURRENT FLATMAP 
    print("\n\nBeginning WAFFLE GENERATION\n\n")
    time.sleep(2)
    print("Retrieving bgd, flat, badpix")
    bgds = flh.setup_bgd_dict(config)

    if use_centoffs == False:
        initial_flatmap = p3k.grab_current_flatmap()
        p3k.safesend2('hwfp dm=off')
    if use_centoffs == True:
        initial_centoffs= p3k.grab_current_centoffs()
    
    #status = p3k.load_new_flatmap(FM.convert_hodm_telem(initial_flatmap))
    firstim = pharo.take_src_return_imagedata(exptime = 4)
    print("\nComputing satellites")
    additionmapx = DM.make_speckle_kxy(kvecr, 0,DMamp , 0) 
    additionmapy = DM.make_speckle_kxy(0,kvecr, DMamp, 0) 
    additionmap = additionmapx + additionmapy 
    print ("sending new flatmap to p3k")
    
    if use_centoffs == False:
        status = p3k.load_new_flatmap((initial_flatmap + additionmap))
    if use_centoffs == True:
        status = p3k.load_new_centoffs((initial_centoffs + 
                            fmf.convert_flatmap_centoffs(additionmap)))
    image = pharo.take_src_return_imagedata(exptime = 4) 

    
    reload = raw_input('Do you want to reload the initial map/centoffs?[Y/N]')
    ipdb.set_trace()
    if reload == 'Y':
        print "RELOADING INITIAL FLATMAP"
        if use_centoffs == False:
            status = p3k.load_new_flatmap(initial_flatmap)
        if use_centoffs == True:
            status = p3k.load_new_centoffs(initial_centoffs)
    else:
        pass 
