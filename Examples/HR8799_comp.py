'''This code handles the relevant functionality of a Hawaii 2RG camera'''
import sys
sys.path.append('D:/dodkins/MEDIS/MEDIS')
import numpy as np
import copy
import matplotlib.pyplot as plt
from vip_hci import phot, pca
from medis.params import ap, cp, tp, sp, mp, iop
from medis.Utils.plot_tools import loop_frames, quicklook_im,view_datacube, compare_images, indep_images, grid
from medis.Utils.rawImageIO import clipped_zoom
import medis.Detector.readout as read
import medis.Analysis.phot
import medis.Analysis.stats
import pandas as pd
from medis.Utils.misc import dprint
import cPickle as pickle

# Global params
sp.save_obs = False
sp.show_cube = False
sp.save_obs = False
sp.show_wframe = False
# ap.star_photons = 1e10#0.5e6# 1e9
ap.star_photons = 1e8#1e10#0.5e6# 1e9

# tp.beam_ratio = 0.6
tp.beam_ratio = 0.32
tp.servo_error= [0,1]#[0,1]#False # No delay and rate of 1/frame_time
tp.quick_ao=True
# tp.diam=8.
tp.use_spiders = True
tp.use_ao = True
# ap.star_photons*=1000
tp.diam = 8.0  # telescope diameter in meters
# tp.ao_act = 44
tp.ao_act = 44#50
tp.grid_size=256
mp.array_size = np.array([257,257])#
# mp.array_size = np.array([140,144])#

mp.total_pix = mp.array_size[0] * mp.array_size[1]
mp.xnum = mp.array_size[0]
mp.ynum = mp.array_size[1]

# mp.R_mean = 8
# mp.g_mean = 0.9
# mp.g_sig = 0.05
# mp.bg_mean = -10
# mp.bg_sig = 40
# mp.pix_yield = 0.8

mp.R_mean = 30
mp.g_mean = 0.95
mp.g_sig = 0.01
mp.bg_mean = -5
mp.bg_sig = 10
mp.pix_yield = 0.95

# mp.hot_pix =True
mp.distort_phase =True
mp.phase_uncertainty =True
mp.phase_background=True
mp.respons_var = True
mp.bad_pix = True
mp.hot_pix = None



# tp.NCPA_type = None#'Static'
# tp.CPA_type = None#'Static'
# tp.NCPA_type = 'Static'
# tp.CPA_type = 'Static'
# tp.aber_params['OOPP'] = [8,4]
# tp.aber_vals['a'] = [8.0e-13, 4.0e-13]
# tp.aber_vals['a'] = [1.2e-13, 3e-14]
# tp.aber_vals['a'] = [7.2e-14, 3e-14]
tp.aber_vals['c'] = [3.0, 0.5]
ap.C_spec = 1.5
tp.aber_params = {'CPA': True,
                    'NCPA': True,
                    'QuasiStatic': False,  # or Static
                    'Phase': True,
                    'Amp': False,
                    'n_surfs': 5,
                    'OOPP': [16,8,8,16,8]}#False}#
# tp.aber_params['CPA'] = False
# tp.aber_params['NCPA'] = False
mp.date = '180830/'
import os
iop.update(mp.date)
iop.aberdir = os.path.join(tp.rootdir, 'data/aberrations/180919e/')
# iop.aberdir = os.path.join(tp.rootdir, 'data/aberrations/180919b/')
# iop.aberdir = os.path.join(iop.rootdir, 'data/aberrations/180630_30mins')
# cp.date = '1804171hr8m/'
cp.date = '180829/180828/'
iop.atmosdir= os.path.join(cp.rootdir,cp.data,cp.date)
sp.num_processes = 45
tp.occulter_type = 'Vortex'#'8th_Order'#
num_exp = 45#100#2000#1000#50#50#1000
ap.exposure_time = 1#0.1#05  # 0.001
cp.frame_time = 1#0.1#05
ap.numframes = int(num_exp * ap.exposure_time / cp.frame_time)
# ap.startframe=ap.numframes
ap.companion = True
# ap.contrast = [1e-4,1e-3,1e-5, 1e-6,1e-6,1e-7]  # [0.1,0.1]
# ap.lods = [[-1.5,1.5],[1,1],[-2.5,2.5],[-3,3],[3,3],[4.5,-4]]
# ap.contrast = [1e-5, 1e-6]  # [0.1,0.1]
# ap.lods = [[-2.5, 2.5], [-4.5, 4.5]]
# ap.contrast = [10**-4.5,10**-4.5,10**-4.5,1*10**-5,1e-5]  # [0.1,0.1]
ap.contrast = [10**-5.515,10**-5.2,10**-5.0,10**-6]  # [0.1,0.1]
ap.lods = [[-3.6,3.0],[-3.52,5.76],[-6,-6],[1.6,1.6]]#[6,-4.5],
tp.detector = 'MKIDs'#'ideal'#
# tp.platescale=10.
tp.platescale=5.
tp.piston_error = True
# tp.band = np.array([700, 1500])
# tp.nwsamp = 3#7#10#5#5#5#1.#
# tp.w_bins = 8#7#10#5#5#5#1.#
# tp.band = np.array([700, 1800])
tp.band = np.array([700, 1800])
tp.nwsamp = 4#5#3#7#10#5#5#5#1.#
tp.w_bins = 12#8#7#10#5#5#5#1.#
# tp.nwsamp = 1
# tp.w_bins = 1

tp.rot_rate = 0  # deg/s
theta=45
lod = 8.
# iop.aberdir = 'D:/dodkins/MEDIS/data/aberrations/180902/'
# iop.aberdir = 'D:/dodkins/MEDIS/data/aberrations/180420/'
dprint(iop.aberdir)
def eval_method(cube, algo, angle_list, algo_dict, psf_template, snr=10):
    dprint((cube.shape, len(angle_list), tp.platescale/1000, psf_template.shape))
    # wsamples = np.linspace(tp.band[0], tp.band[1], tp.w_bins)
    # scale_list = tp.band[0]/wsamples
    # scale_list = 1./scale_list[::-1]
    # dprint(scale_list)
    # fwhms = np.round(lod*scale_list)
    # dprint((fwhms, type(fwhms)))
    dprint('lol')
    fulloutput = phot.contrcurve.contrast_curve(cube=cube,
                                   angle_list=angle_list, psf_template=psf_template,
                                   fwhm=lod, pxscale=tp.platescale/1000,
                                   starphot=star_phot, algo=algo,# wedge=(60,30),
                                    nbranch=1, verbose=True,
                                   debug=False, plot=False, theta=theta,full_output=True,fc_snr=snr, **algo_dict)
    plt.show()
    metrics = [fulloutput[0]['throughput'], fulloutput[0]['noise'], fulloutput[0]['sensitivity (Student)'], fulloutput[0]['distance']]
    metrics = np.array(metrics)
    return metrics, fulloutput[3]


def eff_int(simple_hypercube_1, psf_template):
    dprint('effint')
    algo_dict = {'full_target_cube': simple_hypercube_1}
    angle_list = np.zeros((len(simple_hypercube_1)))
    method_out = eval_method(simple_hypercube_1[:,0], Analysis.stats.effint_4_VIP,angle_list, algo_dict, psf_template=psf_template)
    return method_out

def RDI(simple_hypercube_1, simple_hypercube_2, psf_template):
    dprint('RDI')
    algo_dict = {'cube_ref': simple_hypercube_2[:,0]}
    angle_list = np.zeros((len(simple_hypercube_1)))
    method_out = eval_method(simple_hypercube_1[:,0], Analysis.stats.RDI_4_VIP,angle_list, algo_dict, psf_template=psf_template)
    return method_out

def SDI(simple_hypercube_1, psf_template):
    dprint('SDI')
    wsamples = np.linspace(tp.band[0], tp.band[1], tp.w_bins)
    scale_list = tp.band[0]/wsamples
    algo_dict = {'full_target_cube': simple_hypercube_1, 'scale_list':scale_list, 'thru':True}
    simple_hypercube_1 = np.transpose(simple_hypercube_1, (1, 0, 2, 3))
    angle_list = np.zeros((simple_hypercube_1.shape[1]))

    psf_template = np.resize(psf_template, (tp.w_bins, psf_template.shape[0],psf_template.shape[1]))
    method_out = eval_method(simple_hypercube_1, Analysis.stats.SDI_4_VIP, angle_list, algo_dict, psf_template=psf_template)
    return method_out

def RDI_SDI(simple_hypercube_1, simple_hypercube_2, psf_template):
    dprint('RDI_SDI')
    wsamples = np.linspace(tp.band[0], tp.band[1], tp.w_bins)
    scale_list = tp.band[0]/wsamples
    simple_hypercube_1 = np.transpose(simple_hypercube_1, (1, 0, 2, 3))
    simple_hypercube_2 = np.transpose(simple_hypercube_2, (1, 0, 2, 3))
    psf_template = np.resize(psf_template, (tp.w_bins, psf_template.shape[0],psf_template.shape[1]))
    algo_dict = {'thresh': 0,'full_target_cube': simple_hypercube_1, 'cube_ref': simple_hypercube_2, 'thru':True, 'scale_list':scale_list}
    angle_list = np.zeros((simple_hypercube_1.shape[1]))
    # method_out = eval_method(simple_hypercube_1[:], Analysis.stats.RDI_SDI_4_VIP, angle_list, algo_dict, psf_template=psf_template)
    dprint((simple_hypercube_1.shape[1],angle_list.shape[0]))
    method_out = eval_method(simple_hypercube_1[:], Analysis.stats.SDI_RDI_4_VIP, angle_list, algo_dict, psf_template=psf_template)
    return method_out

def RDI_SDI_DSI(simple_hypercube_1, simple_hypercube_2, psf_template):
    dprint('RDI_SDI_DSI')
    wsamples = np.linspace(tp.band[0], tp.band[1], tp.w_bins)
    scale_list = tp.band[0]/wsamples
    simple_hypercube_1 = np.transpose(simple_hypercube_1, (1, 0, 2, 3))
    simple_hypercube_2 = np.transpose(simple_hypercube_2, (1, 0, 2, 3))
    psf_template = np.resize(psf_template, (tp.w_bins, psf_template.shape[0],psf_template.shape[1]))
    algo_dict = {'thresh': 0,'full_target_cube': simple_hypercube_1, 'cube_ref': simple_hypercube_2, 'thru':True, 'scale_list':scale_list}
    angle_list = np.zeros((simple_hypercube_1.shape[1]))
    method_out = eval_method(simple_hypercube_1[:], Analysis.stats.SDI_RDI_DSI_4_VIP, angle_list, algo_dict, psf_template=psf_template)
    return method_out

def RDI_DSI(simple_hypercube_1, simple_hypercube_2, psf_template):
    dprint('RDI_DSI')
    # wsamples = np.linspace(tp.band[0], tp.band[1], tp.w_bins)
    # scale_list = tp.band[0] / wsamples
    # simple_hypercube_1 = np.transpose(simple_hypercube_1, (1, 0, 2, 3))
    # simple_hypercube_2 = np.transpose(simple_hypercube_2, (1, 0, 2, 3))
    # psf_template = np.resize(psf_template, (tp.w_bins, psf_template.shape[0], psf_template.shape[1]))
    algo_dict = {'thresh': 0, 'cube_ref': simple_hypercube_2[:,0]}
    # angle_list = np.zeros((simple_hypercube_1.shape[1]))
    angle_list = np.zeros((len(simple_hypercube_1)))
    method_out = eval_method(simple_hypercube_1[:,0], Analysis.stats.RDI_DSI_4_VIP, angle_list, algo_dict,
                             psf_template=psf_template, snr=10)
    return method_out

def RDI_DSI_BB(simple_hypercube_1, simple_hypercube_2, psf_template):
    dprint('RDI_DSI_BB')
    wsamples = np.linspace(tp.band[0], tp.band[1], tp.w_bins)
    scale_list = tp.band[0] / wsamples
    simple_hypercube_1 = np.transpose(simple_hypercube_1, (1, 0, 2, 3))
    simple_hypercube_2 = np.transpose(simple_hypercube_2, (1, 0, 2, 3))
    psf_template = np.resize(psf_template, (tp.w_bins, psf_template.shape[0], psf_template.shape[1]))
    algo_dict = {'thresh': 0, 'full_target_cube': simple_hypercube_1, 'cube_ref': simple_hypercube_2, 'thru': True,
                 'scale_list': scale_list}
    angle_list = np.zeros((simple_hypercube_1.shape[1]))
    dprint((psf_template.shape,simple_hypercube_1.shape))
    method_out = eval_method(simple_hypercube_1[:], Analysis.stats.RDI_DSI_BB_4_VIP, angle_list, algo_dict,
                             psf_template=psf_template)
    return method_out


def RDI_DSI_SDI(simple_hypercube_1, simple_hypercube_2, psf_template):
    dprint('RDI_DSI_SDI')
    wsamples = np.linspace(tp.band[0], tp.band[1], tp.w_bins)
    scale_list = tp.band[0] / wsamples
    simple_hypercube_1 = np.transpose(simple_hypercube_1, (1, 0, 2, 3))
    simple_hypercube_2 = np.transpose(simple_hypercube_2, (1, 0, 2, 3))
    psf_template = np.resize(psf_template, (tp.w_bins, psf_template.shape[0], psf_template.shape[1]))
    algo_dict = {'thresh': 0, 'full_target_cube': simple_hypercube_1, 'cube_ref': simple_hypercube_2, 'thru': True,
                 'scale_list': scale_list}
    angle_list = np.zeros((simple_hypercube_1.shape[1]))
    method_out = eval_method(simple_hypercube_1[:], Analysis.stats.RDI_DSI_SDI_4_VIP, angle_list, algo_dict,
                             psf_template=psf_template)
    return method_out

def quick_processing(simple_hypercube_1, simple_hypercube_2, plot=True):
    diff_cube = simple_hypercube_1 - np.mean(simple_hypercube_2, axis=0)
    # diff_cube = simple_hypercube_1 - simple_hypercube_2
    # dprint(diff_cube.shape)
    # loop_frames(simple_hypercube_1[0,:])
    # loop_frames(simple_hypercube_1[:,0])
    # loop_frames(np.median(simple_hypercube_2, axis=0))
    # loop_frames(diff_cube[0,:])
    # loop_frames(diff_cube[::20,0])
    # quicklook_im(diff_cube[:,0,:,0])
    # plt.plot(np.sum(np.abs(diff_cube[:,0,:,0]),axis=0))
    # if plot:
    #     quicklook_im(np.mean(simple_hypercube_1[:,-2], axis=0))
    #     quicklook_im(np.mean(simple_hypercube_2[:,-2], axis=0))
    #     quicklook_im(np.mean(diff_cube[:,-2], axis=0))

    # Lmaps = np.zeros((diff_cube.shape[1], diff_cube.shape[2], diff_cube.shape[3]))
    # rmaps = np.zeros_like(Lmaps)
    # for iw in range(diff_cube.shape[1]):
    #     dprint((diff_cube.shape, iw))
    #     LCcube = np.transpose(diff_cube[:, iw:iw + 1], (2, 3, 0, 1))
    #     # rmaps[iw] = Analysis.stats.get_skew(LCcube)#, xinspect = range(233,236), yinspect = range(233,236), inspect = True)#, xinspect = range(40,50), yinspect = range(40,50), inspect = True)
    #     # quicklook_im(rmaps[iw], logAmp=True)
    #     Lmaps[iw] = Analysis.stats.get_Dmap(LCcube, binning=10, plot=False, threshold=0.01)
    # if plot:
    #     loop_frames(rmaps)
    #     loop_frames(Lmaps)
    # SDI = Analysis.phot.do_SDI(np.mean(diff_cube, axis=0))
    # quicklook_im(SDI)

    # LCcube = np.transpose(diff_cube[:,:1], (2, 3, 0, 1))
    # timecube = np.zeros((diff_cube.shape[2], diff_cube.shape[3],diff_cube.shape[0]/50))
    # intervals = np.arange(0,diff_cube.shape[0],50)
    # for it in range(len(intervals)-1):
    #     print intervals[it], intervals[it + 1], np.sum(np.median(diff_cube[intervals[it]:intervals[it+1]], axis=0))
    #     # loop_frames(np.median(diff_cube[intervals[it]:intervals[it+1]], axis=0))
    #     # quicklook_im(diff_cube[0,0])
    #     # loop_frames(np.median(diff_cube[intervals[it]:intervals[it+1]], axis=0))
    #     # quicklook_im(Analysis.phot.do_SDI(np.median(diff_cube[intervals[it]:intervals[it+1]], axis=0)))
    #     timecube[:,:,it] = Analysis.phot.do_SDI(np.mean(diff_cube[intervals[it]:intervals[it+1]], axis=0))
    #
    # # quicklook_im(timecube[:,:,0])
    # # plt.plot(np.sum(np.abs(timecube[:,:,0]),axis=0))
    # # loop_frames(np.transpose(timecube))
    # rmap = Analysis.stats.get_skew(timecube)#, inspect=True, xinspect=range(99,104), yinspect=range(99,104))
    # quicklook_im(rmap, logAmp=True)
    # LCcube = np.transpose(np.resize(np.mean(diff_cube, axis=1), (diff_cube.shape[0],1,diff_cube.shape[2],diff_cube.shape[3])), (2, 3, 0, 1))
    LCcube = np.transpose(np.resize(diff_cube[:,0], (diff_cube.shape[0],1,diff_cube.shape[2],diff_cube.shape[3])), (2, 3, 0, 1))
    # dprint(LCcube.shape)
    Lmap = Analysis.stats.get_Dmap(LCcube, binning=5, plot=False)
    # Lmap = Analysis.stats.get_Dmap(timecube, binning=10, plot=True)
    # quicklook_im(Lmap)
    LCcube = np.transpose(diff_cube, (2, 3, 0, 1))
    # LCcube = np.resize(timecube, (timecube.shape[0],timecube.shape[1],timecube.shape[2],1))
    # # BBmap = Analysis.stats.get_LmapBB(LCcube, binning=5, plot=False)
    BBmap = Analysis.stats.get_Dmap(LCcube, binning=5, plot=False)
    # quicklook_im(BBmap)
    # return [np.mean(simple_hypercube_1[:,0], axis=0),
    #         np.median(diff_cube[:,0], axis=0),
    #         np.median(np.transpose(timecube), axis=0),#SDI,
    #         rmap,
    #         # Lmap,
    #         BBmap,
    #         -rmap*BBmap
    #         ]
    return [np.mean(simple_hypercube_1[:,0], axis=0),
            np.mean(diff_cube[:,0], axis=0),
            Lmap,
            BBmap]

            # np.median(np.transpose(timecube), axis=0),#SDI,
            # rmap,
            # # Lmap,
            # BBmap,
            # -rmap*BBmap
            # ]
no_sauce=True
plotdata, maps = [], []
if __name__ == '__main__':
    if no_sauce:
        fname = 'eval_meth_out_comp_redout2.pkl'
        if os.path.isfile(fname):
            with open(fname, 'rb') as handle:
                plotdata, maps = pickle.load(handle)
        else:
            orig_device_params = iop.device_params
            for pix_yield in np.arange(1,10)*0.1:#[0.4,0.9,1]:
                for R in [30]:#[10,30,50]:
                    mp.R_mean = R
                    mp.pix_yield = pix_yield
                    iop.device_params = orig_device_params[:-4]+'py%.2fR%i.pkl' % (pix_yield, R)
                    dprint(iop.device_params)
                    dprint(iop.aberdir)
                    rad_samp = np.linspace(0,tp.platescale/1000.*128,50)
                    print rad_samp

                    # if no_sauce:

                    # # tp.use_spiders = False
                    # ap.companion = True
                    ap.companion = False
                    # ap.contrast = [10 ** -6.0]  # [0.1,0.1]
                    # ap.lods = [[-6, -6]]  # [6,-4.5],
                    # iop.obs_seq = iop.datadir + 'HR8799_SPHERE%i_one_sauce_tar%i.pkl' % (num_exp, np.log10(ap.star_photons))# 5
                    iop.obs_seq = iop.datadir + 'HR8799_SPHERE_w%i_%inosauce_tar_%ipy%.2fR%i.pkl' % (tp.w_bins, num_exp, np.log10(ap.star_photons), pix_yield, R)
                    simple_hypercube_1 = read.get_integ_hypercube(plot=False)[:, :]  # /ap.numframes
                    ap.startframe = ap.numframes + 45#20
                    ap.companion = False
                    iop.obs_seq = iop.datadir + 'HR8799_SPHERE_w%i_%inosauce_ref_%ipy%.2fR%i.pkl' % (tp.w_bins, num_exp, np.log10(ap.star_photons), pix_yield, R)
                    # iop.obs_seq = iop.datadir + 'HR8799_SPHERE%i_one_sauce_ref%i.pkl' % (num_exp, np.log10(ap.star_photons))
                    simple_hypercube_2 = read.get_integ_hypercube(plot=False)[:, :]  # /ap.numframes


                        # time_cube = time_cube[:,57:201,59:199]
                    # else:
                    # Get unocculted PSF for intensity
                    # ap.star_photons = 1e8
                    lod = 10
                    # psf_template = Analysis.phot.get_unoccult_psf(obs_seq='/RefPSF_wLyotStop.py%.2fR%i.pkl' % ( pix_yield, R), plot=True, numframes=1)
                    psf_template = Analysis.phot.get_unoccult_psf(obs_seq='/RefPSF_wLyotStop.pkl', plot=False, numframes=1)
                    # quicklook_im(psf_template)
                    # psf_template = np.resize(psf_template, (tp.nwsamp, psf_template.shape[0],psf_template.shape[1]))
                    # star_phot = np.sum(psf_template)
                    # star_phot = phot.contrcurve.aperture_flux(psf_template,[tp.grid_size/2],[tp.grid_size/2],lod,1)[0]*1000#/ap.numframes
                    star_phot = np.max(psf_template) *1e5#/ 1e5  # 1000  # /ap.numframes

                    dprint(star_phot)
                    dprint(psf_template.shape)
                    star_phot = Analysis.phot.aper_phot(psf_template,0,20)
                    if psf_template.shape[1] % 2 == 0:
                        psf_template = psf_template[-1, :-1]
                    # psf_template = psf_template#*1e8
                    dprint(star_phot)
                    # print psf_template.shape
                    # # quicklook_im(psf_template)
                    # #
                    # # # iop.obs_seq = iop.datadir + 'IntHyperUnOccult2.pkl'  # 5
                    # # # psf_hyper = read.get_integ_hypercube(plot=False)#/ap.numframes
                    # # # # loop_frames(psf_hyper[::10,0], logAmp=True)
                    #
                    # # iop.obs_seq = iop.datadir + 'HR8799_MKIDs5_nosource.pkl'  # 5
                    # # iop.obs_seq = iop.datadir + 'HR8799_MKIDs5.pkl'  # 5
                    # # iop.obs_seq = iop.datadir + 'HR8799_MKIDs150sstar_realPs3w_.pkl'  # 5
                    # # iop.obs_seq = iop.datadir + 'HR8799_MEC5000star_nocomp.pkl'  # 5
                    # # iop.obs_seq = iop.datadir + 'HR8799_MEC100star.pkl'  # 5

                    # # iop.obs_seq = iop.datadir + 'HR8799_SPHERE%i_tar_close_f3_easy_coron_easyAO%i.pkl' % (num_exp, ap.star_photons) # 5
                    # ap.companion=False
                    # iop.obs_seq = iop.datadir + 'HR8799_SPHERE%i_3nosauce_close_f_easy_coron_easyAO%i.pkl' % (num_exp, ap.star_photons) # 5
                    # # ap.contrast = [10 ** -5.5]  # [0.1,0.1]
                    # # ap.lods = [[-6, -6]]  # [6,-4.5],
                    # # iop.obs_seq = iop.datadir + 'HR8799_SPHERE%i_one_sauce%i.pkl' % (num_exp, ap.star_photons) # 5
                    # # # iop.obs_seq = iop.datadir + 'noWnoRollHyperWcomp1000cont_Aug_1stMKIDs2.pkl'#5
                    # # # simple_hypercube_1 = read.get_integ_hypercube(plot=False)[:,:,57:201,59:199]#/ap.numframes
                    # simple_hypercube_1 = read.get_integ_hypercube(plot=False)[:,:]#/ap.numframes
                    # ap.startframe = ap.numframes #+3010
                    # ap.companion =False
                    # # # iop.obs_seq = iop.datadir + 'HR8799_2_MKIDs150sref_realPs3w_.pkl'  # 5
                    # # # iop.obs_seq = iop.datadir + 'HR8799_MEC5000ref.pkl'  # 5
                    # # # iop.obs_seq = iop.datadir + 'HR8799_MEC100ref.pkl'  # 5
                    # iop.obs_seq = iop.datadir + 'HR8799_SPHERE%i_ref_close_f3_easy_coron_easyAO%i.pkl' % (num_exp, ap.star_photons) # 5
                    # # # iop.obs_seq = iop.datadir + 'HR8799_2_MKIDs5.pkl'  # 5
                    # # # # iop.obs_seq = iop.datadir + 'noWnoRollHyperWcomp1000cont_Aug_2ndMKIDs2.pkl'#5
                    # # # simple_hypercube_2 = read.get_integ_hypercube(plot=False)[:,:,57:201,59:199]#/ap.numframes




                    # quick_processing(simple_hypercube_1, simple_hypercube_2, plot=True)

                    # method_out = eff_int(simple_hypercube_1, psf_template)
                    # plotdata.append(method_out[0])
                    # maps.append(method_out[1])
                    #
                    # # method_out = SDI(simple_hypercube_1, psf_template)
                    # # plotdata.append(method_out[0])
                    # # maps.append(method_out[1])
                    #
                    # method_out = RDI(simple_hypercube_1, simple_hypercube_2, psf_template)
                    # plotdata.append(method_out[0])
                    # maps.append(method_out[1])

                    # # method_out = RDI_SDI(simple_hypercube_1, simple_hypercube_2, psf_template)
                    # # plotdata.append(method_out[0])
                    # # maps.append(method_out[1])
                    #
                    method_out = RDI_DSI(simple_hypercube_1, simple_hypercube_2, psf_template)
                    plotdata.append(method_out[0])
                    maps.append(method_out[1])
                    #
                    # # method_out = RDI_SDI_DSI(simple_hypercube_1, simple_hypercube_2, psf_template)
                    # # plotdata.append(method_out[0])
                    # # maps.append(method_out[1])
                    #
                    # method_out = RDI_DSI_BB(simple_hypercube_1, simple_hypercube_2, psf_template)
                    # plotdata.append(method_out[0])
                    # maps.append(method_out[1])
                    #
                    # with open(fname, 'wb') as handle:
                    #     pickle.dump((plotdata,maps), handle, protocol=pickle.HIGHEST_PROTOCOL)




            with open(fname, 'wb') as handle:
                pickle.dump((plotdata,maps), handle, protocol=pickle.HIGHEST_PROTOCOL)

        # Plotting
        dprint(np.shape(plotdata))
        plotdata = np.array(plotdata)
        # rad_samp = np.linspace(0,tp.platescale/1000.*mp.array_size[0]/2,plotdata.shape[2])
        rad_samp = plotdata[:,3][0]
        rad_samp = rad_samp*0.006 * 1000
        fig, axes = plt.subplots(nrows=1, ncols=3, figsize=(14, 3.4))

        for thruput in plotdata[:,0]:
            axes[0].plot(rad_samp,thruput)
        for noise in plotdata[:,1]:
            axes[1].plot(rad_samp,noise)
        for cont in plotdata[:,2]:
            axes[2].plot(rad_samp,cont/1e5)
            # for ic, c in enumerate(ap.contrast):
            #     axes[2].axvline(0, ymin=c, ymax=c+c*1.5)
        for ax in axes:
            ax.set_yscale('log')
            ax.set_xlabel('Radial Separation (mas)')
            ax.tick_params(direction='in',which='both', right=True, top=True)
        axes[0].set_ylabel('Throughput')
        axes[1].set_ylabel('Noise')
        axes[2].set_ylabel('5$\sigma$ Contrast')
        axes[2].legend(['Exp.', 'RDI', 'RDI DSI', 'RDI BB-DSI'], loc=1)

        # indep_images(maps, logAmp=True, vmins = [0.1,0.1,5e-3,5e-3], vmaxs = [100,100,0.05,0.05],
        #              annos=['Exp.', 'RDI', 'RDI DSI', 'RDI DSI SDI'],
        #              titles=[r'  $I / I^{*}$', r'  $I / I^{*}$', r'  $I_L / I^{*}$', r'  $I_L / I^{*}$'])


        compare_images(maps, logAmp=True, vmin = 0.001, vmax= 0.1,#vmins = [0.1,0.1,0.1,0.1], vmaxs = [100,100,0.5,0.5],
                       )#annos=['Exp.', 'RDI', 'RDI DSI', 'RDI BB-DSI'])#,
                     # titles=[r'  $I / I^{*}$', r'  $I / I^{*}$', r'  $I_L / I^{*}$', r'  $I_L / I^{*}$'])
        # quicklook_im(maps[0], logAmp=True, vmin = 0.01, vmax = 1)
        plt.show()

    else:
        for pix_yield in [0.4, 0.9, 1]:
            for R in [10, 30, 50]:
                mp.R_mean = R
                mp.pix_yield = pix_yield
                iop.device_params = iop.device_params[:-4] + 'py%.2fR%i.pkl' % (pix_yield, R)

                ap.companion = True
                iop.obs_seq = iop.datadir + 'HR8799_SPHERE%isauce_tar_%ipy%.2fR%i.pkl' % (num_exp, np.log10(ap.star_photons), pix_yield, R)
                dprint(iop.aberdir)
                simple_hypercube_1 = read.get_integ_hypercube(plot=False)[:, :]  # /ap.numframes
                ap.startframe = ap.numframes + 20
                ap.companion = False
                iop.obs_seq = iop.datadir + 'HR8799_SPHERE%isauce_ref_%ipy%.2fR%i.pkl' % (num_exp, np.log10(ap.star_photons), pix_yield, R)
                simple_hypercube_2 = read.get_integ_hypercube(plot=False)[:, :]  # /ap.numframes

                maps = quick_processing(simple_hypercube_1, simple_hypercube_2, plot=True)

                # compare_images(maps, logAmp=True, vmin = 0.01, vmax= 100,#vmins = [0.1,0.1,0.1,0.1], vmaxs = [100,100,0.5,0.5],
                #              annos=['Exp.', 'RDI', 'RDI DSI', 'RDI BB-DSI'])#'RDI SSD',
                #              #titles=[r'  $I / I^{*}$', r'  $I / I^{*}$', r'  $I_L / I^{*}$', r'  $I_L / I^{*}$'])
                # grid(maps, nrows =2, width=3, logAmp=True, vmins = [0.01,0.01,0.01,-4, 0.1,0.1], vmaxs=[100,100,100,1.,10,1.0],#vmins = [0.1,0.1,0.1,0.1], vmaxs = [100,100,0.5,0.5],
                #              annos=['Exp.', 'RDI', 'RDI SDI', 'RDI SSD', 'RDI DSI',  'RDI BB-DSI'])
                grid(maps, nrows =2, width=2, logAmp=True, vmins = [0.01,0.01,0.05,0.005], vmaxs=[100.,100.,1.,0.1],#vmins = [0.1,0.1,0.1,0.1], vmaxs = [100,100,0.5,0.5],
                             annos=['Exp.', 'RDI', 'RDI DSI',  'RDI BB-DSI'], titles=['$I$', '$I_\mathrm{L}$'])
                # quicklook_im(maps[0], logAmp=True, vmin = 0.01, vmax = 1)
                plt.show()


