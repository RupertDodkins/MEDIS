import numpy as np
from PyQt5 import QtWidgets
from statsmodels.tsa.stattools import acf, acovf
# from vip_hci import phot, pca
# from matplotlib.pylab import plt
from medis.params import sp, ap, tp
from medis.Utils.misc import dprint
from scipy import signal
import medis.Detector.readout as read

def take_exposure(obs_sequence, exp_time):
    downsample_cube = obs_sequence * exp_time
    return downsample_cube

def my_round(value, N):
    exponent = np.ceil(np.log10(value))
    return 10**exponent*np.round(value*10**(-exponent), N)

def take_acf(obs_sequence, locs=None, radius = 1):
    # obs_sequence = read.take_exposure(obs_sequence)
    if locs is None:
        locs = [[65,65], [65,83], [83,65], [83,83]]

    corrs = []

    if len(obs_sequence) > 2:
        for (x,y) in locs:
            # print(my_round(np.mean(obs_sequence[:, :, x:x+radius, y:y+radius], axis=(1, 2, 3)), 3))
            count = np.mean(obs_sequence[:, :, x:x + radius, y:y + radius], axis=(1, 2, 3))
            # b, a = signal.butter(3, 0.05)
            # y = signal.filtfilt(b, a, count)
            # corr = acf(my_round(np.mean(obs_sequence[:, :, x:x+radius, y:y+radius], axis=(1, 2, 3)), 1),
            #                         fft=True, nlags=50)
            corr = acovf(count)
            corrs.append(corr)
    else:
        corrs = np.empty((len(locs)))
        corrs[:] = np.nan

    return corrs

def plot_psd(obs_sequence, locs=None, radius = 1):
    # obs_sequence = read.take_exposure(obs_sequence)
    if locs is None:
        locs = [[65,65], [65,83], [83,65], [83,83]]

    psds = []

    if len(obs_sequence) > 2:
        for (x,y) in locs:
            counts = np.mean(obs_sequence[:, :, x:x + radius, y:y + radius], axis=(1, 2, 3))
            psd = signal.periodogram(counts)[1]
            psds.append(np.log10(psd[1:]))

    else:
        psds = np.empty((len(locs)))
        psds[:] = np.nan

    return psds

def plot_counts(obs_sequence, locs, radius = 10):
    # obs_sequence = read.take_exposure(obs_sequence)
    counts = []

    for (x,y) in locs:
        # count = my_round(np.mean(obs_sequence[:, :, x:x+radius, y:y+radius], axis=(1, 2, 3)), 1)

        count = obs_sequence[:, 0, x, y]
        # b, a = signal.butter(3, 0.05)
        # y = signal.filtfilt(b, a, count)
        # counts.append(y)
        counts.append(count)
    # else:
    #     counts = np.empty((len(locs)))
    #     counts[:] = np.nan

    # print(counts)

    return counts

def plot_stats(obs_sequence, locs, radius = 10, bins = 30):
    # obs_sequence = read.take_exposure(obs_sequence)
    dists = []

    for (x,y) in locs:
        # count = np.mean(obs_sequence[:, :, x:x + radius, y:y + radius], axis=(1, 2, 3))
        count = obs_sequence[:, 0, x, y]
        # bins = np.arange(0, ap.sample_time, bin_time)
        dist = np.histogram(count, bins)[0]
        dists.append(dist)

    return dists


sp.use_gui = True
sp.show_cube = False
sp.save_locs = np.array(['add_atmos', 'quick_ao', 'prop_mid_optics', 'coronagraph'])
# sp.save_locs = np.array(['add_atmos', 'prop_mid_optics', 'coronagraph'])
sp.gui_map_type = np.array(['phase', 'phase','amp', 'amp'])
# sp.gui_map_type = np.array(['phase','amp', 'amp'])
# sp.save_locs = np.array([ ['quick_ao','phase'], ['prop_mid_optics','amp'], ['coronagraph','amp']])
# sp.save_locs = np.array([ ['prop_mid_optics','amp'], ['coronagraph','amp']])
# sp.metric_funcs = [take_exposure, take_acf]
sp.metric_funcs = [plot_counts, take_acf, plot_stats, plot_psd]
# sp.metric_args = [0.1, [[65,65], [65,83], [83,65], [83,83]]]
locs = [[65,65], [65,83], [83,65], [83,83]]
sp.metric_args = [locs, locs, locs, locs]
ap.nwsamp = 1
ap.w_bins = 1
# ap.grid_size = 148
ap.companion = True
ap.contrast = [1e-2]
ap.star_photons = 1e8
ap.sample_time = 1e-3
ap.exposure_time = 10e-4
ap.grid_size = 128
# tp.use_atmos = False
# tp.use_ao = False
ap.numframes = 500


# tp.detector = 'MKIDs'
tp.detector = 'ideal'

from medis.Dashboard.architecture import MyWindow

if __name__ == "__main__":
    import sys

    app = QtWidgets.QApplication(sys.argv)
    app.setApplicationName('MyWindow')

    main = MyWindow()

    sys.exit(app.exec_())
