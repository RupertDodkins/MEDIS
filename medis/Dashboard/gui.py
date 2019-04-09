import numpy as np
from proper_mod import prop_run
from matplotlib.colors import LogNorm, SymLogNorm

from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg
from matplotlib.figure import Figure
from matplotlib import gridspec

from PyQt5 import QtCore
from PyQt5 import QtWidgets

from medis.params import tp,ap,sp,iop,cp

sp.save_locs = np.array([['add_obscurations', 'phase'], ['quick_ao', 'phase'], ['prop_mid_optics', 'amp']])

class MatplotlibWidget(QtWidgets.QWidget):
    def __init__(self, parent=None, nrows=3, ncols=2):
        super(MatplotlibWidget, self).__init__(parent)

        self.nrows, self.ncols = nrows, ncols
        self.figure = Figure()
        self.canvas = FigureCanvasQTAgg(self.figure)

        gs = gridspec.GridSpec(self.nrows, self.ncols)
        for n in range(self.nrows*self.ncols):
            self.figure.add_subplot(gs[n])
        self.axes = np.array(self.figure.axes).reshape(self.nrows, self.ncols)

        wsamples = np.linspace(ap.band[0], ap.band[1], ap.nwsamp).astype(int)
        for r in range(self.nrows):
            self.axes[0, r].set_title('{} nm'.format(wsamples[r]))
        props = dict(boxstyle='square', facecolor='k', alpha=0.5)
        for c in range(self.ncols):
            self.axes[c, 0].text(0.05, 0.075, sp.save_locs[c,0], transform=self.axes[c, 0].transAxes, fontweight='bold', color='w',
                            fontsize=12, bbox=props)
            self.axes[0, r].set_title('{} nm'.format(wsamples[r]))

        self.layoutVertical = QtWidgets.QVBoxLayout(self)
        self.layoutVertical.addWidget(self.canvas)


class ThreadSample(QtCore.QThread):
    newSample = QtCore.pyqtSignal(np.ndarray)

    def __init__(self, parent=None):
        super(ThreadSample, self).__init__(parent)

    def run(self):
        for t in range(10):
            # selec_E_fields, _ = prop_run( 'examples.prescription_gui', 1.1, 128, PHASE_OFFSET = 1 )

            r0 = 0.2
            atmos_map = iop.atmosdir + '/telz%f_%1.3f.fits' % (t * cp.frame_time, r0)

            kwargs = {'iter': t, 'atmos_map': atmos_map, 'params': [ap, tp, iop, sp]}
            _, selec_E_fields = prop_run('medis.Telescope.optics_propagate', 1, ap.grid_size, PASSVALUE=kwargs, PHASE_OFFSET=1)

            gui_images = np.zeros_like(selec_E_fields, dtype=np.float)
            phase_ind = sp.save_locs[:, 1] == 'phase'
            amp_ind = sp.save_locs[:, 1] == 'amp'

            gui_images[phase_ind] = np.angle(selec_E_fields[phase_ind], deg=False)
            gui_images[amp_ind] = np.absolute(selec_E_fields[amp_ind])

            self.newSample.emit(gui_images)


class MyWindow(QtWidgets.QWidget):
    def __init__(self, nrows=3, ncols=3):
        super().__init__()

        self.pushButtonPlot = QtWidgets.QPushButton(self)
        self.pushButtonPlot.setText("Run Simulation")
        self.pushButtonPlot.clicked.connect(self.on_pushButtonPlot_clicked)

        probe_screens = QtWidgets.QLineEdit()
        probe_screens.textChanged.connect(self.textchanged)

        self.nrows = nrows
        self.ncols = ncols
        self.matplotlibWidget = MatplotlibWidget(self, self.nrows, self.ncols)
        self.rows, self.cols = self.matplotlibWidget.nrows, self.matplotlibWidget.ncols

        self.layoutVertical = QtWidgets.QVBoxLayout(self)
        self.layoutVertical.addWidget(self.pushButtonPlot)
        self.layoutVertical.addWidget(probe_screens)
        self.layoutVertical.addWidget(self.matplotlibWidget)

        self.threadSample = ThreadSample(self)
        self.threadSample.newSample.connect(self.on_threadSample_newSample)

        self.left = 10
        self.top = 10
        self.width = 750
        self.height = 200 + 200*nrows
        self.title = 'MEDIS Dashboard'
        self.setWindowTitle(self.title)
        self.setGeometry(self.left, self.top, self.width, self.height)

        self.show()

    @QtCore.pyqtSlot()
    def on_pushButtonPlot_clicked(self):
        self.samples = 0
        # for x in range(self.rows):
        #     for y in range(self.cols):
        #         self.matplotlibWidget.axes[x,y].clear()

        self.threadSample.start()

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
                im = self.matplotlibWidget.axes[x,y].imshow(gui_images[x,y,0], norm=norm[x],
                                                            vmin=vmin[x], vmax=vmax[x], cmap=cmap[x])
                if y == 2:
                    cax = self.matplotlibWidget.figure.add_axes([0.92, 0.09 + 0.277 * (self.rows -1 -x), 0.025, 0.25])

            # cb = fig.colorbar(im, cax=cax, orientation='vertical',format=ticker.FuncFormatter(fmt))
            cb = self.matplotlibWidget.figure.colorbar(im, cax=cax, orientation='vertical')

        self.matplotlibWidget.canvas.draw()

    def textchanged(self, amount):
        self.rows = int(amount)
        self.close()
        self.__init__(int(amount))

if __name__ == "__main__":
    import sys

    app = QtWidgets.QApplication(sys.argv)
    app.setApplicationName('MyWindow')

    main = MyWindow()

    sys.exit(app.exec_())
