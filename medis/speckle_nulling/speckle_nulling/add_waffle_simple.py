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



    
def run(configfilename, configspecfile):
    #configfilename = 'speckle_null_config.ini'
    config = ConfigObj(configfilename, configspec=configspecfile)
    val = Validator()
    check = config.validate(val)
    hardwareconfigfile = 'speckle_instruments.ini'
    p3k = hardware.P3K_COM('P3K_COM', configfile = hardwareconfigfile)
    
    time.sleep(0.1)
    kvecr = config['CALSPOTS']['wafflekvec']
    DMamp = config['CALSPOTS']['waffleamp']
    additionmapx = DM.make_speckle_kxy(kvecr, 0,DMamp , 0) 
    additionmapy = DM.make_speckle_kxy(0,kvecr, DMamp, 0) 
    additionmap = additionmapx + additionmapy 
    textmap = DM.text_to_flatmap('hi gene!', 30)
    print ("sending new flatmap to p3k")
    initial_flatmap = p3k.grab_current_flatmap()
    status = p3k.load_new_flatmap((initial_flatmap + additionmap))
    #print ("NOW GO RUN MAKE_CENTS!!!!!")

if __name__ == "__main__":
   configfilename = 'speckle_null_config.ini'
   configspecfile = 'speckle_null_config.spec'
   run(configfilename, configspecfile) 
