

import sys
import random
import numpy as np
import time

from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg
from matplotlib.animation import TimedAnimation, FuncAnimation
from matplotlib.figure import Figure
from matplotlib import gridspec

from PyQt5.QtWidgets import QApplication, QMainWindow, QVBoxLayout, QWidget, \
    QPushButton, QLineEdit

from PyQt5.QtCore import QObject, pyqtSignal, pyqtSlot, QPropertyAnimation, QTimer

#
# class ImageMatrix(QObject):
#     ''' Represents a punching bag; when you punch it, it
#         emits a signal that indicates that it was punched. '''
#     captured = pyqtSignal(np.ndarray)
#
#     def __init__(self):
#         # Initialize the PunchingBag as a QObject
#         QObject.__init__(self)
#         self.captured.connect(self.display)
#
#     def capture(self, val):
#         ''' Punch the bag '''
#         # self.val = val
#         self.captured.emit(val)
#
#     @pyqtSlot()
#     def display(self, val):
#         ''' Give evidence that a bag was punched. '''
#         print('Signal received')
#         plt.imshow(val)
#         plt.show(block=True)
# #
# import matplotlib.pylab as plt
#
#
# #
# #
# matrix = ImageMatrix()
# for i in range(3):
#     data = [random.random() for _ in range(100)]
#     image = np.array(data).reshape(10, 10)
#     matrix.capture(image)
# #

def generate_data(ex):
    for i in range(3):
        data = [random.random() for _ in range(100)]
        image = np.array(data).reshape(10, 10)
        ex.matrix = image
        time.sleep(0.5)

import matplotlib.pylab as plt

plt.ion()

class MatplotlibWidget(QWidget):

    captured = pyqtSignal(np.ndarray)

    def __init__(self, parent=None, rows=3, cols=2):
        super(MatplotlibWidget, self).__init__(parent)

        self.rows, self.cols = rows, cols
        print(self.rows)
        gs = gridspec.GridSpec(self.rows, self.cols)
        self.fig = Figure()
        for n in range(self.rows*self.cols):
            self.fig.add_subplot(gs[n])
        self.axes = self.fig.axes
        self.canvas = FigureCanvasQTAgg(self.fig)

        self.layoutVertical = QVBoxLayout(self)#QVBoxLayout
        self.layoutVertical.addWidget(self.canvas)

        self.captured.connect(self.plot)
        self.timer = QTimer(self)
        self.timer.timeout.connect(self.plot)
        self.timer.start(500)

    def plot(self):
        # self.matplotlibWidget.axes[x].clear()
        print('running plot')

        data = [random.random() for _ in range(100)]
        self.matrix = np.array(data).reshape(10, 10)
        for x in range(self.rows * self.cols):
            self.axes[x].imshow(self.matrix)
        self.canvas.draw()
        # FigureCanvas.__init__(self, self.fig)
        # TimedAnimation.__init__(self, self.fig, interval=50, blit = True)

class MainWindow(QMainWindow):

    # captured = pyqtSignal(np.ndarray)

    def __init__(self, nrows=1, matrix=np.zeros((10, 10))):
        super().__init__()
        self.setWindowTitle("My Awesome App")
        self.left = 10
        self.top = 10
        self.title = 'PyQt5 matplotlib example - pythonspot.com'
        self.width = 640
        self.height = 200 + 200*nrows
        self._matrix = matrix

        self.initUI(nrows=nrows)
        self.show()

    def initUI(self, nrows=2):
        self.setWindowTitle(self.title)
        self.setGeometry(self.left, self.top, self.width, self.height)

        window = QWidget()
        layout = QVBoxLayout()

        button = QPushButton('Go', self)
        button.setToolTip('Start the simulation')
        # button.move(500, 0)
        # button.resize(140, 100)
        button.clicked.connect(self.on_button_clicked)

        probe_screens = QLineEdit()
        probe_screens.textChanged.connect(self.textchanged)

        self.matplotlibWidget = MatplotlibWidget(self, nrows)
        self.rows, self.cols = self.matplotlibWidget.rows, self.matplotlibWidget.cols

        # self.captured.connect(self.matplotlibWidget.plot)

        layout.addWidget(button)
        layout.addWidget(probe_screens)
        layout.addWidget(self.matplotlibWidget)

        window.setLayout(layout)
        self.setCentralWidget(window)

        # myDataLoop = threading.Thread(name='myDataLoop', target=dataSendLoop, daemon=True,
        #                               args=(self.addData_callbackFunc,))
        # myDataLoop.start()

    # def capture(self, val):
    #     ''' Punch the bag '''
    #     # self.val = val
    #     print('received val', val.shape)
    #     self.captured.emit(val)
    #
    #
    # def generate_data(self):
    #     for i in range(3):
    #         data = [random.random() for _ in range(100)]
    #         image = np.array(data).reshape(10, 10)
    #         self.capture(image)
    #         print(i)
    #         time.sleep(0.2)

    @property
    def matrix(self):
        return self._matrix

    @matrix.setter
    def matrix(self, new_matrix):
        self._matrix = new_matrix
        # After the radius is changed, emit the
        # resized signal with the new radius
        print('matrix setter called')

        # for x in range(self.rows*self.cols):
        #     self.matplotlibWidget.axes[x].clear()
        #     self.matplotlibWidget.axes[x].imshow(self.matrix)
        #     # self.matplotlibWidget.axes[x].add_image(ln)
        #
        # self.matplotlibWidget.canvas.draw()

        self.matplotlibWidget.captured.emit(new_matrix)
        # self.captured.emit(new_matrix)

    # @pyqtSlot()
    # def display(self, val):
    #     ''' Give evidence that a bag was punched. '''
    #     print('Signal received', np.shape(val))
    #     plt.imshow(val)
    #     plt.show(block=True)

    # def plot(self, i):
    #     # self.matplotlibWidget.axes[x].clear()
    #     print('running')
    #     for x in range(self.rows * self.cols):
    #         self.matplotlibWidget.axes[x].imshow(self.matrix)
    #     self.matplotlibWidget.canvas.draw()

    def on_button_clicked(self):
        # gpd.run_medis()

        print('button clicked')
        # self.matplotlibWidget.timer.start(500)

        print('here')
        # self.anim = QPropertyAnimation(self.matplotlibWidget.fig, self.plot)
        generate_data(self)

        # self.matrix = np.ones((2, 10, 10))



    def textchanged(self, amount):
        self.rows = int(amount)
        self.close()
        self.__init__(int(amount))
#
# import medis.Detector.get_photon_data as gpd
# from medis.params import iop, sp, tp
# from medis.Utils.plot_tools import initialize_GUI, quicklook_im
# import multiprocessing
#
# import matplotlib.pylab as plt
#
@pyqtSlot()
def display(x):
    print('running display', x[0,0])
    # plt.imshow(x)
    # plt.show(block=True)

if __name__ == '__main__':
    # images = multiprocessing.Queue()
    # tp.nwsamp = 1
    # sp.show_cube = False
    app = QApplication(sys.argv)
    ex = MainWindow()

    # ex.captured.connect(display)
    # ex.matrix = np.ones((2,10,10))

    sys.exit(app.exec_())
#
#
# # import numpy as np
# #
# # import time
# #
# # #
# # # import matplotlib.pylab as plt
# # # import matplotlib as mpl
# # #
# # # plt.plot(range(5))
# # # # with mpl.rc_context(rc={'interactive': True}):
# # # #
# # # #     plt.show()
# # #
# # # time.sleep(5)
# # #
# # # print('lol')
# # # # # plt.ion()
# # # # #
# # # # # plt.draw()
# # # # # plt.show(block=False)
# # # # # # plt.ion()
# # # # # # plt.show()
# # # # #
# # iop.update("gui/")
# # initialize_GUI()
# # # # # print(sp.show_wframe)
# # quicklook_im(np.arange(9).reshape(3,3), show=sp.show_wframe, logAmp=True)
# # quicklook_im(np.arange(9).reshape(3,3), show=sp.show_wframe, logAmp=True)
# # quicklook_im(np.arange(9).reshape(3,3), show=sp.show_wframe, logAmp=True)
# #
# #
# # # time.sleep(5)
# # # # plt.ion()
# # # # ax = plt.gca()
# # # # # ax= sp.fig.add_subplot(111)
# # # # ax.imshow(np.arange(9).reshape(3,3))
# # # # # sp.fig.canvas.draw()
# # # # # plt.show(block=False)
# # # # # # sp.show_wframe = True
# # # #
# # #
# # # # #
# # sp.get_ints = False
# # tp.nwsamp = 1
# # sp.show_cube = False
# # if __name__ == '__main__':
# #     simple_hypercube_1 = read.get_integ_obs_sequence()