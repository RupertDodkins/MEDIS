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
# metric_vals = np.array([[100,100],[150,150],[200,200]])

master.set_field_params()
master.set_mkid_params()

median_val = mp.array_size[0]
metric_multiplier = np.logspace(np.log10(0.25), np.log10(4), 7)
metric_vals = np.int_(median_val * np.sqrt(metric_multiplier))#[:,np.newaxis])
iop.set_testdir(f'{os.path.dirname(iop.testdir[:-1])}/{metric_name}')

print(ap.numframes)

comps = True

def adapt_dp_master():
    if not os.path.exists(iop.testdir):
        os.mkdir(iop.testdir)
    # with open(master.dp, 'rb') as handle:
    #     dp = pickle.load(handle)
    metric_orig = getattr(mp,metric_name)#0.04
    iop.device_params = iop.device_params[:-4] + '_'+metric_name
    for metric_val in metric_vals:
        mp.array_size = np.array([metric_val]*2)
        iop.device_params = iop.device_params.split('_'+metric_name)[0] + f'_{metric_name}={metric_val}.pkl'
        new_dp = MKIDs.initialize()
        new_dp.lod = (metric_val/metric_orig[0])*mp.lod
        new_dp.platescale = mp.platescale * metric_orig[0]/metric_val
        new_dp.array_size = np.array([metric_val, metric_val])
        with open(iop.device_params, 'wb') as handle:
            pickle.dump(new_dp, handle, protocol=pickle.HIGHEST_PROTOCOL)


if __name__ == '__main__':
    master.check_contrast_contriubtions(metric_vals, metric_name)
