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
import random
import master

metric_name = __file__.split('/')[-1].split('.')[0]

master.set_field_params()
master.set_mkid_params()

# metric_vals = [0.4,0.7,1]
median_val = 0.8
# metric_multipler = np.logspace(np.log10(0.5), np.log10(2), 7)
metric_multiplier = np.linspace(0.5,1.25,4)
metric_vals = median_val * metric_multiplier
metric_vals[metric_vals>1] = 1

iop.set_testdir(f'{os.path.dirname(iop.testdir[:-1])}/{metric_name}')

dprint(metric_vals)

comps = False

def adapt_dp_master():
    if not os.path.exists(iop.testdir):
        os.mkdir(iop.testdir)
    with open(master.dp, 'rb') as handle:
        dp = pickle.load(handle)
    # metric_orig = getattr(mp,metric_name)#0.04
    iop.device_params = iop.device_params[:-4] + '_'+metric_name
    new_dp = copy.copy(dp)
    bad_inds = get_bad_inds(metric_vals)
    quicklook_im(dp.QE_map)
    for metric_val, bad_ind in zip(metric_vals, bad_inds):
        dprint((np.std(dp.QE_map)))
        new_dp.pix_yield = metric_val
        new_dp.QE_map = add_bad_pix(dp.QE_map_all, bad_ind)
        dprint(np.std(new_dp.QE_map))
        iop.device_params = iop.device_params.split('_'+metric_name)[0] + f'_{metric_name}={metric_val}.pkl'
        quicklook_im(new_dp.QE_map)
        plt.hist(new_dp.QE_map.flatten())
        plt.show(block=True)
        with open(iop.device_params, 'wb') as handle:
            pickle.dump(new_dp, handle, protocol=pickle.HIGHEST_PROTOCOL)

def get_bad_inds(pix_yields):
    pix_yields = np.array(pix_yields)
    min_yield = min(pix_yields)
    max_yield = max(pix_yields)
    amount = int(mp.array_size[0]*mp.array_size[1]*(1.-min_yield))
    all_bad_inds = random.sample(list(range(mp.array_size[0]*mp.array_size[1])), amount)
    # dprint(len(all_bad_inds))
    bad_inds_inds = np.int_((1 - (pix_yields-min_yield)/(max_yield-min_yield)) * amount)
    bad_inds = []
    for bad_inds_ind in bad_inds_inds:
        bad_inds.append(all_bad_inds[:bad_inds_ind])
    dprint(bad_inds)
    return bad_inds

def add_bad_pix(QE_map_all, bad_ind, plot=False):
    dprint(len(bad_ind))
    QE_map = np.array(QE_map_all, copy=True)
    if len(bad_ind) > 0:
        bad_y = np.int_(np.floor(bad_ind/mp.array_size[1]))
        bad_x = bad_ind % mp.array_size[1]
        QE_map[bad_x, bad_y] = 0
    if plot:
        plt.xlabel('responsivities')
        plt.ylabel('?')
        plt.title('Something Related to Bad Pixels')
        plt.imshow(QE_map)
        plt.show()

    return QE_map

# def form(metric_vals, metric_name, plot=True):
#     iop.perf_data = os.path.join(iop.testdir, 'perf_data.pkl')
#     if not os.path.exists(iop.perf_data):
#
#         if not os.path.exists(f'{iop.device_params[:-4]}_{metric_name}={metric_vals[0]}.pkl'):
#             adapt_dp_master()
#
#         comps_ = [True, False]
#         pca_products = []
#         for comps in comps_:
#             stackcubes, dps = master.get_stackcubes(metric_vals, metric_name, comps=comps, plot=False)
#             pca_products.append(master.pca_stackcubes(stackcubes, dps, comps))
#
#         maps = pca_products[0]
#         rad_samps = pca_products[1][1]
#         conts = pca_products[1][4]
#
#         with open(iop.perf_data, 'wb') as handle:
#             pickle.dump((maps, rad_samps, conts, metric_vals), handle, protocol=pickle.HIGHEST_PROTOCOL)
#     else:
#         with open(iop.perf_data, 'rb') as handle:
#             maps, rad_samps, conts, metric_vals = pickle.load(handle)
#
#     if plot:
#         master.combo_performance(maps, rad_samps, conts, metric_vals)
#
#     return rad_samps, conts

if __name__ == '__main__':
    master.form()
    # if not os.path.exists(f'{iop.device_params[:-4]}_{metric_name}={metric_vals[0]}.pkl'):
    #     adapt_dp_master()
    # stackcubes, dps = master.get_stackcubes(metric_vals, metric_name, comps=comps, plot=False)
    # # plt.show(block=True)
    # master.eval_performance(stackcubes, dps, metric_vals, comps=comps)