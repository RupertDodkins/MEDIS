"""
Module to fascilitate the communication between get_photon_data and the gui in architecture
"""
import numpy as np
from PyQt5 import QtCore
from statsmodels.tsa.stattools import acf, acovf
from medis.get_photon_data import run_medis
import medis.Detector.readout as read
from scipy import signal
from medis.params import ap, tp, mp, sp
from medis.Utils.misc import dprint

class SpectralCubeThread(QtCore.QThread):
    newSample = QtCore.pyqtSignal(bool)

    def __init__(self, parent=None):
        super(SpectralCubeThread, self).__init__(parent)
        if tp.detector == 'MKIDs':
            self.obs_sequence = np.zeros((ap.numframes, len(ap.contrast)+1, ap.w_bins, mp.array_size[1], mp.array_size[0]))
            self.integration = np.zeros((ap.w_bins, mp.array_size[1], mp.array_size[0]))
        else:
            self.obs_sequence = np.zeros((ap.numframes, len(ap.contrast)+1, ap.w_bins, ap.grid_size, ap.grid_size))
            self.integration = np.zeros((ap.w_bins, ap.grid_size, ap.grid_size))
        self.metric = None
        self.func = None

    def run(self):
        """
        Take this timestep's spectralcube and add it to the cummulative sum
        :return:
        """
        if np.sum(self.spectralcube) == 0:
            print('Collect some photons first!')
        else:
            print(self.func, self.spectralcube.shape)

            # self.obs_sequence[self.spectralcube[0] - ap.startframe] = self.spectralcube[1]

            # method_to_call = getattr(read, self.func)
            # self.metric = method_to_call(self.obs_sequence)
            self.metric = self.spectralcube[0]
            # self.newSample.emit(self.metric)

# SCT = SpectralCubeThread()

class EfieldsThread(QtCore.QThread):
    newSample = QtCore.pyqtSignal(bool)
    spectral_cube = QtCore.pyqtSignal(np.ndarray)

    def __init__(self, parent=None):
        super(EfieldsThread, self).__init__(parent)
        self.save_E_fields = np.zeros((len(sp.save_locs) + 1, ap.nwsamp, 1 + len(ap.contrast),
                                       ap.grid_size, ap.grid_size), dtype=np.complex64)
        self.sct = SpectralCubeThread()
        self.gui_images = np.zeros_like(self.save_E_fields[:, :, 0], dtype=np.float)
        # self.SpectralCubeThread = None
        # self.metric = None
        # self.func = None

    def run(self):
        sp.play_gui = True
        run_medis(EfieldsThread=self)

    def get_gui_images(self, o):
        phase_ind = sp.gui_map_type == 'phase'
        amp_ind = sp.gui_map_type == 'amp'
        self.gui_images[phase_ind] = np.angle(self.save_E_fields[phase_ind, :, o], deg=False)
        self.gui_images[amp_ind] = np.absolute(self.save_E_fields[amp_ind, :, o])

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