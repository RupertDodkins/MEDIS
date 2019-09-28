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
from medis.Utils.misc import dprint, expformat
import master

metric_name = __file__.split('/')[-1].split('.')[0]
# metric_vals = [1e7, 5e6, 1e6]

master.set_field_params()
master.set_mkid_params()

# metric_vals = np.int_(np.round(mp.dark_bright * np.logspace(np.log10(0.1), np.log10(10), 7)))[::-1]
median_val = mp.dark_bright
metric_multiplier = np.logspace(np.log10(10), np.log10(0.1), 7)  # flip metric_vals because fewer dark counts is better
metric_vals = np.int_(np.round(median_val * metric_multiplier))

iop.set_testdir(f'{os.path.dirname(iop.testdir[:-1])}/{metric_name}')

dprint((metric_vals,iop.testdir))

comps = False

def adapt_dp_master():
    if not os.path.exists(iop.testdir):
        os.mkdir(iop.testdir)
    with open(master.dp, 'rb') as handle:
        dp = pickle.load(handle)
    metric_orig = getattr(mp,metric_name)#0.04
    # QE_mean_orig = mp.dark_bright
    iop.device_params = iop.device_params[:-4] + '_'+metric_name
    new_dp = copy.copy(dp)
    # quicklook_im(dp.QE_map)
    for metric_val in metric_vals:
        # dprint((np.std(dp.QE_map), QE_mean_orig))
        new_dp.dark_bright = metric_val
        new_dp.dark_pix_frac = 1./2
        new_dp.dark_per_step = ap.sample_time * new_dp.dark_bright
        iop.device_params = iop.device_params.split('_'+metric_name)[0] + f'_{metric_name}={metric_val}.pkl'
        dprint((iop.device_params, metric_val))
        with open(iop.device_params, 'wb') as handle:
            pickle.dump(new_dp, handle, protocol=pickle.HIGHEST_PROTOCOL)

# def form(plot=True):
#     if not os.path.exists(f'{iop.device_params[:-4]}_{metric_name}={metric_vals[0]}.pkl'):
#         adapt_dp_master()
#     # stackcubes, dps = get_stackcubes(metric_vals, metric_name, comps=comps, plot=True)
#     # master.eval_performance(stackcubes, dps, metric_vals, comps=comps)
#
#     comps_ = [True, False]
#     pca_products = []
#     for comps in comps_:
#         stackcubes, dps = master.get_stackcubes(metric_vals, metric_name, comps=comps, plot=False)
#         pca_products.append(master.pca_stackcubes(stackcubes, dps, comps))
#
#     maps = pca_products[0]
#     rad_samps = pca_products[1][1]
#     conts = pca_products[1][4]
#
#     if plot:
#         annos = [expformat(metric_val, 0, 1) for metric_val in metric_vals]
#         master.combo_performance(maps, rad_samps, conts, annos)
#
#     return rad_samps, conts

if __name__ == '__main__':
    # master.form()
    master.check_contrast_contriubtions(metric_vals, metric_name)