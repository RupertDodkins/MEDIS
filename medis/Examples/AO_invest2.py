'''This code handles the relevant functionality of a Hawaii 2RG camera'''
import sys
sys.path.append('D:/dodkins/MEDIS/MEDIS')
import numpy as np
import copy
import matplotlib.pyplot as plt
from vip_hci import phot, pca
from params import ap, cp, tp, sp, mp, iop
from Utils.plot_tools import loop_frames, quicklook_im,view_datacube, compare_images, indep_images
import Detector.readout as read
import Analysis.phot
import Analysis.stats
import pandas as pd

# Global params
sp.save_obs = False
sp.show_cube = False
sp.save_obs = False
sp.return_cube = True
sp.show_wframe = False
ap.companion = False
# ap.contrast = [1e-5, 1e-5]#[0.1,0.1]
# ap.lods = [[-2.5,2.5], [1.5,+1.5]]
ap.contrast = [1e-5]#[0.1,0.1]
ap.lods = [[1.5,-1.5]]
# tp.diam=8.
tp.use_spiders = True
tp.use_ao = True
tp.use_atmos = True
tp.ao_act=65
tp.servo_error= [0,1]#[1,2]#[1,2]#False#[1e-3,1e-3]#
tp.piston_error = False
cp.vary_r0 = False
tp.active_modulate=False
# tp.detector = 'MKIDs'#'ideal'#
ap.star_photons*=100
# tp.NCPA_type = None#'Static'
# tp.CPA_type = None#'Static'
tp.NCPA_type = 'Static'
tp.CPA_type = 'Static'
mp.date = '180508/'
iop.update(mp.date)
sp.num_processes = 1
# tp.occulter_type = '8th_Order'
tp.occulter_type = 'None'
num_exp = 2000
tp.active_null = False
ap.exposure_time = 0.001  # 0.001
ap.numframes = int(num_exp * ap.exposure_time / cp.frame_time)

xlocs = range(0, 128)  # range(0,128)#65
ylocs = range(0, 128)  # range(0,128)#85
tp.band = np.array([860, 1250])
tp.nwsamp = 1
tp.rot_rate = 0  # deg/s
theta=45
lod = 8

def eval_method(cube, algo, angle_list, algo_dict):
    fulloutput = phot.contrcurve.contrast_curve(cube=cube,
                                   angle_list=angle_list, psf_template=psf_template,
                                   fwhm=lod, pxscale=tp.platescale/1000,
                                   starphot=star_phot, algo=algo,
                                   debug=True, plot=False, theta=theta,full_output=True,fc_snr=10, **algo_dict)
    plt.show()
    metrics = [fulloutput[0]['throughput'], fulloutput[0]['noise'], fulloutput[0]['sensitivity (Student)']]
    metrics = np.array(metrics)
    return metrics, fulloutput[3]

def plot_null():
    import cPickle as pickle
    import os

    MEDIUM_SIZE = 14
    plt.rc('font', size=MEDIUM_SIZE)  # controls default text sizes
    from matplotlib import rcParams

    rcParams['axes.linewidth'] = 1.5  # set the value globally
    rcParams['font.family'] = 'STIXGeneral'  # 'Times New Roman'
    rcParams['mathtext.fontset'] = 'custom'
    rcParams['mathtext.fontset'] = 'stix'
    fig, ax = plt.subplots()
    for filename in ['null1maxNCPA5000']:#'null1maxNCPA','null1max','null2max','null4max','null12max']:
        area_sum = []
        fullfilename = os.path.join(iop.datadir,filename+'.pkl')
        # with open(iop.measured_var, 'rb') as handle:
        with open(fullfilename, 'rb') as handle:
            try:
                while 1:
                    area_sum.append(pickle.load(handle))
                    # print area_sum
            except EOFError:
                print 'Finished reading'

        ax.plot(area_sum, linewidth=2,color='#0C5DA5')
    ax.tick_params(direction='in', which='both', right=True, top=True, width=1.5, length=4)
    ax.set_xlabel('Iterations')
    ax.set_ylabel('Total Flux (A.U)')
    plt.show()

plotdata, maps = [], []
if __name__ == '__main__':
    # plot_null()

    # Amplitude
    tp.detector = 'ideal'#'MKIDs'  #
    tp.use_ao = True
    tp.use_atmos = False
    tp.NCPA_type = None#'Static'
    tp.CPA_type = 'Amp'
    # tp.CPA_type = 'test'
    # tp.CPA_type = None#'Static'#'test'
    ap.lods = [[2, 0]]  # initial location (no rotation)
    tp.active_null = True
    tp.speckle_kill = True
    iop.hyperFile = iop.datadir + '/amp_abs2.pkl'
    # tp.active_modulate = True
    perfect_hypercube = read.get_integ_hypercube(plot=False)  # /ap.numframes
    quicklook_im(np.sum(perfect_hypercube[:, 0], axis=0), axis=None, title=r'  $I / I^{*}$', anno='Integration')
    loop_frames(perfect_hypercube[::20, 0])
    # compare_images([perfect_hypercube[0,0],perfect_hypercube[10,0],perfect_hypercube[100,0],perfect_hypercube[1000,0]], logAmp=True)
    annos = ['Frame: 0', 'Frame: 20', 'Frame: 500', 'Frame: 2000']
    compare_images(
        [perfect_hypercube[0, 0], perfect_hypercube[20, 0], perfect_hypercube[500, 0], perfect_hypercube[-1, 0]],
        logAmp=True, title='A.U', annos= annos)

    # Perfect
    tp.detector = 'ideal'#'MKIDs'  #
    tp.use_ao = False
    tp.use_atmos = False
    tp.NCPA_type = None#'Static'
    tp.CPA_type = None#'Static'
    tp.active_null = False
    iop.hyperFile = iop.datadir + '/perfect.pkl'
    # tp.active_modulate = True
    perfect_hypercube = read.get_integ_hypercube(plot=False)  # /ap.numframes
    # quicklook_im(np.sum(perfect_hypercube[:, 0], axis=0), axis=None, title=r'  $I_r / I^{*}$', anno='Integration')
    # loop_frames(perfect_hypercube[:, 0])


    rad_samp = np.linspace(0,tp.platescale/1000.*40,40)
    # # print rad_samp
    # # # Get unocculted PSF for intensity
    # psf_template = Analysis.phot.get_unoccult_psf(hyperFile='/IntHyperUnOccult.pkl', plot=False)
    # # # star_phot = np.sum(psf_template)
    # star_phot = phot.contrcurve.aperture_flux(psf_template,[64],[64],lod,1)[0]/ap.numframes
    # psf_template = psf_template[:-1,:-1]

    # Active null
    tp.use_ao = True
    tp.use_atmos = True
    tp.NCPA_type = 'Static'
    tp.CPA_type = 'Static'
    tp.active_null = True
    iop.hyperFile = iop.datadir + '/active_correct.pkl'
    # tp.active_modulate = True
    active_hypercube = read.get_integ_hypercube(plot=False)#/ap.numframes
    # quicklook_im(np.sum(active_hypercube[:,0], axis=0), axis=None, title=r'  $I_r / I^{*}$', anno='Integration')
    # loop_frames(active_hypercube[:, 0])

    # No active null
    tp.use_ao = True
    tp.use_atmos = True
    tp.NCPA_type = 'Static'
    tp.CPA_type = 'Static'
    tp.active_null = False
    iop.hyperFile = iop.datadir + '/NCPA_correct.pkl'
    # tp.active_modulate = True
    NCPA_hypercube = read.get_integ_hypercube(plot=False)#/ap.numframes
    # quicklook_im(np.sum(NCPA_hypercube[:,0], axis=0), axis=None, title=r'  $I_r / I^{*}$', anno='Integration')
    # loop_frames(NCPA_hypercube[:, 0])

    # No AO
    tp.use_ao = False
    tp.use_atmos = True
    tp.NCPA_type = 'Static'
    tp.CPA_type = 'Static'
    tp.active_null = False
    iop.hyperFile = iop.datadir + '/noAO_correct.pkl'
    # tp.active_modulate = True
    noAO_hypercube = read.get_integ_hypercube(plot=False)#/ap.numframes
    # quicklook_im(np.sum(NCPA_hypercube[:,0], axis=0), axis=None, title=r'  $I_r / I^{*}$', anno='Integration')
    # loop_frames(NCPA_hypercube[:, 0])


    SRs = np.zeros((3,num_exp))
    for i in range(num_exp):
        SRs[0,i] = Analysis.phot.aper_phot(active_hypercube[i,0], 0, 4)/Analysis.phot.aper_phot(perfect_hypercube[i,0], 0, 4)
        SRs[1,i] = Analysis.phot.aper_phot(NCPA_hypercube[i,0], 0, 4)/Analysis.phot.aper_phot(perfect_hypercube[i,0], 0, 4)
        SRs[2,i] = Analysis.phot.aper_phot(noAO_hypercube[i,0], 0, 4)/Analysis.phot.aper_phot(perfect_hypercube[i,0], 0, 4)
    plt.plot(np.arange(0,0.1,0.001),np.transpose(SRs))
    plt.legend(['Active Null', 'AO', 'no AO'])
    plt.xlabel('Time (s)')
    plt.ylabel('SR')
    plt.xlim([0,0.04])

    # plt.xscale('log')
    # plt.yscale('log')
    plt.show()

    # method_out = eval_method(active_hypercube[:,0], Analysis.stats.DSI_4_VIP,angle_list, algo_dict)
    # plotdata.append(method_out[0])
    # maps.append(method_out[1])
    # #
    # quicklook_im(method_out[1], axis=None, title=r'  $I_r / I^{*}$', anno='DSI')
    #


