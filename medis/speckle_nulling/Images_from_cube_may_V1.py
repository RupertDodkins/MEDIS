# -*- coding: utf-8 -*-
"""
Created on Wed Apr 15 15:26:29 2015

@author: J-R
"""

#(fr) pour les math de base
#(en) to do basic math
import numpy as np

#(fr) pour lire et enregistrer les fits
#(en) To read and write fits
import astropy.io.fits as pf

#(fr) Pour faire des stops
#(en) To stop the program
import ipdb

#(fr) Permet de faire des plots
#(en) To plot something
import matplotlib.pyplot as plt

#(fr) Pour initialiser PHARO et P3K
#(en) To initialize PHARO and P3K
import medis.speckle_nulling.sn_hardware as hardware

#(fr) Pour appliquer une commande au DM
#(en) To apply a commande to the DM
import flatmapfunctions as fmap

from configobj import ConfigObj

if __name__ == "__main__":

    # Mac JR 
    # dirwr = '/Users/J-R/Desktop/PHD_JR/Work/Palomar/Run_mai/150507/Matrice_0_150506_offline/'
    # Aousr
    dirwr = '/data1/home/aousr/Desktop/speckle_nulling/SCC_Palomar/150507/last/Random/2/'

    # Flatmap DM
    FDMC_folder = '/data1/home/aousr/Desktop/speckle_nulling/SCC_Palomar/Flat_DM_Com/'
    FDMC_name   =  'Flat_DM_defaut.fits' # 'flat_DM_3.fits' # 'new_flat_1.fits' #
    

    #folder_FDM_Im = 'Mat_inter/FDM_Im/'
    #folder_DM_Com = 'Mat_inter/DM_Com/'
    #folder_SCC_Im = 'Mat_inter/SCC_Im/'
    #folder_CDF    = 'CDF/' 


    folder_FDM_Im = 'FDM_Im/'
    folder_DM_Com = 'DM_Com/'
    folder_SCC_Im = 'SCC_Im/'
    folder_CDF    = 'CDF/' 
    
    #cube_name = 'Freq_DM_map_cube.fits'
    #cube_name = 'Cube_Freq60_5lsd_rampe.fits'
    cube_name = 'Freq_tosend_Random.fits'
    
    # on enregistre une image dans "folder_DM_Flat_image" toutes les "FDM_val" images
    FDM_val = 22  
    
    #(fr) Temps de pose de la camera en UT (unité de temps): 
    #(en) Exposure time of the camera in UT (unit of time):    
    # 2UT = 1.416 sec / 4UT = 2.832 sec / 6UT = 5.664 sec / 10UT = 9.912 sec /  20UT = 19.824 sec / 30UT = sec / 
    exptime = 4.  
    
    #(fr) fichier de parametres pour PK3 et Pharo
    hardwareconfigfile = 'speckle_instruments_scc.ini'

    #(fr) Initialisation de PHARO
    #(en) Initialisation of PHARO
    pharo = hardware.PHARO_COM('PHARO', configfile = hardwareconfigfile)

    #(fr) Initialisation de P3K
    #(en) Initialisation de P3K
    p3k   = hardware.P3K_COM('P3K_COM', configfile = hardwareconfigfile)

    # Load the flatmap of the DM
    #initial_flatmap = p3k.grab_current_flatmap()
    initial_flatmap = pf.open(FDMC_folder + FDMC_name)[0].data    
    #pf.writeto(FDMC_folder + FDMC_name, initial_flatmap , clobber=True)     


    # We apply to the DM the initial flatmap
    status          = p3k.load_new_flatmap(fmap.convert_hodm_telem(initial_flatmap))
    # On remet le DM à plat
    status = p3k.load_new_flatmap(fmap.convert_hodm_telem(initial_flatmap))

    # On remet le DM à plat
    status = p3k.load_new_flatmap(fmap.convert_hodm_telem(initial_flatmap))
    
    # On remet le DM à plat
    status = p3k.load_new_flatmap(fmap.convert_hodm_telem(initial_flatmap))
        
    # stop pour debug 
    ipdb.set_trace()

    #(fr) On lit le cube de fréquence à appliquer
    #(en) We read a cube of frequency to apply
    Cube_freq = pf.open(dirwr + folder_CDF + cube_name)[0].data

    i = 0.
    while i < len(Cube_freq): 
        
        # we register each "FDM_val" images an image with the DM flat
        if (i % FDM_val) == 0:
            # We apply to the DM the initial flatmap
            status  = p3k.load_new_flatmap(fmap.convert_hodm_telem(initial_flatmap))
            # We read an image  
            header,im_flat = pharo.take_src_return_imagedata_header(exptime)
            # We save this image 
            pf.writeto(dirwr + folder_FDM_Im + "FDM_Im_Com_" + str(int(i)) + ".fits", im_flat , header = header, clobber=True, output_verify = 'ignore')        
        
        # Construction de la commmande pour le DM
        DM_commande = Cube_freq[i,:,:] + initial_flatmap

        # On applique la commande au DM
        status = p3k.load_new_flatmap(fmap.convert_hodm_telem(DM_commande))

        # On enregistre la commande envoyée au DM   
        pf.writeto(dirwr + folder_DM_Com + "DM_Com_" + str(int(i)) + ".fits", DM_commande,clobber=True)                  

        # We are taking one image with pharo. The exposture time is exptime in UT (unit of time)
        header, im = pharo.take_src_return_imagedata_header(exptime)

        # On enregistre l'image
        pf.writeto(dirwr + folder_SCC_Im + "SCC_im_Com_" + str(int(i)) + ".fits", im, header = header, clobber=True, output_verify = 'ignore')                
        
        # On remet le DM à plat
        status = p3k.load_new_flatmap(fmap.convert_hodm_telem(initial_flatmap))
        # On remet le DM à plat
        status = p3k.load_new_flatmap(fmap.convert_hodm_telem(initial_flatmap))
        # On remet le DM à plat
        status = p3k.load_new_flatmap(fmap.convert_hodm_telem(initial_flatmap))
        # On remet le DM à plat
        status = p3k.load_new_flatmap(fmap.convert_hodm_telem(initial_flatmap))

        i+=1
            
    # We apply the initial flatmap to the DM
    status = p3k.load_new_flatmap(fmap.convert_hodm_telem(initial_flatmap))

    #stop
    #ipdb.set_trace()
