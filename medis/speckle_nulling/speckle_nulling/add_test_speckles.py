import sn_preprocessing as pre
import os
import matplotlib.pyplot as plt
import pyfits as pf
import ipdb
import sn_math as snm
import numpy as np
from configobj import ConfigObj
import sn_filehandling as flh
import sn_hardware as hardware
import flatmapfunctions as FM
from validate import Validator
import flatmapfunctions as fmf
import dm_functions as DM
import time



if __name__ == "__main__":
    configfilename = 'speckle_null_config.ini'
    hardwareconfigfile = 'speckle_instruments.ini'
    configspecfile = 'speckle_null_config.spec'
    p3k = hardware.P3K_COM('P3K_COM', configfile = hardwareconfigfile)
    
    time.sleep(1)
    additionmap = 0
    phases = np.array([25, 133, 78, 224])*np.pi/180
    kvecx  = [11, 9, 18, 22]
    kvecy  = [13, 7, 9, 4]
    amps   = [15, 6, 10, 25]
    
    for idx, _ in enumerate(phases):
        map = DM.make_speckle_kxy(kvecx[idx],
                                  kvecy[idx],
                                  amps[idx],
                                  phases[idx])
        additionmap += map

    print ("sending new flatmap to p3k")
    initial_flatmap = p3k.grab_current_flatmap()
    status = p3k.load_new_flatmap((initial_flatmap + additionmap))

    print ("NOW GO RUN MAKE_CENTS!!!!!")
