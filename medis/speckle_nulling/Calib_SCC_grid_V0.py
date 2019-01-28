# -*- coding: utf-8 -*-
"""
Created on Thu Apr 16 10:49:08 2015

@author: J-R
"""

def calib_SCC_grid(freq,ampl,nb_im,initial_flatmap):
    """Apply a frequency or a combination of frequencies with  """
    """different amplitudes and retrieve one or several images """

    # Met au bon format si nécessaire
    if type(freq) is int:
        freq = [freq]
        ampl = [ampl]

    # Read a cube of frequencies
    hdulist = pf.open('/Users/J-R/Desktop/PHD_JR/Work/Palomar_observatory/Cube_freq/Freq_DM_map_cube_1.fits')
    Cube_freq = hdulist[0].data
    hdulist.close()
    
    # Initialize the map to apply
    Map_to_apply = initial_flatmap

    # Construction of the Map_to_Apply
    i = 0
    while i < np.size(freq):        
        Map_to_apply += Cube_freq[freq[i],:,:]*ampl[i]
        i+=1

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