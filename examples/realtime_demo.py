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

def my_round(value, N):
    exponent = np.ceil(np.log10(value))
    return 10**exponent*np.round(value*10**(-exponent), N)

def take_acf(obs_sequence, locs=None, radius = 10):
    if locs is None:
        locs = [[65,65], [65,83], [83,65], [83,83]]

    corrs = []

    if len(obs_sequence) > 2:
        for (x,y) in locs:
            print(my_round(np.mean(obs_sequence[:, :, x:x+radius, y:y+radius], axis=(1, 2, 3)), 3))
            corr = acf(my_round(np.mean(obs_sequence[:, :, x:x+radius, y:y+radius], axis=(1, 2, 3)), 3),
                                    fft=True, nlags=20)
            corrs.append(corr)
    else:
        corrs = np.empty((len(locs)))
        corrs[:] = np.nan

    return corrs


sp.use_gui = True
sp.show_cube = False
sp.save_locs = np.array(['add_atmos', 'quick_ao', 'prop_mid_optics', 'coronagraph'])
# sp.save_locs = np.array(['add_atmos', 'prop_mid_optics', 'coronagraph'])
sp.gui_map_type = np.array(['phase', 'phase','amp', 'amp'])
# sp.gui_map_type = np.array(['phase','amp', 'amp'])
# sp.save_locs = np.array([ ['quick_ao','phase'], ['prop_mid_optics','amp'], ['coronagraph','amp']])
# sp.save_locs = np.array([ ['prop_mid_optics','amp'], ['coronagraph','amp']])
# sp.metric_funcs = [take_exposure, take_acf]
sp.metric_funcs = [take_acf]
# sp.metric_args = [0.1, [[65,65], [65,83], [83,65], [83,83]]]
sp.metric_args = [[[65,65], [65,83], [83,65], [83,83]]]
ap.nwsamp = 1
ap.w_bins = 1
# ap.grid_size = 148
ap.companion = True
ap.contrast = [1e-2]
ap.star_photons = 1e8
ap.exposure_time = 1e-3
# tp.use_atmos = False
# tp.use_ao = False
ap.numframes = 1000


# tp.detector = 'MKIDs'
tp.detector = 'ideal'

from medis.Dashboard.architecture import MyWindow

if __name__ == "__main__":
    import sys

    app = QtWidgets.QApplication(sys.argv)
    app.setApplicationName('MyWindow')

    main = MyWindow()

    sys.exit(app.exec_())
