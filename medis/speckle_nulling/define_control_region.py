import medis.speckele_nulling.sn_preprocessing as pre
import os
import matplotlib.pyplot as plt
import astropy.io.fits as pf
import ipdb
import medis.speckele_nulling.sn_math as snm
import numpy as np
from configobj import ConfigObj
import medis.speckele_nulling.sn_filehandling as flh
import medis.speckle_nulling.sn_hardware as hardware
import flatmapfunctions as FM
from validate import Validator
import medis.speckele_nulling.dm_functions as DM
import time


def define_control_region(image):
    """SHIFT- Click on the image to define the vertices of a polygon defining a region. May be convex or concave"""
    spots = pre.get_spot_locations(image, 
            comment='SHIFT-click to select the vertices region you want to control\n, then close the window')
    xs, ys = np.meshgrid( np.arange(image.shape[1]),
                            np.arange(image.shape[0]))
    pp = snm.points_in_poly(xs, ys, spots)
    return pp, spots 

if __name__ == "__main__":
    #configfilename = 'speckle_null_config.ini'
    #config = ConfigObj(configfilename)
    
    configfilename = 'speckle_null_config.ini'
    hardwareconfigfile = 'speckle_instruments.ini'
    configspecfile = 'speckle_null_config.spec'
    config = ConfigObj(configfilename, configspec=configspecfile)
    val = Validator()
    check = config.validate(val)
    
    regionfilename = config['CONTROLREGION']['filename']
    #pharo = hardware.fake_pharo()
    #Real thing
    #pharo = hardware.PHARO_COM('PHARO', 
    #            configfile = hardwareconfigfile)
    ##LOAD P3K HERE
    #p3k = hardware.P3K_COM('P3K_COM', configfile = hardwareconfigfile)

    pharo = hardware.fake_pharo()
    p3k   = hardware.fake_p3k()

    print("\n\nBeginning CONTROL REGION DEFINITION\n\n")
    time.sleep(1)

    print("Retrieving bgd, flat, badpix")
    #bgds = flh.setup_bgd_dict(config)
    
    fake_bgds = {'bkgd':np.zeros((1024, 1024)), 
            'masterflat':np.ones((1024, 1024)),
            'badpix': np.zeros((1024, 1024))}
    print "WARNING: USING FAKE BGDS"
    bgds = fake_bgds.copy() 
    firstim = pharo.take_src_return_imagedata(exptime = 4)
    image = pre.equalize_image(firstim, **bgds)
    image = firstim

    p , verts= define_control_region(image)
    verts = np.array(verts)
    config['CONTROLREGION']['verticesx'] = [x[0] for x in verts]
    config['CONTROLREGION']['verticesy'] = [y[1] for y in verts]
    flh.writeout(p, regionfilename)
    #config['CONTROLREGION']['filename'] = regionfilename
    config.write() 

    
    print "Configuration file written to "+config.filename    
    controlimage = p*image
    plt.imshow(controlimage)
    plt.xlim( (np.min(verts[:,0]), np.max(verts[:,0])))
    plt.ylim( (np.min(verts[:,1]), np.max(verts[:,1])))
    plt.title("This is your control region"+
              "\n saved as "+regionfilename)
    plt.show()
