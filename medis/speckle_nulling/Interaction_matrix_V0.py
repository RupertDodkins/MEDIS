# -*- coding: utf-8 -*-
"""
Created on Wed Apr 15 15:26:29 2015

@author: J-R
"""

import numpy as np
import astropy.io.fits as pf
from configobj import ConfigObj
import ipdb
import matplotlib.pyplot as plt
import medis.speckle_nulling.sn_hardware as hardware
import medis.speckle_nulling.dm_functions as DM
import flatmapfunctions as fmap
import detect_speckles
from validate import Validator
import medis.speckle_nulling.sn_preprocessing as pre
from shift import shift
from Estimation_1ref import Estimation_1ref
from SaveFits import SaveFits

def shift(image,shift_x,shift_y):
    """Returns a shifted image"""
    return np.roll(np.roll(image,shift_y,axis=0),shift_x,axis=1)


if __name__ == "__main__":

    ampl   = 1.  # amplitude
    nb_im  = 1.  #(attention si > à 1 il faut faire une medianne du cube)
    ray    = 22  # en pixel
    Alpha  =  5. # en degré
    Xi     = 66. # en pixel
    Alpha  = Alpha/180.*np.pi 
    nb_ite = 5   # number of iteration
    exptime = 4.
    gain = 0.5


    dirwr = '/data1/home/aousr/Desktop/speckle_nulling/SCC/'
    folder_image     = '150419/Correction/'
    folder_2         = "Correc_1/"
    folder_cube          = '150419/'
    hdulist = pf.open(dirwr + folder_cube + 'ZONE_Freq_DM_map_cube_18avril_1.fits')
    Cube_freq = hdulist[0].data
    hdulist.close()


    """
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
    """
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
    initial_flatmap = initial_flatmap #+ (-1)*Cube_freq[89,:,:]/4.
    # We apply to the DM the initial flatmap
    status          = p3k.load_new_flatmap(fmap.convert_hodm_telem(initial_flatmap))

    #READ Image before any correction

    im_flat         = np.zeros((1024, 1024))
    im_flat         = pharo.take_src_return_imagedata(exptime) #works, tested
    #ipdb.set_trace()
	
    Commande = initial_flatmap
    Image_freq         = im_flat[np.newaxis,:,:]
    Image_name = 'Im'     
    pf.writeto(dirwr + folder_image + Image_name  + ".fits", Image_freq,clobber=True) 

    pf.writeto(dirwr + folder_image + folder_2 + "Im_0.fits", Image_freq, clobber=True) 
    DM_commande_save = Commande[np.newaxis,:,:]
    pf.writeto(dirwr + folder_image + folder_2 + "Com_0.fits", DM_commande_save,clobber=True)    
    flip = 1


    ipdb.set_trace()
    while flip < 100000:
        DL = pf.open(dirwr + folder_image + 'Cmde.fits')[0].data 
	Commande += DL
        status = p3k.load_new_flatmap(fmap.convert_hodm_telem(Commande ))
        im = pharo.take_src_return_imagedata(exptime)
        Image_freq         = im[np.newaxis,:,:]
        Image_name = 'Im'     
        pf.writeto(dirwr + folder_image + Image_name  + ".fits", Image_freq,clobber=True)
        pf.writeto(dirwr + folder_image + folder_2 + "Im_"  + str(int(flip)) + ".fits", Image_freq, clobber=True) 
        DM_commande_save = Commande[np.newaxis,:,:]
        pf.writeto(dirwr + folder_image + folder_2 + "Com_" + str(int(flip)) + ".fits", DM_commande_save,clobber=True)
        flip +=1
        ipdb.set_trace()
 


    DL = pf.open(dirwr + folder_image + 'Cmde2.fits')[0].data
    Commande += (gain * DL[0,:,:])
    status = p3k.load_new_flatmap(fmap.convert_hodm_telem(Commande+initial_flatmap))
    im = pharo.take_src_return_imagedata(exptime)
    Image_freq         = im[np.newaxis,:,:]
    Image_name = 'Image_SCC_ite_3'     
    pf.writeto(dirwr + folder_image + Image_name  + ".fits", Image_freq,clobber=True) 
    ipdb.set_trace()
    
    DL = pf.open(dirwr + folder_image + 'Cmde3.fits')[0].data
    Commande += (gain * DL[0,:,:])
    status = p3k.load_new_flatmap(fmap.convert_hodm_telem(Commande+initial_flatmap))
    im = pharo.take_src_return_imagedata(exptime)
    Image_freq         = im[np.newaxis,:,:]
    Image_name = 'Image_SCC_ite_4'     
    pf.writeto(dirwr + folder_image + Image_name  + ".fits", Image_freq,clobber=True) 
    ipdb.set_trace()
    
    DL = pf.open(dirwr + folder_image + 'Cmde4.fits')[0].data*0.5
    Commande += gain * DL[0,:,:]
    status = p3k.load_new_flatmap(fmap.convert_hodm_telem(Commande+initial_flatmap))
    im = pharo.take_src_return_imagedata(exptime)
    Image_freq         = im[np.newaxis,:,:]
    Image_name = 'Image_SCC_ite_5'     
    pf.writeto(dirwr + folder_image + Image_name  + ".fits", Image_freq,clobber=True) 
    ipdb.set_trace()
    
    DL = pf.open(dirwr + folder_image + 'Cmde5.fits')[0].data*0.5
    Commande += gain * DL[0,:,:]
    status = p3k.load_new_flatmap(fmap.convert_hodm_telem(Commande+initial_flatmap))
    im = pharo.take_src_return_imagedata(exptime)
    Image_freq         = im[np.newaxis,:,:]
    Image_name = 'Image_SCC_ite_6'     
    pf.writeto(dirwr + folder_image + Image_name  + ".fits", Image_freq,clobber=True) 
    ipdb.set_trace()

    Commande += pf.open(dirwr + folder_image + 'Cmde6.fits')[0].data*0.5
    status = p3k.load_new_flatmap(fmap.convert_hodm_telem(Commande+initial_flatmap))
    im = pharo.take_src_return_imagedata(exptime)
    Image_freq         = im[np.newaxis,:,:]
    Image_name = 'Image_SCC_ite_7'     
    pf.writeto(dirwr + folder_image + Image_name  + ".fits", Image_freq,clobber=True) 
    ipdb.set_trace()

    Commande += pf.open(dirwr + folder_image + 'Cmde7.fits')[0].data*0.5
    status = p3k.load_new_flatmap(fmap.convert_hodm_telem(Commande+initial_flatmap))
    im = pharo.take_src_return_imagedata(exptime)
    Image_freq         = im[np.newaxis,:,:]
    Image_name = 'Image_SCC_ite_8'     
    pf.writeto(dirwr + folder_image + Image_name  + ".fits", Image_freq,clobber=True) 
    ipdb.set_trace()

    Commande += pf.open(dirwr + folder_image + 'Cmde8.fits')[0].data*0.5
    status = p3k.load_new_flatmap(fmap.convert_hodm_telem(Commande+initial_flatmap))
    im = pharo.take_src_return_imagedata(exptime)
    Image_freq         = im[np.newaxis,:,:]
    Image_name = 'Image_SCC_ite_9'     
    pf.writeto(dirwr + folder_image + Image_name  + ".fits", Image_freq,clobber=True) 
    ipdb.set_trace()

    Commande += pf.open(dirwr + folder_image + 'Cmde9.fits')[0].data*0.5
    status = p3k.load_new_flatmap(fmap.convert_hodm_telem(Commande+initial_flatmap))
    im = pharo.take_src_return_imagedata(exptime)
    Image_freq         = im[np.newaxis,:,:]
    Image_name = 'Image_SCC_ite_10'     
    pf.writeto(dirwr + folder_image + Image_name  + ".fits", Image_freq,clobber=True) 
    ipdb.set_trace()

    Commande += pf.open(dirwr + folder_image + 'Cmde10.fits')[0].data*0.5
    status = p3k.load_new_flatmap(fmap.convert_hodm_telem(Commande+initial_flatmap))
    im = pharo.take_src_return_imagedata(exptime)
    Image_freq         = im[np.newaxis,:,:]
    Image_name = 'Image_SCC_ite_11'     
    pf.writeto(dirwr + folder_image + Image_name  + ".fits", Image_freq,clobber=True) 
    ipdb.set_trace()

    #stop
    ipdb.set_trace()
    """
    i = 450
    while i < len(Cube_freq): 
        
        status = p3k.load_new_flatmap(fmap.convert_hodm_telem(Cube_freq[i,:,:]*ampl + initial_flatmap))
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

        status = p3k.load_new_flatmap(fmap.convert_hodm_telem(initial_flatmap))
        
        Image_freq = cube_im  ### prob ici
        #pf.writeto(dirwr + 'Freq_Mat_start_' + str(int(i)) + '.fits', Image_freq)
        
        Image_freq = shift(Image_freq,-128,-128)
        
        #plt.imshow(Image_freq)             
        # Image_freq have to be an image centered on (0,0) with a size of 256 by 256
        #Estimapharo.take_src_return_imagedata(exptime)teur = Estimation_1ref(Image_freq,Filtre_Image,Filtre_Fourier,ray,Alpha,Xi)
        
        if i == 0:
            #Mat_int = Estimateur
            i+=1            
        else:
            #Mat_int = np.concatenate((Mat_int,Estimateur),axis=1)
            i+=1
            
        #plt.plot(Estimateur)

    
    #Save the Interaction Matrix    
    #SaveFits(dirwr + "Mat_int.fits", Mat_int)
    
    # We apply the initial flatmap to the DM
    status = p3k.load_new_flatmap(fmap.convert_hodm_telem(initial_flatmap))

    #stop
    #ipdb.set_trace()
    """
