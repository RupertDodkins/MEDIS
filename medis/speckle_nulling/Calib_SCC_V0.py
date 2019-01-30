# -*- coding: utf-8 -*-
"""
Created on Thu Apr 16 10:49:08 2015

@author: J-R
"""

def calib_SCC(freq,ampl,nb_im,Initial_flatmap,initial_flatmap):
    """Apply frequencies with different amplitudes and retrieve one or several images """
    
    i = 0
    while i < len(freq):
        if i == 0 :
            cube = calib_SCC_grid(freq[i],ampl[i],nb_im,,initial_flatmap)
            i+=1            
        else:
            cube = np.concatenate((cube,calib_SCC_grid(freq[i],ampl[i],nb_im,initial_flatmap)), axis = 2)     
            i+=1            
    
    # Le mirroir est remis dans son état initiale à la fin     
    # status = p3k.load_new_flatmap(fmap.convert_hodm_telem(initial_flatmap))          
    
    return cube
    
    