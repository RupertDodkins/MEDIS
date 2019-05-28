import os
from matplotlib.pylab import plt
import numpy as np
from medis.params import sp, ap, tp, iop
from medis.get_photon_data import run_medis
import medis.Dashboard.helper as help
from medis.Utils.misc import dprint

import warnings
warnings.filterwarnings("ignore")

sp.use_gui = True
sp.show_cube = False

# sp.save_locs = np.array(['add_atmos', 'quick_ao', 'prop_mid_optics', 'coronagraph'])
sp.save_locs = np.array(['add_atmos', 'tiptilt', 'prop_mid_optics'])
sp.gui_map_type = np.array(['phase', 'phase','amp'])

sp.metric_funcs = [help.plot_counts, help.take_acf, help.plot_stats, help.plot_psd]
locs = [[65,65], [65,83], [83,65], [83,83]]
sp.metric_args = [locs, locs, locs, locs]
ap.nwsamp = 1
ap.w_bins = 1
tp.include_dm = False
tp.include_tiptilt = True
tp.occulter_type = None
ap.companion = False
ap.contrast = []  #[1e-2]
ap.star_photons = 1e8
ap.sample_time = 1e-3
ap.exposure_time = 10e-4
ap.grid_size = 128
# tp.use_atmos = False
# tp.use_ao = False
# tp.detector = 'MKIDs'
tp.detector = 'ideal'

ap.numframes = 1000
sp.num_processes = 20
sp.gui_samp = sp.num_processes * 2  # display the field on multiples of this number

# *** This has to go here. Don't put at top! ***
from medis.Dashboard.run_dashboard import run_dashboard

if __name__ == "__main__":

    # 50 is roughly the amount where the GUI becomes noticably slow
    if ap.numframes <= 1000 and not os.path.exists(iop.fields):
        run_dashboard()
    else:
        e_fields_sequence = run_medis(realtime=False)
        # for loc in locs:
        #     print(loc, loc[0], loc[1])
        #     plt.psd(np.abs(e_fields_sequence[:, 0, 0, 0, loc[0], loc[1]]) ** 2)
        # plt.show()
        dprint(e_fields_sequence.shape)
        for r, (func, args) in enumerate(zip(sp.metric_funcs, sp.metric_args)):
            plt.figure()
            metric = func(np.abs(e_fields_sequence[:, -1, :, 0, :, :]) ** 2, args)
            plt.title(func.__name__.split('_'))
            for sample in metric:
                plt.plot(sample)
        plt.show()
