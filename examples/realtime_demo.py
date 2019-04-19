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
        locs = [73, 85, 105, 120]

    corrs = []
    if len(obs_sequence) > 2:
        for y in locs:
            corr, ljb, pvalue = acf(obs_sequence[:, 0, 73, y], unbiased=False, qstat=True, nlags=len(range(ap.numframes)))
            corrs.append(corr)
    else:
        corrs = np.empty((len(locs)))
        corrs[:] = np.nan

    return corrs


sp.use_gui = True
sp.show_cube = False
sp.save_locs = np.array([['add_atmos','phase'], ['quick_ao','phase'], ['prop_mid_optics','amp'], ['coronagraph','amp']])
sp.metric_funcs = [take_exposure, take_acf]
sp.metric_args = [0.1, [73, 85, 105, 120]]
ap.nwsamp = 1
ap.grid_size = 148
ap.companion = False
ap.star_photons = 1e8


tp.detector = 'MKIDs'

from medis.Dashboard.architecture import MyWindow

if __name__ == "__main__":
    import sys

    app = QtWidgets.QApplication(sys.argv)
    app.setApplicationName('MyWindow')

    main = MyWindow()

    sys.exit(app.exec_())
