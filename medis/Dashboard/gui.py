import numpy as np
from proper_mod import prop_run
from matplotlib.colors import LogNorm, SymLogNorm

from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg
from matplotlib.figure import Figure
from matplotlib import gridspec

from PyQt5 import QtCore
from PyQt5 import QtWidgets
from PyQt5.QtWidgets import QComboBox, QFormLayout, QHBoxLayout, QVBoxLayout, QLineEdit, QWidget, QPushButton

from medis.params import tp,ap,sp,iop,cp
from medis.Detector.get_photon_data import ThreadSample, ThreadMetric
# from medis.Detector.get_photon_data import run_medis

if sp.save_locs is None:
    sp.save_locs = [['coronagraph',]]

class MatplotlibWidget(QWidget):
    def __init__(self, parent=None, nrows=len(sp.save_locs), ncols=ap.nwsamp):
        super(MatplotlibWidget, self).__init__(parent)

        self.nrows, self.ncols = nrows, ncols
        self.figure = Figure()
        self.canvas = FigureCanvasQTAgg(self.figure)

        gs = gridspec.GridSpec(self.nrows, self.ncols)
        for n in range(self.nrows*self.ncols):
            self.figure.add_subplot(gs[n])
        self.axes = np.array(self.figure.axes).reshape(self.nrows, self.ncols)
        wsamples = np.linspace(ap.band[0], ap.band[1], ap.nwsamp).astype(int)
        for c in range(self.ncols):
            self.axes[0, c].set_title('{} nm'.format(wsamples[c]))
        props = dict(boxstyle='square', facecolor='k', alpha=0.5)
        for r in range(self.nrows):
            self.axes[r, 0].text(0.05, 0.075, sp.save_locs[r, 0], transform=self.axes[r, 0].transAxes, fontweight='bold', color='w',
                            fontsize=12, bbox=props)
            # self.axes[0, r].set_title('{} nm'.format(wsamples[r]))

        self.layoutVertical = QtWidgets.QVBoxLayout(self)
        self.layoutVertical.addWidget(self.canvas)


# class ThreadSample(QtCore.QThread):
#     newSample = QtCore.pyqtSignal(np.ndarray)
#
#     def __init__(self, parent=None):
#         super(ThreadSample, self).__init__(parent)
#
#     def run(self):
#         for t in range(10):
#             r0 = 0.2
#             atmos_map = iop.atmosdir + '/telz%f_%1.3f.fits' % (t * cp.frame_time, r0)
#
#             kwargs = {'iter': t, 'atmos_map': atmos_map, 'params': [ap, tp, iop, sp]}
#             _, save_E_fields = prop_run('medis.Telescope.optics_propagate', 1, ap.grid_size, PASSVALUE=kwargs, PHASE_OFFSET=1)
#
#             gui_images = np.zeros_like(save_E_fields, dtype=np.float)
#             phase_ind = sp.save_locs[:, 1] == 'phase'
#             amp_ind = sp.save_locs[:, 1] == 'amp'
#
#             gui_images[phase_ind] = np.angle(save_E_fields[phase_ind], deg=False)
#             gui_images[amp_ind] = np.absolute(save_E_fields[amp_ind])
#
#             self.newSample.emit(gui_images)


class MyWindow(QWidget):
    def __init__(self, nrows=len(sp.save_locs), ncols=ap.nwsamp, plot_metric=True):
        super().__init__()

        # Define and connect push buttons
        self.pushButtonRun = QPushButton(self)
        self.pushButtonRun.setText("Start Simulation")
        self.pushButtonRun.clicked.connect(self.on_pushButtonRun_clicked)
        self.threadSample = ThreadSample(self)
        self.threadSample.newSample.connect(self.on_threadSample_newSample)

        self.pushButtonStop = QPushButton(self)
        self.pushButtonStop.setText("Play/Pause")
        self.pushButtonStop.clicked.connect(self.on_pushButtonStop_clicked)

        self.pushButtonMetric = QPushButton(self)
        self.pushButtonMetric.setText("Plot Metric")
        self.pushButtonMetric.clicked.connect(self.on_pushButtonMetric_clicked)
        self.threadMetric = ThreadMetric(self)
        self.threadMetric.newSample.connect(self.on_threadMetric_newSample)

        # Define the dropdown combobox
        self.metrics = ['5 r$\sigma$ Contrast', 'ACF']
        self.metricCombo = QComboBox(self)
        self.metricCombo.addItems(self.metrics)

        # Define and connect the textbox
        probe_screens = QLineEdit()
        probe_screens.textChanged.connect(self.textchanged)

        # Define and connect the matplotlib gridspec widget
        self.nrows = nrows
        self.ncols = ncols
        self.EmapsGrid = MatplotlibWidget(self, self.nrows, self.ncols)
        self.rows, self.cols = self.EmapsGrid.nrows, self.EmapsGrid.ncols

        # Panel with start, play/pause etc buttons
        self.topHPanel = QHBoxLayout()
        self.topHPanel.addWidget(self.pushButtonRun)
        self.topHPanel.addWidget(self.pushButtonStop)
        self.topHPanel.addWidget(self.pushButtonMetric)
        self.topHPanel.addWidget(self.metricCombo)

        # Parent of the topHPanel, textbox and matplotlib grid for the E maps
        self.efieldsformlayout = QFormLayout()
        self.efieldsformlayout.addRow(self.topHPanel)
        self.efieldsformlayout.addRow(probe_screens)
        self.efieldsformlayout.addRow(self.EmapsGrid)

        # For the metric plot
        self.metricformlayout = QFormLayout()
        self.metricsGrid = MatplotlibWidget(self, 1, 1)
        self.metricformlayout.addRow(self.metricsGrid)

        # Main layout
        self.parentHlayout = QHBoxLayout()
        self.parentHlayout.addLayout(self.efieldsformlayout)
        self.parentHlayout.addLayout(self.metricformlayout)

        # Set the hbox layout as the window's main layout
        self.setLayout(self.parentHlayout)

        self.left = 10
        self.top = 10
        self.width = 1500
        self.height = 300 + 300*nrows
        self.title = 'MEDIS Dashboard'
        self.setWindowTitle(self.title)
        self.setGeometry(self.left, self.top, self.width, self.height)

        self.show()

    @QtCore.pyqtSlot()
    def on_pushButtonRun_clicked(self):
        self.threadSample.start()

    @QtCore.pyqtSlot()
    def on_pushButtonStop_clicked(self):
        sp.play_gui = not sp.play_gui

    @QtCore.pyqtSlot(np.ndarray)
    def on_threadSample_newSample(self, gui_images):

        amp_ind = sp.save_locs[:, 1] == 'amp'
        norm = np.array([None for _ in range(len(sp.save_locs))])
        vmin = np.array([None for _ in range(len(sp.save_locs))])
        vmax = np.array([None for _ in range(len(sp.save_locs))])
        cmap = np.array([None for _ in range(len(sp.save_locs))])

        norm[amp_ind] = LogNorm()
        vmin[~amp_ind] = -np.pi
        vmax[~amp_ind] = np.pi
        vmin[amp_ind] = np.min(gui_images[amp_ind,:,0])
        vmax[amp_ind] = np.max(gui_images[amp_ind,:,0])
        cmap[~amp_ind] = 'hsv'

        for x in range(self.rows):
            for y in range(self.cols):
                im = self.EmapsGrid.axes[x,y].imshow(gui_images[x,y,0], norm=norm[x],
                                                            vmin=vmin[x], vmax=vmax[x], cmap=cmap[x])
                if y == self.cols-1:
                    cax = self.EmapsGrid.figure.add_axes([0.92, 0.09 + 0.277 * (self.rows -1 -x), 0.025, 0.25])

            # cb = fig.colorbar(im, cax=cax, orientation='vertical',format=ticker.FuncFormatter(fmt))
            cb = self.EmapsGrid.figure.colorbar(im, cax=cax, orientation='vertical')

        self.EmapsGrid.canvas.draw()


    @QtCore.pyqtSlot()
    def on_pushButtonMetric_clicked(self):
        self.threadMetric.start()

    @QtCore.pyqtSlot(np.ndarray)
    def on_threadMetric_newSample(self, metric):
        self.close()
        self.__init__(plot_metric=True)
        print(metric)
        import matplotlib.pyplot as plt
        plt.figure()
        plt.imshow(metric)
        plt.show()

    def textchanged(self, amount):
        self.rows = int(amount)
        self.close()
        self.__init__(int(amount))

# if __name__ == "__main__":
#     import sys
#
#     app = QtWidgets.QApplication(sys.argv)
#     app.setApplicationName('MyWindow')
#
#     main = MyWindow()
#
#     sys.exit(app.exec_())
