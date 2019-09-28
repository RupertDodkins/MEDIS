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
from medis.Utils.plot_tools import quicklook_im, view_datacube
from medis.Utils.misc import dprint, expformat
from medis.Analysis.phot import contrcurve
import master

metric_name = __file__.split('/')[-1].split('.')[0]

master.set_field_params()
master.set_mkid_params()

median_val = 5
metric_multiplier = np.logspace(np.log10(0.5), np.log10(2), 7)
metric_vals = np.int_(np.round(median_val * metric_multiplier))

iop.set_testdir(f'{os.path.dirname(iop.testdir[:-1])}/{metric_name}')

print(ap.numframes)

comps = False

def adapt_dp_master():
    if not os.path.exists(iop.testdir):
        os.mkdir(iop.testdir)
    with open(master.dp, 'rb') as handle:
        dp = pickle.load(handle)
    iop.device_params = iop.device_params[:-4] + '_'+metric_name
    iop.device_params = iop.device_params.split('_' + metric_name)[0] + f'_{metric_name}={metric_vals}.pkl'
    new_dp = copy.copy(dp)
    with open(iop.device_params, 'wb') as handle:
        pickle.dump(new_dp, handle, protocol=pickle.HIGHEST_PROTOCOL)

def get_stackcubes(metric_vals, metric_name, comps=True, plot=False):
    iop.device_params = iop.device_params[:-4] + '_'+metric_name
    iop.form_photons = iop.form_photons[:-4] +'_'+metric_name

    iop.fields = master.master_fields
    fields = gpd.run_medis()

    stackcubes, dps =  [], []
    iop.device_params = iop.device_params.split('_'+metric_name)[0] + f'_{metric_name}={metric_vals}.pkl'
    for metric_val in metric_vals:
        iop.form_photons = iop.form_photons.split('_'+metric_name)[0] + f'_{metric_name}={metric_val}_comps={comps}.pkl'
        reduced_fields = fields[:metric_val]

        if os.path.exists(iop.form_photons):
            dprint(f'Formatted photon data already exists at {iop.form_photons}')
            with open(iop.form_photons, 'rb') as handle:
                stackcube, dp = pickle.load(handle)

        else:
            stackcube, dp = master.get_form_photons(reduced_fields, comps=comps)

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

def detect_obj_photons(metric_vals, metric_name, plot=False):
    iop.device_params = iop.device_params[:-4] + '_'+metric_name
    iop.form_photons = iop.form_photons[:-4] +'_'+metric_name

    iop.fields = master.master_fields
    fields = gpd.run_medis()

    objcubes, dps =  [], []
    # view_datacube(fields[0,:,1], logAmp=True)
    iop.device_params = iop.device_params.split('_' + metric_name)[0] + f'_{metric_name}={metric_vals}.pkl'
    for metric_val in metric_vals:
        iop.form_photons = iop.form_photons.split('_'+metric_name)[0] + f'_{metric_name}={metric_val}_obj.pkl'
        reduced_fields = fields[:metric_val]

        # fcy = np.array([256, 196, 256, 336, 256, 157, 256, 376])
        # fcx = np.array([207, 256, 327, 256, 167, 256, 367, 256])
        # from vip_hci.metrics.contrcurve import noise_per_annulus, aperture_flux
        # injected_flux = aperture_flux(np.mean(reduced_fields[:,:,1], axis=(0, 1)), fcy, fcx, 4, ap_factor=1)
        # plt.plot(injected_flux)
        # plt.show(block=True)

        if os.path.exists(iop.form_photons):
            dprint(f'Formatted photon data already exists at {iop.form_photons}')
            with open(iop.form_photons, 'rb') as handle:
                objcube, dp = pickle.load(handle)
        else:
            objcube, dp = master.get_obj_photons(reduced_fields)

        # fcy = np.array([75,  44,  75, 116,  75,  23,  75, 137])
        # fcx = np.array([49,  75, 111,  75,  28,  75, 132,  75])
        # injected_flux = aperture_flux(np.mean(objcube[:,:,1], axis=(0, 1)), fcy, fcx, 4, ap_factor=1)
        # plt.plot(injected_flux)
        # plt.show(block=True)

        if plot:
            dprint(objcube.shape)
            for o in range(3):
                plt.figure()
                plt.hist(objcube[o, objcube[o]!=0].flatten(), bins=np.linspace(0,1e4, 50))
                plt.yscale('log')
                view_datacube(objcube[o, 0], logAmp=True, show=False)
                view_datacube(objcube[o, :, 0], logAmp=True, show=False)

        objcube /= np.sum(objcube)  # /ap.numframes
        objcube = objcube
        objcube = np.transpose(objcube, (0, 2, 1, 3, 4))
        objcubes.append(objcube)
        dps.append(dp)

    return objcubes, dps

# def form(plot=True):
#     if not os.path.exists(f'{iop.device_params[:-4]}_{metric_name}={metric_vals[0]}.pkl'):
#         adapt_dp_master()
#     # stackcubes, dps = get_stackcubes(metric_vals, metric_name, comps=comps, plot=True)
#     # master.eval_performance(stackcubes, dps, metric_vals, comps=comps)
#
#     comps_ = [True, False]
#     pca_products = []
#     for comps in comps_:
#         stackcubes, dps = get_stackcubes(metric_vals, metric_name, comps=comps, plot=False)
#         pca_products.append(master.pca_stackcubes(stackcubes, dps, comps))
#
#     maps = pca_products[0]
#     rad_samps = pca_products[1][1]
#     conts = pca_products[1][4]
#
#     if plot:
#         master.combo_performance(maps, rad_samps, conts, metric_vals)
#
#     return rad_samps, conts

def form2():
    if not os.path.exists(f'{iop.device_params[:-4]}_{metric_name}={metric_vals[0]}.pkl'):
        adapt_dp_master()
    objcubes, dps = detect_obj_photons(metric_vals, metric_name, plot=False)

    maps, rad_samps, conts = [], [], []
    # fwhm = np.linspace(2,6,ap.w_bins)
    for objcube, dp in zip(objcubes, dps):
        cont_data = contrcurve(objcube, dp=dp)
        maps.append(cont_data[0])
        rad_samps.append(cont_data[1])
        conts.append(cont_data[2])

    master.combo_performance(maps, rad_samps, conts, metric_vals)

# def plot_sum_perf():
#     comps = False
#     stackcubes, dps = get_stackcubes(metric_vals, metric_name, comps=comps)
#     # master.eval_performance(stackcubes, dps, metric_vals, comps=comps)
#     master.eval_performance_sum(stackcubes, dps, metric_vals, comps=comps)

if __name__ == '__main__':
    master.form()
    # plot_sum_perf()