'''This code handles the relevant functionality of a Hawaii 2RG camera'''
import sys
sys.path.append('D:/dodkins/MEDIS/MEDIS')
import numpy as np
from params import ap, cp, tp, sp, iop, hp
import cPickle as pickle
import os
from Utils.plot_tools import loop_frames, quicklook_im, view_datacube, compare_images
from vip_hci import phot, pca
from Utils.misc import debug_program
from medis.Detector.get_photon_data import run
import Detector.readout as read
import Detector.H2RG as H2RG
import Detector.pipeline as pipe
import matplotlib.pyplot as plt
from Utils.misc import dprint

# def get_hypercube(plot=False):
#     print os.path.isfile(binnedHyperCubeFile), binnedHyperCubeFile
#     if os.path.isfile(binnedHyperCubeFile):
#         hypercube = read.open_hypercube(HyperCubeFile=binnedHyperCubeFile)
#     else:
#         hypercube = run()
#         print 'finished run'
#         print np.shape(hypercube)
#         if plot: view_datacube(hypercube[0], logAmp=True)
#
#         if tp.detector == 'H2RG':
#             hypercube = H2RG.scale_to_luminos(hypercube)
#             if plot: view_datacube(hypercube[0], logAmp=True)
#
#         hypercube = read.take_exposure(hypercube)
#         if tp.detector == 'H2RG':
#              hypercube = H2RG.add_readnoise(hypercube)
#              # if plot: view_datacube(hypercube[0], logAmp=True)
#
#         if plot: view_datacube(hypercube[0], logAmp=True)
#         # datacube = pipe.stack_hypercube(hypercube)
#         # if plot: view_datacube(datacube, logAmp=True)
#         read.save_hypercube(hypercube, HyperCubeFile=binnedHyperCubeFile)
#     # hypercube = take_exposure(hypercube)
#     print np.shape(hypercube)
#     # quicklook_im(hypercube[0,0])
#     # hypercube = H2RG.add_readnoise(hypercube)
#     view_datacube(hypercube[0], logAmp=True)
#     if plot: loop_frames(hypercube[:, 0])
#     if plot: loop_frames(hypercube[0])
#     return hypercube
# debug_program()

def eval_method(cube, algo, angle_list, algo_dict):
    dprint(star_phot)
    fulloutput = phot.contrcurve.contrast_curve(cube=cube,
                                   angle_list=angle_list, psf_template=psf_template,
                                   fwhm=lod, pxscale=tp.platescale/1000,
                                   starphot=star_phot, algo=algo,wedge=(0,360),
                                   debug=False, plot=False, theta=theta,full_output=True,fc_snr=10, **algo_dict)
    plt.show()
    metrics = [fulloutput[0]['throughput'], fulloutput[0]['noise'], fulloutput[0]['sensitivity (Student)']]
    metrics = np.array(metrics)
    return metrics, fulloutput[3]

sp.save_obs = False
sp.show_cube = False
sp.return_cube = True
sp.show_wframe = False
ap.companion=False
sp.num_processes = 20
iop.date = '180627'#'180407/'
iop.update(iop.date)
theta = 45
lod = 8


# ************************ H2RG ****************************
tp.detector = 'H2RG'
tp.NCPA_type = 'Static'#'Wave'

#  ++++++++ H2RG - Ref_PSF ++++++++
iop.hyperFile = iop.datadir+'/nocomp_BinH2RG_noCoron_hyper.pkl'
tp.occulter_type = 'None'
num_exp = 10
ap.exposure_time = 0.01#0.001
ap.numframes = int(num_exp * ap.exposure_time / cp.frame_time)
tp.nwsamp = 1
hp.use_readnoise = False
# Yup this is 'if' is necessary
if __name__ == '__main__':
    hypercube = read.get_integ_hypercube(plot=False)
    # view_datacube(hypercube[0], logAmp=False)
    psf_template = hypercube[0,0]
    psf_template = psf_template[:-1,:-1]
    star_phot = phot.contrcurve.aperture_flux(psf_template,[64],[64],lod,1)[0]/ap.numframes
#  +++++++++++++++++++++++++++++++

plotdata, maps = [], []
readnoises = [0.1,1,5,10,30]
for rn in [50]:#readnoises:
    #  ++++++++ H2RG - Full Obs ++++++
    iop.hyperFile = iop.datadir+'/nocompnorm_BinH2RG_with_coron_hyper_%i.pkl' %rn
    tp.occulter_type = 'Gaussian'
    tp.nwsamp = 10
    hp.readnoise = rn
    if __name__ == '__main__':
        hypercube = read.get_integ_hypercube(plot=False)
        # view_datacube(hypercube[0], logAmp=True)
        wsamples = np.linspace(tp.band[0], tp.band[1], tp.nwsamp)
        scale_list = tp.band[0] / wsamples
        print scale_list
        algo_dict = {'scale_list': scale_list}
        # datacube = hypercube[0]
        datacube = (read.take_exposure(hypercube)/ap.numframes)[0]
        # star_phots = star_phot
        angle_list = np.zeros((len(hypercube[0])))
        print datacube.shape
        method_out = eval_method(datacube, pca.pca, angle_list, algo_dict)
        plotdata.append(method_out[0])
        maps.append(method_out[1])
        # quicklook_im(method_out[1])
    # +++++++++++++++++++++++++++++++
    # *********************************************************

# if __name__ == "__main__":
#     plotdata = np.array(plotdata)
#     rad_samp = np.linspace(0,tp.platescale/1000.*plotdata.shape[2],plotdata.shape[2])
#     fig, axes = plt.subplots(nrows=1, ncols=3, figsize=(14, 3.4))
#     for thruput in plotdata[:,0]:
#         axes[0].plot(rad_samp,thruput)
#     for noise in plotdata[:,1]:
#         axes[1].plot(rad_samp,noise)
#     for cont in plotdata[:,2]:
#         axes[2].plot(rad_samp,cont)
#     for ax in axes:
#         ax.set_yscale('log')
#         ax.set_xlabel('Radial Separation')
#         ax.tick_params(direction='in',which='both', right=True, top=True)
#     axes[0].set_ylabel('Throughput')
#     axes[1].set_ylabel('Noise')
#     axes[2].set_ylabel('5$\sigma$ Contrast')
#     axes[2].legend(readnoises)#['RDI','ADI','SDI','DSI','SSD'])
#
#     compare_images(maps, logAmp=True)
#     plt.show()



# ************************ MKIDs ****************************
tp.detector = 'MKIDs'
tp.NCPA_type = 'Static'
ap.star_photons = int(1e6)

# #  ++++++++ MKIDs - Ref_PSF ++++++++
iop.hyperFile = iop.datadir+'/BinMKIDs_noCoron_hyper.pkl'
tp.occulter_type = 'None'
num_exp = 100
ap.exposure_time =0.001# 0.01
ap.numframes = int(num_exp * ap.exposure_time / cp.frame_time)
tp.nwsamp = 1
# # Yup this 'if' is necessary
if __name__ == '__main__':
    hypercube = read.get_integ_hypercube(plot=False)
    # view_datacube(hypercube[0], logAmp=True)
    psf_template = hypercube[0, 0]
    psf_template = psf_template[:-1, :-1]
    star_phot = phot.contrcurve.aperture_flux(psf_template, [64], [64], lod, 1)[0] / ap.numframes
#  +++++++++++++++++++++++++++++++


#  ++++++++ MKIDs - Full Obs ++++++
iop.hyperFile = iop.datadir+'/nocompnorm_BinMKIDs_with_coron_hyper.pkl'
tp.occulter_type = 'Gaussian'
tp.nwsamp = 10


if __name__ == '__main__':
    hypercube = read.get_integ_hypercube(plot=False)
    # view_datacube(hypercube[0], logAmp=True)
    wsamples = np.linspace(tp.band[0], tp.band[1], tp.nwsamp)
    scale_list = tp.band[0] / wsamples
    print scale_list
    algo_dict = {'scale_list': scale_list[::-1]}
    # datacube = hypercube[0]
    datacube = (read.take_exposure(hypercube) / ap.numframes)[0]
    # star_phots = star_phot
    angle_list = np.zeros((len(hypercube[0])))
    print datacube.shape
    method_out = eval_method(datacube, pca.pca, angle_list, algo_dict)
    # quicklook_im(method_out[1])
    plotdata.append(method_out[0])
    maps.append(method_out[1])
#  +++++++++++++++++++++++++++++++
# *********************************************************

if __name__ == "__main__":
    plotdata = np.array(plotdata)
    rad_samp = np.linspace(0,tp.platescale/1000.*plotdata.shape[2],plotdata.shape[2])
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
    axes[2].legend(readnoises)#['RDI','ADI','SDI','DSI','SSD'])

    compare_images(maps, logAmp=True)
    plt.show()