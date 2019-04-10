import numpy as np
from PyQt5 import QtWidgets
from medis.params import iop, sp, cp, ap, tp

sp.use_gui = True
sp.show_cube = False
sp.save_locs = np.array([['add_obscurations', 'phase'], ['quick_ao', 'phase'], ['prop_mid_optics', 'amp']])
ap.nwsamp = 1

from medis.Dashboard.gui import MyWindow

if __name__ == "__main__":
    import sys

    app = QtWidgets.QApplication(sys.argv)
    app.setApplicationName('MyWindow')

    main = MyWindow()

    app.exec_()
