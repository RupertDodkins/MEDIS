import numpy as np
from scipy import interpolate
import scipy.ndimage
from skimage.restoration import unwrap_phase
import pickle as pickle
from scipy import ndimage
import proper
from proper_mod import prop_dm
import medis.speckle_nulling.dm_functions as DM
from medis.params import tp, cp, mp, ap, iop, sp
from medis.Utils.misc import dprint
from medis.Utils.plot_tools import view_datacube, quicklook_wf, quicklook_im
import matplotlib.pyplot as plt

def no_ao(wfo):
    '''Dummy function for the trigger the GUI to plot'''
    # dprint('running no_ao')
    wfo.test_save('no_ao')
    return

def tiptilt(wfo, CPA_maps, tiptilt):
    for iw in range(len(wfo.wf_array)):
        aperture = np.round(proper.prop_ellipse(wfo.wf_array[iw, 0], tp.diam/2., tp.diam/2.)).astype(np.int)

        # calculate the tiptilt mirror from the phase measurement
        coeffs, map = proper.prop_fit_zernikes(CPA_maps[0, iw], aperture, ap.grid_size*tp.beam_ratio/2., nzer=3, fit=True)
        # map = np.arctan2(np.sin(map), np.cos(map))

        # add this increasingly small correction to the tiptilt mirror
        tiptilt += np.arctan2(np.sin(map), np.cos(map))*aperture

        # update the phase measurement so that the DM predictions take the tiptilt corrections into consideration
        CPA_maps[0, iw] -= map*aperture

        # apply the tiptilt mirror
        proper.prop_add_phase(wfo.wf_array[iw,0], -tiptilt*wfo.wf_array[iw,0]._lamda/(2*np.pi))

    wfo.test_save('tiptilt')

    return CPA_maps, tiptilt

def deformable_mirror(wfo, CPA_maps, astrogrid=False):
    # TODO address the kludge. Is it still necessary
    # dprint('running quick_ao')
    wf_array = wfo.wf_array
    beam_ratios = wfo.beam_ratios

    nact = tp.ao_act  # 49                       # number of DM actuators along one axis
    nact_across_pupil = nact -2 # 47          # number of DM actuators across pupil
    dm_xc = (nact / 2)-0.5
    dm_yc = (nact / 2)-0.5

    shape = wf_array.shape
    for iw in range(shape[0]):
        d_beam = 2 * proper.prop_get_beamradius(wf_array[iw,0])  # beam diameter
        act_spacing = d_beam / nact_across_pupil  # actuator spacing
        # Compensating for chromatic beam size
        dm_map = CPA_maps[0,iw, ap.grid_size//2-np.int_(beam_ratios[iw]*ap.grid_size//2):
                              ap.grid_size//2+np.int_(beam_ratios[iw]*ap.grid_size//2)+1,
                 ap.grid_size//2-np.int_(beam_ratios[iw]*ap.grid_size//2):
                 ap.grid_size//2+np.int_(beam_ratios[iw]*ap.grid_size//2)+1]

        f= interpolate.interp2d(list(range(dm_map.shape[0])), list(range(dm_map.shape[0])), dm_map)
        dm_map = f(np.linspace(0,dm_map.shape[0], nact), np.linspace(0, dm_map.shape[0], nact))

        if tp.piston_error:
            mean_dm_map = np.mean(np.abs(dm_map))
            var = 1e-4  # 1e-11
            dm_map = dm_map + np.random.normal(0, var, (dm_map.shape[0], dm_map.shape[1]))

        dm_map = -dm_map * proper.prop_get_wavelength(wf_array[iw,0]) / (4 * np.pi)

        if tp.satelite_speck:
            s_amp = DM.amplitudemodel(0.4*10**-6, 3, c=1.6)
            phase = 1 % 10 * 2 * np.pi / 10.
            s_amp = 1 % 5 * s_amp / 5.
            xloc, yloc = 12, 12
            waffle = DM.make_speckle_kxy(xloc, yloc, s_amp, phase)
            waffle += DM.make_speckle_kxy(xloc, -yloc, s_amp, phase)
            dm_map += waffle

        for io in range(shape[1]):
            dmap = prop_dm(wf_array[iw,io], dm_map, dm_xc, dm_yc, act_spacing, FIT=True)

    # kludge to help with spiders
    for iw in range(shape[0]):
        phase_map = proper.prop_get_phase(wf_array[iw,0])
        amp_map = proper.prop_get_amplitude(wf_array[iw,0])

        lowpass = ndimage.gaussian_filter(phase_map, 1, mode='nearest')
        smoothed = phase_map - lowpass

        wf_array[iw, 0].wfarr = proper.prop_shift_center(amp_map*np.cos(smoothed)+1j*amp_map*np.sin(smoothed))

    wfo.test_save('deformable_mirror')

    return

def flat_outside(wf_array):
    for iw in range(wf_array.shape[0]):
        for io in range(wf_array.shape[1]):
            proper.prop_circular_aperture(wf_array[iw,io], 1, NORM=True)

def quick_wfs(wfo, scale_shortest=True):
    if sp.verbose: print('running quick wfs')

    short_wf = wfo.wf_array[0, 0]
    CPA_maps = np.zeros((1,len(wfo.wf_array),ap.grid_size,ap.grid_size))

    if scale_shortest:
        CPA_maps[0, 0] = unwrap_phase(proper.prop_get_phase(short_wf))
        wsamples = np.linspace(ap.band[0], ap.band[1], ap.nwsamp) / 1e9
        x = np.arange(-ap.grid_size / 2, ap.grid_size / 2)
        for iw in range(1, len(wsamples)):
            beam_ratio = ap.band[0] / wsamples[iw] * 1e-9
            zeros_ind = int(ap.grid_size * (1 - beam_ratio) / 2)
            xnew = np.arange(-ap.grid_size / 2, ap.grid_size / 2, 1. / beam_ratio)
            f = interpolate.interp2d(x, x, CPA_maps[0, 0], kind='cubic')
            shrink = f(xnew, xnew)
            if len(shrink) % 2 == 0:
                CPA_maps[0, iw, zeros_ind:-zeros_ind, zeros_ind:-zeros_ind] = shrink
            else:
                CPA_maps[0, iw, zeros_ind+1:-zeros_ind, zeros_ind+1:-zeros_ind] = shrink

    else:
        for iw in range(len(wfo.wf_array)):
            CPA_maps[0, iw] = unwrap_phase(proper.prop_get_phase(wfo.wf_array[iw,0]))
    # CPA_maps[iw] = scipy.ndimage.filters.gaussian_filter(unwrap_phase(proper.prop_get_phase(wf_vec[iw])), sigma,
    #                                                      mode='constant')

    # if tp.piston_error:
    #     var = 1e-4  #1e-11 #0.1 wavelengths 0.1*1000e-9
    #     CPA_maps[iw] = CPA_maps[iw] + np.random.normal(0,var,(CPA_maps[iw].shape[0],CPA_maps[iw].shape[1]))
    tiptilt = np.zeros((ap.grid_size,ap.grid_size))

    wfo.test_save('quick_wfs')
    return CPA_maps, tiptilt

def closedloop_wfs(wfo, CPA_maps):
    sigma = [2, 2]
    for iw in range(len(wfo.wf_array[:, 0])):
        # CPA_maps[0, iw] = scipy.ndimage.filters.gaussian_filter(unwrap_phase(proper.prop_get_phase(wfo.wf_array[iw, 0])),
        #                                                         sigma, mode='constant')
        CPA_maps[0, iw] = unwrap_phase(proper.prop_get_phase(wfo.wf_array[iw, 0]))
        CPA_maps[0, iw] *= np.round(proper.prop_ellipse(wfo.wf_array[iw, 0], tp.diam/2., tp.diam/2.)).astype(np.int)
    if tp.servo_error:
        # for iw in range(len(wfo.wf_array[:, 0])):
        # print 'This might produce garbage if several processes are run in parrallel'
        CPA_maps = np.roll(CPA_maps,1,0)
        required_servo = int(tp.servo_error[0]) # delay
        required_band = int(tp.servo_error[1]) # averaging
        CPA_maps[0] = np.sum(CPA_maps[required_servo:],axis=0)/ required_band


    wfo.test_save('closedloop_wfs')
    return CPA_maps

def wfs_measurement(wfo, iter, iw, r0):#, obj_map, wfs_sample):
    # TODO verify that several processes running in parrellel does not mess this up for closed loop AO
    # print 'Including WFS Error'

    with open(iop.CPA_meas, 'rb') as handle:
        CPA_maps, iters = pickle.load(handle)

    sigma = [1, 1]

    CPA_maps[0, iw] += scipy.ndimage.filters.gaussian_filter(unwrap_phase(proper.prop_get_phase(wfo)), sigma,
                                                             mode='constant')
    if tp.servo_error:
        # print 'This might produce garbage if several processes are run in parrallel'
        CPA_maps[:,iw] = np.roll(CPA_maps[:,iw],1,0)
        required_servo = int(tp.servo_error[0]) # delay
        required_band = int(tp.servo_error[1]) # averaging

        CPA_maps[0,iw] = np.sum(CPA_maps[required_servo:-1,iw],axis=0)/ required_band


    with open(iop.CPA_meas, 'wb') as handle:
        pickle.dump((CPA_maps, iters+1), handle, protocol=pickle.HIGHEST_PROTOCOL)


