'''Example Code for conducting SDI with MKIDs'''

import os
import matplotlib as mpl
import numpy as np
mpl.use("Qt5Agg")
import matplotlib.pylab as plt
import copy as copy
import pickle as pickle
from medis.params import mp, ap, iop
from medis.Utils.plot_tools import quicklook_im, view_datacube
from medis.Utils.misc import dprint
import master

metric_name = __file__.split('/')[-1].split('.')[0]
# metric_vals = [0.16, 0.04, 0.01]

master.set_field_params()
master.set_mkid_params()

median_val = mp.g_sig
metric_multiplier = np.logspace(np.log10(2.5), np.log10(0.4), 7)
metric_vals = median_val * metric_multiplier

iop.set_testdir(f'{os.path.dirname(iop.testdir[:-1])}/{metric_name}')

def adapt_dp_master():
    if not os.path.exists(iop.testdir):
        os.mkdir(iop.testdir)
    with open(master.master_dp, 'rb') as handle:
        dp = pickle.load(handle)
    metric_orig = getattr(mp,metric_name)#0.04
    QE_mean_orig = mp.g_mean
    iop.device_params = iop.device_params[:-4] + '_'+metric_name
    new_dp = copy.copy(dp)
    # quicklook_im(dp.QE_map)
    for metric_val in metric_vals:
        dprint((np.std(dp.QE_map), QE_mean_orig))
        new_dp.QE_map = (dp.QE_map - QE_mean_orig)*metric_val/metric_orig + QE_mean_orig
        new_dp.QE_map[dp.QE_map == 0] = 0
        new_dp.QE_map[new_dp.QE_map < 0] = 0
        dprint(np.std(new_dp.QE_map))
        iop.device_params = iop.device_params.split('_'+metric_name)[0] + f'_{metric_name}={metric_val}.pkl'
        dprint((iop.device_params, metric_val))
        # quicklook_im(new_dp.QE_map)
        # plt.hist(new_dp.QE_map.flatten())
        # plt.show(block=True)
        with open(iop.device_params, 'wb') as handle:
            pickle.dump(new_dp, handle, protocol=pickle.HIGHEST_PROTOCOL)


if __name__ == '__main__':
    master.check_contrast_contriubtions(metric_vals, metric_name)
