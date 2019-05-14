'''This code handles the relevant functionality of a Hawaii 2RG camera'''
import sys
sys.path.append('D:/dodkins/MEDIS/MEDIS')

import numpy as np
from medis.params import ap, cp, tp, sp, hp
import pickle as pickle
import os
from medis.Utils.plot_tools import loop_frames, quicklook_im
from . import readout as read
import matplotlib.pyplot as plt
H2RGhyperCubeFile = './BinnedH2RGhyper.pkl'
# tp.occulter_type = None  #

def scale_to_luminos(obs_sequence):
    scale_factor = ap.star_photons*1000*ap.exposure_time#/(ap.grid_size**2)
    print(scale_factor)
    obs_sequence *= scale_factor*np.ones((ap.grid_size,ap.grid_size))
    return obs_sequence

def add_readnoise(obs_sequence, std=30):
    # obs_sequence += 6000*np.ones_like((obs_sequence))*np.random.random() - 30
    obs_sequence += np.random.normal(0,std,(obs_sequence.shape[0],obs_sequence.shape[1],obs_sequence.shape[2],obs_sequence.shape[3]))
    # obs_sequence = np.abs(obs_sequence)
    return obs_sequence

def add_darkcurrent(obs_sequence):
    erate = 1
    dark_e = erate*num_exp*ap.exposure_time
    obs_sequence += dark_e*np.ones_like((obs_sequence))*np.random.random()*2 - erate
    return obs_sequence



def get_ref_psf():
    ap.numframes = 1

    print(tp.occulter_type)
    obs_sequence = run_medis()
    frame = obs_sequence[0,0]
    quicklook_im(frame)
    with open('ref_psf.pkl', 'wb') as handle:
        pickle.dump(frame, handle, protocol=pickle.HIGHEST_PROTOCOL)
    return frame





if __name__ == '__main__':
    import medis.get_photon_data as gpd
    tp.occulter_type = None
    tp.detector = 'H2RG'  # ''MKIDs'#
    sp.save_obs = False

    sp.show_cube = False
    sp.return_spectralcube = True
    sp.show_wframe = False
    ap.companion = True
    tp.NCPA_type = 'Wave'

    # tp.use_atmos = True # have to for now because ao wfs reads in map produced but not neccessary
    # tp.use_ao = True
    # tp.active_null=False
    # tp.satelite_speck = True
    # tp.speck_locs = [[40,40]]
    # ap.frame_time = 0.001

    print(tp.occulter_type)
    get_ref_psf()

    # tp.occulter_type = 'Gaussian'#

    num_exp = 10
    ap.exposure_time = 0.01
    tp.NCPA_type = 'Wave'
    ap.numframes = int(num_exp * ap.exposure_time / ap.sample_time)
    print(ap.numframes)

    print(os.path.isfile(H2RGobs_sequenceFile), H2RGobs_sequenceFile)
    if os.path.isfile(H2RGobs_sequenceFile):
        obs_sequence = read.open_obs_sequence(obs_sequenceFile = H2RGobs_sequenceFile)
    else:
        obs_sequence = gpd.run_medis()
        print('finished run')
        print(np.shape(obs_sequence))
        obs_sequence = read.take_exposure(obs_sequence)
        print('here')
        read.save_obs_sequence(obs_sequence, HyperCubeFile = H2RGhyperCubeFile)
        print('here')
    # obs_sequence = take_exposure(obs_sequence)
    print(np.shape(obs_sequence[0,3]), np.shape(obs_sequence))
    loop_frames(obs_sequence[:,0])

    print('here')
    loop_frames(obs_sequence[0])
