# -*- coding: utf-8 -*-
"""
Created on Wed Apr 15 15:26:29 2015

@author: J-R
"""

# pour les math de base
import numpy as np

# pour lire et enregistrer les fits
import pyfits as pf

from configobj import ConfigObj
import ipdb
# permet de faire des plots
import matplotlib.pyplot as plt

# pour initialiser pharo et p3k
import sn_hardware as hardware
import dm_functions as DM
import flatmapfunctions as fmap
import detect_speckles
from validate import Validator
import sn_preprocessing as pre

def shift(image,shift_x,shift_y):
    """Returns a shifted image"""
    return np.roll(np.roll(image,shift_y,axis=0),shift_x,axis=1)


if __name__ == "__main__":

    folder_DM_Flat_image = '150419/K_short_Mat/Flat_DM_Image/'
    folder_DM_vector     = '150419/K_short_Mat/DM_Vector_Mat/'
    folder_SCC_image     = '150419/K_short_Mat/SCC_Image_Mat/'
    folder_cube          = '150419/K_short_Mat/'
     
    
    FDM_val = 22   # on enregistre une image DM_flat toutes les FDM_flat images
    ampl    = 1    # amplitude
    nb_im   = 1.   #(attention si > à 1 il faut faire une medianne du cube - (Ctrl-F: £££) )
    exptime = 4.   # temps de pose de la camera en UT (unité de temps): 
                   # 2UT = 1.416 sec / 4UT = 2.832 sec / 6UT = 5.664 sec / 10UT = 9.912 sec / 

    dirwr = '/data1/home/aousr/Desktop/speckle_nulling/SCC/'

    # fichier de parametres pour PK3 et Pharo
    hardwareconfigfile = 'speckle_instruments_scc.ini'

    # initialisation de Pharo
    # Real thing
    pharo = hardware.PHARO_COM('PHARO', configfile = hardwareconfigfile)

    # LOAD P3K HERE
    # initialisation de P3k
    p3k   = hardware.P3K_COM('P3K_COM', configfile = hardwareconfigfile)

    # LOAD and APPLY a flatmap
    initial_flatmap = np.zeros((66, 66))
    initial_flatmap = p3k.grab_current_flatmap()

    # We apply to the DM the initial flatmap
    status          = p3k.load_new_flatmap(fmap.convert_hodm_telem(initial_flatmap))

    #READ Image before any correction
    im_flat         = pharo.take_src_return_imagedata(exptime) #works, tested

    # stop pour debug
    #ipdb.set_trace()

    # We read a cube of frequency
    #hdulist = pf.open(dirwr + 'Freq_DM_map_cube.fits')
    #hdulist = pf.open(dirwr + 'Freq_start.fits')
    #hdulist = pf.open(dirwr + 'Random.fits')
    #hdulist = pf.open(dirwr + 'Rampe_cosinus.fits')
    #hdulist = pf.open(dirwr + 'Rampe_sinus.fits') 
    #hdulist = pf.open(dirwr + 'Freq_DM_map_cube462_ampl40_17avril.fits')
    hdulist = pf.open(dirwr + folder_cube + 'ZONE_Freq_DM_map_cube_18avril_1.fits')
    Cube_freq = hdulist[0].data
    hdulist.close()

    i = 45
    while i < len(Cube_freq): 
        #print, 'We are working with the frequency number ' + str(int(i)) + '/' + str(int(len(Cube_freq)))
        if (i % FDM_val) == 0:
            # We apply to the DM the initial flatmap
            status          = p3k.load_new_flatmap(fmap.convert_hodm_telem(initial_flatmap))
            #READ Image before any correction
            im_flat         = pharo.take_src_return_imagedata(exptime) #works, tested
            im_flat         = im_flat[np.newaxis,:,:]
            pf.writeto(dirwr + folder_DM_Flat_image + "DM_flat_Im_" + str(int((i%FDM_val)/FDM_val)) + '_afterfreq_' + str(int(i)) + ".fits", im_flat ,clobber=True)        
        
        # Construction de la commmande pour le DM
        DM_commande = Cube_freq[i,:,:]*ampl + initial_flatmap
        # On applique la commande au DM
        status = p3k.load_new_flatmap(fmap.convert_hodm_telem(DM_commande))   
        # On enregistre la commande au DM
        DM_commande_save = DM_commande[np.newaxis,:,:]
        pf.writeto(dirwr + folder_DM_vector + "DM_vector_mat_number_" + str(int(i)) + ".fits", DM_commande,clobber=True)                

        # We are taking "nb_im" images. Cube contain all these images 
        w = 0    

        # We are taking one image with pharo. The exposture time is exptime in UT (unit of time)
        im = pharo.take_src_return_imagedata(exptime)
        # We add a dimention to the image to build a cube of image
        Image_freq = im[np.newaxis,:,:]

        # On remet le DM à plat
        status = p3k.load_new_flatmap(fmap.convert_hodm_telem(initial_flatmap))

        # On enregistre l'image
        pf.writeto(dirwr + folder_SCC_image + "SCC_image_mat_number_" + str(int(i)) + ".fits", Image_freq,clobber=True)                
        
        i+=1
            
    # We apply the initial flatmap to the DM
    status = p3k.load_new_flatmap(fmap.convert_hodm_telem(initial_flatmap))

    #stop
    #ipdb.set_trace()
