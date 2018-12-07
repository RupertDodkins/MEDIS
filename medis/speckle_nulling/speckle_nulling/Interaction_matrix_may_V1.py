# -*- coding: utf-8 -*-
"""
Created on Sat Apr 18 10:47:56 2015

@author: J-R
"""


# pour les math de base
import numpy as np

# pour lire et enregistrer les fits
import pyfits as pf

# permet de faire des plots
import matplotlib.pyplot as plt

#(fr) Pour faire des stops
#(en) To stop the program
import ipdb

import Est_SCC_V0 as Est

from configobj import ConfigObj

def shift(image,shift_x,shift_y):
    """Returns a shifted image"""
    return np.roll(np.roll(image,int(shift_y),axis=0),int(shift_x),axis=1)


if __name__ == "__main__":


    # Mac JR 
    # dirwr = '/Users/J-R/Desktop/PHD_JR/Work/Palomar/Simu_Python/Matrice_PB_1/'
    # Aousr
    dirwr = '/data1/home/aousr/Desktop/speckle_nulling/SCC_Palomar/150506/Matrice_0/'
    
    folder_FDM_Im = 'Mat_inter/FDM_Im/'
    folder_DM_Com = 'Mat_inter/DM_Com/'
    folder_SCC_Im = 'Mat_inter/SCC_Im/'
    folder_CDF    = 'CDF/' 
    folder_Matrix = 'Mat_inter/MatCom/'


    # On importe les filtres pour I-
    Filtre_I  = pf.open(dirwr + folder_CDF + 'Filtre_Robust.fits')[0].data     
    Filtre_I  = Filtre_I[:,:,0:128]
    Filtre_I = Filtre_I*0. + 1.

    # On importe un flat
    Flat = pf.open(dirwr + folder_CDF + 'Flat.fits')[0].data
    # On importe un dark
    #Dark = pf.open(dirwr + folder_CDF + 'Dark_2UT_40mas.fits')[0].data  
    # On importe le cube de fréquences
    Cube = pf.open(dirwr + folder_CDF + 'Freq_DM_map_cube.fits')[0].data    
    
    
    #Vec_sub = pf.open(dirwr + folder_CDF + "Position_beam_subpixel_vec.fits")[0].data                 
    
    # nombre de commandes entre chaque FDM
    FDM_val = 22  

 
    i = 0
    while i < len(Cube):
        # We are reading the Im_DM_Flat associated to the following images        
        if (i % FDM_val) == 0:
            Im_DM_flat = pf.open(dirwr + folder_FDM_Im + "FDM_Im_Com_" + str(int(i)) + ".fits")[0].data    

        
        """ Estimateur (il est possible de tout réduire en deux lignes) """
        # we are reading each images
        Im_SCC_tmp = pf.open(dirwr + folder_SCC_Im + "SCC_im_Com_" + str(int(i)) + ".fits")[0].data             

        # we substract the associated flat_DM_Image
        Im_SCC_tmp -= Im_DM_flat

        # on divise par le flat
        Im_SCC_tmp /= Flat

        # we compute the 3 estimators
        Estimateurs = Est.Est_SCC_V0(Im_SCC_tmp,Filtre_I[i,:,:],dirwr + folder_CDF, cx = 750.,cy = 537.)
        #Estimateurs = Est_SCC_V0(Im_SCC_tmp,Filtre_I[i,:,:],dirwr + folder_CDF, cx = Vec_sub[i,0],cy = Vec_sub[i,1])
        
        Est_SCC_1   = Estimateurs['Est_SCC_1']
        Est_SCC_2   = Estimateurs['Est_SCC_2']
        Est_MRSCC   = Estimateurs['Est_MRSCC']

        if i == 0:

            Mat_int_SCC_1 = Est_SCC_1
            Mat_int_SCC_2 = Est_SCC_2
            Mat_int_MRSCC = Est_MRSCC

            i+=1            

        else:

            Mat_int_SCC_1 = np.concatenate((Mat_int_SCC_1,Est_SCC_1),axis=0)
            Mat_int_SCC_2 = np.concatenate((Mat_int_SCC_2,Est_SCC_2),axis=0)
            Mat_int_MRSCC = np.concatenate((Mat_int_MRSCC,Est_MRSCC),axis=0)

            i+=1           


    # on ecrit les matrices d'intéraction
    pf.writeto(dirwr + folder_Matrix + "Mat_int_SCC_1.fits",Mat_int_SCC_1,clobber=True)
    pf.writeto(dirwr + folder_Matrix + "Mat_int_SCC_2.fits",Mat_int_SCC_2,clobber=True)
    pf.writeto(dirwr + folder_Matrix + "Mat_int_MRSCC.fits",Mat_int_MRSCC,clobber=True)    

    #stop
    #ipdb.set_trace()
