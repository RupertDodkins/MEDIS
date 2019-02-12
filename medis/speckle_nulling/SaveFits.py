# -*- coding: utf-8 -*-
"""
Created on Wed Nov 12 16:13:08 2014

@author: dpickel
"""

#Save an array into a fits file (.fits) and load it into an numpy array.

'''
Arguments:
    path: path of the file + name of the new file (string)   
    A: array of an image that need to be saved into a fits file
'''

from astropy.io import fits

def SaveFits(path,A):
    
    hdu = fits.PrimaryHDU(A) # hdu = Header Data Unit (from astropy doc)
    hdu.writeto(path)

''' End of function
'''