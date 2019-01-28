'''This code handles all the functionality of an ideal camera'''

import numpy as np
from medis.params import mp

def assign_calibtime(datacube,step):
    '''unfinished and untest'''
    time = step*mp.frame_time
    print time, 'time'
    # cube = np.zeros((cp.numframes,tp.nwsamp,tp.grid_size,tp.grid_size))
    timecube = np.ones_like((datacube))*time
    hypercube = np.stack((datacube,timecube))
    print hypercube.shape
    return hypercube