"""This code handles most of the telescope optics based functionality"""

import numpy as np
from scipy.interpolate import interp1d
import copy
import proper
import medis.Telescope.adaptive_optics as ao
import medis.Telescope.aberrations as aber
import medis.Telescope.foreoptics as fo
import medis.Telescope.FPWFS as fpwfs
from medis.Telescope.coronagraph import coronagraph
from medis.Utils.plot_tools import view_datacube, quicklook_wf, quicklook_im, quicklook_IQ, loop_frames, get_intensity
from medis.params import ap, tp, iop, sp
from medis.Utils.misc import dprint

class Wavefronts():
    """
    An object containing all of the complex E fields (for each sample wavelength and astronomical object) for this timestep

    :params
    :save_locs e.g. np.array(['entrance pupil', 'after ao', 'before coron.'])
    :gui_maps_type np.array(['phase', 'phase', 'amp'])
    The shape of self.selec_E_fiels is probe locs x nwsamp x nobjects x tp.grid_size

    :returns
    self.wf_array: a matrix of proper wavefront objects after all optic modifications have been applied
    self.save_E_fields: a matrix of E fields (proper.WaveFront.wfarr) at specified locations in the chain
    """
    def __init__(self):
        self.save_locs = sp.save_locs
        self.locs_seen = []

        # Using Proper to propagate wavefront from primary through optical system, loop over wavelength
        wsamples = np.linspace(ap.band[0], ap.band[1], ap.nwsamp) / 1e9

        # wf_array is an array of arrays; the wf_array is (number_wavelengths x number_astro_objects)
        # each field in the wf_array is the complex E-field at that wavelength, per object
        # the E-field size is given by (ap.grid_size x ap.grid_size)
        if ap.companion:
            self.wf_array = np.empty((len(wsamples), 1 + len(ap.contrast)), dtype=object)
        else:
            self.wf_array = np.empty((len(wsamples), 1), dtype=object)

        self.save_E_fields = np.empty((0,np.shape(self.wf_array)[0],
                                        np.shape(self.wf_array)[1],
                                        ap.grid_size,
                                        ap.grid_size), dtype=np.complex64)

        # Using Proper to propagate wavefront from primary through optical system, loop over wavelength
        self.beam_ratios = np.zeros_like((wsamples))
        for iw, w in enumerate(wsamples):
            # Initialize the wavefront at entrance pupil
            self.beam_ratios[iw] = tp.beam_ratio * ap.band[0] / w * 1e-9
            wfp = proper.prop_begin(tp.diam, w, ap.grid_size, self.beam_ratios[iw])

            wfs = [wfp]
            names = ['primary']
            # Initiate wavefronts for companion(s)
            if ap.companion:
                for id in range(len(ap.contrast)):
                    wfc = proper.prop_begin(tp.diam, w, ap.grid_size, self.beam_ratios[iw])
                    wfs.append(wfc)
                    names.append('companion_%i' % id)

            for io, (iwf, wf) in enumerate(zip(names, wfs)):
                self.wf_array[iw, io] = wf

    def iter_func(self, func, *args, **kwargs):
        """
        For each wavelength and astronomical object apply a function to the wavefront.

        If func is in save_locs then append the E field to save_E_fields

        :param func: function to be applied e.g. ap.add_aber()
        :param args:
        :param kwargs:
        :return: self.save_E_fields
        """
        shape = self.wf_array.shape
        optic_E_fields = np.zeros((1, np.shape(self.wf_array)[0],
                                    np.shape(self.wf_array)[1],
                                    ap.grid_size,
                                    ap.grid_size), dtype=np.complex64)
        for iw in range(shape[0]):
            for iwf in range(shape[1]):
                func(self.wf_array[iw, iwf], *args, **kwargs)
                if self.save_locs is not None and func.__name__ in self.save_locs:
                    wf = proper.prop_shift_center(self.wf_array[iw, iwf].wfarr)
                    optic_E_fields[0, iw, iwf] = copy.copy(wf)

        if self.save_locs is not None and func.__name__ in self.save_locs:
            self.save_E_fields = np.vstack((self.save_E_fields, optic_E_fields))
            self.locs_seen.append(func.__name__)

    def test_save(self, funcname):
        """
        An alternative way to populate save_E_fields since not all functions are run via iter_func
        (e.g. add_atmos). So call this class function at the end of the function that alters the wavefront

        :param funcname:
        :return: self.save_E_fields
        """
        if self.save_locs is not None and funcname in self.save_locs:
            shape = self.wf_array.shape
            optic_E_fields = np.zeros((1, np.shape(self.wf_array)[0],
                                       np.shape(self.wf_array)[1],
                                       ap.grid_size,
                                       ap.grid_size), dtype=np.complex64)
            for iw in range(shape[0]):
                for iwf in range(shape[1]):
                    wf = proper.prop_shift_center(self.wf_array[iw, iwf].wfarr)
                    optic_E_fields[0, iw, iwf] = copy.copy(wf)
            self.save_E_fields = np.vstack((self.save_E_fields, optic_E_fields))
            self.locs_seen.append(funcname)

    def end(self):
        """
        Checks if the save_locs matches the functions seen otherwise save_E_fields is the wrong size for the output
        :return:
        """
        self.iter_func(detector)

        unseen_funcs = list(set(self.locs_seen).symmetric_difference(set(list(sp.save_locs))))
        if len(unseen_funcs) > 0:
            for func in unseen_funcs:
                print('Function %s() not used' % func)
            print('Check your sp.save_locs match the optics set by telescope parameters (tp)')
            raise AssertionError

def detector(wfo):
    """
    Empty function for the purpose of telling the sim to save the final efield screen
    :return:
    """
    return

def optics_propagate(empty_lamda, grid_size, PASSVALUE):
    """
    #TODO pass complex datacube for photon phases

    propagates instantaneous complex E-field through the optical system in loop over wavelength range

    this function is called as a 'prescription' by proper

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

    datacube = []
    wfo = Wavefronts()

    # Defines aperture (baffle-before primary)
    wfo.iter_func(proper.prop_circular_aperture, **{'radius': tp.diam/2})

    # Pass through a mini-atmosphere inside the telescope baffle
    #  The atmospheric model used here (as of 3/5/19) uses different scale heights,
    #  wind speeds, etc to generate an atmosphere, but then flattens it all into
    #  a single phase mask. The phase mask is a real-valued delay lengths across
    #  the array from infinity. The delay length thus corresponds to a different
    #  phase offset at a particular frequency.
    # quicklook_wf(wfo.wf_array[0,0])
    if tp.use_atmos:
        # TODO is this supposed to be in the for loop over w?
        aber.add_atmos(wfo, *(tp.f_lens, PASSVALUE['iter']))

    # quicklook_wf(wfo.wf_array[0,0])
    if tp.rot_rate:
        wfo.iter_func(aber.rotate_atmos, *(PASSVALUE['iter']))

    if tp.use_hex:
        fo.add_hex(wfo.wf_array)

    wfo.iter_func(proper.prop_define_entrance)  # normalizes the intensity

    # Both offsets and scales the companion wavefront
    if wfo.wf_array.shape[1] > 1:
        fo.offset_companion(wfo.wf_array[:, 1:], PASSVALUE['iter'], )

    ########################################
    # Telescope Distortions to Wavefront
    #######################################
    # Abberations before AO
    if tp.aber_params['CPA']:
        aber.add_aber(wfo, tp.f_lens, tp.diam, tp.aber_params, PASSVALUE['iter'], lens_name='CPA1')
        wfo.iter_func(proper.prop_circular_aperture, **{'radius': tp.diam / 2})

    ########################################
    # AO
    #######################################
    if tp.quick_ao:
        # r0 = float(PASSVALUE['atmos_map'][-10:-5])

        ao.flat_outside(wfo.wf_array)
        CPA_maps = ao.quick_wfs(wfo.wf_array[:, 0])  # , obj_map, tp.wfs_scale)

        if tp.use_ao:
            ao.quick_ao(wfo,  CPA_maps)

    else:
        # TODO update this code
        # if tp.use_ao:
        #     ao.adaptive_optics(wf, iwf, iw, tp.f_lens, beam_ratio, PASSVALUE['iter'])
        #
        # if iwf == 'primary':  # and PASSVALUE['iter'] == 0:
        #     r0 = float(PASSVALUE['atmos_map'][-10:-5])
        #     # dprint((r0, 'r0'))
        #     # if iw == np.ceil(ap.nwsamp/2):
        #     ao.wfs_measurement(wf, PASSVALUE['iter'], iw, r0=r0)  # , obj_map, tp.wfs_scale)
        dprint('This needs to be updated to the parallel implementation')
        exit()

    if tp.obscure:
        # TODO check this was resolved and spiders can be applied earlier up the chain
        # spiders are introduced here for now since the phase unwrapping seems to ignore them and hence so does the DM
        # Check out http://scikit-image.org/docs/dev/auto_examples/filters/plot_phase_unwrap.html for masking argument
        print('warning adding obscurations after the AO!!')
        wfo.iter_func(fo.add_obscurations, M2_frac=1/4, d_primary=tp.diam)
        wfo.wf_array = aber.abs_zeros(wfo.wf_array)

    # TODO Verify this
    # if tp.active_modulate:
    #     fpwfs.modulate(wf, w, PASSVALUE['iter'])

    ########################################
    # Post-AO Telescope Distortions
    # #######################################

    # Abberations after the AO Loop
    if tp.aber_params['NCPA']:
        aber.add_aber(wfo, tp.f_lens,tp.diam, tp.aber_params, PASSVALUE['iter'], lens_name='NCPA1')
        wfo.iter_func(proper.prop_circular_aperture, **{'radius': tp.diam / 2})
        # TODO does this need to be here?
        # wfo.iter_func(fo.add_obscurations, tp.diam/4, legs=False)
        wfo.wf_array = aber.abs_zeros(wfo.wf_array)

    # Low-order aberrations
    if tp.use_zern_ab:
        wfo.iter_func(aber.add_zern_ab)

    if tp.use_apod:
        from medis.Telescope.coronagraph import apodization
        wfo.iter_func(apodization, True)

    # First Optic (primary mirror)
    wfo.iter_func(fo.prop_mid_optics, tp.f_lens, tp.f_lens)

    ########################################
    # Coronagraph
    ########################################

    wfo.iter_func(coronagraph, *(tp.f_lens, tp.occulter_type, tp.occult_loc, tp.diam))

    ########################################
    # Focal Plane
    # #######################################

    # Interpolating spectral cube from ap.nwsamp discreet wavelengths to ap.w_bins
    if ap.interp_sample and ap.nwsamp>1 and ap.nwsamp<ap.w_bins:
        wave_samps = np.linspace(0, 1, ap.nwsamp)
        f_out = interp1d(wave_samps, datacube, axis=0)
        new_heights = np.linspace(0, 1, ap.w_bins)
        datacube = f_out(new_heights)

    wfo.end()

    print('Finished datacube at single timestep')
    wfo.save_E_fields = np.array(wfo.save_E_fields)

    return 1, wfo.save_E_fields
