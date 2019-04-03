"""
model the Subaru optics system

This is a code modified from Rupert's original optics_propagate.py. This code adds more optics to the system,
as well as puts the AO, coronagraphs, etc in order for Subaru.

Here, we will add the basic functionality of the Subaru Telescope, including the primary, secondary, and AO188.
The SCExAO system sits behind the AO188 instrument of Subaru, which is a 188-element AO system located at the
Nasmyth focus (IR) of the telescope. AO188 uses laser guide-star technology. More info here:
https://subarutelescope.org/Introduction/instrument/AO188.html
We then will use just a basic focal lens and coronagraph in this example. A more detailed model of SCExAO will
be modelled in a SCExAO_optics.py code. However, this routine is designed for simple simulations that need to
optimize runtime but still have relevance to the Subaru Telescope.

Here, we do not include the final micro-lens array of MEC or any other device.

This script is meant to override any Subaru/SCExAO-specific parameters specified in the user's params.py
"""

from scipy.interpolate import interp1d
import proper
import numpy as np
import medis.Telescope.adaptive_optics as ao
import medis.Telescope.aberrations as aber
import medis.Telescope.foreoptics as fo
import medis.Telescope.FPWFS as fpwfs
from medis.Telescope.coronagraph import coronagraph
from medis.Utils.plot_tools import view_datacube, quicklook_wf, quicklook_im, quicklook_IQ, loop_frames, get_intensity
from medis.params import ap, tp, iop, sp
from medis.Utils.misc import dprint

# Defining Subaru parameters

# Optics + Detector
# tp.d_primary = 8.2  # m
# tp.fn_primary = 1.83  # f# primary
# tp.fl_primary = 15 # m  focal length
# tp.dist_prim_second = 12.652  # m distance primary to secondary
# #---------------------------
# # According to Iye-et.al.2004-Optical_Performance_of_Subaru:AstronSocJapan, the AO188 uses the IR-Cass secondary,
# # but then feeds it to the IR Nasmyth f/13.6 focusing arrangement.
# tp.fn_secondary = 12.6  # f# secondary
# tp.fl_secondary = tp.fn_secondary * tp.d_secondary  # m  focal length
# tp.dist_second_nsmyth =   # m distance secondary to nasmyth focus
#----------------------------
# According to Iye-et.al.2004-Optical_Performance_of_Subaru:AstronSocJapan, the AO188 uses the IR-Cass secondary,
# but then feeds it to the IR Nasmyth f/13.6 focusing arrangement. So instead of simulating the full Subaru system,
# we can use the effective focal length at the Nasmyth focus, and simulate it as a single lens.
tp.d_nsmyth = 7.971  # m pupil diameter
tp.fn_nsmyth = 13.612  # f# Nasmyth focus
tp.fl_nsmyth = 108.512  # m focal length
tp.dist_nsmyth_ao1 = 0.015  # m distance nasmyth focus to AO188

tp.d_secondary = 1.265  # m diameter secondary, used for central obscuration

#----------------------------
# AO188 OAP1
tp.d_ao1 = 0.090  # m  diamater of AO1
tp.fn_ao1 = 6  # f# AO1
tp.fl_ao1 = 0.015  # m  focal length AO1
tp.dist_ao1_dm = 0.05  # m distance AO1 to DM (just a guess here, shouldn't matter for the collimated beam)

#----------------------------
# AO188 OAP2
tp.dist_dm_ao2 = 0.05  # m distance DM to AO2 (again, guess here)
tp.d_ao1 = 0.090  # m  diamater of AO2
tp.fn_ao2 = 13.6  # f# AO2
tp.fl_ao2 = 151.11  # m  focal length AO2


tp.obscure = True
tp.use_ao = True
tp.ao188_act = 188
tp.use_atmos = True
tp.use_zern_ab = True
tp.occulter_type = 'Vortex'  # 'None'


def iter_func(wavefronts, func, *args, **kwargs):
    shape = wavefronts.shape
    for iw in range(shape[0]):
        for iwf in range(shape[1]):
            func(wavefronts[iw, iwf], *args, **kwargs)


def Subaru_optics(empty_lamda, grid_size, PASSVALUE):
    """
    propagates instantaneous complex E-field through the optical system in loop over wavelength range

    this function is called as a 'perscription' by proper

    uses PyPROPER3 to generate the complex E-field at the source, then propagates it through atmosphere, then telescope, to the focal plane
    currently: optics system "hard coded" as single aperture and lens
    the AO simulator happens here
    this does not include the observation of the wavefront by the detector
    :returns spectral cube at instantaneous time
    """
    print("Propagating Broadband Wavefront Through Telescope")
    # Getting Parameters-import statements weren't working
    passpara = PASSVALUE['params']
    ap.__dict__ = passpara[0].__dict__
    tp.__dict__ = passpara[1].__dict__
    iop.__dict__ = passpara[2].__dict__
    sp.__dict__ = passpara[3].__dict__

    wsamples = np.linspace(ap.band[0], ap.band[1], ap.nwsamp) / 1e9
    datacube = []

    ########################################
    # Astronomical Distortions to Wavefront
    #######################################
    # wf_array is an array of arrays; the wf_array is (number_wavelengths x number_astro_objects)
    # each field in the wf_array is the complex E-field at that wavelength, per object
    # the E-field size is given by (ap.grid_size x ap.grid_size)
    if ap.companion:
        wf_array = np.empty((len(wsamples), 1 + len(ap.contrast)), dtype=object)
    else:
        wf_array = np.empty((len(wsamples), 1), dtype=object)

    beam_ratios = np.zeros_like((wsamples))
    for iw, w in enumerate(wsamples):
        # Initialize the wavefront at entrance pupil
        beam_ratios[iw] = tp.beam_ratio * ap.band[0] / w * 1e-9
        wfp = proper.prop_begin(tp.d_nsmyth, w, ap.grid_size, beam_ratios[iw])

        wfs = [wfp]
        names = ['cent_star']
        # Initiate wavefronts for companion(s)
        if ap.companion:
            for id in range(len(ap.contrast)):
                wfc = proper.prop_begin(tp.d_nsmyth, w, ap.grid_size, beam_ratios[iw])
                wfs.append(wfc)
                names.append('companion_%i' % id)

        for io, (iwf, wf) in enumerate(zip(names, wfs)):
            wf_array[iw, io] = wf

    # Both offsets and scales the companion wavefront
    if wf_array.shape[1] >= 1:
        fo.offset_companion(wf_array[:, 1:], PASSVALUE['atmos_map'], )

    # Defines aperture (baffle-before primary)
    iter_func(wf_array, proper.prop_circular_aperture, **{'radius':tp.d_nsmyth/2})

    # Pass through a mini-atmosphere inside the telescope baffle
    #  The atmospheric model used here (as of 3/5/19) uses different scale heights,
    #  wind speeds, etc to generate an atmosphere, but then flattens it all into
    #  a single phase mask. The phase mask is a real-valued delay lengths across
    #  the array from infinity. The delay length thus corresponds to a different
    #  phase offset at a particular frequency.
    if tp.use_atmos:
        # TODO is this supposed to be in the for loop over w?
        aber.add_atmos(wf_array, *(w, PASSVALUE['atmos_map']))

    wf_array = aber.abs_zeros(wf_array)  # Zeroing outside the pupil

    if tp.rot_rate:
        iter_func(wf_array, aber.rotate_atmos, *(PASSVALUE['atmos_map']))

    ########################################
    # Subaru Distortions to Wavefront
    #######################################
    iter_func(wf_array, proper.prop_define_entrance)  # normalizes the intensity

    if tp.obscure:
        # spiders are introduced here for now since the phase unwrapping seems to ignore them and hence so does the DM
        # Check out http://scikit-image.org/docs/dev/auto_examples/filters/plot_phase_unwrap.html for masking argument
        iter_func(wf_array, fo.add_obscurations, tp.d_secondary, legs=True)
        wf_array = aber.abs_zeros(wf_array)  # zeros outside of primary
        if sp.get_ints: get_intensity(wf_array, sp, phase=True)

    wf_array = aber.abs_zeros(wf_array)  # Zeroing outside the pupil

    # CPA from Effective Primary
    filename = '%s%s_Phase%f_v%i.fits' % (iop.quasi, 'CPA', step * cp.frame_time,0)
    rms_error = np.random.normal(aber_vals['a'][0], aber_vals['a'][1])
    c_freq = np.random.normal(aber_vals['b'][0],
                              aber_vals['b'][1])  # correlation frequency (cycles/meter)
    high_power = np.random.normal(aber_vals['c'][0],
                                  aber_vals['c'][1])  # high frequency falloff (r^-high_power)
    iter_func(wf_array, proper.prop_psd_errormap, rms_error, c_freq, high_power, FILE=filename, TPF=True)  # CPA

     # Nasmyth Focus- Effective Primary/Secondary
    iter_func(wf_array, fo.prop_mid_optics, tp.fl_nsmyth, tp.fl_nsmyth + tp.dist_nsmyth_ao1)  # AO188 is located
                                                                # behind the Nasmyth focus, so propagate extra amount
    if sp.get_ints: get_intensity(wf_array, sp, phase=False)

    # Low-order aberrations
    if tp.use_zern_ab:
        iter_func(wf_array, aber.add_zern_ab)

    ########################################
    # AO188 Distortions to Wavefront
    #######################################
    # AO188-OAP1
    filename = '%s%s_Phase%f_v%i.fits' % (iop.quasi, 'CPA', step * cp.frame_time, 1)
    iter_func(wf_array, proper.prop_psd_errormap, rms_error, c_freq, high_power, FILE=filename, TPF=True)  # CPA
    iter_func(wf_array, fo.prop_mid_optics, tp.fl_ao1, tp.dist_ao1_dm)
    if sp.get_ints: get_intensity(wf_array, sp, phase=False)

    ########################################
    # AO
    #######################################

    if tp.quick_ao:
        r0 = float(PASSVALUE['atmos_map'][-10:-5])

        ao.flat_outside(wf_array)
        CPA_maps = ao.quick_wfs(wf_array[:,0], PASSVALUE['iter'], r0=r0)  # , obj_map, tp.wfs_scale)

        if tp.use_ao:
            ao.quick_ao(wf_array, iwf, tp.f_lens, beam_ratios, PASSVALUE['iter'], CPA_maps)
            wf_array = aber.abs_zeros(wf_array)
            if sp.get_ints: get_intensity(wf_array, sp, phase=True)

    else:
        # TODO update this code
        # if tp.use_ao:
        #     ao.adaptive_optics(wf, iwf, iw, tp.f_lens, beam_ratio, PASSVALUE['iter'])
        #
        # if iwf == 'primary':  # and PASSVALUE['iter'] == 0:
        #     # quicklook_wf(wf, show=True)
        #     r0 = float(PASSVALUE['atmos_map'][-10:-5])
        #     # dprint((r0, 'r0'))
        #     # if iw == np.ceil(ap.nwsamp/2):
        #     ao.wfs_measurement(wf, PASSVALUE['iter'], iw, r0=r0)  # , obj_map, tp.wfs_scale)
        dprint('This needs to be updated to the parallel implementation')
        exit()

    ########################################
    # AO188 Distortions to Wavefront
    #######################################

    # AO188-OAP2
    iter_func(wf_array, proper.prop_propagate, tp.dist_dm_ao2)
    filename = '%s%s_Phase%f_v%i.fits' % (iop.quasi, 'CPA', step * cp.frame_time, surf)
    iter_func(wf_array, proper.prop_psd_errormap, rms_error, c_freq, high_power, FILE=filename, TPF=True)  # NCPA
    iter_func(wf_array, fo.prop_mid_optics, tp.fl_ao2, tp.fl_ao2)
    if sp.get_ints: get_intensity(wf_array, sp, phase=False)

    ########################################
    # Focal Plane
    # #######################################

    shape = wf_array.shape
    for iw in range(shape[0]):
        wframes = np.zeros((ap.grid_size, ap.grid_size))
        for io in range(shape[1]):
            (wframe, sampling) = proper.prop_end(wf_array[iw, io])

            wframes += wframe

        datacube.append(wframes)

    datacube = np.array(datacube)
    datacube = np.roll(np.roll(datacube, tp.pix_shift[0], 1), tp.pix_shift[1], 2)  # cirshift array for off-axis observing
    datacube = np.abs(datacube)  # get intensity from datacube

    # Interpolating spectral cube from ap.nwsamp discreet wavelengths to ap.w_bins
    if ap.interp_sample and ap.nwsamp>1 and ap.nwsamp<ap.w_bins:
        wave_samps = np.linspace(0, 1, ap.nwsamp)
        f_out = interp1d(wave_samps, datacube, axis=0)
        new_heights = np.linspace(0, 1, ap.w_bins)
        datacube = f_out(new_heights)

    print('Finished datacube at single timestep')

    return datacube, sampling












