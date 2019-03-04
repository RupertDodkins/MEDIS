from medis.params import tp, mp, sp, cp, ap
import matplotlib.pyplot as plt
from get_photon_data import run
# import medis.Detector.H2RG as H2RG
import medis.Detector.readout as read
from medis.Utils.plot_tools import loop_frames
import numpy as np

tp.detector = 'H2RG'#''MKIDs'#
sp.save_obs = False
sp.show_wframe = False#True#'continuous'
if sp.show_wframe == 'continuous':
    sp.fig = plt.figure()

sp.show_cube = False
sp.return_cube=True
tp.nwsamp = 4
# tp.use_atmos = True # have to for now because ao wfs reads in map produced but not neccessary
# tp.use_ao = True
# tp.active_null=False
# tp.satelite_speck = True
# tp.speck_locs = [[40,40]]
# ap.frame_time = 0.001
num_exp = 25
ap.exposure_time = 0.01
ap.numframes = int(num_exp * ap.exposure_time/cp.frame_time)
sp.num_processes = 1
if __name__ == '__main__':
    hypercube = run()
    hypercube = read.take_exposure(hypercube)
    loop_frames(hypercube[:,0])
    plt.close()
    loop_frames(hypercube[0])
    plt.show()
    loop_frames(hypercube[:,0])
    plt.show()