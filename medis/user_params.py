"""
Example user_params. If you want to change any of the defaults parameters, without changing them for everyone, do
that here. Your version of this file should not get pushed to the repo (hopefully)
"""
from pathlib import Path
import os

def update(conf_obj_list):
    print('calling user_params update')
    ap, cp, tp, mp, hp, sp, iop, dp, fp = conf_obj_list
    # datadir = '/home/captainkay/mazinlab/MKIDSim/CDIsim_data/'  # personal datadir instead
    iop.datadir = os.path.join(str(Path.home()), 'dummy1')#'medis_data')
    iop.update()

    return ap, cp, tp, mp, hp, sp, iop, dp, fp
