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
sp.save_locs = np.array(['add_atmos',  'prop_mid_optics'])
sp.gui_map_type = np.array(['phase', 'amp'])
# sp.save_locs = np.array(['add_atmos', 'closedloop_wfs', 'prop_mid_optics'])
# sp.gui_map_type = np.array(['phase', 'phase', 'amp'])

sp.metric_funcs = [help.plot_counts, help.take_acf, help.plot_stats, help.plot_psd]
# locs = [[70,65], [65,83], [83,65], [65,70]]
locs = [[70,70], [80,80], [90,90], [100,100]]
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
ap.exposure_time = 1e-3
tp.beam_ratio = 0.5 #0.75
ap.grid_size = 128
tp.use_atmos = True
tp.use_ao = True
# tp.detector = 'MKIDs'
tp.detector = 'ideal'
tp.quick_ao = False
tp.servo_error = [0, 1]
tp.aber_params['CPA'] = True
tp.aber_params['NCPA'] = True

ap.numframes = 13000
sp.num_processes = 1
sp.gui_samp = sp.num_processes * 50  # display the field on multiples of this number
cp.model = 'single'
iop.datadir = '/mnt/data0/dodkins/medis_save'
iop.update()

# *** This has to go here. Don't put at top! ***
from medis.Dashboard.run_dashboard import run_dashboard
from scipy.signal import savgol_filter
from statsmodels.tsa.stattools import acf

if __name__ == "__main__":

    # 50 is roughly the amount where the GUI becomes noticably slow
    if ap.numframes <= 20000 and not os.path.exists(iop.fields):
        run_dashboard()
    else:
        e_fields_sequence = run_medis(realtime=False)
        from statsmodels.graphics.tsaplots import plot_acf
        figs, lines = [], []
        for loc in locs:
            print(loc)
            counts = np.mean(np.abs(e_fields_sequence[:, -1, 0, 0, loc[0]-3:loc[0]+3, loc[1]-3:loc[1]+3]) ** 2, axis=(1,2))
            # smooth = savgol_filter(counts, 51, 3)
            # figs.append(plot_acf(counts, use_vlines=False, alpha=None, lags=1000))
            plt.plot(acf(counts, nlags=1000), label='pix %i, %i' % (loc[0], loc[1]), linewidth=2)

        # for fig in figs:
        #     ax = fig.add_subplot(111)
        #     lines.append(ax.plot())
        plt.xlabel(r'$\tau$ (ms)')
        plt.ylabel(r'$C_1(\tau)$')
        plt.legend()
        plt.show()
        # dprint(e_fields_sequence.shape)
        # for r, (func, args) in enumerate(zip(sp.metric_funcs, sp.metric_args)):
        #     plt.figure()
        #     metric = func(np.abs(e_fields_sequence[:, -1, :, 0, :, :]) ** 2, args)
        #     plt.title(func.__name__.split('_'))
        #     for sample in metric:
        #         plt.plot(sample)
        # plt.show()
