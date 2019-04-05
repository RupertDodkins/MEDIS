'''This code handles most of the telescope optics based functionality'''

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


def iter_func(wavefronts, func, *args, **kwargs):
    shape = wavefronts.shape
    for iw in range(shape[0]):
        for iwf in range(shape[1]):
            func(wavefronts[iw, iwf], *args, **kwargs)


def optics_propagate(empty_lamda, grid_size, PASSVALUE):
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

    # Using Proper to propagate wavefront from primary through optical system, loop over wavelength
    wsamples = np.linspace(ap.band[0], ap.band[1], ap.nwsamp) / 1e9
    datacube = []

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
        wfp = proper.prop_begin(tp.diam, w, ap.grid_size, beam_ratios[iw])

        wfs = [wfp]
        names = ['primary']
        # Initiate wavefronts for companion(s)
        if ap.companion:
            for id in range(len(ap.contrast)):
                wfc = proper.prop_begin(tp.diam, w, ap.grid_size, beam_ratios[iw])
                wfs.append(wfc)
                names.append('companion_%i' % id)

        for io, (iwf, wf) in enumerate(zip(names, wfs)):
            wf_array[iw, io] = wf


    # Defines aperture (baffle-before primary)
    iter_func(wf_array, proper.prop_circular_aperture, **{'radius':tp.diam/2})

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

    iter_func(wf_array, fo.add_obscurations, tp.diam / 4, legs=False)
    if sp.get_ints: get_intensity(wf_array, sp, phase=True)

    wf_array = aber.abs_zeros(wf_array)  # Zeroing outside the pupil

    if tp.use_hex:
        fo.add_hex(wf_array)

    iter_func(wf_array, proper.prop_define_entrance)  # normalizes the intensity

    # Both offsets and scales the companion wavefront
    if wf_array.shape[1] >=1:
        fo.offset_companion(wf_array[:,1:], PASSVALUE['atmos_map'], )

    # Abberations before AO
    if tp.aber_params['CPA']:
        aber.add_aber(wf_array, tp.f_lens, tp.aber_params, tp.aber_vals, PASSVALUE['iter'], Loc='CPA')
        iter_func(wf_array, proper.prop_circular_aperture, **{'radius': tp.diam / 2})

    if tp.obscure:
        # TODO check this was resolved and spiders can be applied earlier up the chain
        # spiders are introduced here for now since the phase unwrapping seems to ignore them and hence so does the DM
        # Check out http://scikit-image.org/docs/dev/auto_examples/filters/plot_phase_unwrap.html for masking argument
        iter_func(wf_array, fo.add_obscurations, tp.diam/4, legs=False)
        wf_array = aber.abs_zeros(wf_array)
        if sp.get_ints: get_intensity(wf_array, sp, phase=True)

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

    # TODO Verify this
    # if tp.active_modulate:
    #     fpwfs.modulate(wf, w, PASSVALUE['iter'])

    # Abberations after the AO Loop
    if tp.aber_params['NCPA']:
        aber.add_aber(wf_array, tp.f_lens, tp.aber_params, tp.aber_vals, PASSVALUE['iter'], Loc='NCPA')
        iter_func(wf_array, proper.prop_circular_aperture, **{'radius': tp.diam / 2})
        iter_func(wf_array, fo.add_obscurations, tp.diam/4, legs=False)
        wf_array = aber.abs_zeros(wf_array)
        if sp.get_ints: get_intensity(wf_array, sp, phase=True)

    # Low-order aberrations
    if tp.use_zern_ab:
        iter_func(wf_array, aber.add_zern_ab)

    if tp.use_apod:
        from medis.Telescope.coronagraph import apodization
        iter_func(wf_array, apodization, True)

    # First Optic (primary mirror)
    iter_func(wf_array, fo.prop_mid_optics, tp.f_lens, tp.f_lens)
    if sp.get_ints: get_intensity(wf_array, sp, phase=False)

    # Coronagraph
    iter_func(wf_array, coronagraph, *(tp.f_lens, tp.occulter_type, tp.occult_loc, tp.diam))
    if sp.get_ints: get_intensity(wf_array, sp, phase=False)

    shape = wf_array.shape
    for iw in range(shape[0]):
        wframes = np.zeros((ap.grid_size, ap.grid_size))
        for io in range(shape[1]):
            (wframe, sampling) = proper.prop_end(wf_array[iw, io])

            wframes += wframe

        datacube.append(wframes)

    datacube = np.array(datacube)
    # TODO implement this format of dithering
    # width = mp.array_SIZE
    # left = np.round(datacube.shape[1]//2+x - width//2).astype(int)
    # right = left+width
    # bottom = np.round(datacube.shape[2]//2+y - width//2).astype(int)
    # top = bottom +width
    # # print(rot_sky.shape,x,y, left, right, bottom, top)
    # dither = rot_sky[bottom:top, left:right]
    datacube = np.roll(np.roll(datacube, tp.pix_shift[0], 1), tp.pix_shift[1], 2)  # cirshift array for off-axis observing
    datacube = np.abs(datacube)  # get intensity from datacube

    # Interpolating spectral cube from ap.nwsamp discreet wavelengths to ap.w_bins
    if ap.interp_sample and ap.nwsamp>1 and ap.nwsamp<ap.w_bins:
        wave_samps = np.linspace(0, 1, ap.nwsamp)
        f_out = interp1d(wave_samps, datacube, axis=0)
        new_heights = np.linspace(0, 1, ap.w_bins)
        datacube = f_out(new_heights)

    # TODO is this still neccessary?
    # datacube = np.transpose(np.transpose(datacube) / np.sum(datacube, axis=(1, 2)))/float(ap.nwsamp)

    print('Finished datacube at single timestep')

    return (datacube, sampling)












