"""
Example user_params. If you want to change any of the defaults parameters, without changing them for everyone, do
that here. Your version of this file should not get pushed to the repo (hopefully)
"""

def update(conf_obj_list):
    ap, cp, tp, mp, hp, sp, iop, dp, fp = conf_obj_list
    iop.datadir = '/home/captainkay/mazinlab/MKIDSim/CDIsim_data/'  # personal datadir instead
    iop.rootdir = '/home/captainkay/mazinlab/MKIDSim/'

    return ap, cp, tp, mp, hp, sp, iop, dp, fp


