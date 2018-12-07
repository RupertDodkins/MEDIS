# -*- coding: utf-8 -*-
"""
Created on Thu Apr 16 10:15:11 2015

@author: J-R
"""
import numpy as np

def shift(image,shift_x,shift_y):
    """Returns a shifted image"""
    return np.roll(np.roll(image,shift_y,axis=0),shift_x,axis=1)
    
    
