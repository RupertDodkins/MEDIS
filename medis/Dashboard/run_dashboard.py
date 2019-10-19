import sys
from PyQt5 import QtWidgets

from medis.Dashboard.architecture import Dashboard

def run_dashboard():
    app = QtWidgets.QApplication(sys.argv)
    app.setApplicationName('Dashboard')

    main = Dashboard()

    app.exec_()