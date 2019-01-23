import sys
import os
sys.path.append(os.path.dirname(__file__))
sys.path.append(os.path.join(os.path.dirname(__file__), "Telescope"))
# set matplotlibrc to Qt5Agg gets rid of a whole bunch of warnings. Probably important...
import matplotlib as mpl
mpl.use('Qt5Agg')