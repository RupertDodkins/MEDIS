'''Example Code for conducting SDI with MKIDs'''

import os
import matplotlib as mpl
import numpy as np
from scipy import interpolate
mpl.use("Qt5Agg")
import matplotlib.pylab as plt
import pickle as pickle
import medis.get_photon_data as gpd
from medis.params import mp, ap, iop
from medis.Utils.plot_tools import quicklook_im, view_datacube
from medis.Utils.misc import dprint
import master
import array_size

metric_name = __file__.split('/')[-1].split('.')[0]

master.set_field_params()
master.set_mkid_params()

median_val = mp.array_size[0]
metric_multiplier = np.logspace(np.log10(0.25), np.log10(4), 7)
metric_vals = np.int_(median_val * np.sqrt(metric_multiplier))
iop.set_testdir(f'{os.path.dirname(iop.testdir[:-1])}/{metric_name}/')

adapt_dp_master = array_size.adapt_dp_master


def rebin_factor(stackcube):
    orig_shape = stackcube.shape

    x = np.linspace(-orig_shape[2]/2, orig_shape[3]/2, orig_shape[2])
    xnew = np.linspace(-orig_shape[2]/2, orig_shape[3]/2, median_val)
    binned_cube = np.zeros((orig_shape[0], orig_shape[1], median_val, median_val))
    for d, datacube in enumerate(stackcube):
        for s, wslice in enumerate(datacube):
            f = interpolate.interp2d(x, x, wslice, kind='cubic')
            binned_cube[d,s] = f(xnew, xnew)

    return binned_cube

def get_stackcubes(metric_vals, _, master_cache, comps=True, plot=False):
    """ check iop.device params and form_photons """
    master_dp, master_fields = master_cache

    metric_name = 'array_size'

    iop.device_params = iop.device_params[:-4] + '_'+metric_name
    iop.form_photons = iop.form_photons[:-4] +'_'+metric_name

    dprint((iop.device_params))
    iop.fields = master_fields
    fields = gpd.run_medis()

    stackcubes, dps =  [], []
    for metric_val in metric_vals:
        dprint((metric_name, median_val, iop.device_params.split('_'+metric_name)[0]))
        iop.form_photons = iop.form_photons.split('_'+metric_name)[0] + f'_{metric_name}={metric_val}_comps={comps}.pkl'
        iop.device_params = iop.device_params.split('_'+metric_name)[0] + f'_{metric_name}={metric_val}.pkl'
        dprint(iop.device_params)
        if os.path.exists(iop.form_photons):
            dprint(f'Formatted photon data already exists at {iop.form_photons}')
            with open(iop.form_photons, 'rb') as handle:
                stackcube, _ = pickle.load(handle)

        else:
            stackcube, _ = master.get_form_photons(fields, comps=comps)

        if plot:
            plt.figure()
            plt.hist(stackcube[stackcube!=0].flatten(), bins=np.linspace(0,1e4, 50))
            plt.yscale('log')
            view_datacube(stackcube[0], logAmp=True, show=False)
            view_datacube(stackcube[:, 0], logAmp=True, show=True)

        stackcube /= np.sum(stackcube)  # /ap.numframes
        stackcube = np.transpose(stackcube, (1, 0, 2, 3))

        # view_datacube(stackcube[:,0],logAmp=True)
        stackcube = rebin_factor(stackcube)
        # view_datacube(stackcube[:,0], logAmp=True)

        stackcubes.append(stackcube)

        with open(master_dp, 'rb') as handle:
            dp = pickle.load(handle)
        dps.append(dp)

    return stackcubes, dps

if __name__ == '__main__':
    master.check_contrast_contriubtions(metric_vals, metric_name)
