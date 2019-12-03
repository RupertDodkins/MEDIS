import os
from matplotlib.pylab import plt
import numpy as np
from medis.params import sp, ap, tp, iop, cp
from medis.get_photon_data import run_medis
import medis.Dashboard.helper as help
from medis.Utils.misc import dprint

import warnings
warnings.filterwarnings("ignore")

sp.use_gui = True
sp.show_cube = False


# sp.save_locs = np.array(['add_atmos', 'tiptilt', 'closedloop_wfs', 'prop_mid_optics'])
# sp.gui_map_type = np.array(['phase', 'phase', 'phase', 'amp'])
# sp.save_locs = np.array(['add_atmos',  'prop_mid_optics'])
# sp.gui_map_type = np.array(['phase', 'amp'])
sp.save_locs = np.array(['add_atmos', 'deformable_mirror',  'prop_mid_optics', 'coronagraph'])
sp.gui_map_type = np.array(['phase', 'phase', 'amp', 'amp'])


sp.metric_funcs = [help.plot_counts, help.take_acf, help.plot_stats]
# locs = [[70,65], [65,83], [83,65], [65,70]]
locs = [[65,65], [70,50], [50,70], [80,80]]
sp.metric_args = [locs, locs, locs]
ap.nwsamp = 2
ap.w_bins = ap.nwsamp
# tp.include_dm = False
# tp.include_tiptilt = True
tp.include_dm = True
tp.include_tiptilt = False
tp.occulter_type = 'Vortex'
ap.companion = True
if ap.companion == False:
    ap.contrast = []  #[1e-2]
else:
    ap.contrast = [1e-2]  #[1e-2]
ap.band = [800, 1000]
ap.star_photons_per_s = 1e8
ap.sample_time = 1e-2
ap.exposure_time = 1e-2
tp.beam_ratio = 0.25 #0.75
ap.grid_size = 512
tp.use_atmos = True
tp.use_ao = True
tp.detector = 'ideal'
tp.quick_ao = True
tp.servo_error = [0, 1]
tp.aber_params['CPA'] = True
tp.aber_params['NCPA'] = True

ap.numframes = 100
sp.num_processes = 1
sp.gui_samp = sp.num_processes * 5  # display the field on multiples of this number
cp.model = 'single'
iop.update('GUI demo')

# *** This has to go here. Don't put at top! ***
from medis.Dashboard.run_dashboard import run_dashboard

if __name__ == "__main__":
    run_dashboard()

