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


def optics_propagate(empty_lamda, grid_size, PASSVALUE):  # 'dm_disp':0         # possible rename to optics_propagate
    """
    propagates instantaneous complex E-field through the optical system in loop over wavelength range

    uses PyPROPER3 to generate the complex E-field at the source, then propagates it through atmosphere, then telescope, to the focal plane
    the AO simulator happens here
    this does not include the observation of the wavefront by the detector
    :returns spectral cube at instantaneous time
    """
    #dprint("Propagating Wavefront Through Telescope")
    passpara = PASSVALUE['params']
    ap.__dict__ = passpara[0].__dict__
    tp.__dict__ = passpara[1].__dict__
    iop.__dict__ = passpara[2].__dict__
    sp.__dict__ = passpara[3].__dict__

    wsamples = np.linspace(tp.band[0], tp.band[1], tp.nwsamp) / 1e9
    datacube = []

    if ap.companion:
        wf_array = np.empty((len(wsamples), 1 + len(ap.contrast)), dtype=object)
    else:
        wf_array = np.empty((len(wsamples), 1), dtype=object)

    # Using Proper to propagate wavefront from primary through optical system, loop over wavelength
    beam_ratios = np.zeros_like((wsamples))
    for iw, w in enumerate(wsamples):
        # Initialize the wavefront at entrance pupil
        beam_ratios[iw] = tp.beam_ratio * tp.band[0] / w * 1e-9
        wfp = proper.prop_begin(tp.diam, w, tp.grid_size, beam_ratios[iw])

        wfs = [wfp]
        names = ['primary']
        # Initiate wavefronts for companion(s)
        if ap.companion:
            for id in range(len(ap.contrast)):
                wfc = proper.prop_begin(tp.diam, w, tp.grid_size, beam_ratios[iw])
                wfs.append(wfc)
                names.append('companion_%i' % id)

        for io, (iwf, wf) in enumerate(zip(names, wfs)):
            wf_array[iw, io] = wf

    # Defines aperture (before primary)
    iter_func(wf_array, proper.prop_circular_aperture, **{'radius':tp.diam/2})

    # Pass through a mini-atmosphere inside the telescope baffle
    #  The atmospheric model used here (as of 3/5/19) uses different scale heights,
    #  wind speeds, etc to generate an atmosphere, but then flattens it all into
    #  a single phase mask. The phase mask is a real-valued delay lenghts across
    #  the array from infinity. The delay length thus corresponds to a different
    #  phase offset at a particular frequency.
    if tp.use_atmos:
        # TODO is there a name hack in here? seems like an error...
        aber.add_atmos(wf_array, *(tp.f_lens, w, PASSVALUE['atmos_map']))

    wf_array = aber.abs_zeros(wf_array)

    if tp.rot_rate:
        iter_func(wf_array, aber.rotate_atmos, *(PASSVALUE['atmos_map']))

    if tp.use_spiders:
        iter_func(wf_array, fo.add_spiders, tp.diam)
        wf_array = aber.abs_zeros(wf_array)
        if sp.get_ints: get_intensity(wf_array, sp, phase=True)

    wf_array = aber.abs_zeros(wf_array)

    if tp.use_hex:
        fo.add_hex(wf_array)

    iter_func(wf_array, proper.prop_define_entrance)  # normalizes the intensity

    if wf_array.shape[1] >=1:
        fo.offset_companion(wf_array[:,1:], PASSVALUE['atmos_map'], )

    if tp.aber_params['CPA']:
        aber.add_aber(wf_array, tp.f_lens, tp.aber_params, tp.aber_vals, PASSVALUE['iter'], Loc='CPA')
        iter_func(wf_array, proper.prop_circular_aperture, **{'radius': tp.diam / 2})
        iter_func(wf_array, fo.add_spiders, tp.diam, legs=False)
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
        #     # if iw == np.ceil(tp.nwsamp/2):
        #     ao.wfs_measurement(wf, PASSVALUE['iter'], iw, r0=r0)  # , obj_map, tp.wfs_scale)
        print('This need to be updated to the parrallel implementation')
        exit()

    # TODO Verify this
    # if tp.active_modulate:
    #     fpwfs.modulate(wf, w, PASSVALUE['iter'])

    if tp.aber_params['NCPA']:
        aber.add_aber(wf_array, tp.f_lens, tp.aber_params, tp.aber_vals, PASSVALUE['iter'], Loc='NCPA')
        iter_func(wf_array, proper.prop_circular_aperture, **{'radius': tp.diam / 2})
        iter_func(wf_array, fo.add_spiders, tp.diam, legs=False)
        wf_array = aber.abs_zeros(wf_array)
        if sp.get_ints: get_intensity(wf_array, sp, phase=True)

    if tp.use_zern_ab:
        iter_func(wf_array, aber.add_zern_ab)

    # TODO check this was resolved and spiders can be applied earlier up the chain
    # spiders are introduced here for now since the phase unwrapping seems to ignore them and hence so does the DM
    # Check out http://scikit-image.org/docs/dev/auto_examples/filters/plot_phase_unwrap.html for masking argument
    # if tp.use_spiders:
    #     iter_func(wf_array, fo.add_spiders, tp.diam)
    #         fo.prop_mid_optics(wf, tp.f_lens)

    if tp.use_apod:
        from medis.Telescope.coronagraph import apodization
        iter_func(wf_array, apodization, True)

    # First Optic (primary mirror)
    iter_func(wf_array, fo.prop_mid_optics, tp.f_lens)
    if sp.get_ints: get_intensity(wf_array, sp, phase=False)

    # Caronagraph
    iter_func(wf_array, coronagraph, *(tp.f_lens, tp.occulter_type, tp.occult_loc, tp.diam))

    if sp.get_ints: get_intensity(wf_array, sp, phase=False)

    #
    shape = wf_array.shape
    for iw in range(shape[0]):
        wframes = np.zeros((tp.grid_size, tp.grid_size))
        for io in range(shape[1]):
            (wframe, sampling) = proper.prop_end(wf_array[iw, io])

            wframes += wframe

        datacube.append(wframes)

    datacube = np.array(datacube)
    datacube = np.roll(np.roll(datacube, tp.pix_shift[0], 1), tp.pix_shift[1], 2)
    datacube = np.abs(datacube)

    if tp.interp_sample and tp.nwsamp>1 and tp.nwsamp<tp.w_bins:
        wave_samps = np.linspace(0, 1, tp.nwsamp)
        f_out = interp1d(wave_samps, datacube, axis=0)
        new_heights = np.linspace(0, 1, tp.w_bins)
        datacube = f_out(new_heights)

    # TODO is this still neccessary?
    # datacube = np.transpose(np.transpose(datacube) / np.sum(datacube, axis=(1, 2)))/float(tp.nwsamp)

    return (datacube, sampling)












