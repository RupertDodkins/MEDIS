import numpy as np
import astropy.io.fits as pf
from configobj import ConfigObj
import cv2
import ipdb
import matplotlib.pyplot as plt
import sn_hardware as hardware
import dm_functions as DM
import sn_filehandling as flh
import flatmapfunctions as fmap
import detect_speckles
from validate import Validator
import sn_preprocessing as pre


if __name__ == "__main__":

    configfilename = 'speckle_null_config.ini'
    hardwareconfigfile = 'speckle_instruments.ini'
    configspecfile = 'speckle_null_config.spec'
    config = ConfigObj(configfilename, configspec=configspecfile)
    val = Validator()
    check = config.validate(val)
    
    print("Retrieving bgd, flat, badpix")
    bgds = flh.setup_bgd_dict(config)
    im_params = config['IM_PARAMS']
    abc = config['INTENSITY_CAL']['abc']
    phases = config['NULLING']['phases']
    cx = round(im_params['centerx'])
    cy = round(im_params['centery'])
    
    vertsx = config['CONTROLREGION']['verticesx']
    vertsy = config['CONTROLREGION']['verticesy']
    
    controlregion = pf.open(config['CONTROLREGION']['filename'])[0].data
    #Simulator
    #pharo = hardware.fake_pharo()
    
    #Real thing
    pharo = hardware.PHARO_COM('PHARO', 
                configfile = hardwareconfigfile)
    #LOAD P3K HERE
    p3k = hardware.P3K_COM('P3K_COM', configfile = hardwareconfigfile)
    #LOAD CURRENT FLATMAP 
    initial_flatmap = p3k.grab_current_flatmap()

    add = DM.make_speckle_xy([485], [250], [50], [0], **im_params)
    p3k.load_new_flatmap(add+initial_flatmap)
    pharo.take_src_return_imagedata(exptime=4)

    
