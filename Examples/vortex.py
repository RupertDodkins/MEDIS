import sys, os
sys.path.append('D:/dodkins/MEDIS/MEDIS')
import numpy as np
import proper
import cv2
from medis.params import ap, tp, iop
# import medis.Telescope.adaptive_optics as ao
from medis.Utils.plot_tools import view_datacube, quicklook_wf, quicklook_im, quicklook_IQ, loop_frames
import medis.Analysis.phot as phot

from astropy.io.fits import getdata, writeto


def readfield(path, filename):

    data_r, hdr = getdata(path + filename + '_r.fits', header=True)
    data_i = getdata(path + filename + '_i.fits')

    field = np.array(data_r, dtype=complex)
    field.imag = data_i


    return(field)

def writefield(path, filename, field):

    writeto(path + filename + '_r.fits', field.real, header=None, overwrite=True)
    writeto(path + filename + '_i.fits', field.imag, header=None, overwrite=True)

    return


tmp_dir='./'

def vortex(wfo):
    n = int(proper.prop_get_gridsize(wfo))
    ofst = 0  # no offset
    ramp_sign = 1  # sign of charge is positive
    ramp_oversamp = 11.  # vortex is oversampled for a better discretization

    f_lens = tp.f_lens#200.0 * tp.diam#658.6 #conf['F_LENS']
    diam = 8#conf['DIAM']
    charge = 2#conf['CHARGE']
    pixelsize = 5.0#conf['PIXEL_SCALE']
    Debug_print = False#conf['DEBUG_PRINT']

    if charge != 0:
        wavelength = proper.prop_get_wavelength(wfo)
        gridsize = proper.prop_get_gridsize(wfo)

        beam_ratio = pixelsize * 4.85e-9 / (wavelength / diam)
        from medis.Utils.misc import dprint
        dprint((wavelength,gridsize,beam_ratio))
        calib = str(charge) + str('_') + str(int(beam_ratio * 100)) + str('_') + str(gridsize)
        my_file = str(tmp_dir + 'zz_perf_' + calib + '_r.fits')

        proper.prop_propagate(wfo, f_lens, 'inizio')  # propagate wavefront
        proper.prop_lens(wfo, f_lens, 'focusing lens vortex')  # propagate through a lens
        proper.prop_propagate(wfo, f_lens, 'VC')  # propagate wavefront

        quicklook_wf(wfo)
        if (os.path.isfile(my_file) == True):
            if (Debug_print == True):
                print ("Charge ", charge)
            vvc = readfield(tmp_dir, 'zz_vvc_' + calib)  # read the theoretical vortex field
            vvc = proper.prop_shift_center(vvc)
            scale_psf = wfo._wfarr[0, 0]
            psf_num = readfield(tmp_dir, 'zz_psf_' + calib)  # read the pre-vortex field
            psf0 = psf_num[0, 0]
            psf_num = psf_num / psf0 * scale_psf
            perf_num = readfield(tmp_dir, 'zz_perf_' + calib)  # read the perfect-result vortex field
            perf_num = perf_num / psf0 * scale_psf
            wfo._wfarr = (
                         wfo._wfarr - psf_num) * vvc + perf_num  # the wavefront takes into account the real pupil with the perfect-result vortex field

        else:  # CAL==1: # create the vortex for a perfectly circular pupil
            if (Debug_print == True):
                print ("Charge ", charge)

            wfo1 = proper.prop_begin(diam, wavelength, gridsize, beam_ratio)
            proper.prop_circular_aperture(wfo1, diam / 2)
            proper.prop_define_entrance(wfo1)
            proper.prop_propagate(wfo1, f_lens, 'inizio')  # propagate wavefront
            proper.prop_lens(wfo1, f_lens, 'focusing lens vortex')  # propagate through a lens
            proper.prop_propagate(wfo1, f_lens, 'VC')  # propagate wavefront

            # writefield(tmp_dir, 'zz_psf_' + calib, wfo1.wfarr)  # write the pre-vortex field
            nramp = int(n * ramp_oversamp)  # oversamp
            # create the vortex by creating a matrix (theta) representing the ramp (created by atan 2 gradually varying matrix, x and y)
            y1 = np.ones((nramp,), dtype=np.int)
            y2 = np.arange(0, nramp, 1.) - (nramp / 2) - int(ramp_oversamp) / 2
            y = np.outer(y2, y1)
            x = np.transpose(y)
            theta = np.arctan2(y, x)
            x = 0
            y = 0
            vvc_tmp = np.exp(1j * (ofst + ramp_sign * charge * theta))
            theta = 0
            vvc_real_resampled = cv2.resize(vvc_tmp.real, (0, 0), fx=1 / ramp_oversamp, fy=1 / ramp_oversamp,
                                            interpolation=cv2.INTER_LINEAR)  # scale the pupil to the pupil size of the simualtions
            vvc_imag_resampled = cv2.resize(vvc_tmp.imag, (0, 0), fx=1 / ramp_oversamp, fy=1 / ramp_oversamp,
                                            interpolation=cv2.INTER_LINEAR)  # scale the pupil to the pupil size of the simualtions
            vvc = np.array(vvc_real_resampled, dtype=complex)
            vvc.imag = vvc_imag_resampled
            vvcphase = np.arctan2(vvc.imag, vvc.real)  # create the vortex phase
            vvc_complex = np.array(np.zeros((n, n)), dtype=complex)
            vvc_complex.imag = vvcphase
            vvc = np.exp(vvc_complex)
            vvc_tmp = 0.
            # writefield(tmp_dir, 'zz_vvc_' + calib, vvc)  # write the theoretical vortex field

            proper.prop_multiply(wfo1, vvc)
            proper.prop_propagate(wfo1, f_lens, 'OAP2')
            proper.prop_lens(wfo1, f_lens)
            proper.prop_propagate(wfo1, f_lens, 'forward to Lyot Stop')
            proper.prop_circular_obscuration(wfo1, 1., NORM=True)  # null the amplitude iside the Lyot Stop
            proper.prop_propagate(wfo1, -f_lens)  # back-propagation
            proper.prop_lens(wfo1, -f_lens)
            proper.prop_propagate(wfo1, -f_lens)
            # writefield(tmp_dir, 'zz_perf_' + calib, wfo1.wfarr)  # write the perfect-result vortex field

            vvc = readfield(tmp_dir, 'zz_vvc_' + calib)
            vvc = proper.prop_shift_center(vvc)
            scale_psf = wfo._wfarr[0, 0]
            psf_num = readfield(tmp_dir, 'zz_psf_' + calib)  # read the pre-vortex field
            psf0 = psf_num[0, 0]
            psf_num = psf_num / psf0 * scale_psf
            perf_num = readfield(tmp_dir, 'zz_perf_' + calib)  # read the perfect-result vortex field
            perf_num = perf_num / psf0 * scale_psf
            wfo._wfarr = (
                         wfo._wfarr - psf_num) * vvc + perf_num  # the wavefront takes into account the real pupil with the perfect-result vortex field
        quicklook_wf(wfo)
        proper.prop_propagate(wfo, f_lens, "propagate to pupil reimaging lens")
        proper.prop_lens(wfo, f_lens, "apply pupil reimaging lens")
        proper.prop_propagate(wfo, f_lens, "lyot stop")
        quicklook_wf(wfo)
    return wfo


wfo = proper.prop_begin(tp.diam, tp.band[0], tp.grid_size, tp.beam_ratio)
proper.prop_circular_aperture(wfo, tp.diam/2)
proper.prop_define_entrance(wfo)
# proper.prop_zernikes(wfo, [2, 3], np.array([3,3])*1e-6)

vortex(wfo)
# quicklook_wf(wfo)
proper.prop_circular_aperture(wfo, 0.75, NORM=True)
quicklook_wf(wfo)

proper.prop_propagate(wfo, tp.f_lens)
proper.prop_lens(wfo, tp.f_lens)

# quicklook_wf(wfo)
(wframe, sampling) = proper.prop_end(wfo)
print np.sum(phot.aper_phot(wframe,0,5, plot=True))
quicklook_im(wframe, logAmp=True)
quicklook_im(phot.aper_phot(wframe,0,5))