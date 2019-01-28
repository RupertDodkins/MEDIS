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
import sn_processing as pro
import flatmapfunctions as FM
from validate import Validator
import dm_functions as DM
import time


def define_control_annulus(image, cx= None, cy = None,
                           rad_in = None, rad_out = None):
    #"""SHIFT- Click on the image to define the vertices of a polygon defining a region. May be convex or concave"""
    #spots = pre.get_spot_locations(image, 
    #        comment='SHIFT-click to select IN THIS ORDER, inner radius, and outer radius of the annular region to control')
    spots = [(cx +rad_in, cy), (cx+rad_out, cy)]
    xs, ys = np.meshgrid( np.arange(image.shape[1]),
                            np.arange(image.shape[0]))
    return ( pro.annulus(image, cx, cy, rad_in, rad_out), spots)

if __name__ == "fake__main__":
    pharo = hardware.fake_pharo()
    im = pharo.get_image()
    ann = define_control_annulus(im)
    plt.imshow(ann*im);plt.show()

def run(configfilename, configspecfile):    
    hardwareconfigfile = 'speckle_instruments.ini'
    config = ConfigObj(configfilename, configspec=configspecfile)
    val = Validator()
    check = config.validate(val)
    
    centx = config['IM_PARAMS']['centerx']
    centy = config['IM_PARAMS']['centery']
    lambdaoverd = config['IM_PARAMS']['lambdaoverd']
    
    regionfilename = config['CONTROLREGION']['filename']
    # pharo = hardware.fake_pharo()
    #Real thing
    
    innerlam = config['CONTROLREGION']['innerannulus'] 
    outerlam = config['CONTROLREGION']['outerannulus'] 
    
    # pharo = hardware.PHARO_COM('PHARO', 
    #             configfile = hardwareconfigfile)
    #LOAD P3K HERE
    pharo = hardware.fake_pharo()
    print("Retrieving bgd, flat, badpix")
    # bgds = flh.setup_bgd_dict(config)
    fake_bgds = {'bkgd':np.zeros((1024, 1024)), 
           'masterflat':np.ones((1024, 1024)),
           'badpix': np.zeros((1024, 1024))}
    print "WARNING: USING FAKE BGDS"
    bgds = fake_bgds.copy() 
    
    firstim = pharo.take_src_return_imagedata(exptime = 4)
    image = pre.equalize_image(firstim, **bgds)
    image = firstim
    ann, verts = define_control_annulus(image, cx = centx, cy = centy, 
                         rad_in = lambdaoverd*innerlam,
                         rad_out= lambdaoverd*outerlam)
    flh.writeout(ann*1.0, regionfilename)
    config['CONTROLREGION']['verticesx'] = [centx]+[x[0] for x in verts]
    config['CONTROLREGION']['verticesy'] = [centy]+[y[1] for y in verts]
    config.write() 
    
    print "Configuration file written to "+config.filename    

if __name__ == "__main__":
    configfilename = 'speckle_null_config.ini'
    configspecfile = 'speckle_null_config.spec'

    run(configfilename, configspecfile)
    #configfilename = 'speckle_null_config.ini'
    #config = ConfigObj(configfilename)
