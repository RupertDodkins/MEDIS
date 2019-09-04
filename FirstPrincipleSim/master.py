''' Make the master fields.h5 and device_params.pkl '''

import os
import matplotlib as mpl
import numpy as np
mpl.use("Qt5Agg")
import matplotlib.pyplot as plt
from matplotlib.colors import LogNorm
import pickle as pickle
from vip_hci import phot, pca
from statsmodels.tsa.stattools import acf
from medis.params import tp, mp, cp, sp, ap, iop
import medis.get_photon_data as gpd
from medis.Utils.plot_tools import quicklook_im, indep_images, view_datacube
from medis.Utils.misc import dprint
import medis.Detector.readout as read
from medis.Detector import mkid_artefacts as MKIDs
from medis.Detector import pipeline as pipe
from medis.Analysis.phot import get_unoccult_psf, eval_method

iop.update(new_name='FirstPrincipleSim/master/')
iop.atmosdata = '190801'
iop.atmosdir = os.path.join(iop.datadir, iop.atmosroot, iop.atmosdata)  # full path to FITS files
iop.aberdir = os.path.join(iop.datadir, iop.aberroot, 'Palomar256')
iop.quasi = os.path.join(iop.aberdir, 'quasi')
iop.atmosdata = '190823'
iop.atmosdir = os.path.join(iop.datadir, iop.atmosroot, iop.atmosdata)  # full path to FITS files
iop.atmosconfig = os.path.join(iop.atmosdir, cp.model, 'config.txt')

iop.fields = iop.testdir + 'fields_master.h5'
iop.form_photons = os.path.join(iop.testdir, 'formatted_photons_master.pkl')
iop.device_params = os.path.join(iop.testdir, 'deviceParams_master.pkl')  # detector metadata

ap.sample_time = 0.05
ap.numframes = 10

def make_fields_master(monitor=False):
    """ The master fields file of which all the photons are seeded from according to their device_params

    :return:
    """

    sp.show_wframe = False
    sp.save_obs = False
    sp.show_cube = False
    sp.num_processes = 1
    sp.get_ints = False

    ap.companion = True
    ap.star_photons_per_s = int(1e5)
    ap.contrast = [10 ** -3.5, 10 ** -3.5, 10 ** -4.5, 10 ** -4]
    ap.lods = [[6, 0.0], [3, 0.0], [-6, 0], [-3, 0]]
    ap.grid_size = 256
    ap.nwsamp = 8
    ap.w_bins = 16  # 8

    tp.save_locs = np.empty((0, 1))
    tp.diam = 8.
    tp.beam_ratio = 0.5
    tp.obscure = True
    tp.use_ao = True
    tp.include_tiptilt = False
    tp.ao_act = 50
    tp.platescale = 10  # mas
    tp.detector = 'ideal'
    tp.use_atmos = True
    tp.use_zern_ab = False
    tp.occulter_type = 'Vortex'  # "None (Lyot Stop)"
    tp.aber_params = {'CPA': True,
                      'NCPA': True,
                      'QuasiStatic': False,  # or Static
                      'Phase': True,
                      'Amp': False,
                      'n_surfs': 4,
                      'OOPP': False}  # [16,8,4,16]}#False}#
    tp.aber_vals = {'a': [5e-18, 1e-19],  # 'a': [5e-17, 1e-18],
                    'b': [2.0, 0.2],
                    'c': [3.1, 0.5],
                    'a_amp': [0.05, 0.01]}
    tp.piston_error = False
    ap.band = np.array([800, 1500])
    tp.rot_rate = 0  # deg/s
    tp.pix_shift = [[0, 0]]

    if monitor:
        sp.save_locs = np.array(['add_atmos','deformable_mirror', 'prop_mid_optics', 'coronagraph'])
        sp.gui_map_type = np.array(['phase',  'phase', 'amp', 'amp'])
        from medis.Dashboard.run_dashboard import run_dashboard

        if __name__ == '__main__':
            run_dashboard()
        return None

    else:
        if __name__ == '__main__':
            fields = gpd.run_medis()
            tess = np.abs(np.sum(fields[:, -1, :, :], axis=2)) ** 2
            view_datacube(tess[0], logAmp=True, show=False)
            view_datacube(tess[:,0], logAmp=True, show=True)

    return fields

def make_dp_master(fields, comps=True):
    """

    :param comps:
    :return:
    """
    mp.phase_uncertainty = True
    mp.phase_background = False
    mp.QE_var = True
    mp.bad_pix = True
    mp.hot_pix = None
    mp.hot_bright = 1e3
    mp.R_mean = 8
    mp.g_mean = 0.2
    mp.g_sig = 0.04
    mp.bg_mean = -10
    mp.bg_sig = 40
    mp.pix_yield = 0.9  # 0.7 # check dis
    mp.bad_pix = True
    mp.array_size = np.array([146, 146])

    dprint(iop.form_photons)

    MKIDs.initialize()

    # if os.path.exists(iop.form_photons):
    #     dprint(f'Formatted photon data already exists at {iop.form_photons}')
    #     with open(iop.form_photons, 'rb') as handle:
    #         photons, stackcube = pickle.load(handle)
    #
    # else:
    #     photons, stackcube = get_form_photons(fields, comps=comps)
    #
    # view_datacube(stackcube[0], logAmp=True, show=False)
    # view_datacube(stackcube[:, 0], logAmp=True, show=True)
    # return


if __name__ == '__main__':
    fields = make_fields_master()
    make_dp_master(fields)

