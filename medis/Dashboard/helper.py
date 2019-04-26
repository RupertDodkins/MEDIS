"""
Module to fascilitate the communication between get_photon_data and the gui in architecture
"""
import numpy as np
from PyQt5 import QtCore
from medis.Detector.get_photon_data import run_medis
import medis.Detector.readout as read
from medis.params import ap, tp, mp

class SpectralCubeThread(QtCore.QThread):
    newSample = QtCore.pyqtSignal(tuple)

    def __init__(self, parent=None):
        super(SpectralCubeThread, self).__init__(parent)
        if tp.detector == 'MKIDs':
            self.obs_sequence = np.zeros((ap.numframes, ap.w_bins, mp.array_size[1], mp.array_size[0]))
            self.integration = np.zeros((ap.w_bins, mp.array_size[1], mp.array_size[0]))
        else:
            self.obs_sequence = np.zeros((ap.numframes, ap.w_bins, ap.grid_size, ap.grid_size))
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
    newSample = QtCore.pyqtSignal(np.ndarray)
    spectral_cube = QtCore.pyqtSignal(np.ndarray)

    def __init__(self, parent=None):
        super(EfieldsThread, self).__init__(parent)
        self.save_E_fields = None
        self.sct = SpectralCubeThread()
        # self.SpectralCubeThread = None
        # self.metric = None
        # self.func = None

    def run(self):
        run_medis(EfieldsThread=self)
