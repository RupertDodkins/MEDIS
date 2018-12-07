import sys, os
from scipy.interpolate import interp1d
import proper

import Telescope.telescope_dm as tdm
from Telescope.coronagraph import coronagraph
import Telescope.FPWFS as FPWFS
from Utils.plot_tools import view_datacube, quicklook_wf, quicklook_im, quicklook_IQ, loop_frames, get_intensity
import Utils.rawImageIO as rawImageIO
# import matplotlib.pylab as plt
# import params
from params import ap, tp, iop, sp

import numpy as np
from Analysis.stats import save_pix_IQ
from Analysis.phot import aper_phot
import speckle_killer_v3 as skv3
from Utils.misc import dprint
dprint(proper.__file__)