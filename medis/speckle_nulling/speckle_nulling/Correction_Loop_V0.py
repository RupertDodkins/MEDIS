# -*- coding: utf-8 -*-
"""
Created on Wed Apr 15 15:26:29 2015

@author: J-R
"""

import numpy as np
import pyfits as pf
from configobj import ConfigObj
import ipdb
import matplotlib.pyplot as plt
import sn_hardware as hardware
import dm_functions as DM
import flatmapfunctions as fmap
import detect_speckles
from validate import Validator
import sn_preprocessing as pre
from shift import shift
from Estimation_1ref import Estimation_1ref
from SaveFits import SaveFits


if __name__ == "__main__":

    ampl   = 1.  # amplitude
    nb_im  = 1.  #(attention si > à 1 il faut faire une medianne du cube)
    ray    = 22  # en pixel
    Alpha  =  5. # en degré
    Xi     = 66. # en pixel
    Alpha  = Alpha/180.*np.pi 
    nb_ite = 5   # number of iteration
    exptime = 4
  
    dirwr = '/data1/home/aousr/Desktop/speckle_nulling/SCC/'

    # We read a cube of frequency
    #hdulist = pf.open(dirwr + 'Freq_DM_map_cube.fits')
    hdulist = pf.open(dirwr + 'Freq_start.fits')
    Cube_freq = hdulist[0].data
    hdulist.close()

    # Read the Commande Matrix
    hdulist = pf.open(dirwr + 'Mat_com.fits')
    Mat_com = hdulist[0].data
    hdulist.close()
        
    # Read image
    hdulist = pf.open( dirwr + 'Filtre_Image.fits')
    Filtre_Image = hdulist[0].data
    hdulist.close()    
    Filtre_Image = shift(Filtre_Image,-128,-128)
    Filtre_Image = Filtre_Image[0:256,0:256]
    
    # Read Filtre Fourier
    hdulist = pf.open( dirwr + 'Filtre_Fourier.fits')
    Filtre_Fourier = hdulist[0].data
    hdulist.close()

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
    im_flat         = np.zeros((1024, 1024))
    im_flat         = pharo.take_src_return_imagedata(exptime) #works, tested

    # We initialized the DM Shape to apply    
    phdm = initial_flatmap	

    # Correction Loop
    ite = 0
    while ite < nb_ite:

        # we apply phdm to the DM and we take image(s)
        status = p3k.load_new_flatmap(fmap.convert_hodm_telem(phdm))
        w = 0    
        while w < nb_im:
           im = pharo.take_src_return_imagedata(exptime)
           im   = im[:,:, np.newaxis]
           if w == 0:
              cube_im = im
              w+=1            
           else:
              cube_im = np.concatenate((cube_im,im), axis = 2)                
              w+=1
        
        SCC_Image = shift(Cube,-128,-128)        
        #SaveFits(dirwr + "Mat_int.fits", Mat_int)
        #pf.writeto("test"".fits", SCC_Image)

        # from the image we obtain an estimation
        Estimateur = Estimation_1ref(SCC_Image,Filtre_Image,Filtre_Fourier,ray,Alpha,Xi)
        # We multiply the estimation of the electric field by 
        # the command matrix to obtained a commande for the DM
        Vec_com = np.dot(Mat_com,Estimateur)
        # We built the phdm to apply
        i = 0
        while i < len(Cube_freq):
            phdm += Cube_freq[i,:,:]*Vec_com[i]
            i+=1   

    # We apply the initial flatmap to the DM
    status = p3k.load_new_flatmap(fmap.convert_hodm_telem(initial_flatmap))
