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
import sn_hardware as hardware
import dm_functions as DM
import flatmapfunctions as fmap
import detect_speckles
from validate import Validator
import sn_preprocessing as pre
from SaveFits import SaveFits

def shift(image,shift_x,shift_y):
    """Returns a shifted image"""
    return np.roll(np.roll(image,shift_y,axis=0),shift_x,axis=1)

if __name__ == "__main__":

    freq    = [1,2]
    ampl    = [1,1]  # amplitude
    nb_im   = 1.  #(attention si > à 1 il faut faire une medianne du cube)
    exptime = 2   # exposure time 2 = 1.416s, 4 = 2.832s, ...

    dirwr = '/data1/home/aousr/Desktop/speckle_nulling/SCC/'
    # We read a cube of frequency
    #hdulist = pf.open(dirwr + 'Freq_DM_map_cube.fits')
    hdulist = pf.open(dirwr + 'Freq_start.fits')
    Cube_freq = hdulist[0].data
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
    #ipdb.set_trace()
	

    Freq_num = 0
    while Freq_num < len(freq):
        Freq_selected = freq[Freq_num]
        Ampl_selected = ampl[Freq_num]
        
        # Met au bon format si nécessaire
        if type(Freq_selected) is int:
            Freq_selected = [Freq_selected]
            Ampl_selected = [Ampl_selected]
           
        # Initialize the map to apply
        Map_to_apply = initial_flatmap
        
        # Construction of the Map_to_Apply
        Sub_Freq_i = 0
        while Sub_Freq_i < np.size(Freq_selected):        
            Map_to_apply += Cube_freq[Freq_selected[Sub_Freq_i],:,:]*Ampl_selected[Sub_Freq_i]
            Sub_Freq_i+=1
            
        # We apply the Map to the DM
        status = p3k.load_new_flatmap(fmap.convert_hodm_telem(Map_to_apply))    

        nb_im_i = 0    
        while nb_im_i < nb_im:
            im = pharo.take_src_return_imagedata()
            im   = im[:,:, np.newaxis]
            if nb_im_i  == 0:
                cube_im_tmp =  im
                nb_im_i += 1            
            else:
                cube_im_tmp = np.concatenate((cube_im_tmp,im), axis = 2)                
                nb_im_i += 1

        im   = im[:,:, np.newaxis]
        if Freq_num  == 0:
            cube_im  =  im
            Freq_num += 1            
        else:
            cube_im  =  np.concatenate((cube_im,im), axis = 2)                
            Freq_num += 1          

    #stop
    status = p3k.load_new_flatmap(fmap.convert_hodm_telem(initial_flatmap))
    #ipdb.set_trace()


