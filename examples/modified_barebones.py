import medis.Detector.get_photon_data as gpd

from medis.params import ap, tp, sp, iop
import numpy as np

##set astro parameters
ap.companion=False #is there a planet in there?
ap.exposure_time = 0.001 #exposure time in [???units]
ap.numframes = 1
ap.nwsamp = 1 #number of wavefronts in proper to sample from

##set telescope parameters
tp.use_spiders =False #spiders off/on
tp.use_ao = True #AO off/on
tp.piston_error = False #piston error off/on
tp.use_coron = False #coronagraph off/on
tp.occulter_type = 'None' #occulter type - vortex, none, gaussian
tp.detector = 'ideal'
tp.check_args()

##set simulation parameters
sp.show_wframe = False
sp.save_obs = False
sp.num_processes = 1
sp.save_locs = np.array([['add_atmos',], ['coronagraph',]])
sp.return_E = True

iop.update("mod_barebones/")
ap.grid_size = 148

if __name__ == '__main__':
    simple_hypercube_1 = gpd.run_medis(plot=False)
    print(simple_hypercube_1.shape) # ap.numframes x len(sp.save_locs) x (1 star + # of companions) x ap.nwsamp x ap.grid_size x ap.grid_size
