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
import medis.speckele_nulling.sn_hardware as hardware

import flatmapfunctions as fmap

def shift(image,shift_x,shift_y):
    """Returns a shifted image"""
    return np.roll(np.roll(image,shift_y,axis=0),shift_x,axis=1)

if __name__ == "__main__":
    dirwr         = '/data1/home/aousr/Desktop/speckle_nulling/SCC_Palomar/'
    folder_image  = '150507/last/'

    Image_name    = 'Im_nocoro'     
    FDMC_folder = '/data1/home/aousr/Desktop/speckle_nulling/SCC_Palomar/Flat_DM_Com/'
    FDMC_name   =   'new_flat_1.fits' #'Flat_DM_defaut.fits'

    num_im  = 10. # number of image we want recorded 

    exptime = 2.  # temps de pose de la camera en UT (unité de temps): 
                  # 2UT = 1.416 sec / 4UT = 2.832 sec / 6UT = 5.664 sec / 10UT = 9.912 sec / 

    # fichier de parametres pour PK3 et Pharo
    hardwareconfigfile = 'speckle_instruments_scc.ini'

    # initialisation de Pharo

    pharo = hardware.PHARO_COM('PHARO', configfile = hardwareconfigfile)

    # initialisation de P3k
    p3k   = hardware.P3K_COM('P3K_COM', configfile = hardwareconfigfile)

    # we load the DM flatmap

    #ipdb.set_trace()
    #initial_flatmap = p3k.grab_current_flatmap()
    initial_flatmap   = pf.open(FDMC_folder + FDMC_name)[0].data  
    # We apply to the DM the flatmap
    status          = p3k.load_new_flatmap(fmap.convert_hodm_telem(initial_flatmap))



    i = 0
    while i < num_im: 
        #('Image_number ' + str(int(i)) + '/' + str(int(num_im)))
        #Image_freq = pharo.take_src_return_imagedata(exptime)
        header, Image_freq = pharo.take_src_return_imagedata_header(exptime)

        # On enregistre l'image 
        pf.writeto(dirwr + folder_image + Image_name + "_" + str(int(i)) + ".fits", Image_freq, header=header, clobber=True, output_verify = 'ignore')                
        i+=1

    # We apply the initial flatmap to the DM
    status = p3k.load_new_flatmap(fmap.convert_hodm_telem(initial_flatmap))

    #stop
    #ipdb.set_trace()

