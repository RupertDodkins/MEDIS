import numpy as np
from PyQt5 import QtWidgets
# from statsmodels.tsa.stattools import acf
# from vip_hci import phot, pca
import medis.Detector.readout as read
from medis.params import iop, sp, cp, ap, tp
from functools import partial

# # generic function takes op and its argument
# def runOp(op, val):
#     return op(val)
#
# # declare full function
# def take_exposure(obs_sequence, exp_time):
#     downsample_cube = obs_sequence * exp_time
#     return downsample_cube
#
# # run example
# def main():
#     funcs = [take_exposure, take_exposure]
#     args = [0.1, 1]
#     for func, arg in zip(funcs, args):
#         f = partial(func, arg)
#         result = runOp(f, 1) # is 4
#         print(result)
#
# main()

def take_exposure(obs_sequence, exp_time):
    downsample_cube = obs_sequence * exp_time
    return downsample_cube

sp.use_gui = True
sp.show_cube = False
sp.save_locs = np.array([['add_atmos','phase'], ['quick_ao','phase'], ['prop_mid_optics','amp'], ['coronagraph','amp']])
sp.metric_funcs = [take_exposure, take_exposure]
sp.metric_args = [0.1, 1]
ap.nwsamp = 1
ap.companion = False
# ap.star_photons = 1e3


tp.detector = 'MKIDs'

from medis.Dashboard.architecture import MyWindow

if __name__ == "__main__":
    import sys

    app = QtWidgets.QApplication(sys.argv)
    app.setApplicationName('MyWindow')

    main = MyWindow()

    sys.exit(app.exec_())
