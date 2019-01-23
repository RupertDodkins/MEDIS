import sn_preprocessing as pre
import cv2
import os
import matplotlib.pyplot as plt
import astropy.io.fits as pf
import ipdb
import sn_math as snm
import numpy as np
from configobj import ConfigObj
import sn_filehandling as flh
import sn_hardware as hardware
import flatmapfunctions as FM
from validate import Validator
import dm_functions as DM
import time
import detect_speckles

class speckle:
    def __init__(self, image,xp, yp, config):
        self.imparams = config['IM_PARAMS']
        self.abc       = config['INTENSITY_CAL']['abc']
        self.xcentroid = xp 
        self.ycentroid = yp 
        self.kvec      = DM.convert_pixels_kvecs(self.xcentroid,
                                                 self.ycentroid,
                                                 **self.imparams)
        self.kvecx     = self.kvec[0]
        self.kvecy     = self.kvec[1]
        self.krad      = np.linalg.norm((self.kvecx, self.kvecy))
        self.aperture  = detect_speckles.create_speckle_aperture(
                image, self.xcentroid, self.ycentroid, config['INTENSITY_CAL']['aperture_radius'])
        self.intensity = detect_speckles.get_speckle_photometry(image, self.aperture)
        self.intensities = [None, None, None, None]

    def generate_flatmap(self, phase):
        """generates flatmap with a certain phase for this speckle"""
        s_amp = DM.amplitudemodel(self.intensity, self.krad, **self.abc)
        print 's_amp: ', s_amp, 'self.krad: ', self.krad, 'phase: ', phase	
        return DM.make_speckle_kxy(self.kvecx, self.kvecy, s_amp, phase)
    def get_null_phase(self, intensities, phases):
        A, B, C, D = intensities 
        phase0 =  np.arctan((D-B)/(A-C))
        if phase0 < 0:
            phase0 += np.pi
        
        null_phase = np.pi - phase0
        ind = np.argmin(np.abs(null_phase - np.array(phases)))
        if len((np.where(intensities > intensities[ind]))[0]) < 2:
            null_phase += np.pi
        return null_phase
    

if __name__ == "__main__":
    #configfilename = 'speckle_null_config.ini'
    #config = ConfigObj(configfilename)
    configfilename = 'speckle_null_config.ini'
    hardwareconfigfile = 'speckle_instruments.ini'
    configspecfile = 'speckle_null_config.spec'
    config = ConfigObj(configfilename, configspec=configspecfile)
    val = Validator()
    check = config.validate(val)
    
    pharo = hardware.PHARO_COM('PHARO', 
                configfile = hardwareconfigfile)
    p3k = hardware.P3K_COM('P3K_COM', configfile = hardwareconfigfile)
    im_params= config['IM_PARAMS']
    abc = config['INTENSITY_CAL']['abc']
    bgds = flh.setup_bgd_dict(config) 
    #test passing centoffs bakc and forth
    #co = p3k.grab_current_centoffs()
    currflat = p3k.grab_current_flatmap()
    #pdb.set_trace()
    ipdb.set_trace()
    co2 = p3k.load_new_flatmap(currflat, centroid_offset=True)
    perturbmap = DM.make_speckle_xy(332, 448, 50, 0)
    p3k.load_new_flatmap(currflat+perturbmap, centroid_offset = True)
    #first_flatmap = p3k.grab_current_flatmap()
    #x_p, y_p = 471, 287.0
    #intended_counts= 300
    #
    #kx, ky = DM.convert_pixels_kvecs(x_p, y_p, **im_params)
    #kr = np.linalg.norm((kx, ky))
    #print "kr: ", kr
    #converted_amplitude = DM.amplitudemodel(intended_counts,kr, **abc)
    #print "converted: " + str(converted_amplitude)
    #
    #perturbmap = DM.make_speckle_xy(x_p, y_p, converted_amplitude, 38*np.pi/180, **im_params)
    #firstim = pharo.take_src_return_imagedata(exptime = 4)
    #firstim = pre.equalize_image(firstim, **bgds)
    ##ipdb.set_trace()
    #p3k.load_new_flatmap(first_flatmap+perturbmap)
    #
    #secondim = pharo.take_src_return_imagedata(exptime = 4)
    #secondim = pre.equalize_image(secondim, **bgds)
    #redim = secondim#-firstim
    #ap = detect_speckles.create_speckle_aperture(redim, x_p, y_p, 5)
    #phot = detect_speckles.get_speckle_photometry(redim, ap)
    ##print "Actual photometry ", phot

    ###detected_specklepos = [x_p, y_p]
    ###s = speckle(redim,x_p, y_p, config)
    ###intensities = []
    ###for phase in config['NULLING']['phases']:
    ###    flatmap_perturb = first_flatmap + perturbmap+ s.generate_flatmap(phase)
    ###    p3k.load_new_flatmap(flatmap_perturb)
    ###    #time.sleep(0.25)
    ###    im = pharo.take_src_return_imagedata(exptime = 4)
    ###    im = pre.equalize_image(im, **bgds)
    ###    diffim = im #- firstim
    ###    intensity = detect_speckles.get_speckle_photometry(diffim, s.aperture)
    ###    intensities.append(intensity)
    ###    print "phase: ",phase, " intensity: ", intensity
    ###null_phase = null_phase(intensities, config['NULLING']['phases'])

    ###p3k.load_new_flatmap(first_flatmap+perturbmap+s.generate_flatmap(null_phase))
