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

import proper
print proper.__file__
import Telescope.telescope_dm as tdm
from Telescope.coronagraph import coronagraph
import Telescope.FPWFS as FPWFS
from Utils.plot_tools import view_datacube, quicklook_wf, quicklook_im, quicklook_IQ, loop_frames
import Utils.rawImageIO as rawImageIO
# import matplotlib.pylab as plt
# import params
from params import ap, tp, iop

import numpy as np
from Analysis.stats import save_pix_IQ
from Analysis.phot import aper_phot
import speckle_killer_v3 as skv3
from Utils.misc import dprint



# print 'line 21', tp.occulter_type
def run_system(empty_lamda, grid_size, PASSVALUE ):#'dm_disp':0
    passpara = PASSVALUE['params']
    ap.__dict__ = passpara[0].__dict__
    tp.__dict__ = passpara[1].__dict__
    iop.__dict__ = passpara[2].__dict__
    # params.ap = passpara[0]
    # params.tp = passpara[1]
    #
    # ap = params.ap
    # tp = params.tp

    # print 'line 23', tp.occulter_type
    # print 'propagating frame:', PASSVALUE['iter']
    wsamples = np.linspace(tp.band[0], tp.band[1], tp.nwsamp)/1e9
    # print wsamples
    datacube = []
    # print proper.prop_get_sampling(wfp), proper.prop_get_nyquistsampling(wfp), proper.prop_get_fratio(wfp)
    # global phase_map, Imaps
    # Imaps = np.zeros((4,tp.grid_size,tp.grid_size))
    # phase_map = np.zeros((tp.grid_size, tp.grid_size))
    # wavefronts = np.empty((len(wsamples),1+len(ap.contrast)), dtype=object)
    for iw, w in enumerate(wsamples):
        # Define the wavefront
        beam_ratio =  tp.beam_ratio*tp.band[0]/w*1e-9
        wfp = proper.prop_begin(tp.diam, w, tp.grid_size, beam_ratio)

        wfs = [wfp]
        names = ['primary']
        if ap.companion:
            for id in range(len(ap.contrast)):
                wfc = proper.prop_begin(tp.diam, w, tp.grid_size, beam_ratio)
                wfs.append(wfc)
                names.append('companion_%i'%id)

        # proper.prop_circular_aperture(wfo, tp.diam / 2)
        # for iw, wf in enumerate([wfo, wfc]):
        wframes = np.zeros((tp.grid_size,tp.grid_size))
        for iwf, wf in zip(names,wfs):
            # wavefronts[iw,iwf] = wf
            proper.prop_circular_aperture(wf, tp.diam/2)
            # quicklook_wf(wf, show=True)
            if tp.use_atmos:
                tdm.add_atmos(wf, tp.f_lens, w, atmos_map = PASSVALUE['atmos_map'])

            if tp.rot_rate:
                tdm.rotate_atmos(wf, PASSVALUE['atmos_map'])

            # quicklook_wf(wf, show=True)
            # if tp.use_spiders:
            #     tdm.add_spiders(wf, tp.diam)

            if tp.use_hex:
                tdm.add_hex(wf)

            proper.prop_define_entrance(wf) # normalizes the intensity

            if iwf[:9] == 'companion':
                tdm.offset_companion(wf, int(iwf[10:]), PASSVALUE['atmos_map'])
                # quicklook_wf(wf, show=True)
            if tp.use_apod:
                tdm.do_apod(wf, tp.grid_size, tp.beam_ratio, tp.apod_gaus)

            # quicklook_wf(wf, show=True)
            # obj_map = tdm.wfs_measurement(wfo)#, obj_map, tp.wfs_scale)
            proper.prop_propagate(wf, tp.f_lens)

            if tp.aber_params['CPA']:
                tdm.add_aber(wf,tp.f_lens,tp.aber_params,tp.aber_vals,PASSVALUE['iter'],Loc='CPA')

            # if tp.CPA_type == 'test':
            #     tdm.add_single_speck(wf, PASSVALUE['iter'] )
            # if tp.CPA_type == 'Static':
            #     tdm.add_static(wf, tp.f_lens, loc = 'CPA')
            # if tp.CPA_type == 'Amp':
            #     tdm.add_static(wf, tp.f_lens, loc = 'CPA', type='Amp')
            # if tp.CPA_type == 'Quasi':
            #     tdm.add_quasi(wf, tp.f_lens, PASSVALUE['iter'])

            # rawImageIO.save_wf(wf, iop.datadir+'/beforeAO.pkl')
            # quicklook_wf(wf)
            # quicklook_im(obj_map, logAmp=False)

            proper.prop_propagate(wf, tp.f_lens)
            if tp.quick_ao:
                if iwf == 'primary':  # and PASSVALUE['iter'] == 0:
                    # quicklook_wf(wf, show=True)
                    r0 = float(PASSVALUE['atmos_map'][-10:-5])
                    # dprint((r0, 'r0'))
                    CPA_map = tdm.quick_wfs(wf, PASSVALUE['iter'], r0=r0)  # , obj_map, tp.wfs_scale)
                # dprint('quick_ao')
                # quicklook_wf(wf, show=True)
                if tp.use_ao:
                    tdm.quick_ao(wf, iwf, tp.f_lens, beam_ratio, PASSVALUE['iter'], CPA_map)
                # dprint('quick_ao')
                # quicklook_wf(wf, show=True)
            else:
                if tp.use_ao:
                    tdm.adaptive_optics(wf, iwf, iw, tp.f_lens, beam_ratio, PASSVALUE['iter'])

                if iwf == 'primary':# and PASSVALUE['iter'] == 0:
                    # quicklook_wf(wf, show=True)
                    r0 = float(PASSVALUE['atmos_map'][-10:-5])
                    # dprint((r0, 'r0'))
                    # if iw == np.ceil(tp.nwsamp/2):
                    tdm.wfs_measurement(wf, PASSVALUE['iter'], iw, r0 = r0)#, obj_map, tp.wfs_scale)

            proper.prop_propagate(wf, tp.f_lens)

            # rawImageIO.save_wf(wf, iop.datadir+'/loopAO_8act.pkl')
            # if iwf == 'primary':
            #     quicklook_wf(wf, show=True)


            # if tp.active_modulate:
            #     tdm.modulate(wf, w, PASSVALUE['iter'])

            # if iwf == 'primary':
            #     quicklook_wf(wf, show=True)

            if tp.aber_params['NCPA']:
                tdm.add_aber(wf,tp.f_lens,tp.aber_params,tp.aber_vals,PASSVALUE['iter'],Loc='NCPA')

            # if tp.NCPA_type == 'Static':
            #     tdm.add_static(wf, tp.f_lens, loc = 'NCPA')
            # if tp.NCPA_type == 'Wave':
            #     tdm.add_IFS_ab(wf, tp.f_lens, w)
            # if tp.NCPA_type == 'Quasi':
            #     tdm.add_quasi(wf, tp.f_lens, PASSVALUE['iter'])

            # quicklook_wf(wf, show=True)

            # if iwf == 'primary':
            #     NCPA_phasemap = proper.prop_get_phase(wf)
            #     quicklook_im(NCPA_phasemap, logAmp=False, show=False, colormap="jet", vmin=-3.14, vmax=3.14)
            # if iwf == 'primary':
            #     global obj_map
            #     r0 = float(PASSVALUE['atmos_map'][-10:-5])
            #     obj_map = tdm.wfs_measurement(wf, r0 = r0)#, obj_map, tp.wfs_scale)
            #     # quicklook_im(obj_map, logAmp=False)


            proper.prop_propagate(wf, tp.f_lens)

            # spiders are introduced here for now since the phase unwrapping seems to ignore them and hence so does the DM
            # Check out http://scikit-image.org/docs/dev/auto_examples/filters/plot_phase_unwrap.html for masking argument
            if tp.use_spiders:
                tdm.add_spiders(wf, tp.diam)

            tdm.prop_mid_optics(wf, tp.f_lens)


            # if iwf == 'primary':
            # if PASSVALUE['iter']>ap.numframes-2 or PASSVALUE['iter']==0:
            #     quicklook_wf(wf, show=True)
            # print proper.prop_get_sampling(wfp), proper.prop_get_sampling_arcsec(wfp), 'here'
            if tp.satelite_speck and iwf == 'primary':
                tdm.add_speckles(wf)

            # tp.variable = proper.prop_get_phase(wfo)[20,20]
            # print 'speck phase', tp.variable

            # import cPickle as pickle
            # dprint('just saved')
            # with open(iop.phase_ideal, 'wb') as handle:
            #     pickle.dump(proper.prop_get_phase(wf), handle, protocol=pickle.HIGHEST_PROTOCOL)
            # exit()

            if tp.active_null and iwf == 'primary':
                FPWFS.active_null(wf, PASSVALUE['iter'], w)
            # if tp.speckle_kill and iwf == 'primary':
            #     tdm.speckle_killer(wf)
                # tdm.speck_kill(wf)

            # iwf == 'primary':
            #     parent_bright = aper_phot(proper.prop_get_amplitude(wf),0,8)


            # if iwf == 'primary' and iop.saveIQ:
            #     save_pix_IQ(wf)
            #     complex_map = proper.prop_shift_center(wf.wfarr)
            #     complex_pix = complex_map[64, 64]
            #     print complex_pix
            #     if np.real(complex_pix) < 0.2:
            #         quicklook_IQ(wf)
            #
            # if iwf == 'primary':
            # #     print np.sum(proper.prop_get_amplitude(wf)), 'before', aper_phot(proper.prop_get_amplitude(wf),0,4)
            #     quicklook_wf(wf, show=True, logAmp=True)
            # if iwf == 'primary':
            #     quicklook_wf(wf, show=True)

            # if tp.active_modulate and PASSVALUE['iter'] >=8:
            #     coronagraph(wf, tp.f_lens, tp.occulter_type, tp.occult_loc, tp.diam)
            # if not tp.active_modulate:
            coronagraph(wf, tp.f_lens, tp.occulter_type, tp.occult_loc, tp.diam)
            # dprint(proper.prop_get_sampling_arcsec(wf))
            # exit()
            #     tp.occult_factor = aper_phot(proper.prop_get_amplitude(wf),0,8)/parent_bright
            #     if PASSVALUE['iter'] % 10 == 0:
            #         with open(iop.logfile, 'a') as the_file:
            #               the_file.write('\n', tp.occult_factor)

            # quicklook_wf(wf, show=True)
            if tp.occulter_type != 'None' and iwf == 'primary': #kludge for now until more sophisticated coronapraph has been installed
                wf.wfarr *= 0.1
            #     # print np.sum(proper.prop_get_amplitude(wf)), 'after', aper_phot(proper.prop_get_amplitude(wf), 0, 4)
                # quicklook_wf(wf, show=True)
            # print proper.prop_get_sampling(wfp), proper.prop_get_sampling_arcsec(wfp), 'here'
            # if iwf == 'primary':
            #     quicklook_wf(wf, show=True)
            if tp.use_zern_ab:
                tdm.add_zern_ab(wf, tp.f_lens)

            (wframe, sampling) = proper.prop_end(wf)
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
            quicklook_im(wframe)
            # quicklook_im(wframe)

            # mid = int(len(wframe)/2)
            # wframe = wframe[mid - tp.grid_size/2 : mid +tp.grid_size/2, mid - tp.grid_size/2 : mid +tp.grid_size/2]
            # if max(mp.array_size) < tp.grid_size:
            #     # Photons seeded outside the array cannot have pixel phase uncertainty applied to them. Instead make both grids match in size
            #     wframe = rawImageIO.resize_image(wframe, newsize=(max(mp.array_size),max(mp.array_size)))
            # dprint(np.sum(wframe))
            # dprint(iwf)
            # if iwf == 'companion_0':
            wframes += wframe
            # if sp.show_wframe:
        # quicklook_im(wframes, logAmp=True, show=True)
        datacube.append(wframes)

    datacube = np.array(datacube)
    datacube = np.abs(datacube)
    # #normalize
    # datacube = np.transpose(np.transpose(datacube) / np.sum(datacube, axis=(1, 2)))/float(tp.nwsamp)

    # print 'Some pixels have negative values, possibly because of some Gaussian uncertainy you introduced. Taking abs for now.'


    # view_datacube(datacube)
    # # End

    # print type(wfo[0,0]), type(wfo)
        # #     proper.prop_savestate(wfo)  
    # # else:
    # #     wfo = proper.prop_state(wfo)
    return (datacube, sampling)

    # calib_file = 'calib_map.txt'
    # if not os.path.isfile(calib_file):
    #     FPWFS.do_amp_calib_1d(wfo, f_lens, calib_file)
    
    # abs_locs = [[450,512]]
    # abs_locs = [[100,128], [50,128]]
    # abs_locs = [[75,128]]
    # # Is = [0.05, 0.05]#[0.5]
    # Is = [0.01]
    # num_speck = len(abs_locs)
    # for s in range(num_speck):
    #     # abs_loc = abs_locs[s]
    #     # locs = [128,128] -np.array(abs_locs)
    #     add_speckle(wfo, abs_locs[s], Is[s])

    # quicklook_wf(wfo)
    # plt.show()

    # hdu = pyfits.PrimaryHDU(proper.prop_get_amplitude(wfo))
    # hdulist = pyfits.HDUList([hdu])
    # #hdulist.writeto(out_dir + '%i-%i%i.fits' % (f,x1,x2))
    # out_dir = './'#'./atmos/' 
    # f = PASSVALUE["iter"]
    # print f
    # f = int(f)
    # outfile = out_dir + 'frame%i.fits' % (f)
    # #if os.path.isfile(outfile):
    #     #outfile = outfile 'b.'.join(outfile.split('.'))
    # hdulist.writeto(outfile)

    # pyfits.writeto('test.fits', proper.prop_get_amplitude(wfo))
    # skv3.speck_killing_loop(wfo)
    # plt.imshow(nullmap)
    # locs = [[30,0],[50,0],[40,0]]
    # abs_locs = [[111,116],[113,131]]
    # num_spec = len(abs_locs)
    # for s in range(num_spec):
    #     for r in range(2):
    #         abs_loc = abs_locs[s]

    #         loc = [128,128] -np.array(abs_loc)
    #         print np.shape(loc)
    #         # locs[:,1] = locs[:,1]*-1 
    #         print loc

    #         # locs = [[20,50]]#,[30,30]]#, [50,0]]
    #         I = 0.25

    #         # for s in range(num_spec):
    #         #     add_speckle(wfo, locs[s], Is[s])

    #         phis = np.zeros((num_spec))
    #         kxs = np.zeros((num_spec))
    #         kys = np.zeros((num_spec))
    #         amps = np.zeros((num_spec))
    #         dm_z = PASSVALUE["dm_z"]

    #         # for s in range(num_spec):
    #         s = 0
    #         wf_temp = copy.copy(wfo)
    #         phi,kx,ky,amp = speckle_killer(wf_temp, f_lens, dm_z, loc, I)
    #         del wf_temp

    #         # phis = [4.71238898038,3.1415926535897931]
    #         # ks = [8.90207715134, 14.836795252225519]
    #         print phi, kx, ky, amp
    #         # amp = 1.9576635365271368e-08
    #         obj_map = DM.create_waffle([phi],[kx], [ky],[amp])
    #         FPWFS.propagate_DM(wfo, f_lens, obj_map)
    #         quicklook_wf(wfo)
    #         plt.show()
    #         speckle_killer(wfo, f_lens, dm_z, [50,0])


# wf.wfarr = proper.prop_shift_center(wf.wfarr)
# wf.wfarr = proper.prop_magnify(wf.wfarr, tp.band[0] / (w * 1e9), QUICK=True)  #
# # mid = int(tp.grid_size/2)
# # wf.wfarr = wf.wfarr[mid - tp.grid_size/2 : mid +tp.grid_size/2, mid - tp.grid_size/2 : mid +tp.grid_size/2]
# wf.wfarr = np.lib.pad(wf.wfarr, (tp.grid_size - len(wf.wfarr)) / 2, mode='constant')
# wf.wfarr = proper.prop_shift_center(wf.wfarr)
# # wf.wfarr = proper.prop_shift_center(wf.wfarr)
# # complex_ten = np.transpose(np.array([np.real(wf.wfarr), np.imag(wf.wfarr)]))
# # print np.shape(complex_ten)
# # Data = clipped_zoom(complex_ten, tp.band[0]/w*1e-9)
# # Data = np.transpose(Data)
# # wf.wfarr = proper.prop_shift_center(Data[0] + 1j * Data[1])
# quicklook_wf(wf, show=True)














