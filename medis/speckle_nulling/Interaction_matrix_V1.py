# -*- coding: utf-8 -*-
"""
Created on Sat Apr 18 10:47:56 2015

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

    # Folders

    dirwr              = '/data1/home/aousr/Desktop/speckle_nulling/SCC/'
    folder_SCC_image   = '150418/Matrice_1/SCC_Image_Mat/'
    folder_Cube_filtre = 'Cubes_and_Filters/'
    folder_Matrix      =
    
    FDM_val = 22  # on enregistre une image DM_flat toutes les FDM_flat images    
    
    # Parameters
    
    dim_init = 1024
    dim_s    = 400
    cx       = 572
    cy       = 407
    
    xi0_x1   = 64
    xi0_y1   = 66
    ray_c1   = 30

    xi0_x2   = 66
    xi0_y2   = 330
    ray_c2   = 30

    dim_fourier=4.*ray_c1
    dim_dh_x=64
    dim_dh_y =64    

    # Read data

    Cube_freq           = pf.open(dirwr + folder_Cube_filtre + 'Freq_DM_map_cube462_ampl40_17avril.fits')[0].data
    Filtre_Image        = pf.open(dirwr + folder_Cube_filtre + 'Filtre_Image.fits')[0].data
    Filtre_Fourier_ref1 = pf.open(dirwr + folder_Cube_filtre + 'Filtre_Fourier'   )[0].data
 
    i = 0
    while i < len(Cube_freq):
        # We are reading the Im_DM_Flat associated to the following images
        if (i % FDM_val) == 0:
            Im_DM_flat = pf.open(dirwr + folder_DM_Flat_image + "DM_flat_Im_" + str(int((i - (i%FDM_val))/FDM_val)) + ".fits")[0].data    
        
        
        """ Estimateur (il est possible de tout réduire en deux lignes)"""
        # we are reading each images
        Im_SCC_tmp = pf.open(dirwr + folder_SCC_image + "SCC_image_mat_number_" + str(int((i)) + ".fits")[0].data    
        
        # we substract the associated flat_DM_Image
        Im_SCC_tmp -= Im_DM_flat

        # on centre l'image en cx, cy et on la coupe en une image dim_s*dim_s
        Im_SCC_tmp = shift(Im_SCC_tmp[cx-dim_s/2:cx+dim_s/2,cy-dim_s/2:cy+dim_s/2],-dim_s/2,-dim_s/2)        
        
        # On multiplie l'image par le filtre image
        Im_SCC_tmp *= Filtre_Image
        
        # On passe dans le plan de Fourier
        Im_SCC_FFT = np.fft.fft2(Im_SCC_tmp)
        
        """ Référence 1 """
        # On multiplie par le masque filtre_fourier (on selectionne un des piques de correlation)
        Ref_1 = Im_SCC_FFT*Filtre_Fourier_ref1
        
        # on recentre le pique
        Ref_1 = shift(Ref_1,-xi0_x1+dim_fourier/2,-xi0_y1+dim_fourier/2)

        # on coupe une zone de dim_fourier autour
        Ref_1 = Ref_1[0:dim_fourier,0:dim_fourier]

        # On recentre le pique
        Ref_1 = shift(Ref_1,-dim_fourier/2,-dim_fourier/2)
        
        # On fait la TF inverse du pique
        I_minus_1 = np.fft.ifft2(Ref_1)
        
        # On le décale pour reduire la taille de l'image
        I_minus_1 = shift(I_minus_1,dim_dh_x/2,dim_dh_y/2)
        
        # On coupe l'image pour concerver l'information utile
        I_minus_1 = I_minus_1[0:dim_dh_x,0:dim_dh_y]
        
        # On construit l'estimateur
        Est_SCC_1 = np.concatenate((np.reshape(I_minus_1.real,dim_dh_y**2),np.reshape(I_minus_1.imag,dim_dh_y**2)),axis=0)
        
        # On ajoute une dimension pour pouvoir le mettre sous forme de cube
        Est_SCC_1 = Est_SCC_1[np.newaxis,:]
        
        """ Autre solution """
        # On construit l'estimateur
        # Est_1 = np.concatenate((I_minus_1.real,I_minus_1.imag),axis=1)
        # On ajoute une dimention pour pouvoir le mettre sous forme de cube
        # Est_1 = Est_1[np.newaxis,:,:]
        
        """ Référence 2 """        
        # On multiplie par le masque filtre_fourier (on selectionne un des piques de correlation)
        Ref_2 = Im_SCC_FFT*Filtre_Fourier_ref2
        
        # on recentre le pique
        Ref_2 = shift(Ref_2,-xi0_x2+dim_fourier/2,-xi0_y2+dim_fourier/2)

        # on coupe une zone de dim_fourier autour
        Ref_2 = Ref_2[0:dim_fourier,0:dim_fourier]
        
        # On recentre le pique
        Ref_2 = shift(Ref_2,-dim_fourier/2,-dim_fourier/2)
  
        # On fait la TF inverse du pique
        I_minus_2 = np.fft.ifft2(Ref_2)
        
        # On le décale pour reduire la taille de l'image
        I_minus_2 = shift(I_minus_2,dim_dh_x/2,dim_dh_y/2)
        
        # On coupe l'image pour concerver l'information utile
        I_minus_2 = I_minus_2[0:dim_dh_x,0:dim_dh_y]      

        # On construit l'estimateur
        Est_SCC_2 = np.concatenate((np.reshape(I_minus_2.real,dim_dh_y**2),np.reshape(I_minus_2.imag,dim_dh_y**2)),axis=0)
        
        # On ajoute une dimension pour pouvoir le mettre sous forme de cube
        Est_SCC_2 = Est_SCC_2[np.newaxis,:]

        """ Autre solution """
        # On construit l'estimateur
        # Est_2 = np.concatenate((I_minus_2.real,I_minus_2.imag),axis=1)
        # On ajoute une dimention pour pouvoir le mettre sous forme de cube
        # Est_2 = Est_1[np.newaxis,:,:]

        # Estimateur MRSCC
        Est_MRSCC = np.concatenate((Est_SCC_1,Est_SCC_2),axis=1)        

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
