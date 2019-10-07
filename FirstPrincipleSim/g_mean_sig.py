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

master.set_field_params()
master.set_mkid_params()

median_val = mp.g_mean
# metric_multiplier = np.logspace(np.log10(0.1), np.log10(2.25), 7)
metric_multiplier = np.logspace(np.log10(0.1), np.log10(10), 7)

metric_vals = median_val * metric_multiplier


iop.set_testdir(f'{os.path.dirname(iop.testdir[:-1])}/{metric_name}')

def adapt_dp_master():
    if not os.path.exists(iop.testdir):
        os.mkdir(iop.testdir)
    with open(master.master_dp, 'rb') as handle:
        dp = pickle.load(handle)
    mean_orig = mp.g_mean
    sig_orig = mp.g_sig
    iop.device_params = iop.device_params[:-4] + '_'+metric_name
    new_dp = copy.copy(dp)
    # quicklook_im(dp.QE_map)
    for metric_val in metric_vals:
        dprint((np.std(dp.QE_map)))
        new_dp.QE_map = (dp.QE_map - mean_orig) * (2/15.)*metric_val / sig_orig + metric_val
        new_dp.QE_map[new_dp.QE_map < 0] = 0
        new_dp.QE_map[dp.QE_map == 0] = 0
        # new_dp.QE_map = dp.QE_map * metric_val / QE_mean_orig
        dprint(np.std(new_dp.QE_map))
        iop.device_params = iop.device_params.split('_'+metric_name)[0] + f'_{metric_name}={metric_val}.pkl'
        dprint((iop.device_params, metric_val))
        # quicklook_im(new_dp.QE_map)
        # plt.hist(new_dp.QE_map.flatten())
        # plt.show(block=True)

        with open(iop.device_params, 'wb') as handle:
            pickle.dump(new_dp, handle, protocol=pickle.HIGHEST_PROTOCOL)

def check_param_dp():
    iop.set_testdir(f'FirstPrincipleSim_repeat{0}_quantize_fcs/master/')
    iop.set_testdir(f'{os.path.dirname(iop.testdir[:-1])}/{metric_name}')
    for metric_val in metric_vals:
        param_dp = f'{iop.device_params[:-4]}_{metric_name}={metric_val}.pkl'
        with open(param_dp, 'rb') as handle:
            dp = pickle.load(handle)
        quicklook_im(dp.QE_map)
        plt.hist(dp.QE_map.flatten())
        plt.show(block=True)


# if __name__ == '__main__':
#     # check_param_dp()
