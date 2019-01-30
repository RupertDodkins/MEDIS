# -*- coding: utf-8 -*-
"""
Created on Sat Apr 18 09:54:16 2015

@author: J-R
"""

# pour les math de base
import numpy as np

# pour lire et enregistrer les fits
import astropy.io.fits as pf

from configobj import ConfigObj
import ipdb
# permet de faire des plots
import matplotlib.pyplot as plt

# pour initialiser pharo et p3k
import medis.speckle_nulling.sn_hardware as hardware
import medis.speckle_nulling.dm_functions as DM
import flatmapfunctions as fmap
import detect_speckles
from validate import Validator
import medis.speckle_nulling.sn_preprocessing as pre


def shift(image,shift_x,shift_y):
    """Returns a shifted image"""
    return np.roll(np.roll(image,shift_y,axis=0),shift_x,axis=1)


if __name__ == "__main__":

    dirwr      = '/data1/home/aousr/Desktop/speckle_nulling/SCC/'
    folder_image     = '150418/Flat/Flat_2UT_21h10/'
    Image_name = 'Flat_2UT_21h10'     
 
    num_im  = 20. # number of image we want recorded 
    ampl    = 1.  # amplitude
    exptime = 2.  # temps de pose de la camera en UT (unité de temps): 
                  # 2UT = 1.416 sec / 4UT = 2.832 sec / 6UT = 5.664 sec / 10UT = 9.912 sec / 

    # fichier de parametres pour PK3 et Pharo
    hardwareconfigfile = 'speckle_instruments_scc.ini'

    # initialisation de Pharo
    # Real thing
    pharo = hardware.PHARO_COM('PHARO', configfile = hardwareconfigfile)

    # LOAD P3K HERE
    # initialisation de P3k
    #p3k   = hardware.P3K_COM('P3K_COM', configfile = hardwareconfigfile)

    # LOAD and APPLY a flatmap
    #initial_flatmap = np.zeros((66, 66))
    #initial_flatmap = p3k.grab_current_flatmap()
    # We apply to the DM the initial flatmap
    #status          = p3k.load_new_flatmap(fmap.convert_hodm_telem(initial_flatmap))

    i = 0
    while i < num_im: 
        #('Image_number ' + str(int(i)) + '/' + str(int(num_im)))

        Image_freq = pharo.take_src_return_imagedata(exptime)

        # On enregistre l'image 
        pf.writeto(dirwr + folder_image + Image_name + "_" + str(int(i)) + ".fits", Image_freq,clobber=True)                
        i+=1

    #print, 'Change the name of the image'
    #print, 'Change the name of the image'
    #print, 'Change the name of the image'
    #print, 'Change the name of the image'
            
    # We apply the initial flatmap to the DM
    #status = p3k.load_new_flatmap(fmap.convert_hodm_telem(initial_flatmap))

    #stop
    #ipdb.set_trace()
