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


class Wavefronts():
    """
    An object containing all of the complex E fields (for each sample wavelength and astronomical object) for this timestep

    :params
    save_locs e.g. np.array([['entrance pupil', 'phase'], ['after ao', 'phase'], ['before coron.', 'amp']])
    The shape of self.selec_E_fiels is probe locs x nwsamp x nobjects x tp.grid_size

    """
    def __init__(self):
        self.save_locs = sp.save_locs

        # Using Proper to propagate wavefront from primary through optical system, loop over wavelength
        wsamples = np.linspace(ap.band[0], ap.band[1], ap.nwsamp) / 1e9

        # wf_array is an array of arrays; the wf_array is (number_astro_objects x number_wavelengths)
        # each field in the wf_array is the complex E-field at that wavelength, per object
        # the E-field size is given by (ap.grid_size x ap.grid_size)
        if ap.companion:
            self.wf_array = np.empty((len(wsamples), 1 + len(ap.contrast)), dtype=object)
        else:
            self.wf_array = np.empty((len(wsamples), 1), dtype=object)

        self.selec_E_fields = np.empty((0,np.shape(self.wf_array)[0],
                                        np.shape(self.wf_array)[1],
                                        ap.grid_size,
                                        ap.grid_size), dtype=np.complex64)

        # Using Proper to initiate complex wavefront for each object, wavelength
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

        If func is in save_locs then append the E field to selec_E_fields

        :param func: function to be applied e.g. ap.add_aber()
        :param args:
        :param kwargs:
        :return: self.selec_E_fields

        """
        shape = self.wf_array.shape
        optic_E_fields = np.zeros((1, np.shape(self.wf_array)[0],
                                    np.shape(self.wf_array)[1],
                                    ap.grid_size,
                                    ap.grid_size), dtype=np.complex64)
        for iw in range(shape[0]):
            for iwf in range(shape[1]):
                func(self.wf_array[iw, iwf], *args, **kwargs)
                if self.save_locs is not None and func.__name__ in self.save_locs[:, 0]:
                    wf = proper.prop_shift_center(self.wf_array[iw, iwf].wfarr)

                    optic_E_fields[0, iw, iwf] = copy.copy(wf)

        if self.save_locs is not None and func.__name__ in self.save_locs[:, 0]:
            self.selec_E_fields = np.vstack((self.selec_E_fields, optic_E_fields))

    def test_save(self, funcname):
        """
        An alternative way to populate selec_E_fields since not all functions are run via iter_func
        (e.g. add_atmos). So call this class function at the end of the function that alters the wavefront

        :param funcname:
        :return: self.selec_E_fields
        """
        if self.save_locs is not None and funcname in self.save_locs[:, 0]:
            shape = self.wf_array.shape
            optic_E_fields = np.zeros((1, np.shape(self.wf_array)[0],
                                       np.shape(self.wf_array)[1],
                                       ap.grid_size,
                                       ap.grid_size), dtype=np.complex64)
            for iw in range(shape[0]):
                for iwf in range(shape[1]):
                    wf = proper.prop_shift_center(self.wf_array[iw, iwf].wfarr)
                    optic_E_fields[0, iw, iwf] = copy.copy(wf)
            self.selec_E_fields = np.vstack((self.selec_E_fields, optic_E_fields))


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

    datacube = []
    wfo = Wavefronts()

    ########################################
    # Astro/Atmospheric Distortions to Wavefront
    #######################################

    # Defines aperture (baffle-before primary)
    wfo.iter_func(proper.prop_circular_aperture, **{'radius': tp.d_nsmyth / 2})

    # Pass through a mini-atmosphere inside the telescope baffle
    #  The atmospheric model used here (as of 3/5/19) uses different scale heights,
    #  wind speeds, etc to generate an atmosphere, but then flattens it all into
    #  a single phase mask. The phase mask is a real-valued delay lengths across
    #  the array from infinity. The delay length thus corresponds to a different
    #  phase offset at a particular frequency.
    if tp.use_atmos:
        # TODO is this supposed to be in the for loop over w?
        aber.add_atmos(wfo, *(PASSVALUE['atmos_map']))

    wfo.wf_array = aber.abs_zeros(wfo.wf_array)  # Zeroing outside the pupil

    if tp.rot_rate:
        wfo.iter_func(aber.rotate_atmos, *(PASSVALUE['atmos_map']))

    ########################################
    # Subaru Distortions to Wavefront
    #######################################
    wfo.iter_func(proper.prop_define_entrance)  # normalizes the intensity

    wf_array = aber.abs_zeros(wf_array)  # Zeroing outside the pupil

    if tp.obscure:
        wfo.iter_func(fo.add_obscurations, d_primary=tp.d_nsmyth, d_secondary=tp.d_secondary)
        wfo.wf_array = aber.abs_zeros(wfo.wf_array)

    # CPA from Effective Primary
    aber.add_aber(wf_array, tp.fl_nsmyth, tp.d_nsmyth, tp.aber_params, step=0, lens_name='nsmyth')

     # Nasmyth Focus- Effective Primary/Secondary
    wfo.iter_func(wf_array, fo.prop_mid_optics, tp.fl_nsmyth, tp.fl_nsmyth + tp.dist_nsmyth_ao1)  # AO188 is located
                                                                # behind the Nasmyth focus, so propagate extra amount
    # Low-order aberrations
    if tp.use_zern_ab:
        iter_func(wf_array, aber.add_zern_ab)

    ########################################
    # AO188 Distortions to Wavefront
    #######################################
    # AO188-OAP1
    aber.add_aber(wf_array, tp.fl_ao1, tp.d_ao1, tp.aber_params, 0, 'ao188-OAP1')
    wfo.iter_func(wf_array, fo.prop_mid_optics, tp.fl_ao1, tp.dist_ao1_dm)

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

    else:
        # TODO update this code
        dprint('This needs to be updated to the parallel implementation')
        exit()

    ########################################
    # AO188 Distortions to Wavefront
    #######################################

    # AO188-OAP2
    wfo.iter_func(wf_array, proper.prop_propagate, tp.dist_dm_ao2)
    aber.add_aber(wf_array, tp.fl_ao2, tp.d_ao1, tp.aber_params, 0, 'ao188-OAP2')
    wfo.iter_func(wf_array, fo.prop_mid_optics, tp.fl_ao2, tp.fl_ao2)

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
    wfo.selec_E_fields = np.array(wfo.selec_E_fields)

    return (datacube, wfo.selec_E_fields)











