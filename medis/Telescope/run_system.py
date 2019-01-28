'''This code handles most of the telescope optics based functionality'''

import sys, os

sys.path.append(os.path.dirname(os.path.realpath(__file__))[:-9] + "speckle_nulling/speckle_nulling")

# main = sys.argv[0][:-3]
# modules = main.split('/')[-2:]
# main = modules[0]+'.'+modules[1]
# import importlib
# params = importlib.import_module(main, package=None)
# ap.__dict__ = params.ap.__dict__
# tp.__dict__ = params.tp.__dict__
# iop.__dict__ = params.iop.__dict__
from scipy.interpolate import interp1d
import proper

import medis.Telescope.telescope_dm as tdm
from medis.Telescope.coronagraph import coronagraph
import medis.Telescope.FPWFS as FPWFS
from medis.Utils.plot_tools import view_datacube, quicklook_wf, quicklook_im, quicklook_IQ, loop_frames, get_intensity
import medis.Utils.rawImageIO as rawImageIO
# import matplotlib.pylab as plt
# import medis.params
from medis.params import ap, tp, iop, sp

import numpy as np
from medis.Analysis.stats import save_pix_IQ
from medis.Analysis.phot import aper_phot
import speckle_killer_v3 as skv3
from medis.Utils.misc import dprint
dprint(proper.__file__)


# print 'line 21', tp.occulter_type
def iter_func(wavefronts, func, *args, **kwargs):
    shape = wavefronts.shape
    for iw in range(shape[0]):
        for iwf in range(shape[1]):
            func(wavefronts[iw, iwf], *args, **kwargs)

def run_system(empty_lamda, grid_size, PASSVALUE):  # 'dm_disp':0
    passpara = PASSVALUE['params']
    ap.__dict__ = passpara[0].__dict__
    tp.__dict__ = passpara[1].__dict__
    iop.__dict__ = passpara[2].__dict__
    sp.__dict__ = passpara[3].__dict__
    # params.ap = passpara[0]
    # params.tp = passpara[1]
    #
    # ap = params.ap
    # tp = params.tp

    # print 'line 23', tp.occulter_type
    # print 'propagating frame:', PASSVALUE['iter']
    wsamples = np.linspace(tp.band[0], tp.band[1], tp.nwsamp) / 1e9
    # print wsamples
    datacube = []
    # print proper.prop_get_sampling(wfp), proper.prop_get_nyquistsampling(wfp), proper.prop_get_fratio(wfp)
    # global phase_map, Imaps
    # Imaps = np.zeros((4,tp.grid_size,tp.grid_size))
    # phase_map = np.zeros((tp.grid_size, tp.grid_size))

    if ap.companion:
        wf_array = np.empty((len(wsamples), 1 + len(ap.contrast)), dtype=object)
    else:
        wf_array = np.empty((len(wsamples), 1), dtype=object)
    beam_ratios = np.zeros_like((wsamples))
    for iw, w in enumerate(wsamples):
        # Define the wavefront
        beam_ratios[iw] = tp.beam_ratio * tp.band[0] / w * 1e-9
        wfp = proper.prop_begin(tp.diam, w, tp.grid_size, beam_ratios[iw])

        wfs = [wfp]
        names = ['primary']
        if ap.companion:
            for id in range(len(ap.contrast)):
                wfc = proper.prop_begin(tp.diam, w, tp.grid_size, beam_ratios[iw])
                wfs.append(wfc)
                names.append('companion_%i' % id)

        for io, (iwf, wf) in enumerate(zip(names, wfs)):
            wf_array[iw, io] = wf


    iter_func(wf_array, proper.prop_circular_aperture, **{'radius':tp.diam/2})
    if tp.use_atmos:
        tdm.add_atmos(wf_array, *(tp.f_lens, w, PASSVALUE['atmos_map']))
        # quicklook_wf(wf_array[0, 0])

    wf_array = tdm.abs_zeros(wf_array)
        # get_intensity(wf_array, sp, phase=True)



    if tp.rot_rate:
        iter_func(wf_array, tdm.rotate_atmos, *(PASSVALUE['atmos_map']))

    if tp.use_spiders:
        iter_func(wf_array, tdm.add_spiders, tp.diam)
        wf_array = tdm.abs_zeros(wf_array)
        if sp.get_ints: get_intensity(wf_array, sp, phase=True)
    #     tdm.add_spiders(wf, tp.diam)
    wf_array = tdm.abs_zeros(wf_array)

    # if tp.use_hex:
    #     tdm.add_hex(wf)
    iter_func(wf_array,proper.prop_define_entrance)  # normalizes the intensity

    if wf_array.shape[1] >=1:
        tdm.offset_companion(wf_array[:,1:], PASSVALUE['atmos_map'], )

    # tdm.offset_companion(wf_array, PASSVALUE['atmos_map'])

    # if tp.use_apod:
    #     tdm.do_apod(wf, tp.grid_size, tp.beam_ratio, tp.apod_gaus)
    #
    # iter_func(wf_array, proper.prop_propagate, tp.f_lens)

    if tp.aber_params['CPA']:

        tdm.add_aber(wf_array, tp.f_lens, tp.aber_params, tp.aber_vals, PASSVALUE['iter'], Loc='CPA')
        iter_func(wf_array, proper.prop_circular_aperture, **{'radius': tp.diam / 2})
        iter_func(wf_array, tdm.add_spiders, tp.diam, legs=False)
        wf_array = tdm.abs_zeros(wf_array)
        if sp.get_ints: get_intensity(wf_array, sp, phase=True)

    # iter_func(wf_array, proper.prop_propagate, tp.f_lens)
    # quicklook_wf(wf_array[0,0])
    # iter_func(wf_array, proper.prop_circular_aperture, **{'radius': tp.diam / 2})
    # iter_func(wf_array, tdm.add_spiders, tp.diam, legs=False)
    # # proper.prop_rectangular_obscuration(wf_array[0,0], 0.05 * 8, 8 * 1.3, ROTATION=20)
    # # proper.prop_rectangular_obscuration(wf_array[0,0], 8 * 1.3, 0.05 * 8, ROTATION=20)
    # quicklook_wf(wf_array[0, 0])

    if tp.quick_ao:
        r0 = float(PASSVALUE['atmos_map'][-10:-5])

        tdm.flat_outside(wf_array)
        CPA_maps = tdm.quick_wfs(wf_array[:,0], PASSVALUE['iter'], r0=r0)  # , obj_map, tp.wfs_scale)

        if tp.use_ao:
            tdm.quick_ao(wf_array, iwf, tp.f_lens, beam_ratios, PASSVALUE['iter'], CPA_maps)
            # iter_func(wf_array, proper.prop_circular_aperture, **{'radius': tp.diam / 2})
            # iter_func(wf_array, tdm.add_spiders, tp.diam, legs=False)
            wf_array = tdm.abs_zeros(wf_array)
            if sp.get_ints: get_intensity(wf_array, sp, phase=True)
            # dprint('quick_ao')

    else:
        print('This need to be updated to the parrallel implementation')
        exit()
        # if tp.use_ao:
        #     tdm.adaptive_optics(wf, iwf, iw, tp.f_lens, beam_ratio, PASSVALUE['iter'])
        #
        # if iwf == 'primary':  # and PASSVALUE['iter'] == 0:
        #     # quicklook_wf(wf, show=True)
        #     r0 = float(PASSVALUE['atmos_map'][-10:-5])
        #     # dprint((r0, 'r0'))
        #     # if iw == np.ceil(tp.nwsamp/2):
        #     tdm.wfs_measurement(wf, PASSVALUE['iter'], iw, r0=r0)  # , obj_map, tp.wfs_scale)
    #
    # iter_func(wf_array, proper.prop_propagate, tp.f_lens)
    # quicklook_wf(wf_array[0,0])
    # rawImageIO.save_wf(wf, iop.datadir+'/loopAO_8act.pkl')
    # if iwf == 'primary':
    #     quicklook_wf(wf, show=True)


    # if tp.active_modulate:
    #     tdm.modulate(wf, w, PASSVALUE['iter'])

    # if iwf == 'primary':
    #     quicklook_wf(wf, show=True)

    if tp.aber_params['NCPA']:
        tdm.add_aber(wf_array, tp.f_lens, tp.aber_params, tp.aber_vals, PASSVALUE['iter'], Loc='NCPA')
        iter_func(wf_array, proper.prop_circular_aperture, **{'radius': tp.diam / 2})
        iter_func(wf_array, tdm.add_spiders, tp.diam, legs=False)
        wf_array = tdm.abs_zeros(wf_array)
        if sp.get_ints: get_intensity(wf_array, sp, phase=True)

    if tp.use_zern_ab:
        iter_func(wf_array, tdm.add_zern_ab, tp.f_lens)

    #         # if iwf == 'primary':
    #         #     NCPA_phasemap = proper.prop_get_phase(wf)
    #         #     quicklook_im(NCPA_phasemap, logAmp=False, show=False, colormap="jet", vmin=-3.14, vmax=3.14)
    #         # if iwf == 'primary':
    #         #     global obj_map
    #         #     r0 = float(PASSVALUE['atmos_map'][-10:-5])
    #         #     obj_map = tdm.wfs_measurement(wf, r0 = r0)#, obj_map, tp.wfs_scale)
    #         #     # quicklook_im(obj_map, logAmp=False)
    #
    # iter_func(wf_array, proper.prop_propagate, 2*tp.f_lens)
    #
    # spiders are introduced here for now since the phase unwrapping seems to ignore them and hence so does the DM
    # Check out http://scikit-image.org/docs/dev/auto_examples/filters/plot_phase_unwrap.html for masking argument
    # if tp.use_spiders:
    #     iter_func(wf_array, tdm.add_spiders, tp.diam)
    #
    #         tdm.prop_mid_optics(wf, tp.f_lens)

    if tp.use_apod:
        from medis.Telescope.coronagraph import apodization
        iter_func(wf_array, apodization, True)


    iter_func(wf_array, tdm.prop_mid_optics, tp.f_lens)
    #
    #         # if iwf == 'primary':
    #         # if PASSVALUE['iter']>ap.numframes-2 or PASSVALUE['iter']==0:
    #         #     quicklook_wf(wf, show=True)
    # dprint((proper.prop_get_sampling(wf_array[0,0]), proper.prop_get_sampling_arcsec(wf_array[0,0]), 'here'))
    #         if tp.satelite_speck and iwf == 'primary':
    #             tdm.add_speckles(wf)
    #
    #         # tp.variable = proper.prop_get_phase(wfo)[20,20]
    #         # print 'speck phase', tp.variable
    #
    #         # import cPickle as pickle
    #         # dprint('just saved')
    #         # with open(iop.phase_ideal, 'wb') as handle:
    #         #     pickle.dump(proper.prop_get_phase(wf), handle, protocol=pickle.HIGHEST_PROTOCOL)
    #
    #         if tp.active_null and iwf == 'primary':
    #             FPWFS.active_null(wf, PASSVALUE['iter'], w)
    #             # if tp.speckle_kill and iwf == 'primary':
    #             #     tdm.speckle_killer(wf)
    #             # tdm.speck_kill(wf)
    #
    #         # iwf == 'primary':
    #         #     parent_bright = aper_phot(proper.prop_get_amplitude(wf),0,8)
    #
    #
    #         # if iwf == 'primary' and iop.saveIQ:
    #         #     save_pix_IQ(wf)
    #         #     complex_map = proper.prop_shift_center(wf.wfarr)
    #         #     complex_pix = complex_map[64, 64]
    #         #     print complex_pix
    #         #     if np.real(complex_pix) < 0.2:
    #         #         quicklook_IQ(wf)
    #         #
    #         # if iwf == 'primary':
    #         # #     print np.sum(proper.prop_get_amplitude(wf)), 'before', aper_phot(proper.prop_get_amplitude(wf),0,4)
    #         #     quicklook_wf(wf, show=True, logAmp=True)
    #         # if iwf == 'primary':
    #         #     quicklook_wf(wf, show=True)
    #
    #         # if tp.active_modulate and PASSVALUE['iter'] >=8:
    #         #     coronagraph(wf, tp.f_lens, tp.occulter_type, tp.occult_loc, tp.diam)
    #         # if not tp.active_modulate:
    if sp.get_ints: get_intensity(wf_array, sp, phase=False)
    # quicklook_wf(wf_array[0, 0], show=True)
    iter_func(wf_array, coronagraph, *(tp.f_lens, tp.occulter_type, tp.occult_loc, tp.diam))
    # if 'None' not in tp.occulter_type:  # kludge for now until more sophisticated coronagraph has been installed
    #     for iw in range(len(wf_array)):
    #         wf_array[iw,0].wfarr *= 0.1
    if sp.get_ints: get_intensity(wf_array, sp, phase=False)
    # dprint(wf_array.shape)
    # quicklook_wf(wf_array[0, 0], show=True)
    # quicklook_wf(wf_array[0, 1], show=True)
    # quicklook_wf(wf_array[1, 0], show=True)

    dprint(proper.prop_get_sampling_arcsec(wf_array[0,0]))
    # dprint(proper.prop_get_sampling_arcsec(wf_array[0,1]))

    #         # exit()
    #         #     tp.occult_factor = aper_phot(proper.prop_get_amplitude(wf),0,8)/parent_bright
    #         #     if PASSVALUE['iter'] % 10 == 0:
    #         #         with open(iop.logfile, 'a') as the_file:
    #         #               the_file.write('\n', tp.occult_factor)
    #
    #         # quicklook_wf(wf, show=True)
    #         if tp.occulter_type != 'None' and iwf == 'primary':  # kludge for now until more sophisticated coronapraph has been installed
    #             wf.wfarr *= 0.1
    #             #     # print np.sum(proper.prop_get_amplitude(wf)), 'after', aper_phot(proper.prop_get_amplitude(wf), 0, 4)
    #             # quicklook_wf(wf, show=True)
    #         # print proper.prop_get_sampling(wfp), proper.prop_get_sampling_arcsec(wfp), 'here'
    #         # if iwf == 'primary':
    #         #     quicklook_wf(wf, show=True)
    #         if tp.use_zern_ab:
    #             tdm.add_zern_ab(wf, tp.f_lens)
    #

    shape = wf_array.shape
    # comp_scaling = 10*np.arange(1,shape[0]+1)/shape[0]
    # dprint(comp_scaling)

    for iw in range(shape[0]):
        wframes = np.zeros((tp.grid_size, tp.grid_size))
        for io in range(shape[1]):
            (wframe, sampling) = proper.prop_end(wf_array[iw,io])
            # dprint((np.sum(wframe), 'sum'))
            # wframe = proper.prop_get_amplitude(wf)

            # planet = np.roll(np.roll(wframe, 20, 1), 20, 0) * 0.1  # [92,92]
            # if ap.companion:
            #     from scipy.ndimage.interpolation import shift
            #     companion = shift(wframe, shift=  np.array(ap.comp_loc[::-1])- np.array([tp.grid_size/2,tp.grid_size/2])) * ap.contrast
            #     # planet = np.roll(wframe, 15, 0) * 0.1  # [92,92]
            #
            #     wframe = (wframe + companion)

            # quicklook_im(wframe, logAmp=True)
            # '''test conserve=True on prop_magnify!'''

            # wframe = proper.prop_magnify(wframe, (w*1e9)/tp.band[0])
            # wframe = tdm.scale_wframe(wframe, w, iwf)
            # print np.shape(wframe)
            # quicklook_im(wframe, logAmp=True)
            # quicklook_im(wframe[57:201,59:199])

            # mid = int(len(wframe)/2)
            # wframe = wframe[mid - tp.grid_size/2 : mid +tp.grid_size/2, mid - tp.grid_size/2 : mid +tp.grid_size/2]
            # if max(mp.array_size) < tp.grid_size:
            #     # Photons seeded outside the array cannot have pixel phase uncertainty applied to them. Instead make both grids match in size
            #     wframe = rawImageIO.resize_image(wframe, newsize=(max(mp.array_size),max(mp.array_size)))
            # dprint(np.sum(wframe))
            # dprint(iwf)
            # if iwf == 'companion_0':

            # if io > 0:
            #     wframe *= comp_scaling[iw]

            wframes += wframe
            # if sp.show_wframe:
        # quicklook_im(wframes, logAmp=True, show=True)
        datacube.append(wframes)

    datacube = np.array(datacube)
    # if tp.pix_shift:
    #     datacube = np.roll(np.roll(datacube, tp.pix_shift[0], 1), tp.pix_shift[1], 2)
    datacube = np.abs(datacube)
    # #normalize
    # dprint(np.sum(datacube, axis=(1, 2)))

    # dprint((tp.interp_sample , tp.nwsamp>1 , tp.nwsamp<tp.w_bins))
    if tp.interp_sample and tp.nwsamp>1 and tp.nwsamp<tp.w_bins:
        # view_datacube(datacube, logAmp=True)
        wave_samps = np.linspace(0, 1, tp.nwsamp)
        f_out = interp1d(wave_samps, datacube, axis=0)
        new_heights = np.linspace(0, 1, tp.w_bins)
        datacube = f_out(new_heights)
        # dprint(datacube.shape)
        # view_datacube(datacube, logAmp=True)
        
    # datacube = np.transpose(np.transpose(datacube) / np.sum(datacube, axis=(1, 2)))/float(tp.nwsamp)

    # print 'Some pixels have negative values, possibly because of some Gaussian uncertainy you introduced. Taking abs for now.'


    # view_datacube(datacube)
    # # End

    # print type(wfo[0,0]), type(wfo)
    # #     proper.prop_savestate(wfo)
    # # else:
    # #     wfo = proper.prop_state(wfo)
    return (datacube, sampling)












