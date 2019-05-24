from matplotlib.pylab import plt
import numpy as np
from medis.params import sp, ap, tp
from medis.get_photon_data import run_medis
import medis.Dashboard.helper as help
from medis.Utils.misc import dprint

import warnings
warnings.filterwarnings("ignore")

sp.use_gui = True
sp.show_cube = False

# sp.save_locs = np.array(['add_atmos', 'quick_ao', 'prop_mid_optics', 'coronagraph'])
# sp.gui_map_type = np.array(['phase', 'phase','amp', 'amp'])

sp.metric_funcs = [help.plot_counts, help.take_acf, help.plot_stats, help.plot_psd]
locs = [[65,65], [65,83], [83,65], [83,83]]
sp.metric_args = [locs, locs, locs, locs]
ap.nwsamp = 1
ap.w_bins = 1
ap.companion = False
ap.contrast = [1e-2]
ap.star_photons = 1e8
ap.sample_time = 1e-3
ap.exposure_time = 10e-4
ap.grid_size = 128
# tp.use_atmos = False
# tp.use_ao = False
# tp.detector = 'MKIDs'
tp.detector = 'ideal'

ap.numframes = 100
sp.num_processes = 10

# *** This has to go here. Don't put at top! ***
from medis.Dashboard.run_dashboard import run_dashboard

if __name__ == "__main__":
    # 50 is roughly the amount where the GUI becomes noticably slow
    if ap.numframes < 200:
        run_dashboard()
    else:
        e_fields_sequence = run_medis(realtime=False)
        dprint(e_fields_sequence.shape)
        for r, (func, args) in enumerate(zip(sp.metric_funcs, sp.metric_args)):
            plt.figure()
            metric = func(np.abs(e_fields_sequence[:, 0, :, 0]) ** 2, args)
            plt.title(func.__name__.split('_'))
            for sample in metric:
                plt.plot(sample)
        plt.show()


