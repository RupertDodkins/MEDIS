'''Example Code for conducting SDI with MKIDs'''

import os
import matplotlib as mpl
import numpy as np
mpl.use("Qt5Agg")
import matplotlib.pylab as plt
import copy as copy
import pickle as pickle
import medis.get_photon_data as gpd
from medis.params import mp, ap, iop, tp, sp
from medis.Utils.plot_tools import quicklook_im, view_datacube
from medis.Utils.misc import dprint
from medis.Utils.rawImageIO import clipped_zoom
import medis.Detector.mkid_artefacts as MKIDs
import master

metric_name = __file__.split('/')[-1].split('.')[0]
metric_vals = np.array([[100,100],[150,150],[200,200]])

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
    metric_orig = getattr(mp,metric_name)#0.04
    iop.device_params = iop.device_params[:-4] + '_'+metric_name
    quicklook_im(dp.QE_map)
    for metric_val in metric_vals:
        dprint((np.std(dp.QE_map), metric_val))
        mp.array_size = np.array(metric_val)
        iop.device_params = iop.device_params.split('_'+metric_name)[0] + f'_{metric_name}={metric_val}.pkl'
        new_dp = MKIDs.initialize()
        dprint((iop.device_params, metric_val))
        quicklook_im(new_dp.QE_map)
        plt.hist(new_dp.QE_map.flatten())
        plt.show(block=True)
        new_dp.platescale = mp.platescale * metric_orig[0]/metric_val[0]
        new_dp.array_size = metric_val
        with open(iop.device_params, 'wb') as handle:
            pickle.dump(new_dp, handle, protocol=pickle.HIGHEST_PROTOCOL)

if __name__ == '__main__':
    # print(iop.fields)
    # master.set_field_params()
    # ap.grid_size = 512
    # tp.beam_ratio = 0.25
    #
    # # sp.save_locs = np.array(['add_atmos', 'deformable_mirror', 'prop_mid_optics', 'coronagraph'])
    # # sp.gui_map_type = np.array(['phase', 'phase', 'amp', 'amp'])
    # # from medis.Dashboard.run_dashboard import run_dashboard
    # # run_dashboard()
    # fields = gpd.run_medis()
    # # tess = np.abs(np.sum(fields[:, -1, :, :], axis=2)) ** 2
    # # view_datacube(tess[0], logAmp=True, show=False)
    # # view_datacube(tess[:, 0], logAmp=True, show=True)
    # master.set_mkid_params()
    if not os.path.exists(f'{iop.device_params[:-4]}_{metric_name}={metric_vals[0]}.pkl'):
        adapt_dp_master()
    # ap.star_photons_per_s = 1e6
    stackcubes, dps = master.get_stackcubes(metric_vals, metric_name, comps=comps)
    master.eval_performance(stackcubes, dps, metric_vals, comps=comps)
    # iop.device_params = iop.device_params[:-4] + '_' + metric_name
    # for metric_val in metric_vals:
    #     iop.device_params = iop.device_params.split('_' + metric_name)[0] + f'_{metric_name}={metric_val}.pkl'
    #     master.get_form_photons(fields)
