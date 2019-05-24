import sys
from PyQt5 import QtWidgets
from medis.params import sp, ap, tp, iop
from medis.Utils.misc import dprint
dprint(ap.nwsamp)

from medis.Dashboard.architecture import MyWindow

def run_dashboard():
    app = QtWidgets.QApplication(sys.argv)
    app.setApplicationName('MyWindow')

    main = MyWindow()

    app.exec_()