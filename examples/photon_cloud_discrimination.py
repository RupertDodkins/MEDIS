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
sp.num_processes = 1
# sp.save_locs = np.array(['coronagraph'])
# sp.return_E = True
sp.save_obs = True

iop.update("AIPD/")

if __name__ == "__main__":
    import sys

    app = QtWidgets.QApplication(sys.argv)
    app.setApplicationName('MyWindow')

    main = MyWindow()

    sys.exit(app.exec_())
