import numpy as np
import medis.save_photon_data as gpd
from medis.Utils.plot_tools import view_datacube
from medis.params import iop, sp, ap

iop.update("minimal_demo/")
sp.save_locs = np.array(['add_atmos', 'deformable_mirror', 'prop_mid_optics'])
ap.numframes = 3

if __name__ == '__main__':
    fields = gpd.run_medis()  # get the fields hypercube using the default params

    for t in range(len(fields)):
        spectralcube = np.abs(np.sum(fields[t, -1, :, :], axis=1)) ** 2  # get intensity of detector plane and collapse the object axis
        view_datacube(spectralcube, logAmp=True)
