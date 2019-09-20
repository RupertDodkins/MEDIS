'''Example Code for conducting SDI with MKIDs'''

import os
import matplotlib as mpl
import numpy as np
mpl.use("Qt5Agg")
import matplotlib.pylab as plt
import copy as copy
import pickle as pickle
from medis.params import ap, iop
import medis.get_photon_data as gpd
from medis.Utils.plot_tools import view_datacube
from medis.Utils.misc import dprint, expformat
import master

metric_name = __file__.split('/')[-1].split('.')[0]
metric_vals = [1e4, 1e5, 1e6]

master.set_field_params()
master.set_mkid_params()

iop.set_testdir(f'FirstPrincipleSim/{metric_name}')
iop.set_atmosdata('190823')
iop.set_aberdata('Palomar512')

print(ap.numframes)

comps = True

def adapt_dp_master():
    if not os.path.exists(iop.testdir):
        os.mkdir(iop.testdir)
    with open(master.dp, 'rb') as handle:
        dp = pickle.load(handle)
    iop.device_params = iop.device_params[:-4] + '_'+metric_name
    for metric_val in metric_vals:
        new_dp = copy.copy(dp)
        iop.device_params = iop.device_params.split('_' + metric_name)[0] + f'_{metric_name}={metric_val}.pkl'
        new_dp.star_phot = metric_val
        with open(iop.device_params, 'wb') as handle:
            pickle.dump(new_dp, handle, protocol=pickle.HIGHEST_PROTOCOL)

def get_stackcubes(metric_vals, metric_name, comps=True, plot=False):
    iop.device_params = iop.device_params[:-4] + '_'+metric_name
    iop.form_photons = iop.form_photons[:-4] +'_'+metric_name

    iop.fields = master.master_fields
    fields = gpd.run_medis()

    stackcubes, dps =  [], []
    for metric_val in metric_vals:
        iop.device_params = iop.device_params.split('_'+metric_name)[0] + f'_{metric_name}={metric_val}.pkl'
        iop.form_photons = iop.form_photons.split('_'+metric_name)[0] + f'_{metric_name}={metric_val}_comps={comps}.pkl'
        ap.star_photons_per_s = metric_val

        if os.path.exists(iop.form_photons):
            dprint(f'Formatted photon data already exists at {iop.form_photons}')
            with open(iop.form_photons, 'rb') as handle:
                stackcube, dp = pickle.load(handle)

        else:
            stackcube, dp = master.get_form_photons(fields, comps=comps)

        if plot:
            plt.figure()
            plt.hist(stackcube[stackcube!=0].flatten(), bins=np.linspace(0,1e4, 50))
            plt.yscale('log')
            view_datacube(stackcube[0], logAmp=True, show=False)
            view_datacube(stackcube[:, 0], logAmp=True, show=False)

        stackcube /= np.sum(stackcube)  # /ap.numframes
        stackcube = stackcube
        stackcube = np.transpose(stackcube, (1, 0, 2, 3))
        stackcubes.append(stackcube)
        dps.append(dp)

    return stackcubes, dps

def form():
    if not os.path.exists(f'{iop.device_params[:-4]}_{metric_name}={metric_vals[0]}.pkl'):
        adapt_dp_master()

    # stackcubes, dps = get_stackcubes(metric_vals, metric_name, comps=comps, plot=True)
    # master.eval_performance(stackcubes, dps, metric_vals, comps=comps)

    comps_ = [True, False]
    pca_products = []
    for comps in comps_:
        stackcubes, dps = get_stackcubes(metric_vals, metric_name, comps=comps, plot=False)
        pca_products.append(master.pca_stackcubes(stackcubes, dps, comps))

    maps = pca_products[0]
    rad_samps = pca_products[1][1]
    conts = pca_products[1][4]

    annos = [expformat(metric_val,0,1) for metric_val in metric_vals]
    master.combo_performance(maps, rad_samps, conts, annos)

def plot_sum_perf():
    comps = False
    stackcubes, dps = get_stackcubes(metric_vals, metric_name, comps=comps)
    # master.eval_performance(stackcubes, dps, metric_vals, comps=comps)
    master.eval_performance_sum(stackcubes, dps, metric_vals, comps=comps)

if __name__ == '__main__':
    # form()

    # plot_sum_perf()

    comps = False
    stackcubes, dps = master.get_stackcubes(metric_vals, metric_name, comps=comps)
    master.eval_performance(stackcubes, dps, metric_vals, comps=comps)

