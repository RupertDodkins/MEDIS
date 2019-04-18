import numpy as np

from matplotlib.colors import LogNorm, SymLogNorm
from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg
from matplotlib.figure import Figure
from matplotlib import gridspec
from mpl_toolkits.axes_grid1 import make_axes_locatable

from functools import partial

from PyQt5.QtCore import pyqtSlot
from PyQt5.QtWidgets import QComboBox, QFormLayout, QHBoxLayout, QVBoxLayout, QLineEdit, QWidget, QPushButton, QProgressBar

from medis.params import ap,sp
from medis.Dashboard.helper import EfieldsThread, SpectralCubeThread


if sp.save_locs is None:
    sp.save_locs = [['coronagraph',]]


class MatplotlibWidget(QWidget):
    def __init__(self, parent=None, nrows=len(sp.save_locs), ncols=ap.nwsamp):
        super(MatplotlibWidget, self).__init__(parent)

        self.nrows, self.ncols = nrows, ncols
        self.figure = Figure(figsize=(3*ncols,3*nrows))
        self.canvas = FigureCanvasQTAgg(self.figure)

        gs = gridspec.GridSpec(self.nrows, self.ncols)

        for r in range(self.nrows):
            for c in range(self.ncols):
                self.figure.add_subplot(gs[r,c])

        self.axes = np.array(self.figure.axes).reshape(self.nrows, self.ncols)
        self.cax = []
        for r in range(self.nrows):
            divider = make_axes_locatable(self.axes[r,-1])
            self.cax.append(divider.append_axes('right', size='5%', pad=0.15))

        self.layoutVertical = QFormLayout(self)
        self.layoutVertical.addWidget(self.canvas)

    def add_Efield_annotations(self):
        wsamples = np.linspace(ap.band[0], ap.band[1], ap.nwsamp).astype(int)
        for c in range(self.ncols):
            self.axes[0, c].set_title('{} nm'.format(wsamples[c]))
        props = dict(boxstyle='square', facecolor='k', alpha=0.5)
        for r in range(self.nrows):
            self.axes[r, 0].text(0.05, 0.075, sp.save_locs[r, 0], transform=self.axes[r, 0].transAxes, fontweight='bold', color='w',
                            fontsize=12, bbox=props)

    def add_metric_annotations(self):
        props = dict(boxstyle='square', facecolor='k', alpha=0.5)
        self.axes[0, 0].text(0.05, 0.075, 'Integration', transform=self.axes[0, 0].transAxes,
                             fontweight='bold', color='w',
                             fontsize=12, bbox=props)
        for r in range(self.nrows-1):
            self.axes[r+1, 0].text(0.05, 0.075, sp.metric_funcs[r], transform=self.axes[r+1, 0].transAxes,
                                 fontweight='bold', color='w',
                                 fontsize=12, bbox=props)


class MyWindow(QWidget):
    def __init__(self, nrows=len(sp.save_locs), ncols=ap.nwsamp, plot_metric=True):
        super().__init__()
        
        self.framenumber = 0
        
        # Define and connect push buttons
        self.pushButtonRun = QPushButton(self)
        self.pushButtonRun.setText("Start Simulation")
        self.pushButtonRun.clicked.connect(self.on_pushButtonRun_clicked)
        self.EfieldsThread = EfieldsThread(self)
        self.EfieldsThread.newSample.connect(self.on_EfieldsThread_newSample)

        self.pushButtonStop = QPushButton(self)
        self.pushButtonStop.setText("Play/Pause")
        self.pushButtonStop.clicked.connect(self.on_pushButtonStop_clicked)

        self.pushButtonSave = QPushButton(self)
        self.pushButtonSave.setText("Save State")
        self.pushButtonSave.clicked.connect(self.on_pushButtonSave_clicked)

        self.nwsamp = QLineEdit(self)
        self.nwsamp.setPlaceholderText(f'{ap.nwsamp}')
        self.nwsamp.textChanged.connect(self.textchanged)

        self.degfac = QLineEdit(self)
        self.degfac.setPlaceholderText('2')

        self.pushButtonInt = QPushButton(self)
        self.pushButtonInt.setText("Integrate")
        self.pushButtonInt.clicked.connect(self.on_pushButtonInt_clicked)

        self.pushButtonMetric = QPushButton(self)
        self.pushButtonMetric.setText("Plot Metric")
        self.pushButtonMetric.clicked.connect(self.on_pushButtonMetric_clicked)
        # self.EfieldsThread.spectral_cube.connect(self.on_SpectralCubeThread_newSample)
        self.EfieldsThread.sct = SpectralCubeThread(self)
        self.EfieldsThread.sct.newSample.connect(self.on_SpectralCubeThread_newSample)

        # Define the dropdown combobox
        self.metrics = ['take_exposure', 'Sample Photons', 'Plot Stats', 'mSDI', 'SSD', 'DSI', '5 r$\sigma$ Contrast', 'ACF']
        self.metricCombo = QComboBox(self)
        self.metricCombo.addItems(self.metrics)

        # Define and connect the matplotlib gridspec widget
        self.nrows = nrows
        self.ncols = ncols
        self.EmapsGrid = MatplotlibWidget(self, self.nrows, self.ncols)
        self.EmapsGrid.add_Efield_annotations()
        self.rows, self.cols = self.EmapsGrid.nrows, self.EmapsGrid.ncols

        # Panel with start, play/pause etc buttons
        self.topHPanel = QHBoxLayout()
        self.topHPanel.addWidget(self.pushButtonRun)
        self.topHPanel.addWidget(self.pushButtonStop)
        self.topHPanel.addWidget(self.pushButtonSave)

        self.paramsform = QFormLayout()
        # self.paramsform.setContentsMargins(0, 0, 0, 0)
        print(ap.nwsamp)
        self.paramsform.addRow('wavelength samples:', self.nwsamp)
        self.paramsform.addRow('degredation factor:', self.degfac)

        self.procHPanel = QHBoxLayout()
        self.procHPanel.addWidget(self.pushButtonInt)
        self.procHPanel.addWidget(self.pushButtonMetric)
        self.procHPanel.addWidget(self.metricCombo)

        # Parent of the topHPanel, textbox and matplotlib grid for the E maps
        self.ParaWaveHbox = QHBoxLayout()
        # self.ParaWaveHbox.setContentsMargins(0,0,0,0)
        self.ParaWaveHbox.addLayout(self.paramsform)
        self.ParaWaveHbox.addWidget(self.EmapsGrid)

        self.buttonParaWaveVBox = QVBoxLayout()
        self.buttonParaWaveVBox.addLayout(self.topHPanel)
        self.buttonParaWaveVBox.addLayout(self.ParaWaveHbox)

        self.progress = QProgressBar(self)
        self.progress.setGeometry(200, 80, 250, 20)

        # For the metric plot
        self.metricformlayout = QFormLayout()
        self.metricsGrid = MatplotlibWidget(self, len(sp.metric_funcs)+1, 1)  # +1 because of the default intergation plot
        self.metricsGrid.add_metric_annotations()
        self.metricformlayout.addRow(self.procHPanel)
        self.metricformlayout.addRow(self.progress)
        # self.metricformlayout.addRow(probe_screens)
        self.metricformlayout.addRow(self.metricsGrid)

        # Main layout
        self.parentHlayout = QHBoxLayout()
        self.parentHlayout.addLayout(self.buttonParaWaveVBox)
        self.parentHlayout.addLayout(self.metricformlayout)

        # Set the hbox layout as the window's main layout
        self.setLayout(self.parentHlayout)

        self.left = 10
        self.top = 10
        self.width = 1500
        self.height = 200 + 300*nrows
        self.title = 'MEDIS Dashboard'
        self.setWindowTitle(self.title)
        self.setGeometry(self.left, self.top, self.width, self.height)

        self.show()

    @pyqtSlot()
    def on_pushButtonRun_clicked(self):
        self.EfieldsThread.start()

    @pyqtSlot()
    def on_pushButtonStop_clicked(self):
        sp.play_gui = not sp.play_gui

    @pyqtSlot()
    def on_pushButtonSave_clicked(self):
        NotImplementedError

    @pyqtSlot()
    def on_pushButtonInt_clicked(self):
        NotImplementedError

    @pyqtSlot(np.ndarray)
    def on_EfieldsThread_newSample(self, gui_images):

        amp_ind = sp.save_locs[:, 1] == 'amp'
        norm = np.array([None for _ in range(len(sp.save_locs))])
        vmin = np.array([None for _ in range(len(sp.save_locs))])
        vmax = np.array([None for _ in range(len(sp.save_locs))])
        cmap = np.array([None for _ in range(len(sp.save_locs))])

        norm[amp_ind] = LogNorm()
        vmin[~amp_ind] = -np.pi
        vmax[~amp_ind] = np.pi
        vmin[amp_ind] = np.min(gui_images[amp_ind, :, 0])
        vmax[amp_ind] = np.max(gui_images[amp_ind, :, 0])
        cmap[~amp_ind] = 'hsv'

        for x in range(self.rows):
            for y in range(self.cols):
                # self.EmapsGrid.axes[x, y].cla()
                im = self.EmapsGrid.axes[x, y].imshow(gui_images[x,y,0,::2,::2], norm=norm[x],
                                                     vmin=vmin[x], vmax=vmax[x], cmap=cmap[x])

            self.EmapsGrid.figure.colorbar(im, cax=self.EmapsGrid.cax[x], orientation='vertical')

        self.EmapsGrid.canvas.draw()
        del gui_images

        self.framenumber += 1
        self.progress.setValue(self.framenumber/ap.numframes * 100)

    @pyqtSlot()
    def on_pushButtonMetric_clicked(self):
        self.EfieldsThread.sct.func = self.metricCombo.currentText()
        self.EfieldsThread.sct.start()

    @pyqtSlot(tuple)
    def on_SpectralCubeThread_newSample(self, spec_tuple):
        (it, spectralcube) = spec_tuple
        self.EfieldsThread.sct.integration += spectralcube
        self.EfieldsThread.sct.obs_sequence[it] = spectralcube

        # self.metricsGrid.axes[0,0].cla()
        im = self.metricsGrid.axes[0,0].imshow(np.sum(self.EfieldsThread.sct.integration, axis=0), norm=LogNorm())
        self.metricsGrid.figure.colorbar(im, cax=self.metricsGrid.cax[0], orientation='vertical')

        for r, (func, args) in enumerate(zip(sp.metric_funcs, sp.metric_args)):
            # self.metricsGrid.axes[r+1,0].cla()
            f = partial(func, args)
            metric = f(self.EfieldsThread.sct.obs_sequence[:it])

            im = self.metricsGrid.axes[r+1, 0].imshow(metric[it-1, 0], norm=LogNorm())
            self.metricsGrid.figure.colorbar(im, cax=self.metricsGrid.cax[r+1], orientation='vertical')

        self.metricsGrid.canvas.draw()
        del it, spectralcube

    def textchanged(self, amount):
        # self.rows = int(amount)
        ap.nwsamp = int(amount)
        self.close()
        self.__init__(ncols=ap.nwsamp)
