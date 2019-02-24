'''Place holder for the caos atmosphere map replacement (whatever form that takes)'''
import sys, os
from scipy.interpolate import interp1d
import proper

import medis.Telescope.adaptive_optics as ao
from medis.Telescope.coronagraph import coronagraph
import medis.Telescope.FPWFS as FPWFS
from medis.Utils.plot_tools import view_datacube, quicklook_wf, quicklook_im, quicklook_IQ, loop_frames, get_intensity
import medis.Utils.rawImageIO as rawImageIO
# import matplotlib.pylab as plt
# import medis.params
from medis.params import ap, tp, iop, sp

import numpy as np
from medis.Analysis.stats import save_pix_IQ
from medis.Analysis.phot import aper_phot
import speckle_killer_v3 as skv3
from medis.Utils.misc import dprint
dprint(proper.__file__)