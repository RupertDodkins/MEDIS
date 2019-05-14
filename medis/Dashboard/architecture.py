import numpy as np

from matplotlib.colors import LogNorm, SymLogNorm
from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg
from matplotlib.figure import Figure
from matplotlib import gridspec
from mpl_toolkits.axes_grid1 import make_axes_locatable
from matplotlib.image import AxesImage

from PyQt5.QtCore import pyqtSlot, Qt
from PyQt5.QtWidgets import QComboBox, QFormLayout, QHBoxLayout, QVBoxLayout, QLineEdit, QWidget, QPushButton, \
    QProgressBar, QRadioButton, QSlider, QLabel

from medis.params import ap, sp, tp
from medis.Utils.misc import dprint
from medis.Dashboard.helper import EfieldsThread, SpectralCubeThread
from medis.Dashboard.twilight import sunlight, twilight

if sp.save_locs is None:
    sp.save_locs = np.array(['final'])

class MatplotlibWidget(QWidget):
    def __init__(self, parent=None, nrows=len(sp.save_locs), ncols=ap.nwsamp):
        super(MatplotlibWidget, self).__init__(parent)

        self.nrows, self.ncols = nrows, ncols
        self.figure = Figure(figsize=(5*ncols,3*nrows))
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

        self.ims = np.empty((self.nrows, self.ncols), dtype=AxesImage)

    def add_Efield_annotations(self):
        wsamples = np.linspace(ap.band[0], ap.band[1], ap.nwsamp).astype(int)
        for c in range(self.ncols):
            self.axes[0, c].set_title('{} nm'.format(wsamples[c]))
        props = dict(boxstyle='square', facecolor='k', alpha=0.5)
        for r in range(self.nrows):
            pretty_func_name = ' '.join(sp.save_locs[r].split('_'))
            self.axes[r, 0].text(0.05, 0.075, pretty_func_name, transform=self.axes[r, 0].transAxes, fontweight='bold', color='w',
                            fontsize=12, bbox=props)

    def add_metric_annotations(self):
        props = dict(boxstyle='square', facecolor='k', alpha=0.5)
        self.axes[0, 0].text(0.05, 0.075, 'Integration', transform=self.axes[0, 0].transAxes,
                             fontweight='bold', color='w',
                             fontsize=12, bbox=props)
        for r in range(self.nrows-1):
            pretty_func_name = ' '.join(sp.metric_funcs[r].__name__.split('_'))
            self.axes[r+1, 0].text(0.05, 0.075, pretty_func_name, transform=self.axes[r+1, 0].transAxes,
                                 fontweight='bold', color='w',
                                 fontsize=12, bbox=props)


class MyWindow(QWidget):
    def __init__(self, nrows=len(sp.save_locs), ncols=ap.nwsamp, plot_metric=True):
        super().__init__()

        self.framenumber = 0
        self.plotsamp = 2

        # Define and connect push buttons
        self.pushButtonRun = QPushButton(self)
        self.pushButtonRun.setText("Start Simulation")
        self.pushButtonRun.clicked.connect(self.on_pushButtonRun_clicked)
        self.initializeEfieldsThread()
        self.vmin, self.vmax = None, None

        self.pushButtonStop = QPushButton(self)
        # self.pushButtonStop_options = np.rec.fromarrays((['Play', 'Pause'], [0, 1]), names=('keys', 'values'))
        # self.pushButtonStop.setText(self.pushButtonStop_options['keys'][self.pushButtonStop_options['values'] == True][0])
        self.pushButtonStop.setText('Stop and Save')
        self.pushButtonStop.clicked.connect(self.on_pushButtonStop_clicked)

        # self.pushButtonSave = QPushButton(self)
        # self.pushButtonSave.setText("Save State")
        # self.pushButtonSave.clicked.connect(self.on_pushButtonSave_clicked)

        self.nwsamp = QLineEdit(self)
        self.nwsamp.setPlaceholderText(f'{ap.nwsamp}')
        self.nwsamp.textChanged.connect(self.textchanged)

        self.degfac = QLineEdit(self)
        self.degfac.setPlaceholderText('2')


        self.plotsamptext = QLineEdit(self)
        self.plotsamptext.setPlaceholderText(str(self.plotsamp))
        self.plotsamptext.textChanged.connect(self.changeplotsamp)

        self.pushButtonInt = QPushButton(self)
        self.pushButtonInt.setText("Placeholder")
        self.pushButtonInt.clicked.connect(self.on_pushButtonInt_clicked)

        self.pushButtonMetric = QPushButton(self)
        self.pushButtonMetric.setText("Placeholder")
        self.pushButtonMetric.clicked.connect(self.on_pushButtonMetric_clicked)

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
        # self.topHPanel.addWidget(self.pushButtonSave)

        self.paramsform = QFormLayout()
        # self.paramsform.setContentsMargins(0, 0, 0, 0)
        # print(ap.nwsamp)
        # self.paramsform.addRow('wavelength samples:', self.nwsamp)
        self.paramsform.addWidget(QLabel('Wavelength Displays'))
        self.paramsform.addWidget(self.nwsamp)
        self.paramsform.addWidget(QLabel('Spatial Degradation'))
        self.paramsform.addWidget(self.degfac)
        self.paramsform.addWidget(QLabel('Metric Time Display'))
        self.paramsform.addWidget(self.plotsamptext)
        # self.paramsform.addRow('degredation factor:', self.degfac)
        # self.paramsform.addRow('plot sample number:', self.plotsamptext)

        # TODO turn off plots individually
        # self.locs_buttons = []
        # for il, loc in enumerate(sp.save_locs):

        # self.b1 = QRadioButton('Show screens')
        # self.b1.setChecked(True)
        # self.b1.toggled.connect(lambda: self.fieldsbtnstate(self.b1))
        # self.paramsform.addWidget(self.b1)
        #
        # self.b2 = QRadioButton('Show metrics')
        # self.b2.setChecked(True)
        # self.b2.toggled.connect(lambda: self.metricbtnstate(self.b2))
        # self.paramsform.addWidget(self.b2)

        self.b3 = QRadioButton('Toggle AO')
        self.b3.setChecked(True)
        self.b3.toggled.connect(lambda: self.toggle_ao(self.b3))
        self.paramsform.addWidget(self.b3)

        if ap.companion:
            self.sp = QSlider(Qt.Horizontal)
            # self.sp.setFocusPolicy(Qt.StrongFocus)
            self.sp.setMinimum(0)
            self.sp.setMaximum(len(ap.contrast))
            self.sp.setValue(self.EfieldsThread.fields_ob)
            self.sp.setTickPosition(QSlider.TicksBelow)
            self.sp.setTickInterval(1)
            self.sp.setSingleStep(1)
            self.paramsform.addWidget(QLabel('Object'))
            self.paramsform.addWidget(self.sp)
            self.sp.valueChanged.connect(self.valuechange)

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

        self.obj, self.it = -1, 0

        self.show()

    def valuechange(self):
        self.EfieldsThread.fields_ob = self.sp.value()
        print(self.EfieldsThread.fields_ob, 'lol')

    def initializeEfieldsThread(self):
        self.EfieldsThread = EfieldsThread(self)
        self.EfieldsThread.newSample.connect(self.on_EfieldsThread_newSample)
        self.EfieldsThread.fields_ob = 0
        self.EfieldsThread.sct = SpectralCubeThread(self)
        self.EfieldsThread.sct.newSample.connect(self.on_SpectralCubeThread_newSample)

    def fieldsbtnstate(self, b):
        dprint(b.isChecked())
        if not b.isChecked():
            self.EfieldsThread.newSample.disconnect()
            # self.EfieldsThread.newSample.connect(self.on_EfieldsThread_placeholder)
        else:
            self.EfieldsThread.newSample.connect(self.on_EfieldsThread_newSample)
    #         sp.save_locs =
    #     # b.setChecked(not b.isChecked())

    def metricbtnstate(self, b):
        dprint(b.isChecked())
        if not b.isChecked():
            self.EfieldsThread.sct.newSample.disconnect()
        else:
            self.EfieldsThread.sct.newSample.connect(self.on_SpectralCubeThread_newSample)

    def toggle_ao(self, b):
        dprint(b.isChecked())
        tp.use_ao = b.isChecked()
        dprint((sp.save_locs, sp.save_locs == 'quick_ao', sp.save_locs[sp.save_locs == 'quick_ao']))
        if not tp.use_ao:
            sp.save_locs[sp.save_locs == 'quick_ao'] = 'no_ao'
        else:
            sp.save_locs[sp.save_locs == 'no_ao'] = 'quick_ao'
        dprint((sp.save_locs, sp.save_locs == 'quick_ao', sp.save_locs[sp.save_locs == 'quick_ao']))
        dprint('ao_toggle')
        sp.play_gui = False
        ap.startframe = self.it
        dprint(('ao_toggle', ap.startframe))
        dprint((tp.use_ao, sp.play_gui, ap.startframe, sp.save_locs))

        # self.initializeEfieldsThread()
        # # self.EfieldsThread.start()
        # dprint((tp.use_ao, sp.play_gui))

    @pyqtSlot()
    def on_pushButtonRun_clicked(self):
        self.EfieldsThread.start()

    @pyqtSlot()
    def on_pushButtonStop_clicked(self):
        # self.pushButtonStop_options['values'] = np.logical_not(self.pushButtonStop_options['values'])
        # self.pushButtonStop.setText(self.pushButtonStop_options['keys'][self.pushButtonStop_options['values'] == True][0])
        # if np.array_equal(self.pushButtonStop_options['values'], [1, 0]):
        #     self.pushButtonStop.setStyleSheet("background-color: blue")
        # else:
        #     self.pushButtonStop.setStyleSheet("background-color: white")
        sp.play_gui = False#not sp.play_gui

    @pyqtSlot()
    def on_pushButtonSave_clicked(self):
        NotImplementedError

    @pyqtSlot()
    def on_pushButtonInt_clicked(self):
        NotImplementedError

    @pyqtSlot(np.ndarray)
    def on_EfieldsThread_newSample(self, gui_images):
        amp_ind = sp.gui_map_type == 'amp'
        norm = np.array([None for _ in range(len(sp.save_locs))])
        vmin = np.array([None for _ in range(len(sp.save_locs))])
        vmax = np.array([None for _ in range(len(sp.save_locs))])
        cmap = np.array([None for _ in range(len(sp.save_locs))])

        print(sp.save_locs, sp.gui_map_type)
        norm[amp_ind] = LogNorm()
        # vmin[~amp_ind] = -np.pi
        # vmax[~amp_ind] = np.pi
        vmin[~amp_ind] = np.min(gui_images[~amp_ind], axis=(1,2,3))
        vmax[~amp_ind] = np.max(gui_images[~amp_ind], axis=(1,2,3))
        vmin[amp_ind] = np.min(gui_images[amp_ind], axis=(1,2,3))
        vmax[amp_ind] = np.max(gui_images[amp_ind], axis=(1,2,3))
        if self.vmin is None:
            # may mess up when there is just one amp figure?
            log_bins = np.logspace(np.log10(vmin[amp_ind][0]), np.log10(vmax[amp_ind][0]), 5)
            self.vmin = vmin
            self.vmax = vmax
            self.vmin[amp_ind] = log_bins[1]
            self.vmax[amp_ind] = log_bins[-1]
        cmap[~amp_ind] = twilight
        cmap[amp_ind] = 'cividis'

        for x in range(self.rows):
            for y in range(self.cols):
                # self.EmapsGrid.axes[x, y].cla()
                try:
                    self.EmapsGrid.ims[x, y].remove()
                except (AttributeError, ValueError):
                    pass
                self.EmapsGrid.ims[x, y] = self.EmapsGrid.axes[x, y].imshow(gui_images[x, y, ::1, ::1], norm=norm[x],
                                                     vmin=self.vmin[x], vmax=self.vmax[x], cmap=cmap[x], origin='lower')

            self.EmapsGrid.figure.colorbar(self.EmapsGrid.ims[x,-1], cax=self.EmapsGrid.cax[x], orientation='vertical')

        self.EmapsGrid.canvas.draw()
        del gui_images

    @pyqtSlot()
    def on_pushButtonMetric_clicked(self):
        self.EfieldsThread.sct.func = self.metricCombo.currentText()
        self.EfieldsThread.sct.start()

    @pyqtSlot(tuple)
    def on_SpectralCubeThread_newSample(self, spec_tuple):
        (it, spectralcube) = spec_tuple

        if self.it == it:
            self.obj += 1

        self.EfieldsThread.sct.integration += spectralcube
        self.EfieldsThread.sct.obs_sequence[it, self.obj] = spectralcube

        if self.obj == len(ap.contrast):
            self.obj = -1
            self.it += 1

        try:
            self.metricsGrid.ims[0,0].remove()
        except AttributeError:
            True

        # self.metricsGrid.axes[0,0].cla()
        # print(type(self.metricsGrid.ims[0,0]))
        self.metricsGrid.ims[0,0] = self.metricsGrid.axes[0,0].imshow(np.sum(self.EfieldsThread.sct.integration,
                                                                             axis=0), norm=LogNorm(),
                                                                      origin='lower', cmap='cividis')
        self.metricsGrid.figure.colorbar(self.metricsGrid.ims[0,0], cax=self.metricsGrid.cax[0],
                                         orientation='vertical')

        for r, (func, args) in enumerate(zip(sp.metric_funcs, sp.metric_args)):
            import traceback
            # self.metricsGrid.axes[r+1,0].cla()

            try:
                if type(self.metricsGrid.ims[r+1, 0]) == list:
                    for im in self.metricsGrid.ims[r + 1, 0]:
                        try:
                            im[0].remove()
                        except TypeError:
                            pass
                    # self.metricsGrid.axes[r + 1, 0].cla()
                    # self.metricsGrid.add_metric_annotations()
                else:
                    try:
                        self.metricsGrid.ims[r+1, 0].remove()
                    except AttributeError:
                        pass
            except (KeyboardInterrupt, SystemExit):
                raise
            except:
                traceback.print_exc()
            # dprint(type(self.metricsGrid.ims[r + 1, 0]) == list)

            metric = func(self.EfieldsThread.sct.obs_sequence[:it,0], args)

            dims = len(np.shape(metric))
            if dims == 4:
                if np.shape(metric)[0] == 0:
                    return
                # itclip = np.array([it-1]).clip(min=0)[0]
                self.metricsGrid.ims[r+1,0] = self.metricsGrid.axes[r+1, 0].imshow(np.sum(metric[it-1], axis=0),
                                                                                   norm=LogNorm(), origin='lower',
                                                                                   cmap='cividis')
                self.metricsGrid.figure.colorbar(self.metricsGrid.ims[r+1,0], cax=self.metricsGrid.cax[r+1],
                                                 orientation='vertical')
                self.metricsGrid.axes[r + 1, 0].set_title(f'wavelength collapsed image at step {it-1}')

            elif dims == 3 and metric.shape[0] == ap.nwsamp:
                self.metricsGrid.ims[r+1,0] = self.metricsGrid.axes[r+1, 0].imshow(np.sum(metric, axis=0),
                                                                                   norm=LogNorm(),
                                                                                   origin='lower',
                                                                                   cmap='cividis')
                self.metricsGrid.figure.colorbar(self.metricsGrid.ims[r+1,0], cax=self.metricsGrid.cax[r+1],
                                                 orientation='vertical')
                self.metricsGrid.axes[r + 1, 0].set_title(f'wavelength collapsed image')
            elif dims == 3 and metric.shape[0] == ap.numframes:
                self.metricsGrid.ims[r+1,0] = self.metricsGrid.axes[r+1, 0].imshow(metric[it-1], norm=LogNorm(),
                                                                                   origin='lower',
                                                                                   cmap='cividis')
                self.metricsGrid.figure.colorbar(self.metricsGrid.ims[r+1,0], cax=self.metricsGrid.cax[r+1],
                                                 orientation='vertical')
                self.metricsGrid.axes[r + 1, 0].set_title(f'monochromatic image at step {it - 1}')
            elif dims == 2 and type(metric) is np.ndarray:
                self.metricsGrid.ims[r+1, 0] = self.metricsGrid.axes[r+1, 0].imshow(metric, norm=LogNorm(),
                                                                                    origin='lower',
                                                                                   cmap='cividis')
                self.metricsGrid.figure.colorbar(self.metricsGrid.ims[r+1,0], cax=self.metricsGrid.cax[r+1],
                                                 orientation='vertical')
                self.metricsGrid.axes[r + 1, 0].set_title(f'constant monochromatic image')
            elif dims == 2 and type(metric) is list:
                self.metricsGrid.ims[r + 1, 0] = []
                colors = ['#1f77b4', '#ff7f0e', '#2ca02c', '#d62728',
                              '#9467bd', '#8c564b', '#e377c2', '#7f7f7f',
                              '#bcbd22', '#17becf']
                for i in range(len(metric)):
                    self.metricsGrid.ims[r + 1, 0].append(self.metricsGrid.axes[r + 1, 0].plot(metric[i], c=colors[i], label=args[i]))
                self.metricsGrid.axes[r + 1, 0].set_title(f'constant list of lines')
                self.metricsGrid.axes[r + 1, 0].legend()
                # self.metricsGrid.axes[r + 1, 0].set_xscale('log')
            elif dims == 1:
                self.metricsGrid.ims[r + 1, 0] = self.metricsGrid.axes[r + 1, 0].plot(metric)
                # self.metricsGrid.ims[r + 1, 0].set_xscale('log')
            else:
                print(f"metric from {func} with shape {np.shape(metric)} cannot be plotted")

        if it % self.plotsamp == 0:
            self.metricsGrid.canvas.draw()
        del it, spectralcube

        self.framenumber += 1
        self.progress.setValue(self.framenumber/ap.numframes * 100)

    def textchanged(self, amount):
        # self.rows = int(amount)
        ap.nwsamp = int(amount)
        sp.play_gui = False
        ap.startframe = self.it
        dprint(('ao_toggle', ap.startframe))
        dprint((tp.use_ao, sp.play_gui, ap.startframe, sp.save_locs))
        self.ncols = ap.nwsamp
        self.ParaWaveHbox.removeWidget(self.EmapsGrid)
        self.EmapsGrid = MatplotlibWidget(self, self.nrows, self.ncols)
        self.EmapsGrid.add_Efield_annotations()
        self.ParaWaveHbox.addWidget(self.EmapsGrid)
        self.initializeEfieldsThread()
        self.EfieldsThread.start()

        # self.close()
        # self.__init__(ncols=ap.nwsamp)

    def changeplotsamp(self, amount):
        # self.rows = int(amount)
        self.plotsamp = int(amount)

