import sys
import numpy as np
sys.path.append('D:/dodkins/MEDIS/MEDIS')
from medis.params import tp, mp, cp, sp, ap, iop
from get_photon_data import run_medis
import get_photon_data as gpd
from medis.Utils.plot_tools import view_datacube
import medis.Utils.rawImageIO as rawImageIO
from medis.Utils.plot_tools import quicklook_im, compare_images
import medis.Analysis.phot as phot
import proper
from medis.Utils.misc import dprint
import matplotlib.pyplot as plt



sp.show_wframe = False
sp.show_cube=False

# ap.companion = False#True
# ap.lods = [[3,3]]
# ap.contrast = [1]#[0.0005]
tp.diam=8.
tp.use_spiders = False
tp.use_ao = False
tp.ao_act = 64
tp.detector = 'ideal'
tp.use_atmos = False
# tp.beam_ratio=0.6
# tp.NCPA_type = 'Static'
# tp.CPA_type = 'Static'
tp.NCPA_type = None
tp.CPA_type = None
mp.date = '180424/'
iop.update(mp.date)
sp.num_processes = 1
num_exp =1 #5000
ap.exposure_time = 0.001  # 0.001
ap.numframes = int(num_exp * ap.exposure_time / cp.frame_time)
tp.piston_error = True
tp.band = np.array([860, 1250])
tp.nwsamp = 1
tp.rot_rate = 0  # deg/s
lods = [8,10,12,14,16]
tp.aber_params = {'CPA': False,
                    'NCPA': False,
                    'QuasiStatic': False,  # or 'Static'
                    'Phase': True,
                    'Amp': False,
                    'n_surfs': 2,
                    'OOPP': [8, 4]}
occulter_types = ['Solid', 'Gaussian', '8th_Order', 'Vortex']
# acts = [8,16,32,64]

def star_throughput():
    ap.companion = False
    thru_tot = np.zeros((3, 4))
    for p in range(2, 3):
        # for p in range(0,1):

        if p == 0:
            tp.aber_params['CPA'] = False
            tp.aber_params['NCPA'] = False
            tp.use_atmos = False
            tp.use_ao = False

        if p == 1:
            tp.aber_params['CPA'] = True
            tp.aber_params['NCPA'] = False
            tp.use_atmos = True
            tp.use_ao = True

        if p == 2:
            tp.aber_params['CPA'] = True
            tp.aber_params['NCPA'] = True
            tp.use_atmos = True
            tp.use_ao = True

        # tp.band[0] = 860
        tp.occulter_type = 'None'
        ref = gpd.run_medis()[0, 0]
        # ref_phot = phot.aper_phot(ref, 0, lods[0])
        ref_tot = np.sum(ref)
        # # mask = np.int_(phot.aperture(76, 52, 6))
        # print ref_phot
        # datacube = []
        # # tp.use_ao = False
        rad_int = np.zeros((4, 64))
        for i in range(1,4):#range(4):
            tp.occulter_type = occulter_types[i]  # 'Gaussian'
            occult = gpd.run_medis()[0, 0]
            # datacube[i]/ref_phot
            # phot.coron_4_VIP(datacube[i],ref)
            for r in range(64):
                print i, r, occult.shape, r+1
                rad_int[i, r] = phot.aper_phot(occult, r * 1, (r + 1) * 1)
            # plt.plot(rad_int[i])
            # plt.show()
            occult_tot = np.sum(occult)
            dprint(occult_tot / ref_tot)
            thru_tot[p, i] = occult_tot / ref_tot
            # datacube = np.array(datacube)
            # throughput = np.zeros((3))
    return thru_tot


def exo_through():
    ap.companion = True
    ap.lods = [[0,0],[0.5, -0.5], [1, 1], [-1.5, 1.5],[-2, -2], [2.5, -2.5], [3, 3], [-3.5, 3.5],[-4, -4]]
    # ap.lods = []
    # for io in range(9):
    #     ap.lods.append(np.array([0.5,0.5]))
    ap.contrast = np.ones((len(ap.lods)))*10#00
    thru_matrix = np.zeros((3, 4, 8))
    colors = ['#1F77b4', '#ff7f0e', '#2ca02c', '#d62728']
    fwhm = 12
    def get_xy(lod):

        x = tp.grid_size/2 - lod[0]*fwhm
        y = tp.grid_size/2 - lod[1]*fwhm
        return x, y

    for p in range(2, 3):
        # for p in range(0,1):

        if p == 0:
            tp.aber_params['CPA'] = False
            tp.aber_params['NCPA'] = False
            tp.use_atmos = False
            tp.use_ao = False

        if p == 1:
            tp.aber_params['CPA'] = True
            tp.aber_params['NCPA'] = False
            tp.use_atmos = True
            tp.use_ao = True

        if p == 2:
            tp.aber_params['CPA'] = True
            tp.aber_params['NCPA'] = True
            tp.use_atmos = True
            tp.use_ao = True
            # if ap.companion == True:

        tp.occulter_type = 'None'
        ref = gpd.run_medis()[0, 0]
        # ref = np.transpose(ref)
        injected = np.zeros((len(ap.contrast)))
        for io in range(len(ap.contrast)):
            x, y = get_xy(ap.lods[io])
            print io, x, y,
            mask = phot.aperture(x, y, 4)
            # quicklook_im(ref, logAmp=True)
            # quicklook_im(ref * mask)
            injected[io] = np.sum(ref * mask) / np.sum(mask)
            print injected[io]

        for i in range(0, 4):
            tp.occulter_type = occulter_types[i]  # 'Gaussian'
            occult = gpd.run_medis()[0, 0]
            recovered = np.zeros((len(ap.contrast)))
            for io in range(len(ap.contrast)):
                x, y = get_xy(ap.lods[io])
                print io, x, y,
                mask = phot.aperture(x, y, 4)
                # quicklook_im(ref, logAmp=True)
                # quicklook_im(ref * mask)
                recovered[io] = np.sum(occult * mask) / np.sum(mask)
                print recovered[io]

            # plt.plot(injected)
            # plt.plot(recovered)
            # plt.show()
            # plt.figure()
            vector_radd = range(0,9)
            thruput_mean = recovered/injected
            # plt.plot(thruput_mean, marker='o', c=colors[i])
            rad_samp = np.arange(0,9,0.5)
            from scipy.interpolate import InterpolatedUnivariateSpline
            print len(vector_radd), len(thruput_mean)
            f = InterpolatedUnivariateSpline(vector_radd, thruput_mean, k=2)
            thruput_interp = f(rad_samp)
            plt.plot(rad_samp, thruput_interp,c=colors[i])
            # plt.show()
        plt.show()
        plt.figure()
    #     Isource = np.sum(ref * mask) / np.sum(mask)  # , 'sum'
    #     # plt.imshow(ref * mask, origin='lower')
    #     # plt.show()
    #
    #     mask = np.int_(phot.aperture(76, 52, 6))
    #     # plt.imshow(datacube[i]*mask, origin='lower')
    #     throughput[0] = (np.sum(datacube[0] * mask) / np.sum(mask)) / Isource  # , 'sum'
    #     # plt.show()
    #
    #     mask = np.int_(phot.aperture(76, 52, 10))
    #     # plt.imshow(datacube[i]*mask, origin='lower')
    #     throughput[1] = (np.sum(datacube[1] * mask) / np.sum(mask)) / Isource  # , 'sum'
    #     # plt.show()
    #
    #     mask = np.int_(phot.aperture(76, 52, 8))
    #     # plt.imshow(datacube[i]*mask, origin='lower')
    #     throughput[2] = (np.sum(datacube[2] * mask) / np.sum(mask)) / Isource  # , 'sum'
    #     # plt.show()
    #     print throughput
    #
    # # throughput = [ 0.68996802,  0.12175953,  0.27923381]
    # MEDIUM_SIZE = 16
    # plt.rc('font', size=MEDIUM_SIZE)  # controls default text sizes
    # # plt.rc('axes', linewidth=2)
    # from matplotlib import rcParams
    # rcParams['font.family'] = 'STIXGeneral'  # 'Times New Roman'
    # rcParams['mathtext.fontset'] = 'custom'
    # rcParams['mathtext.fontset'] = 'stix'
    #
    # fig, ax = plt.subplots(figsize=(4.3, 3.8))
    # labels = ['a', 'b', 'c']
    # for i, int in enumerate(rad_int):
    #     # int/=throughput[i]
    #     ax.plot(np.linspace(0, 0.8, 64), int, label=occulter_types[i])
    # ax.text(0.05, 0.9, labels[p], transform=ax.transAxes, fontweight='bold', color='k', fontsize=17,
    #         family='serif')
    # ax.tick_params(direction='in', which='both', right=True, top=True)
    # ax.set_xlabel('Radial Separation')
    #
    # ax.set_yscale('log')
    # if p == 0:
    #     ax.set_ylabel('Intensity Ratio')
    #     ax.legend()
    # plt.subplots_adjust(left=0.19, right=0.98, top=0.99, bottom=0.15)
    # # plt.savefig(str(p)+'.pdf')
    # print thru_data
    # plt.show()
    return
    # for frame in datacube:
    #     plt.plot(frame[64])
    # plt.show()
    # compare_images(datacube,logAmp=True)

if __name__ == '__main__':
    # dprint(star_throughput())
    exo_through()

#
# tp.use_ao=True
# for act in acts:
#     tp.ao_act = act
#     if __name__ == '__main__': datacube.append(gpd.run_medis()[0])
#


# if __name__ == '__main__':
#     hypercube = gpd.run_medis()