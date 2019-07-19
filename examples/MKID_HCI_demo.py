'''Example Code for conducting SDI with MKIDs'''

import os
import matplotlib as mpl
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.colors import LogNorm
from vip_hci import phot, pca
from statsmodels.tsa.stattools import acf
from medis.params import tp, mp, cp, sp, ap, iop
import medis.get_photon_data as gpd
from medis.Utils.plot_tools import loop_frames, quicklook_im, view_datacube, compare_images, indep_images, grid
from medis.Utils.misc import dprint
import medis.Detector.readout as read
from medis.Analysis.phot import get_unoccult_psf, eval_method


mpl.use('Qt5Agg')

# Renaming obs_sequence directory location
iop.update(new_name='HCIdemo/')

# Parameters specific to this script
sp.show_wframe = False
sp.save_obs = False
sp.show_cube=False
sp.num_processes = 1

ap.companion = False
sp.get_ints=False
ap.star_photons_per_s = int(1e6)
ap.contrast = [10**-3.1,10**-3.1,10**-3.1,10**-4,10**-4,10**-4]
ap.lods = [[-1.6,0.0],[-3.2,0.0],[-5,0.0],[1.6,0.0],[3.2,0.0],[5,0.0]]

tp.save_locs = np.empty((0,1))

tp.diam=8.
ap.grid_size=148
tp.beam_ratio =0.5
tp.obscure = True
tp.use_ao = True
tp.ao_act = 50
tp.platescale=10 # mas
tp.detector = 'ideal'
# tp.detector = 'MKIDs'
tp.use_atmos = True
tp.use_zern_ab = False
tp.occulter_type = 'Vortex'#"None (Lyot Stop)"
tp.aber_params = {'CPA': True,
                'NCPA': True,
                'QuasiStatic': False,  # or Static
                'Phase': True,
                'Amp': False,
                'n_surfs': 4,
                'OOPP': [16,8,4,16]}#False}#
tp.aber_vals = {'a': [5e-18, 1e-19],#'a': [5e-17, 1e-18],
                'b': [2.0, 0.2],
                'c': [3.1, 0.5],
                'a_amp': [0.05, 0.01]}
tp.piston_error = False
ap.band = np.array([700, 1500])
ap.nwsamp = 4
ap.w_bins = 16#8
tp.rot_rate = 0  # deg/s
# tp.pix_shift = [[0,0],[20,20]]

mp.bad_pix = True
mp.array_size = np.array([146,146])
num_exp =100
ap.sample_time = 0.05
# date = '180828/'
# dprint((iop.datadir, date))
# iop.atmosdir= os.path.join(iop.datadir,'atmos',date)

mp.phase_uncertainty =True
mp.phase_background=False
mp.QE_var = True
mp.bad_pix = True
mp.hot_pix = None
mp.hot_bright = 1e3

mp.R_mean = 8
mp.g_mean = 0.2
mp.g_sig = 0.04
mp.bg_mean = -10
mp.bg_sig = 40
mp.pix_yield = 0.9#0.7 # check dis

lod = 6

# tp.pix_shift = None
# tp.pix_shift = []
# for ix in range(-2, 3):
#     for iy in range(-2, 3):
#         print(ix, iy, ix * 15, iy * 15)
#         tp.pix_shift.append([ix * 15, iy * 15])
# tp.pix_shift = np.array(tp.pix_shift)

# if __name__ == '__main__':
#     if os.path.exists(iop.int_maps):
#         os.remove(iop.int_maps)
#
#     ideal = gpd.run()[0, :]
#
#     # compare_images(ideal, logAmp=True, vmax = 0.01, vmin=1e-6, annos = ['Ideal 800 nm', '1033 nm', '1267 nm', '1500 nm'], title=r'$I$')
#     with open(iop.int_maps, 'rb') as handle:
#         int_maps =pickle.load(handle)
#
#     int_maps = np.array(int_maps)
#     dprint(int_maps[0].shape)
#     # view_datacube(int_maps, logAmp=True)
#     # grid(int_maps[::-1][:4,ap.grid_size//4:-ap.grid_size//4,ap.grid_size//4:-ap.grid_size//4], ctitles=r'$\phi$',
#     #      annos=['Entrance Pupil', 'After CPA', 'After AO', 'After NCPA'],
#     #      vmins=[-3.14] * 4, vmaxs=[3.14] * 4)
#     grid(int_maps[::-1][4:,ap.grid_size//4:-ap.grid_size//4,ap.grid_size//4:-ap.grid_size//4], nrows =2, width=1,
#          ctitles=r'$I$', annos=['Before Coron.', 'After Coron.'],
#          logAmp=True, vmins=[1e-9]*2, vmaxs=[1e-2]*2)
#     plt.show(block=True)

ap.numframes = 3
if __name__ == '__main__':
    plotdata, maps = [], []

    print(ap.__dict__)
    psf_template = get_unoccult_psf(fields='/IntHyperUnOccult.h5', plot=False, numframes=1)
    dprint((ap.grid_size//2, psf_template.shape))
    # quicklook_im(np.sum(psf_template,axis=0), logAmp=True)
    star_phot = phot.contrcurve.aperture_flux(np.sum(psf_template,axis=0),[mp.array_size[0]//2],[mp.array_size[0]//2],lod,1)[0]#/1e4#/ap.numframes * 500
    wsamples = np.linspace(ap.band[0], ap.band[1], ap.w_bins)
    scale_list = wsamples/(ap.band[1]-ap.band[0])
    # scale_list = scale_list[::-1]
    algo_dict = {'scale_list': scale_list}

ap.exposure_time = 0.1  # 0.001
ap.numframes = int(num_exp * ap.exposure_time / ap.sample_time)
iop.fields = iop.testdir + '/HR8799_phot_tag%i_tar_%i.h5' % (ap.numframes, np.log10(ap.star_photons_per_s))

if __name__ == '__main__':
    fields = gpd.run_medis()
    orig_hyper = np.abs(fields[:, -1, :, 0])**2


    # fast_hyper = fast_hyper[:100]
    # ap.numframes = int(100 * ap.exposure_time / ap.sample_time)
    # dprint(fast_hyper.shape)
    fast_hyper = read.take_exposure(orig_hyper)
    ap.exposure_time = 1  # 0.001
    med_hyper = read.take_exposure(orig_hyper)
    ap.exposure_time = 10#1.0  # 0.001
    slow_hyper = read.take_exposure(orig_hyper)
    ap.exposure_time = 100#1.0  # 0.001
    v_slow_hyper = read.take_exposure(orig_hyper)

    # this is crucial for the PCA
    fast_hyper /= np.sum(fast_hyper) # /ap.numframes
    med_hyper /= np.sum(med_hyper) # /ap.numframes
    slow_hyper /= np.sum(slow_hyper) # /ap.numframes
    # v_slow_hyper /= np.sum(v_slow_hyper) # /ap.numframes

    fast_hyper = np.transpose(fast_hyper, (1, 0, 2, 3))
    med_hyper = np.transpose(med_hyper, (1, 0, 2, 3))
    slow_hyper = np.transpose(slow_hyper, (1, 0, 2, 3))
    # v_slow_hyper = np.transpose(v_slow_hyper, (1, 0, 2, 3))


    # # view_datacube(np.sum(fast_hyper, axis=1), logAmp=True)
    # SDI = pca.pca(fast_hyper, angle_list=np.zeros((fast_hyper.shape[1])), scale_list=scale_list,
    #               mask_center_px=None,adimsdi='double', ncomp=7, ncomp2=None, collapse='median')#, ncomp2=3)#,
    # quicklook_im(SDI, logAmp=True, show=False)

    # plt.figure()
    # for y in [73, 85, 105, 120]:
    #     print(y)
    #     corr, ljb, pvalue = acf(fast_hyper[0, :, 73, y], unbiased=False, qstat=True, nlags=len(range(ap.numframes)))
    #     star_corr = corr
    #     # plt.plot(fast_hyper[0, :, 73, y])
    #     plt.plot(star_corr)
    #     # plt.xscale('log')
    # loop_frames(fast_hyper[0], logAmp=True)
    # plt.show()
    dprint(fast_hyper.shape)

    SDI = pca.pca(fast_hyper, angle_list=np.zeros((fast_hyper.shape[1])), scale_list=scale_list,
                  mask_center_px=None,adimsdi='double', ncomp=7, ncomp2=None, collapse='median')#, ncomp2=3)#,
    # quicklook_im(SDI, logAmp=True, show=False)
    maps.append(SDI)
    SDI = pca.pca(med_hyper, angle_list=np.zeros((med_hyper.shape[1])), scale_list=scale_list,
                  mask_center_px=None,adimsdi='double', ncomp=7, ncomp2=None, collapse='median')#, ncomp2=3)#,
    # quicklook_im(SDI, logAmp=True, show=True)
    maps.append(SDI)
    # SDI = pca.pca(slow_hyper, angle_list=np.zeros((slow_hyper.shape[1])), scale_list=scale_list,
    #               mask_center_px=None,adimsdi='double', ncomp=7, ncomp2=None, collapse='median')#, ncomp2=3)#,
    # # quicklook_im(SDI, logAmp=True)
    # maps.append(SDI)

    dprint((fast_hyper.shape, med_hyper.shape, slow_hyper.shape, psf_template.shape))
    indep_images(maps, logAmp=True)
    plt.show()
    # fast_hyper = fast_hyper[:,:10]
    method_out = eval_method(fast_hyper, pca.pca,psf_template,
                                           np.zeros((fast_hyper.shape[1])), algo_dict,
                                           fwhm=lod, star_phot=star_phot)
    plotdata.append(method_out[0])
    maps.append(method_out[1])
    # #
    method_out = eval_method(med_hyper, pca.pca,psf_template,
                                           np.zeros((med_hyper.shape[1])), algo_dict,
                                           fwhm=lod, star_phot=star_phot)
    plotdata.append(method_out[0])
    maps.append(method_out[1])
    #
    method_out = eval_method(slow_hyper, pca.pca,psf_template,
                                           np.zeros((slow_hyper.shape[1])), algo_dict,
                                           fwhm=lod, star_phot=star_phot)
    plotdata.append(method_out[0])
    maps.append(method_out[1])


    # method_out = eval_method(v_slow_hyper, pca.pca, np.zeros((v_slow_hyper.shape[1])), algo_dict)
    # plotdata.append(method_out[0])
    # maps.append(method_out[1])


    # Plotting
    plotdata = np.array(plotdata)
    # rad_samp = np.linspace(0,tp.platescale/1000.*plotdata.shape[2],plotdata.shape[2])
    rad_samp = np.linspace(0,tp.platescale/1000.*100,plotdata.shape[2])
    fig, axes = plt.subplots(nrows=1, ncols=3, figsize=(14, 3.4))
    for thruput in plotdata[:,0]:
        axes[0].plot(rad_samp,thruput)
    for noise in plotdata[:,1]:
        axes[1].plot(rad_samp,noise)
    for cont in plotdata[:,2]:
        axes[2].plot(rad_samp,cont)
    for ax in axes:
        ax.set_yscale('log')
        ax.set_xlabel('Radial Separation')
        ax.tick_params(direction='in',which='both', right=True, top=True)
    axes[0].set_ylabel('Throughput')
    axes[1].set_ylabel('Noise')
    axes[2].set_ylabel('5$\sigma$ Contrast')
    axes[2].legend(['Fast','Med','Slow'])

    # plt.show()
    indep_images(maps, logAmp=True)
    plt.show()

    # Plot just contrast curves
    # rad_samp = np.linspace(0, tp.platescale / 1000. * (plotdata.shape[2]-6), plotdata.shape[2]-6)
    rad_samp = np.linspace(0, tp.platescale / 1000. * 100, plotdata.shape[2])
    fig, axes = plt.subplots(nrows=1, ncols=1, figsize=(6, 6))
    for cont in plotdata[:, 2]:
        # dprint((len(cont[:-6]), plotdata.shape[2]-6))
        axes.plot(rad_samp, cont, '-')
        # axes.plot(rad_samp[:-3], cont[:-9], '-o')
        # axes.plot(rad_samp[-4:-2], cont[-10:-8], '--')
    axes.plot([0.4, 0.65, 0.9], [1e-4,1e-4,1e-4], 'o')
    axes.set_yscale('log')
    axes.set_xlabel('Radial Separation')
    axes.tick_params(direction='in',which='both', right=True, top=True)
    axes.set_ylabel('5$\sigma$ Contrast')
    axes.legend(['Fast', 'Med', 'Slow', 'Companions'])

    plt.show()