import sys
import numpy as np
sys.path.append('D:/dodkins/MEDIS/MEDIS')
from params import tp, mp, cp, sp, ap, iop
from get_photon_data import run
import get_photon_data as gpd
from Utils.plot_tools import view_datacube
import Utils.rawImageIO as rawImageIO
from Utils.plot_tools import quicklook_im
import Analysis.phot
from Utils.misc import dprint
import proper
import matplotlib.pyplot as plt


sp.show_wframe = False
sp.show_cube=False
ap.companion = False
tp.diam=8.
tp.use_spiders = False
tp.quick_ao=False
tp.use_ao = True
tp.ao_act = 50
tp.detector = 'ideal'
tp.NCPA_type = None#'Static'
tp.CPA_type = None#'Static'
mp.date = '180424/'
iop.update(mp.date)
sp.num_processes = 1
tp.occulter_type = 'None'#'Gaussian'
num_exp =3#20 #5000
ap.exposure_time = 0.001  # 0.001
ap.numframes = int(num_exp * ap.exposure_time / cp.frame_time)
tp.piston_error = False
tp.band = np.array([860, 1250])
tp.nwsamp = 1
tp.rot_rate = 0  # deg/s
lod = 8
# sp.num_processes = 5

# acts = [8,16,32,64]
#
# datacube=[]
# tp.use_ao = False
# if __name__ == '__main__': datacube.append(gpd.run()[0])
#
# tp.use_ao=True
# for act in acts:
#     tp.ao_act = act
#     if __name__ == '__main__': datacube.append(gpd.run()[0])
#
# datacube = np.array(datacube)
# view_datacube(datacube)


if __name__ == '__main__':
    psf = Analysis.phot.get_unoccult_perf_psf(plot=False)
    peak_perf = psf[tp.grid_size/2,tp.grid_size/2]
    dprint(peak_perf)

    # tp.aber_params = {'CPA': True,
    #                   'NCPA': False,
    #                   'QuasiStatic': False,  # or 'Static'
    #                   'Phase': True,
    #                   'Amp': False,
    #                     'n_surfs':2}
    #
    # NCPAs = [False,True,True]
    # Amps = [False,False,True]
    # acts = [64, 32, 16, 8, 4]
    # fig, ax = plt.subplots()
    # #
    # #
    # # ax.plot([1,2,4,8,16,32,64], noise, 'o-')
    # ax.tick_params(direction='in', which='both', right=True, top=True)
    # ax.set_xscale('log')
    # ax.set_xlabel('$N_{act}$')
    # ax.set_ylabel('SR')
    # ax1 = ax.twinx()
    # # ax1.set_ylim(ax.get_ylim())
    # ax1.set_ylabel('$\phi$ (nm)')
    # from matplotlib.ticker import FormatStrFormatter
    #
    #
    # for i in range(3):
    #     tp.aber_params['NCPA'] = NCPAs[i]
    #     tp.aber_params['Amp'] = Amps[i]
    #     SRs = []
    #     phis = []
    #     for act in acts:
    #         tp.ao_act = act
    #         hypercube = gpd.run()
    #
    #         peak_meas = hypercube[-1,0,tp.grid_size/2,tp.grid_size/2]
    #         SR = peak_meas/peak_perf
    #         dprint(SR)
    #         SRs.append(SR)
    #         phi = np.sqrt((1-SR))*tp.band[0]/(2*np.pi)
    #         phis.append(phi)
    #     ax.plot(acts,SRs)
    #     # ax1.plot(acts, phis)
    #     phi_lab = np.int_(np.sqrt((1-ax.get_yticks()))*tp.band[0]/(2*np.pi))
    #     phi_lab[-2:] = [0,0]
    #     dprint(phi_lab)
    #     ax1.set(yticks=ax.get_yticks(), yticklabels=phi_lab, ylim=ax.get_ylim())
    #     # ax1.yaxis.set_major_formatter(FormatStrFormatter('%.2f'))
    # # ax1.set_ylim(ax1.get_ylim()[1], ax1.get_ylim()[0])
    # plt.show()

    # psf = Analysis.phot.get_unoccult_perf_psf(plot=False)
    # peak_perf = psf[tp.grid_size / 2, tp.grid_size / 2]
    # dprint(peak_perf)

    tp.aber_params = {'CPA': True,
                      'NCPA': False,
                      'QuasiStatic': False,  # or 'Static'
                      'Phase': True,
                      'Amp': False,
                      'n_surfs': 2}

    NCPAs = [False, True, True]
    Amps = [False, False, True]
    acts = [1, 2, 4, 8, 16,32,64,128]#,256,512,1014]

    fig, ax = plt.subplots()
    #
    #
    # ax.plot([1,2,4,8,16,32,64], noise, 'o-')
    ax.tick_params(direction='in', which='both', right=True, top=True)
    ax.set_xscale('log')
    ax.set_xlabel('Servo Lag (ms)')
    ax.set_ylabel('SR')
    ax1 = ax.twinx()
    # ax1.set_ylim(ax.get_ylim())
    ax1.set_ylabel('$\phi$ (nm)')
    from matplotlib.ticker import FormatStrFormatter

    for i in range(3):
        tp.aber_params['NCPA'] = NCPAs[i]
        tp.aber_params['Amp'] = Amps[i]
        SRs = []
        phis = []
        for act in acts:
            tp.servo_error[0] = act
            num_exp = 3 +act # 20 #5000
            ap.numframes = int(num_exp * ap.exposure_time / cp.frame_time)
            hypercube = gpd.run()

            peak_meas = hypercube[-1, 0, tp.grid_size / 2, tp.grid_size / 2]
            SR = peak_meas / peak_perf
            dprint(SR)
            SRs.append(SR)
            phi = np.sqrt((1 - SR)) * tp.band[0] / (2 * np.pi)
            phis.append(phi)
        ax.plot(acts, SRs)
        dprint(acts)
        # ax1.plot(acts, phis)
        phi_lab = np.int_(np.sqrt((1 - ax.get_yticks())) * tp.band[0] / (2 * np.pi))
        # phi_lab[-2:] = [0, 0]
        dprint(phi_lab)
        ax1.set(yticks=ax.get_yticks(), yticklabels=phi_lab, ylim=ax.get_ylim())
        # ax1.yaxis.set_major_formatter(FormatStrFormatter('%.2f'))
        # ax1.set_ylim(ax1.get_ylim()[1], ax1.get_ylim()[0])
    ax.legend(['CPA','CPA + NCPA', 'CPA + NCPA (Amp)'])
    plt.show()

    # tp.aber_params = {'CPA': True,
    #                   'NCPA': False,
    #                   'QuasiStatic': False,  # or 'Static'
    #                   'Phase': True,
    #                   'Amp': False,
    #                   'n_surfs': 2}
    #
    # NCPAs = [False, True, True]
    # Amps = [False, False, True]
    # acts = [2, 10, 25, 50, 100, 250]  # ,256,512,1014]
    #
    # fig, ax = plt.subplots()
    # #
    # #
    # # ax.plot([1,2,4,8,16,32,64], noise, 'o-')
    # ax.tick_params(direction='in', which='both', right=True, top=True)
    # ax.set_xscale('log')
    # ax.set_xlabel('Frame Rate (Hz)')
    # ax.set_ylabel('SR')
    # ax1 = ax.twinx()
    # # ax1.set_ylim(ax.get_ylim())
    # ax1.set_ylabel('$\phi$ (nm)')
    # from matplotlib.ticker import FormatStrFormatter
    #
    # for i in range(3):
    #     tp.aber_params['NCPA'] = NCPAs[i]
    #     tp.aber_params['Amp'] = Amps[i]
    #     SRs = []
    #     phis = []
    #     for act in acts:
    #         tp.servo_error[1] = act
    #         num_exp = 3 + act  # 20 #5000
    #         ap.numframes = int(num_exp * ap.exposure_time / cp.frame_time)
    #         hypercube = gpd.run()
    #
    #         peak_meas = hypercube[-1, 0, tp.grid_size / 2, tp.grid_size / 2]
    #         SR = peak_meas / peak_perf
    #         dprint(SR)
    #         SRs.append(SR)
    #         phi = np.sqrt((1 - SR)) * tp.band[0] / (2 * np.pi)
    #         phis.append(phi)
    #     ax.plot(1000/np.array(acts), SRs)
    #     dprint(acts)
    #     # ax1.plot(acts, phis)
    #     phi_lab = np.int_(np.sqrt((1 - ax.get_yticks())) * tp.band[0] / (2 * np.pi))
    #     # phi_lab[-2:] = [0, 0]
    #     dprint(phi_lab)
    #     ax1.set(yticks=ax.get_yticks(), yticklabels=phi_lab, ylim=ax.get_ylim())
    #     # ax1.yaxis.set_major_formatter(FormatStrFormatter('%.2f'))
    #     # ax1.set_ylim(ax1.get_ylim()[1], ax1.get_ylim()[0])
    # plt.show()
# AO_8act = rawImageIO.load_wf(iop.datadir+'/loopAO_8act.pkl')
# AO_16act = rawImageIO.load_wf(iop.datadir+'/loopAO_16act.pkl')
# AO_32act = rawImageIO.load_wf(iop.datadir+'/loopAO_32act.pkl')
# AO_64act = rawImageIO.load_wf(iop.datadir + '/loopAO_64act.pkl')
 # before = rawImageIO.load_wf(iop.datadir+'/beforeAO.pkl')
# before = rawImageIO.load_wf(iop.datadir+'/AO_1act.pkl')
# AO_2act = rawImageIO.load_wf(iop.datadir+'/AO_2act.pkl')
# AO_4act = rawImageIO.load_wf(iop.datadir+'/AO_4act.pkl')
# AO_8act = rawImageIO.load_wf(iop.datadir+'/AO_8act.pkl')
# AO_16act = rawImageIO.load_wf(iop.datadir+'/AO_16act.pkl')
# AO_32act = rawImageIO.load_wf(iop.datadir+'/AO_32act.pkl')
# AO_64act = rawImageIO.load_wf(iop.datadir+'/AO_64act.pkl')
# #
# before = proper.prop_get_phase(before)
# AO_2act = proper.prop_get_phase(AO_2act)
# AO_4act = proper.prop_get_phase(AO_4act)
# AO_8act = proper.prop_get_phase(AO_8act)
# AO_16act = proper.prop_get_phase(AO_16act)
# AO_32act = proper.prop_get_phase(AO_32act)
# AO_64act = proper.prop_get_phase(AO_64act)
#
# quicklook_im(before, logAmp=False)
# quicklook_im(AO_8act, logAmp=False)
# # quicklook_im(AO_16act, logAmp=False)
# # quicklook_im(AO_32act, logAmp=False)
# quicklook_im(AO_64act, logAmp=False)
# #
# from vip_hci import phot, pca
# noise, rrad = phot.noise_per_annulus(after, separation=1, fwhm=lod,
#                                                       init_rad=lod, wedge=(0, 360))
# noise = np.zeros((7))
# noise[0] = np.var(before[:,64])
# noise[1] = np.var(AO_2act[:,64])
# noise[2] = np.var(AO_4act[:,64])
# noise[3] = np.var(AO_8act[:,64])
# noise[4] = np.var(AO_16act[:,64])
# noise[5] = np.var(AO_32act[:,64])
# noise[6] = np.var(AO_64act[:,64])
# #
# fig, ax = plt.subplots()
# #
# #
# ax.plot([1,2,4,8,16,32,64], noise, 'o-')
# ax.tick_params(direction='in', which='both', right=True, top=True)
# ax.set_xscale('log')
# ax.set_xlabel('$N_{act}$')
# ax.set_ylabel('$\sigma_\phi$')
# plt.show()

# tp.detector = 'ideal'#
# tp.save_obs = False
# tp.show_wframe = False
# cp.numframes = 1
#
#
# acts = [8,16,32,64]
#
# datacube=[]
# tp.use_ao = False
# datacube.append(run()[0])
#
# tp.use_ao=True
# for act in acts:
#     tp.ao_act = act
#     datacube.append(run()[0])
#
# datacube = np.array(datacube)
# view_datacube(datacube)
