import numpy as np
from PyQt5 import QtWidgets
from statsmodels.tsa.stattools import acf
# from vip_hci import phot, pca
# from matplotlib.pylab import plt
from medis.params import sp, ap, tp
from medis.Utils.misc import dprint

def take_exposure(obs_sequence, exp_time):
    downsample_cube = obs_sequence * exp_time
    return downsample_cube

def take_acf(obs_sequence, locs=None):
    if locs is None:
        locs = [[65,65], [65,83], [83,65], [83,83]]

    corrs = []
    row = 80
    if len(obs_sequence) > 2:
        for (x,y) in locs:
            corr, ljb, pvalue = acf(np.mean(obs_sequence[:, :, x-3:x+3, y-3:y+3], axis=(1, 2, 3)),
                                    unbiased=False, qstat=True, nlags=50)
            corrs.append(corr)
    else:
        corrs = np.empty((len(locs)))
        corrs[:] = np.nan

    return corrs


sp.use_gui = True
sp.show_cube = False
sp.save_locs = np.array(['add_atmos', 'quick_ao', 'prop_mid_optics', 'coronagraph'])
sp.gui_map_type = np.array(['phase', 'phase','amp', 'amp'])
# sp.save_locs = np.array([ ['quick_ao','phase'], ['prop_mid_optics','amp'], ['coronagraph','amp']])
# sp.save_locs = np.array([ ['prop_mid_optics','amp'], ['coronagraph','amp']])
sp.metric_funcs = [take_exposure, take_acf]
sp.metric_args = [0.1, [[65,65], [65,83], [83,65], [83,83]]]
ap.nwsamp = 1
# ap.grid_size = 148
ap.companion = True
ap.contrast = [1e-2]
ap.star_photons = 1e8
ap.exposure_time = 1e-3
# tp.use_atmos = False
# tp.use_ao = False
# ap.numframes = 500


tp.detector = 'MKIDs'
# tp.detector = 'ideal'

from medis.Dashboard.architecture import MyWindow

if __name__ == "__main__":
    import sys

    app = QtWidgets.QApplication(sys.argv)
    app.setApplicationName('MyWindow')

    main = MyWindow()

    sys.exit(app.exec_())
