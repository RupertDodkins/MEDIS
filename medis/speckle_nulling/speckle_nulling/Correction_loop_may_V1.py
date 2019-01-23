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
 
    # Mac JR 
    # dirwr = '/Users/J-R/Desktop/PHD_JR/Work/Palomar/Simu_Python/Matrice_PB_1/'
    # Aousr
    dirwr = '/data1/home/aousr/Desktop/speckle_nulling/SCC_Palomar/150506/Matrice_0/'

    # Flatmap DM
    FDMC_folder = '/data1/home/aousr/Desktop/speckle_nulling/SCC_Palomar/Flat_DM_Com/'
    FDMC_name   = 'Flat_DM_defaut.fits' 
    
    #config file 
    configfilename = 'SCC_config.ini'
    configspecfile = 'SCC_config.spec'


    folder_Correction = 'Correction_3/'

    folder_FDM_Im = 'FDM_Im/'
    folder_DM_Com = 'DM_Com/'
    folder_SCC_Im = 'SCC_Im/'
    folder_CDF    = 'CDF/' 
    folder_Matrix = 'Mat_inter/MatCom/'

    # On importe un flat
    Flat = pf.open(dirwr + folder_CDF + 'Flat.fits')[0].data
    # On importe un dark
    Dark = pf.open(dirwr + folder_CDF + 'Dark_2UT_40mas.fits')[0].data 
    # On importe le cube de fréquences
    Cube = pf.open(dirwr + folder_CDF + 'Freq_DM_map_cube.fits')[0].data 
    # On importe les vecteurs qui permet de supprimer certaines fréquences
    VecF = pf.open(dirwr + folder_CDF + 'VecF.fits')[0].data     
    

    # On lit la matrice de commande
    if Instrument == 'SCC_1':    
        Mat_com = pf.open(dirwr + folder_Matrix + "Mat_Com_SCC_1.fits")[0].data
    if Instrument == 'SCC_2':    
        Mat_com = pf.open(dirwr + folder_Matrix + "Mat_Com_SCC_2.fits")[0].data
    if Instrument == 'MRSCC':    
        Mat_com = pf.open(dirwr + folder_Matrix + "Mat_Com_MRSCC.fits")[0].data
    
    ## PARAMETERS  ##
    
    # GENERAL PARAMETERS
    
    # Number of iteration
    nb_ite  = 6.

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

 
    phdm   = initial_flatmap
    #phdm   = np.zeros((66.,66.))

    # On enregistre la commande DM
    DM_commande_save = phdm
    pf.writeto(dirwr + folder_Correction + folder_DM_Com + "Commande_" + str(int(0)) + ".fits", DM_commande_save,clobber=True)                        

    i = 0
    while i <nb_ite:

        if i > 0:
            phdm -= pf.open(dirwr + folder_Correction + folder_DM_Com + "Commande_" + str(int(0)) + ".fits")[0].data 

        #print '\n'
        #print "Iteration: " % i, "/", string(nb_ite)
        
        # We define a filter for the images in detector plane
        Filtre_I = pf.open(dirwr + folder_CDF + 'DH_butterworth_3.fits')[0].data

        #read the Config file
        config = ConfigObj(configfilename, configspec=configspecfile)
        val = Validator()
        #checks to make sure all the values are correctly typed in
        check = config.validate(val)


        #load the value into your code
        gain = config['Loop']['gain']

        #print '\n'
        #print "gain value is: ", gain
        
        # Test IDL Cam
        # Im_SCC_tmp = pf.open(dirwr + folder_Correction + folder_SCC_Im + "SCC_Im_Com_" + str(int(i)) + ".fits")[0].data

        # We apply the command to the DM
        status  = p3k.load_new_flatmap(fmap.convert_hodm_telem(phdm))                
        
        # We read the image with pharo
        header, Im_SCC_tmp= pharo.take_src_return_imagedata_header(exptime)

        # On enregistre l'image
        pf.writeto(dirwr + folder_Correction + folder_SCC_Im + "SCC_image_ite_" + str(int(i)) + ".fits", Im_SCC_tmp, header = header, clobber=True, output_verify = 'ignore')                

        # On lit l'image pour faire comme dans Interaction_matrix_may_V0.py
        Im_SCC_tmp = pf.open(dirwr + folder_Correction + folder_SCC_Im + "SCC_image_ite_" + str(int(i)) + ".fits")[0].data             

        # we substract the dark and divide by the Flat
        Im_SCC_tmp = (Im_SCC_tmp - Dark)/Flat

         # we compute the 3 estimators
        Estimateurs = Esti.Est_SCC_V0(Im_SCC_tmp,Filtre_I,dirwr + folder_CDF,cx=750.,cy=537.)

      #  if Instrument == 'SCC_1':            
      #      Est   = Estimateurs['Est_SCC_1']
       # if Instrument == 'SCC_2':    
        #    Est   = Estimateurs['Est_SCC_2']
        #if Instrument == 'MRSCC':            
        Est   = Estimateurs['Est_MRSCC']    
        
        # We multiply the estimation of the electric field by 
        # the command matrix to obtain a command for the DM
        Vec_com = np.dot(Mat_com,Est.T)

        #On supprime certaines fréquences
        #Vec_com *= VecF

        # We built the phdm to apply
        freq = 0
        while freq < len(Cube):
            phdm -= Cube[freq,:,:]*Vec_com[freq]*gain*0.3
            freq += 1

        # On enregistre la commande DM
        DM_commande_save = phdm
        pf.writeto(dirwr + folder_Correction + folder_DM_Com + "Commande_" + str(int(i+1)) + ".fits", DM_commande_save,clobber=True)                        
        
        # On enregistre le vecteur de commande
        pf.writeto(dirwr + folder_Correction + folder_DM_Com + "Vec_Commande_" + str(int(i+1)) + ".fits", Vec_com,clobber=True)
            
        i+=1
        ipdb.set_trace()


    # We apply the initial flatmap to the DM
    #status = p3k.load_new_flatmap(fmap.convert_hodm_telem(initial_flatmap))

    #stop
    #ipdb.set_trace()
