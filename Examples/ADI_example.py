'''This code handles the relevant functionality of a Hawaii 2RG camera'''
import sys
# sys.path.append('D:/dodkins/MEDIS/MEDIS')
import numpy as np
from medis.params import ap, cp, tp, sp, mp, iop
import cPickle as pickle
import os
from medis.Utils.plot_tools import loop_frames, quicklook_im, view_datacube, compare_images
from medis.Utils.misc import debug_program
from medis.Detector.get_photon_data import run
import medis.Detector.readout as read
import medis.Detector.H2RG as H2RG
from medis.Utils.rawImageIO import clipped_zoom
import medis.Analysis.phot as phot
# import proper


mp.date = '180411/'
iop.update(mp.date)
if __name__ == '__main__':
    psf_template = phot.make_fake_psf()[0,0]
    psf_template = psf_template[:-1,:-1]
    # quicklook_im(psf_template)

sp.save_obs = False
sp.show_cube = False
sp.return_cube = True
sp.show_wframe = False
ap.companion=True
# sp.num_processes = 1
ap.companion = True
ap.contrast = [0.01]#[0.1,0.1]
ap.lods = [[-2.5,2.5]]
tp.detector = 'ideal'
tp.NCPA_type = None#'Static'
tp.CPA_type = None#'Static'
tp.use_spiders = True
tp.use_ao = True
tp.occulter_type = 'GAUSSIAN'
tp.piston_error = False
tp.band = np.array([860,1250])
tp.nwsamp = 1
tp.rot_rate = 450 # deg/s
num_exp = 10
ap.exposure_time = 0.001#0.001
ap.numframes = int(num_exp * ap.exposure_time / cp.frame_time)


# binnedHyperCubeFile = os.path.join(mp.rootdir,mp.proc_dir, mp.date, './BinH2RG_with_coron_hyper.pkl')
iop.hyperFile = iop.datadir + '/rotateHyper.pkl'
wsamples = np.linspace(tp.band[0], tp.band[1], tp.nwsamp)
scale_list = tp.band[0] / wsamples


if __name__ == '__main__':
    hypercube = read.get_integ_hypercube(plot=False)

    import matplotlib.pyplot as plt

    # psf_template = hypercube[0,0,20:31,98:109]
    # print scale_list[5], 'SL'

    # quicklook_im(hypercube[0,0])
    # quicklook_im(psf_template)

    from vip_hci import phot, pca
    star_phot = phot.contrcurve.aperture_flux(psf_template,[64],[64],10,1)
    star_phot = np.ones((hypercube.shape[0]))*star_phot
    print star_phot, 'star_phot'
    algo_dict = {'scale_list':scale_list}
    # res_throug = phot.contrcurve.throughput(hypercube[0], angle_list=np.zeros((len(hypercube[0]))), psf_template=psf_template, fwhm=10, pxscale=0.13,
    #                         algo = pca.pca,full_output=True, **algo_dict)
    # print res_throug[3].shape
    # loop_frames(res_throug[3][0])
    # loop_frames(res_throug[3][:,0])
    # plt.plot(res_throug[0][0])
    # plt.show()
    phot.contrcurve.contrast_curve(cube=hypercube[:,0], angle_list=-1*np.arange(0,num_exp*tp.rot_rate*cp.frame_time,tp.rot_rate*cp.frame_time), psf_template=psf_template, fwhm=10, pxscale=0.13, starphot=star_phot, algo=pca.pca, debug=True)


    # from vip_hci import pca
    # loop_frames(hypercube[:,0])
    ADI = pca.pca(hypercube[:,0], angle_list=-1*np.arange(0,num_exp*tp.rot_rate*cp.frame_time,tp.rot_rate*cp.frame_time))#, scale_list=np.ones((len(hypercube[:,0]))), mask_center_px=None)

    quicklook_im(ADI)
    ADI = ADI.reshape(1,128,128)

    wsamples = np.linspace(tp.band[0], tp.band[1], tp.nwsamp)
    scale_list = tp.band[0] / wsamples
    print scale_list, scale_list[-1], 'SL', 1./scale_list[-1]
    wframe = clipped_zoom(hypercube[0,0], 1./scale_list[-1])
    quicklook_im(wframe)
    wframe = wframe.reshape(1,128,128)
    cube = np.vstack((hypercube[0,[0,-1]],wframe,SDI))
    # cube = np.dstack((hypercube[0,0],wframe,hypercube[0,-1],SDI)).transpose()
    annos = ['$\lambda_0$=860 nm','$\lambda_8=$1250 nm','$\lambda_0$ Scaled','SDI Residual']
    print 'change titles to bottom left text in figure white'
    # view_datacube(cube, logAmp=True,)
    compare_images(cube, logAmp=True, annos=annos)




