# -*- coding: utf-8 -*-
"""
Created on Sat Apr 18 19:43:44 2015

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


import Est_SCC_V0 as Esti

#(fr) Permet de faire des plots
#(en) To plot something
import matplotlib.pyplot as plt

#(fr) Pour initialiser PHARO et P3K
#(en) To initialize PHARO and P3K
import sn_hardware as hardware

#(fr) Pour appliquer une commande au DM
#(en) To apply a commande to the DM
import flatmapfunctions as fmap

from configobj import ConfigObj
from validate import Validator

if __name__ == "__main__":

    #Instrument = 'SCC_1'
    #Instrument = 'SCC_2'
    Instrument = 'MRSCC'
 
    # Aousr
    dirwr = '/data1/home/aousr/Desktop/speckle_nulling/SCC_Palomar/150507/last/Matrice/'

    # Flatmap DM
    FDMC_folder = '/data1/home/aousr/Desktop/speckle_nulling/SCC_Palomar/Flat_DM_Com/'
    #FDMC_name   = 'sum_sin_10_100_54_coeff_1_2_1.fits' #'sum_0_10_68_coeff_2_3.2_0.5.fits' # 'Flat_DM_defaut.fits' #'sum_0_10_68_coeff_2_3.2_0.5'# 'ph_random_plus_flat.fits' # 'Flat_DM_defaut.fits' #

    FDMC_name   =  'new_flat_1.fits' # 'flat_p_sin.fits' # 'new_flat_1.fits' #'Flat_DM_defaut.fits'

    folder_Correction = 'Correction/'

    folder_FDM_Im = 'FDM_Im/'
    folder_DM_Com = 'DM_Com/'
    folder_SCC_Im = 'SCC_Im/'
    folder_CDF    = 'CDF/' 
    folder_Matrix = 'Mat_inter/MatCom/'

    
    # Number of iteration
    nb_ite  = 100.
#    nb_im   = 4.

    #(fr) Temps de pose de la camera en UT (unité de temps): 
    #(en) Exposure time of the camera in UT (unit of time):    
    # 2UT = 1.416 sec / 4UT = 2.832 sec / 6UT = 5.664 sec / 10UT = 9.912 sec /  20UT = 19.824 sec / 30UT = sec / 
    exptime = 4.        
    
    # fichier de parametres pour PK3 et Pharo
    hardwareconfigfile = 'speckle_instruments_scc.ini'

    # initialisation de Pharo
    # Real thing
    pharo = hardware.PHARO_COM('PHARO', configfile = hardwareconfigfile)

    # LOAD P3K HERE
    # initialisation de P3k
    p3k   = hardware.P3K_COM('P3K_COM', configfile = hardwareconfigfile)

    # Load the flatmap of the DM
    # initial_flatmap = p3k.grab_current_flatmap()
    initial_flatmap = pf.open(FDMC_folder + FDMC_name)[0].data      

    # We apply to the DM the initial flatmap
    status          = p3k.load_new_flatmap(fmap.convert_hodm_telem(initial_flatmap))

    ipdb.set_trace()
 
    phdm   = initial_flatmap

    # On enregistre la commande DM
    DM_commande_save = phdm
    pf.writeto(dirwr + folder_Correction + folder_DM_Com + "Commande_" + str(int(0)) + ".fits", DM_commande_save,clobber=True)                        

    i = 0
    while i <nb_ite:

        if i > 0:
            phdm -= pf.open(dirwr + folder_Correction + folder_DM_Com + "Commande_" + str(int(i)) + ".fits")[0].data 
        
        # We apply the command to the DM
        status  = p3k.load_new_flatmap(fmap.convert_hodm_telem(phdm))                
        
        # We read the image with pharo

	header, Im_SCC_tmp= pharo.take_src_return_imagedata_header(exptime)

        # On enregistre l'image
        pf.writeto(dirwr + folder_Correction + folder_SCC_Im + "SCC_image_ite_" + str(int(i)) + ".fits", Im_SCC_tmp, header = header, clobber=True, output_verify = 'ignore')                

        # On enregistre la commande envoyée au DM   
        pf.writeto(dirwr + folder_Correction + folder_DM_Com  + "DM_Com_" + str(int(i)) + ".fits",phdm,clobber=True)                  

        i+=1
        ipdb.set_trace()


    # We apply the initial flatmap to the DM
    #status = p3k.load_new_flatmap(fmap.convert_hodm_telem(initial_flatmap))

    #stop
    #ipdb.set_trace()
# pf.writeto(dirwr + folder_Correction + folder_SCC_Im + "SCC_image_ite_" + str(int(i)) + "_" + str(int(j)) +".fits", Im_SCC_tmp, header = header, clobber=True, output_verify = 'ignore')       
