import medis.speckele_nulling.sn_preprocessing as pre
import cv2
import os
import matplotlib.pyplot as plt
import astropy.io.fits as pf
import ipdb
import medis.speckele_nulling.sn_math as snm
import numpy as np
from configobj import ConfigObj
import medis.speckele_nulling.sn_filehandling as snf
import medis.speckele_nulling.sn_hardware as hardware

def get_satellite_centroids(image, window=20):
    """centroid each satellite spot using a 2d gaussian"""
    spots = pre.get_spot_locations(image, 
            comment='Click on the satellites CLOCKWISE'+
                     'starting from 10 o clock')
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
    angs = np.array([np.arctan(reltocenter[i,1]/reltocenter[i,0])*180/np.pi for i in range(4)])
    fixangs = np.array([90,0,90,0])+angs
    assert np.std(fixangs)< 3.0
    angle = np.mean(fixangs)
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
    return avgdiagdist/cyclesperap/2.0

def define_control_region(image):
    """Click on an image to define the vertices of a polygon defining a region"""
    spots = pre.get_spot_locations(image, 
            comment='Click on the region you want to control')
    xs, ys = np.meshgrid( np.arange(image.shape[1]),
                            np.arange(image.shape[0]))
    pp = snm.points_in_poly(xs, ys, spots)
    return pp, spots 


if __name__ == "__main__":
    configfilename = 'speckle_null_config.ini'
    config = ConfigObj(configfilename)
    
    pharo = hardware.fake_pharo()

    regionfile = 'controlregion.fits'

    image = pharo.get_image()
    spotcenters = get_satellite_centroids(image)
    
    print spotcenters
    c =find_center(spotcenters)
    a =find_angle(spotcenters)
    
    config['IM_PARAMS']['centerx'] = c[0]
    config['IM_PARAMS']['centery'] = c[1]
    config['IM_PARAMS']['angle']  = a
    
    cyclesperap = int(config['AOSYS']['dmcyclesperap'])
    lambdaoverd = get_lambdaoverd(spotcenters, cyclesperap)
    config['IM_PARAMS']['lambdaoverd'] = lambdaoverd
    
   
    print "Image center: " , c
    print "DM angle: ", a
    p , verts= define_control_region(image)
    verts = np.array(verts)
    config['CONTROLREGION']['verticesx'] = [x[0] for x in verts]
    config['CONTROLREGION']['verticesy'] = [y[1] for y in verts]
    snf.writeout(p, regionfile)
    config['CONTROLREGION']['filename'] = regionfile
    config.write() 

    print "Configuration file written to "+config.filename    
    controlimage = p*image
    plt.imshow(controlimage)
    plt.xlim( (np.min(verts[:,0]), np.max(verts[:,0])))
    plt.ylim( (np.min(verts[:,1]), np.max(verts[:,1])))
    plt.show()
