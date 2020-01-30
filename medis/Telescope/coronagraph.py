import os
import proper
import numpy as np
import matplotlib.pylab as plt
from medis.Utils.plot_tools import quicklook_wf, quicklook_im
from scipy.ndimage.interpolation import shift
from astropy.io.fits import getdata, writeto
import cv2
from medis.params import ap, tp, iop
from medis.Utils.misc import dprint
import math
from skimage.transform import resize


def readfield(path, filename):

    try:
        data_r, hdr = getdata(path + filename + '_r.fits', header=True)
        data_i = getdata(path + filename + '_i.fits')
    except:
        dprint('FileNotFoundError. Waiting...')
        import time
        time.sleep(10)
        data_r, hdr = getdata(path + filename + '_r.fits', header=True)
        data_i = getdata(path + filename + '_i.fits')

    field = np.array(data_r, dtype=complex)
    field.imag = data_i


    return(field)

def writefield(path, filename, field):

    writeto(path + filename + '_r.fits', field.real, header=None, overwrite=True)
    writeto(path + filename + '_i.fits', field.imag, header=None, overwrite=True)

    return


def coronagraph(wfo, f_lens, occulter_type, occult_loc, diam):
    # proper.prop_lens(wfo, f_lens, "coronagraph imaging lens")
    # proper.prop_propagate(wfo, f_lens, "occulter")
    # quicklook_wf(wfo)
    # occulter sizes are specified here in units of lambda/diameter;
    # convert lambda/diam to radians then to meters

    lamda = proper.prop_get_wavelength(wfo)
    # print lamda
    occrad = 3                           # occulter radius in lam/D
    occrad_rad = occrad * lamda / diam    # occulter radius in radians
    dx_m = proper.prop_get_sampling(wfo)
    dx_rad = proper.prop_get_sampling_radians(wfo)    
    occrad_m = occrad_rad * dx_m / dx_rad  # occulter radius in meters
    # print occrad_m, occulter_type
    # print 'line 22.', occulter_type
    #plt.figure(figsize=(12,8))
    # quicklook_wf(wfo)
    if occulter_type == "Gaussian":
        r = proper.prop_radius(wfo)
        h = np.sqrt(-0.5 * occrad_m**2 / np.log(1 - np.sqrt(0.5)))#*0.8
        gauss_spot = 1 - np.exp(-0.5 * (r/h)**2)
        # print occult_loc
        # gauss_spot = np.roll(gauss_spot,occult_loc,(0,1))
        gauss_spot = shift(gauss_spot,shift=occult_loc,mode='wrap')
        proper.prop_multiply(wfo, gauss_spot)
        # quicklook_wf(wfo)
        #plt.suptitle("Gaussian spot", fontsize = 18)
    elif occulter_type == "Solid":
        proper.prop_circular_obscuration(wfo, occrad_m*4./3)
        #plt.suptitle("Solid spot", fontsize = 18)
        # quicklook_wf(wfo)
    elif occulter_type == "8th_Order":
        proper.prop_8th_order_mask(wfo, occrad*3./4., CIRCULAR = True)
        # quicklook_wf(wfo)
    elif occulter_type == 'Vortex':
        # print('lol')
        # apodization(wfo, True)
        vortex(wfo)
        # quicklook_wf(wfo)
        # lyotstop(wfo, True)

        #plt.suptitle("8th order band limited spot", fontsize = 18)
    # quicklook_wf(wfo, logAmp=False, show=True)
    # After occulter
    # plt.subplot(1,2,1)
    # plt.imshow(np.sqrt(proper.prop_get_amplitude(wfo)), origin = "lower", cmap = plt.cm.gray)
    # plt.text(200, 10, "After Occulter", color = "w")
    # plt.show()
    # quicklook_wf(wfo)

    proper.prop_propagate(wfo, f_lens, "pupil reimaging lens")
    # quicklook_wf(wfo)
    proper.prop_lens(wfo, f_lens, "pupil reimaging lens")
    # quicklook_wf(wfo)
    proper.prop_propagate(wfo, 2*f_lens, "lyot stop")
    # quicklook_wf(wfo)

    # from numpy.fft import fft2, ifft2
    # wfo.wfarr = fft2(wfo.wfarr) #/ np.size(wfo.wfarr)
    # quicklook_wf(wfo)

    # plt.subplot(1,2,2)        
    # plt.imshow(proper.prop_get_amplitude(wfo)**0.2, origin = "lower", cmap = plt.cm.gray)
    # plt.text(200, 10, "Before Lyot Stop", color = "w")
    # plt.show()   
    # quicklook_wf(wfo,logAmp=False, show=True)

    if occulter_type == "Gaussian":
        # quicklook_wf(wfo)
        proper.prop_circular_aperture(wfo, 0.75, NORM = True)
    elif occulter_type == "Solid":
        # quicklook_wf(wfo)
        proper.prop_circular_aperture(wfo, 0.84, NORM = True)
    elif occulter_type == "8th_Order":
        # quicklook_wf(wfo)
        proper.prop_circular_aperture(wfo, 0.75, NORM = True) #0.5
    elif occulter_type == "Vortex":
        # proper.prop_circular_aperture(wfo, 0.98, NORM = True) #0.5
        # quicklook_wf(wfo, logAmp=False)
        lyotstop(wfo,True)
        # quicklook_wf(wfo, logAmp=False)
    elif occulter_type == "None (Lyot Stop)":
        proper.prop_circular_aperture(wfo, 0.8, NORM=True)

    proper.prop_propagate(wfo, f_lens, "reimaging lens")
    # errs = np.sqrt(proper.prop_get_amplitude(wfo))
    # # plt.figure()
    # # plt.imshow(errs)
    # # plt.show()
    # quicklook_wf(wfo)
    proper.prop_lens(wfo, f_lens, "reimaging lens")
    # quicklook_wf(wfo)
    proper.prop_propagate(wfo, f_lens, "final focus")
    # from numpy.fft import fft2, ifft2
    # wfo.wfarr = fft2(wfo.wfarr) / np.size(wfo.wfarr)
    # quicklook_wf(wfo)
    return

def init_vortex():
    wfo = proper.prop_begin(tp.diam, ap.band[0], ap.grid_size, tp.beam_ratio)

def vortex(wfo):
    # https://github.com/vortex-exoplanet/HEEPS/tree/master/heeps
    n = int(proper.prop_get_gridsize(wfo))
    ofst = 0  # no offset
    ramp_sign = 1  # sign of charge is positive
    ramp_oversamp = 11.  # vortex is oversampled for a better discretization

    # f_lens = tp.f_lens #conf['F_LENS']
    # diam = tp.diam#conf['DIAM']
    charge = 2#conf['CHARGE']
    pixelsize = 5#conf['PIXEL_SCALE']
    Debug_print = False#conf['DEBUG_PRINT']

    if not os.path.exists(iop.coron_temp):
        os.mkdir(iop.coron_temp)

    if charge != 0:
        wavelength = proper.prop_get_wavelength(wfo)
        gridsize = proper.prop_get_gridsize(wfo)
        beam_ratio = pixelsize * 4.85e-9 / (wavelength / tp.diam)
        # dprint((wavelength,gridsize,beam_ratio))
        calib = str(charge) + str('_') + str(int(beam_ratio * 100)) + str('_') + str(gridsize)
        my_file = str(iop.coron_temp + 'zz_perf_' + calib + '_r.fits')

        # proper.prop_propagate(wfo, tp.f_lens, 'inizio')  # propagate wavefront
        # proper.prop_lens(wfo, tp.f_lens, 'focusing lens vortex')  # propagate through a lens
        # proper.prop_propagate(wfo, tp.f_lens, 'VC')  # propagate wavefront
        # quicklook_wf(wfo)
        # print proper.prop_get_phase(wfo)[0,0]
        # proper.prop_add_phase(wfo, np.ones((ap.grid_size, ap.grid_size)) * -1)
        # quicklook_wf(wfo)
        # print proper.prop_get_phase(wfo)[0,0]
        # proper.prop_add_phase(wfo, np.ones((ap.grid_size, ap.grid_size)) * -1)
        # quicklook_wf(wfo)
        # print proper.prop_get_phase(wfo)[0,0]
        # proper.prop_add_phase(wfo, np.ones((ap.grid_size, ap.grid_size))*-proper.prop_get_phase(wfo)[0,0])
        # quicklook_wf(wfo)

        if (os.path.isfile(my_file) == True):
            if (Debug_print == True):
                print ("Charge ", charge)
            vvc = readfield(iop.coron_temp, 'zz_vvc_' + calib)  # read the theoretical vortex field
            vvc = proper.prop_shift_center(vvc)
            scale_psf = wfo._wfarr[0, 0]
            psf_num = readfield(iop.coron_temp, 'zz_psf_' + calib)  # read the pre-vortex field
            psf0 = psf_num[0, 0]
            psf_num = psf_num / psf0 * scale_psf
            perf_num = readfield(iop.coron_temp, 'zz_perf_' + calib)  # read the perfect-result vortex field
            perf_num = perf_num / psf0 * scale_psf
            wfo._wfarr = (
                         wfo._wfarr - psf_num) * vvc + perf_num  # the wavefront takes into account the real pupil with the perfect-result vortex field

        else:  # CAL==1: # create the vortex for a perfectly circular pupil
            if (Debug_print == True):
                print ("Charge ", charge)

            wfo1 = proper.prop_begin(tp.diam, wavelength, gridsize, beam_ratio)
            proper.prop_circular_aperture(wfo1, tp.diam / 2)
            proper.prop_define_entrance(wfo1)
            proper.prop_propagate(wfo1, tp.f_lens, 'inizio')  # propagate wavefront
            proper.prop_lens(wfo1, tp.f_lens, 'focusing lens vortex')  # propagate through a lens
            proper.prop_propagate(wfo1, tp.f_lens, 'VC')  # propagate wavefront

            writefield(iop.coron_temp, 'zz_psf_' + calib, wfo1.wfarr)  # write the pre-vortex field
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
            writefield(iop.coron_temp, 'zz_vvc_' + calib, vvc)  # write the theoretical vortex field

            proper.prop_multiply(wfo1, vvc)
            proper.prop_propagate(wfo1, tp.f_lens, 'OAP2')
            proper.prop_lens(wfo1, tp.f_lens)
            proper.prop_propagate(wfo1, tp.f_lens, 'forward to Lyot Stop')
            proper.prop_circular_obscuration(wfo1, 1., NORM=True)  # null the amplitude iside the Lyot Stop
            proper.prop_propagate(wfo1, -tp.f_lens)  # back-propagation
            proper.prop_lens(wfo1, -tp.f_lens)
            proper.prop_propagate(wfo1, -tp.f_lens)
            writefield(iop.coron_temp, 'zz_perf_' + calib, wfo1.wfarr)  # write the perfect-result vortex field

            vvc = readfield(iop.coron_temp, 'zz_vvc_' + calib)
            vvc = proper.prop_shift_center(vvc)
            scale_psf = wfo._wfarr[0, 0]
            psf_num = readfield(iop.coron_temp, 'zz_psf_' + calib)  # read the pre-vortex field
            psf0 = psf_num[0, 0]
            psf_num = psf_num / psf0 * scale_psf
            perf_num = readfield(iop.coron_temp, 'zz_perf_' + calib)  # read the perfect-result vortex field
            perf_num = perf_num / psf0 * scale_psf
            wfo._wfarr = (
                         wfo._wfarr - psf_num) * vvc + perf_num  # the wavefront takes into account the real pupil with the perfect-result vortex field
        # quicklook_wf(wfo)
        # proper.prop_propagate(wfo, tp.f_lens, "propagate to pupil reimaging lens")
        # proper.prop_lens(wfo, tp.f_lens, "apply pupil reimaging lens")
        # proper.prop_propagate(wfo, tp.f_lens, "lyot stop")

    return wfo

def circular_apodization(wf, radius, t_in, t_out, xc = 0.0, yc = 0.0, **kwargs):

    if ("NORM" in kwargs and kwargs["NORM"]):
        norm = True
    else:
        norm = False

    if (t_in > t_out):
        apodizer = proper.prop_shift_center(proper.prop_ellipse(wf, radius, radius, xc, yc, NORM = norm))*(t_in-t_out)+t_out
    else:
         apodizer = proper.prop_shift_center(proper.prop_ellipse(wf, radius, radius, xc, yc, NORM = norm))*(t_out-t_in)+t_in

    return apodizer

def apodization(wf, RAVC=False, phase_apodizer_file=0, amplitude_apodizer_file=0, apodizer_misalignment=0,
                Debug_print=False):

    r_obstr = 0.15#0.15#conf['R_OBSTR']
    npupil = 1#conf['NPUPIL']

    apodizer_misalignment = np.zeros((6))#np.array(conf['RAVC_MISALIGN'])
    n = int(proper.prop_get_gridsize(wf))
    apodizer = 1
    if (RAVC == True):
        t1_opt = 1. - 1. / 4 * (r_obstr ** 2 + r_obstr * (
            math.sqrt(r_obstr ** 2 + 8.)))  # define the apodizer transmission [Mawet2013]
        R1_opt = (r_obstr / math.sqrt(1. - t1_opt))  # define the apodizer radius [Mawet2013]
        if (Debug_print == True):
            print("r1_opt: ", R1_opt)
            print("t1_opt: ", t1_opt)
        apodizer = circular_apodization(wf, R1_opt, 1., t1_opt, xc=apodizer_misalignment[0],
                                        yc=apodizer_misalignment[1], NORM=True)  # define the apodizer
        apodizer = proper.prop_shift_center(apodizer)
        # quicklook_im(apodizer, logAmp=False)

    if (isinstance(phase_apodizer_file, (list, tuple, np.ndarray)) == True):
        xc_pixels = int(apodizer_misalignment[3] * npupil)
        yc_pixels = int(apodizer_misalignment[4] * npupil)
        apodizer_pixels = (phase_apodizer_file.shape)[0]  ## fits file size
        scaling_factor = float(npupil) / float(
            apodizer_pixels)  ## scaling factor between the fits file size and the pupil size of the simulation
        if (Debug_print == True):
            print("scaling_factor: ", scaling_factor)
        apodizer_scale = resize(phase_apodizer_file.astype(np.float32), (npupil, npupil), preserve_range=True,
                                mode='reflect')
        if (Debug_print == True):
            print("apodizer_resample", apodizer_scale.shape)
        apodizer_large = np.zeros((n, n))  # define an array of n-0s, where to insert the pupuil
        if (Debug_print == True):
            print("n: ", n)
            print("npupil: ", npupil)
        apodizer_large[int(n / 2) + 1 - int(npupil / 2) - 1 + xc_pixels:int(n / 2) + 1 + int(npupil / 2) + xc_pixels,
        int(n / 2) + 1 - int(npupil / 2) - 1 + yc_pixels:int(n / 2) + 1 + int(
            npupil / 2) + yc_pixels] = apodizer_scale  # insert the scaled pupil into the 0s grid
        apodizer = np.exp(1j * apodizer_large)

    if (isinstance(amplitude_apodizer_file, (list, tuple, np.ndarray)) == True):
        xc_pixels = int(apodizer_misalignment[0] * npupil)
        yc_pixels = int(apodizer_misalignment[1] * npupil)
        apodizer_pixels = (amplitude_apodizer_file.shape)[0]  ## fits file size
        scaling_factor = float(npupil) / float(
            apodizer_pixels)  ## scaling factor between the fits file size and the pupil size of the simulation
        if (Debug_print == True):
            print("scaling_factor: ", scaling_factor)
        apodizer_scale = resize(amplitude_apodizer_file.astype(np.float32), (npupil, npupil), preserve_range=True,
                                mode='reflect')
        if (Debug_print == True):
            print("apodizer_resample", apodizer_scale.shape)
        apodizer_large = np.zeros((n, n))  # define an array of n-0s, where to insert the pupuil
        if (Debug_print == True):
            print("n: ", n)
            print("npupil: ", npupil)
        apodizer_large[int(n / 2) + 1 - int(npupil / 2) - 1 + xc_pixels:int(n / 2) + 1 + int(npupil / 2) + xc_pixels,
        int(n / 2) + 1 - int(npupil / 2) - 1 + yc_pixels:int(n / 2) + 1 + int(
            npupil / 2) + yc_pixels] = apodizer_scale  # insert the scaled pupil into the 0s grid
        apodizer = apodizer_large
    # quicklook_wf(wf)
    proper.prop_multiply(wf, apodizer)
    # quicklook_wf(wf)

    return wf


def lyotstop(wf,  RAVC=None, APP=None, get_pupil='no', dnpup=50):
    """Add a Lyot stop, or an APP."""

    # load parameters
    npupil = 1#conf['NPUPIL']
    pad = int((210 - npupil) / 2)

    # get LS misalignments
    LS_misalignment = (np.array([0.0, 0.0, 0.0, 0.0, 0.0, 0.0]) * npupil).astype(int)
    dx_amp, dy_amp, dz_amp = LS_misalignment[0:3]
    dx_phase, dy_phase, dz_phase = LS_misalignment[3:6]

    # case 1: Lyot stop (no APP)
    if APP is not True:

        # Lyot stop parameters: R_out, dR_in, spi_width
        # outer radius (absolute %), inner radius (relative %), spider width (m)
        (R_out, dR_in, spi_width) = [0.98, 0.03, 0]

        # Lyot stop inner radius at least as large as obstruction radius
        R_in = 0.15

        # case of a ring apodizer
        if RAVC is True:
            # define the apodizer transmission and apodizer radius [Mawet2013]
            # apodizer radius at least as large as obstruction radius
            T_ravc = 1 - (R_in ** 2 + R_in * np.sqrt(R_in ** 2 + 8)) / 4
            R_in /= np.sqrt(1 - T_ravc)

        # oversize Lyot stop inner radius
        R_in += dR_in

        # create Lyot stop
        proper.prop_circular_aperture(wf, R_out, dx_amp, dy_amp, NORM=True)
        if R_in > 0:
            proper.prop_circular_obscuration(wf, R_in, dx_amp, dy_amp, NORM=True)
        if spi_width > 0:
            for angle in [10]:
                proper.prop_rectangular_obscuration(wf, 0.05 * 8, 8 * 1.3, ROTATION=20)
                proper.prop_rectangular_obscuration(wf, 8 * 1.3, 0.05 * 8, ROTATION=20)
                # proper.prop_rectangular_obscuration(wf, spi_width, 2 * 8, \
                #                                     dx_amp, dy_amp, ROTATION=angle)

    # case 2: APP (no Lyot stop)
    else:
        # get amplitude and phase files
        APP_amp_file = os.path.join(conf['INPUT_DIR'], conf['APP_AMP_FILE'])
        APP_phase_file = os.path.join(conf['INPUT_DIR'], conf['APP_PHASE_FILE'])
        # get amplitude and phase data
        APP_amp = fits.getdata(APP_amp_file) if os.path.isfile(APP_amp_file) \
            else np.ones((npupil, npupil))
        APP_phase = fits.getdata(APP_phase_file) if os.path.isfile(APP_phase_file) \
            else np.zeros((npupil, npupil))
        # resize to npupil
        APP_amp = resize(APP_amp, (npupil, npupil), preserve_range=True, mode='reflect')
        APP_phase = resize(APP_phase, (npupil, npupil), preserve_range=True, mode='reflect')
        # pad with zeros to match PROPER gridsize
        APP_amp = np.pad(APP_amp, [(pad + 1 + dx_amp, pad - dx_amp), \
                                   (pad + 1 + dy_amp, pad - dy_amp)], mode='constant')
        APP_phase = np.pad(APP_phase, [(pad + 1 + dx_phase, pad - dx_phase), \
                                       (pad + 1 + dy_phase, pad - dy_phase)], mode='constant')
        # multiply the loaded APP
        proper.prop_multiply(wf, APP_amp * np.exp(1j * APP_phase))

    # get the pupil amplitude or phase for output
    if get_pupil.lower() in 'amplitude':
        return wf, proper.prop_get_amplitude(wf)[pad + 1 - dnpup:-pad + dnpup, pad + 1 - dnpup:-pad + dnpup]
    elif get_pupil.lower() in 'phase':
        return wf, proper.prop_get_phase(wf)[pad + 1 - dnpup:-pad + dnpup, pad + 1 - dnpup:-pad + dnpup]
    else:
        return wf