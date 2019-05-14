import numpy as np
from PyQt5 import QtWidgets
from statsmodels.tsa.stattools import acf
# from vip_hci import phot, pca
# from matplotlib.pylab import plt
from medis.params import sp, ap, tp, iop
from medis.Utils.misc import dprint

def take_acf(obs_sequence, locs=None, radius = 10):
    if locs is None:
        locs = [[65,65], [65,83], [83,65], [83,83]]

    corrs = []

    if len(obs_sequence) > 2:
        for (x,y) in locs:
            # print(my_round(np.mean(obs_sequence[:, :, x:x+radius, y:y+radius], axis=(1, 2, 3)), 3))
            corr = acf(np.mean(obs_sequence[:, :, x:x+radius, y:y+radius], axis=(1, 2, 3)), fft=True, nlags=20)
            corrs.append(corr)
    else:
        corrs = np.empty((len(locs)))
        corrs[:] = np.nan

    return corrs

sp.metric_args = [[[65,65], [65,83], [83,65], [83,83]]]
sp.gui_map_type = np.array(['amp'])

sp.metric_funcs = [take_acf]

sp.use_gui = True
# sp.save_locs = np.array(['coronagraph'])

ap.nwsamp = 1
ap.w_bins = 1
# ap.grid_size = 148
ap.companion = True
ap.contrast = [1e-2]
ap.star_photons = 1e8
ap.exposure_time = 1e-3
# tp.use_atmos = False
# tp.use_ao = False
ap.numframes = 50

##set telescope parameters
tp.use_ao = True #AO off/on
tp.detector = 'ideal'

##set simulation parameters
sp.num_processes = 1
# sp.save_locs = np.array(['coronagraph'])
# sp.return_E = True
sp.save_obs = True

iop.update("AIPD/")

from medis.Dashboard.architecture import MyWindow

if __name__ == "__main__":
    import sys

    app = QtWidgets.QApplication(sys.argv)
    app.setApplicationName('MyWindow')

    main = MyWindow()

    sys.exit(app.exec_())
