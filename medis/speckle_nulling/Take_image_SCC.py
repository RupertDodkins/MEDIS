# -*- coding: utf-8 -*-
"""
Created on Fri Apr 17 10:33:30 2015

@author: J-R
"""

def Take_image_SCC(Map_to_apply,nb_im):
    
    # We apply the Map to the DM
    status = p3k.load_new_flatmap(fmap.convert_hodm_telem(Map_to_apply))    
    
    # We Read Nb_im Image    
    i = 0    
    while i < nb_im:   
        if i == 0:
            cube = pharo.take_src_return_imagedata()
            cube = cube[:,:, np.newaxis]
            i+=1            
        else:
            im = pharo.take_src_return_imagedata()
            im   = im[:,:, np.newaxis]
            cube = np.concatenate((cube,im), axis = 2)                
            i+=1

    return cube