import os
import numpy as np
# from scipy import interpolate
import pickle as pickle
import proper
from proper_mod import prop_psd_errormap
# from medis.Utils.plot_tools import quicklook_im, quicklook_wf, loop_frames,quicklook_IQ
import medis.Atmosphere.atmos as atmos
import medis.Utils.rawImageIO as rawImageIO
import medis.Utils.misc as misc
from medis.params import tp, cp, mp, ap, iop
from medis.Utils.misc import dprint
import astropy.io.fits as fits
# import matplotlib.pylab as plt
from skimage.restoration import unwrap_phase


def initialize_CPA_meas():
    required_servo = int(tp.servo_error[0])
    required_band = int(tp.servo_error[1])
    required_nframes = required_servo + required_band + 1
    CPA_maps = np.zeros((required_nframes, ap.nwsamp, ap.grid_size, ap.grid_size))

    with open(iop.CPA_meas, 'wb') as handle:
        pickle.dump((CPA_maps, np.arange(0,-required_nframes,-1)), handle, protocol=pickle.HIGHEST_PROTOCOL)


def initialize_NCPA_meas():
    Imaps = np.zeros((4, ap.grid_size, ap.grid_size))
    phase_map = np.zeros((tp.ao_act,tp.ao_act))  # np.zeros((ap.grid_size,ap.grid_size))
    with open(iop.NCPA_meas, 'wb') as handle:
        pickle.dump((Imaps, phase_map, 0), handle, protocol=pickle.HIGHEST_PROTOCOL)


def abs_zeros(wf_array):
    """zeros everything outside the pupil"""
    shape = wf_array.shape
    for iw in range(shape[0]):
        for io in range(shape[1]):
            bad_locs = np.logical_or(np.real(wf_array[iw,io].wfarr) == -0,
                                     np.imag(wf_array[iw,io].wfarr) == -0)
            wf_array[iw,io].wfarr[bad_locs] = 0 +0j

    return wf_array


def generate_maps(lens_diam, lens_name='lens'):
    """
    generate PSD-defined aberration maps for a lens(mirror) using Proper

    Use Proper to generate an 2D aberration pattern across an optical element. The amplitude of the error per spatial
     frequency (cycles/m) across the surface is taken from a power spectral density (PSD) of statistical likelihoods
     for 'real' aberrations of physical optics.
    parameters defining the PSD function are specified in tp.aber_vals. These limit the range for the constants of the
     governing equation given by PSD = a/ [1+(k/b)^c]. This formula assumes the Terrestrial Planet Finder PSD, which is
     set to TRUE unless manually overridden line-by-line. As stated in the proper manual, this PSD function general
      under-predicts lower order aberrations, and thus Zernike polynomials can be added to get even more realistic
      surface maps.
    more information on a PSD error map can be found in the Proper manual on pgs 55-60

    :param lens_diam: diameter of the lens/mirror to generate an aberration map for
    :param Loc: either CPA or NCPA, depending on where the optic is relative to the DM/AO system
    :param lens_name: name of the lens, for file naming
    :return: will create a FITs file in the folder specified by iop.quasi for each optic (and  timestep in the case
     of quasi-static aberrations)
    """
    # TODO add different timescale aberrations
    dprint('Generating optic aberration maps using Proper')
    wfo = proper.prop_begin(lens_diam, 1., ap.grid_size, tp.beam_ratio)
    aber_cube = np.zeros((ap.numframes, tp.aber_params['n_surfs'], ap.grid_size, ap.grid_size))
    for surf in range(tp.aber_params['n_surfs']):

        # Randomly select a value from the range of values for each constant
        rms_error = np.random.normal(tp.aber_vals['a'][0], tp.aber_vals['a'][1])
        c_freq = np.random.normal(tp.aber_vals['b'][0], tp.aber_vals['b'][1])  # correlation frequency (cycles/meter)
        high_power = np.random.normal(tp.aber_vals['c'][0], tp.aber_vals['c'][1])  # high frewquency falloff (r^-high_power)

        perms = np.random.rand(ap.numframes, ap.grid_size, ap.grid_size)-0.5
        perms *= 1e-7

        phase = 2 * np.pi * np.random.uniform(size=(ap.grid_size, ap.grid_size)) - np.pi
        aber_cube[0, surf] = prop_psd_errormap(wfo, rms_error, c_freq, high_power, TPF=True, PHASE_HISTORY=phase)

        filename = f"{iop.quasi}/t{0}_{lens_name}.fits"
        print(filename)
        if not os.path.isfile(filename):
            rawImageIO.saveFITS(aber_cube[0, surf], filename)

        for a in range(1, ap.numframes):
            if a % 100 == 0: misc.progressBar(value=a, endvalue=ap.numframes)
            perms = np.random.rand(ap.grid_size, ap.grid_size) - 0.5
            perms *= 0.05
            phase += perms
            aber_cube[a, surf] = prop_psd_errormap(wfo, rms_error, c_freq, high_power,
                                 MAP="prim_map", TPF=True, PHASE_HISTORY=phase)

            filename = f"{iop.quasi}/t{0}_{lens_name}.fits"
            if not os.path.isfile(filename):
                rawImageIO.saveFITS(aber_cube[0, surf], filename)

    # for f in range(0,ap.numframes,1):
    #     # print 'saving frame #', f
    #     if f%100==0: misc.progressBar(value = f, endvalue=ap.numframes)
    #     for surf in range(tp.aber_params['n_surfs']):
    #         filename = '%s%s_Phase%f_v%i.fits' % (iop.aberdir, f * ap.sample_time, surf)
    #         rawImageIO.saveFITS(aber_cube[f, surf], '%stelz%f.fits' % (iop.aberdir, f*ap.sample_time))
            # quicklook_im(aber_cube[f], logAmp=False, show=True)


def circularise(prim_map):
    # TODO test this
    x = np.linspace(-1,1,128) * np.ones((128,128))
    y = np.transpose(np.linspace(-1, 1, 128) * np.ones((128, 128)))
    circ_map = np.zeros((2, 128, 128))
    circ_map[0] = x*np.sqrt(1-(y**2/2.))
    circ_map[1] = y*np.sqrt(1-(x**2/2.))
    circ_map*= 64
    new_prim = np.zeros((128,128))
    for x in range(128):
        for y in range(128):
            ix = circ_map[0][x,y]
            iy = circ_map[1][x,y]
            new_prim[ix,iy] = prim_map[x,y]
    new_prim = proper.prop_shift_center(new_prim)
    new_prim = np.transpose(new_prim)
    return new_prim


def add_aber(wfo, f_lens, d_lens, aber_params, step=0, lens_name='lens'):
    """
    loads a phase error map and adds aberrations using proper.prop_add_phase
    if no aberration file exists, creates one for specific lens using generate_maps

    :param wf_array: 2D wavefront
    :param f_lens: focal length (m) of lens to add aberrations to
    :param d_lens: diameter (in m) of lens (only used when generating new aberrations maps)
    :param aber_params: parameters specified by tp.aber_params
    :param step: is the step number for quasistatic aberrations
    :param lens_name: name of the lens, used to save/read in FITS file of aberration map
    :return will act upon a given wavefront and apply new or loaded-in aberration map
    """
    # TODO this does not currently loop over time, so it is not using quasi-static abberations.
    # dprint("Adding Abberations")

    if not aber_params['QuasiStatic']:
        step = 0
    else:
        dprint((iop.aberdir, iop.aberdir[-6:]))
        if iop.aberdir[-6:] != 'quasi/':
            iop.aberdir = iop.aberdir+'quasi/'

    # Load in or Generate Aberration Map
    filename = f"{iop.quasi}/t{step}_{lens_name}.fits"
    if not os.path.isfile(filename):
        generate_maps(d_lens, lens_name)
    phase_map = rawImageIO.read_image(filename, prob_map=False)

    shape = wfo.wf_array.shape
    # The For Loop of Horror:
    for iw in range(shape[0]):
        for io in range(shape[1]):
            if aber_params['Phase']:
                for surf in range(aber_params['n_surfs']):
                    if aber_params['OOPP']:
                        proper.prop_lens(wfo.wf_array[iw,io], f_lens, "OOPP")
                        proper.prop_propagate(wfo.wf_array[iw,io], f_lens/aber_params['OOPP'][surf])
                        lens_name = f"OOPP{surf}"
                        filename = f"{iop.quasi}/t{step}_{lens_name}.fits"
                        if not os.path.isfile(filename):
                            generate_maps(d_lens, lens_name)
                        phase_map = rawImageIO.read_image(filename, prob_map=False)

                    # Add Phase Map
                    proper.prop_add_phase(wfo.wf_array[iw, io], phase_map[0])

                    if aber_params['OOPP']:
                        proper.prop_propagate(wfo.wf_array[iw,io], f_lens+f_lens*(1-1./aber_params['OOPP'][surf]))
                        proper.prop_lens(wfo.wf_array[iw,io], f_lens, "OOPP")

                # quicklook_im(phase_maps[0]*1e9, logAmp=False, colormap="jet", show=True, axis=None, title='nm', pupil=True)

            if aber_params['Amp']:
                dprint("Outdated code-please update")
                # for surf in range(aber_params['n_surfs']):
                #     filename = '%s%s_Amp%f_v%i.fits' % (iop.quasi, step * ap.sample_time, surf)
                #     rms_error = np.random.normal(aber_vals['a_amp'][0],aber_vals['a_amp'][1])
                #     c_freq = np.random.normal(aber_vals['b'][0],
                #                               aber_vals['b'][1])  # correlation frequency (cycles/meter)
                #     high_power = np.random.normal(aber_vals['c'][0],
                #                                   aber_vals['c'][1])  # high frewquency falloff (r^-high_power)
                #     if aber_params['OOPP']:
                #         proper.prop_lens(wfo.wf_array[iw, io], f_lens, "OOPP")
                #         proper.prop_propagate(wfo.wf_array[iw, io], f_lens / aber_params['OOPP'][surf])
                #     if iw == 0 and io == 0:
                #         if iw == 0 and io == 0:
                #             amp_maps[surf] = proper.prop_psd_errormap(wfo.wf_array[0, 0], rms_error, c_freq, high_power,
                #                                                       FILE=filename, TPF=True)
                #         else:
                #             proper.prop_multiply(wfo.wf_array[iw, io], amp_maps[surf])
                #     if aber_params['OOPP']:
                #         proper.prop_propagate(wfo.wf_array[iw, io], f_lens + f_lens * (1 - 1. / aber_params['OOPP'][surf]))
                #         proper.prop_lens(wfo.wf_array[iw, io], f_lens, "OOPP")
    wfo.test_save('add_aber')


def add_zern_ab(wfo):
    """
    adds low-order aberrations from Zernike polynomials

    see good example in Proper manual pg 51
    quote: These [polynomials] form an orthogonal set of aberrations that include:
     wavefront tilt, defocus, coma, astigmatism, spherical aberration, and others
    """
    proper.prop_zernikes(wfo, [2,3,4], np.array([175,150,200])*1.0e-9)


def add_atmos(wfo, f_lens, it):
    """
    creates a phase offset matrix for each wavelength at each time step,
    sampled from the atmosphere generated by CAOS

    :param wf_array: array of complex E-field arrays at each wavelength for each astronomical body
    :param atmos_map: fits file of atmospheric aberrations at time step
    :param correction:
    :return:
    """
    obj_map = None
    # TODO get rid of this hack
    # The sampling keyward should be passed to proper.prop_errormap. This keyword scales the atmosphere map in the fits
    #  file to the same grid spacing as the wf_array. The sampling is defined in the Proper manual (pg36), and should
    #  be wavelength dependent. However, Rupert moved away from this to hard-code a ap.samp parameter, which is now
    #  common to all wavelengths. Rupert can then tune this parameter. Not mathematically sound, but is a hack that
    #  works reasonably well for now (probably?)
    # dprint(f"Adding Atmosphere--at wavelength {w*1e9} nm")
    #samp = proper.prop_get_sampling(wf_array[0, 0])*ap.band[0]*1e-9/w  # <--This looks good!?!

    shape = wfo.wf_array.shape

    for iw in range(shape[0]):
        wavelength = wfo.wf_array[iw, 0].lamda
        atmos_map = atmos.get_filename(it, wavelength)
        for io in range(shape[1]):
            # if iw == 0 and io == 0:
                obj_map = fits.open(atmos_map)[1].data

                obj_map = unwrap_phase(obj_map)

                obj_map *= wavelength/np.pi
                proper.prop_add_phase(wfo.wf_array[iw,io], obj_map)

    wfo.wf_array = abs_zeros(wfo.wf_array)  # Zeroing outside the pupil
    wfo.test_save('add_atmos')

def rotate_atmos(wf, it):
    time = it * ap.sample_time
    rotate_angle = tp.rot_rate * time
    wf.wfarr = proper.prop_shift_center(wf.wfarr)
    wf.wfarr = proper.prop_rotate(wf.wfarr, rotate_angle)
    wf.wfarr = proper.prop_shift_center(wf.wfarr)
