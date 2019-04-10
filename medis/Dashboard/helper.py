"""
Module to fascilitate the communication between get_photon_data and the gui in architecture
"""
import numpy as np
from PyQt5 import QtCore
from medis.Detector.get_photon_data import run_medis
import medis.Detector.readout as read


class ThreadSample(QtCore.QThread):
    newSample = QtCore.pyqtSignal(np.ndarray)

    def __init__(self, parent=None):
        super(ThreadSample, self).__init__(parent)
        self.save_E_fields = None

    def run(self):
        run_medis(self)

class ThreadMetric(QtCore.QThread):
    newSample = QtCore.pyqtSignal(np.ndarray)

    def __init__(self, parent=None):
        super(ThreadMetric, self).__init__(parent)
        self.metric = None
        self.func = None

    def run(self):
        # self.func = 'take_exposure'
        method_to_call = getattr(read, self.func)
        self.metric = method_to_call()
        self.newSample.emit(self.metric)

