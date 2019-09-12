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
from medis.Detector.mkid_artefacts import get_R_hyper
import master

metric_name = __file__.split('/')[-1].split('.')[0]
metric_vals = [2,4,10,20]

master.set_field_params()
master.set_mkid_params()

iop.set_testdir(f'FirstPrincipleSim/{metric_name}')
iop.set_atmosdata('190823')
iop.set_aberdata('Palomar256')

print(ap.numframes)

comps = True

def adapt_dp_master():
    if not os.path.exists(iop.testdir):
        os.mkdir(iop.testdir)
    with open(master.dp, 'rb') as handle:
        dp = pickle.load(handle)
    metric_orig = getattr(mp,metric_name)#0.04
    iop.device_params = iop.device_params[:-4] + '_'+metric_name
    new_dp = copy.copy(dp)
    quicklook_im(dp.Rs)
    for metric_val in metric_vals:
        dprint((np.std(dp.Rs)))
        new_dp.Rs = dp.Rs - metric_orig + metric_val
        new_dp.Rs[new_dp.Rs < 0] = 0
        new_dp.Rs[dp.Rs == 0] = 0
        new_dp.sigs = get_R_hyper(new_dp.Rs)
        # new_dp.QE_map = dp.QE_map * metric_val / QE_mean_orig
        dprint(np.std(new_dp.Rs))
        iop.device_params = iop.device_params.split('_'+metric_name)[0] + f'_{metric_name}={metric_val}.pkl'
        dprint((iop.device_params, metric_val))
        quicklook_im(new_dp.Rs)
        quicklook_im(new_dp.sigs[:,:,0])
        plt.hist(new_dp.Rs.flatten())
        plt.show(block=True)
        with open(iop.device_params, 'wb') as handle:
            pickle.dump(new_dp, handle, protocol=pickle.HIGHEST_PROTOCOL)

if __name__ == '__main__':
    if not os.path.exists(f'{iop.device_params[:-4]}_{metric_name}={metric_vals[0]}.pkl'):
        adapt_dp_master()
    stackcubes, dps = master.get_stackcubes(metric_vals, metric_name, comps=comps)
    # plt.show(block=True)
    master.eval_performance(stackcubes, dps, metric_vals, comps=comps)