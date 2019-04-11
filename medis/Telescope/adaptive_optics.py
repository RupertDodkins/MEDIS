import numpy as np
from scipy import interpolate
import pickle as pickle
from scipy import ndimage
import proper
from proper_mod import prop_dm
from medis.params import tp, cp, mp, ap, iop

def adaptive_optics(wfo, iwf, iw, f_lens, beam_ratio, iter):
    # print 'Including Adaptive Optics'

    # code to distort measured phase map goes here....
    # print 'add code to distort phase measurment'
    nact = tp.ao_act  # number of DM actuators along one axis
    nact_across_pupil = nact-2#/1.075#nact #47          # number of DM actuators across pupil
    dm_xc = (nact / 2) -0.5#-1#0.5#- 0.5
    dm_yc = (nact / 2) -0.5#-1#0.5#- 0.5
    d_beam = 2 * proper.prop_get_beamradius(wfo)        # beam diameter
    act_spacing = d_beam / (nact_across_pupil)     # actuator spacing
    map_spacing = proper.prop_get_sampling(wfo)        # map sampling

    try:
        with open(iop.CPA_meas, 'rb') as handle:
            CPA_maps, iters = pickle.load(handle)
    except EOFError:
        print('CPA file not ready?')
        import time
        time.sleep(10)
        with open(iop.CPA_meas, 'rb') as handle:
            CPA_maps, iters = pickle.load(handle)

    if iwf[:9] == 'companion':
        CPA_map = CPA_maps[1,iw]
    else:
        CPA_map = CPA_maps[0,iw]

    dm_map = CPA_map[ap.grid_size/2-(beam_ratio*ap.grid_size/2):ap.grid_size/2+(beam_ratio*ap.grid_size/2)+1, ap.grid_size/2-(beam_ratio*ap.grid_size/2):ap.grid_size/2+(beam_ratio*ap.grid_size/2)+1]
    f= interpolate.interp2d(list(range(dm_map.shape[0])), list(range(dm_map.shape[0])), dm_map)
    dm_map = f(np.linspace(0,dm_map.shape[0],nact),np.linspace(0,dm_map.shape[0],nact))
    dm_map = -dm_map*proper.prop_get_wavelength(wfo)/(4*np.pi) #<--- here
    # dm_map = -dm_map * proper.prop_get_wavelength(wfo) / (2 * np.pi)
    # if tp.piston_error:
    #     mean_dm_map = np.mean(np.abs(dm_map))
    #     var = mean_dm_map/200.#40.
    #     print var
    #     # var = 0.001#1e-11
    #     if var != 0.0:
    #         dm_map = dm_map + np.random.normal(0, var, (dm_map.shape[0], dm_map.shape[1]))

    if tp.active_null:
        with open(iop.NCPA_meas, 'rb') as handle:
            _, null_map,_ = pickle.load(handle)
        dm_NCPA = null_map*proper.prop_get_wavelength(wfo)/(4*np.pi)
        dm_map += dm_NCPA

    if tp.active_modulate and iter >=8:
        import medis.speckle_nulling.dm_functions as DM
        # speck.generate_flatmap(phase)
        s_amp = DM.amplitudemodel(0.05, 30, c=1.6)
        tp.null_ao_act = tp.ao_act
        xloc, yloc = 4, 0

        phase = iter % 10 * 2 * np.pi / 10.
        s_amp = iter % 5 * s_amp/ 5.
        waffle = DM.make_speckle_kxy(xloc, yloc, s_amp, phase) / 1e6
        waffle += DM.make_speckle_kxy(yloc, xloc, s_amp, -phase) / 1e6
        waffle += DM.make_speckle_kxy(0.71 * xloc, 0.71 * xloc, s_amp, -phase) / 1e6
        waffle += DM.make_speckle_kxy(0.71 * xloc, -0.71 * xloc, s_amp, -phase) / 1e6
        waffle /= 4

        dm_map = -dm_map * proper.prop_get_wavelength(wfo) / (4 * np.pi * 5) * (iter % 10 - 5)
        # dm_map = dm_map/5. * (iter % 10 - 5)
        # dmap = proper.prop_dm(wfo, pattern, dm_xc, dm_yc,
        #                       N_ACT_ACROSS_PUPIL=nact, FIT=True)
    # dmap =proper.prop_dm(wfo, dm_map, dm_xc, dm_yc, N_ACT_ACROSS_PUPIL=nact, FIT = True) #<-- here
    dmap = prop_dm(wfo, dm_map, dm_xc, dm_yc, act_spacing, FIT = True) #<-- here

    return


def quick_ao(wfo, CPA_maps):
    # TODO address the kludge. Is it still necessary

    wf_array = wfo.wf_array
    beam_ratios = wfo.beam_ratios

    nact = tp.ao_act  # 49                       # number of DM actuators along one axis
    nact_across_pupil = nact -2 # 47          # number of DM actuators across pupil
    dm_xc = (nact / 2)-0.5
    dm_yc = (nact / 2)-0.5

    shape = wf_array.shape

    for iw in range(shape[0]):
        for io in range(shape[1]):
            d_beam = 2 * proper.prop_get_beamradius(wf_array[iw,io])  # beam diameter
            act_spacing = d_beam / nact_across_pupil  # actuator spacing
            # Compensating for chromatic beam size
            dm_map = CPA_maps[iw,ap.grid_size//2-np.int_(beam_ratios[iw]*ap.grid_size//2):
                                ap.grid_size//2+np.int_(beam_ratios[iw]*ap.grid_size//2)+1,
                                ap.grid_size//2-np.int_(beam_ratios[iw]*ap.grid_size//2):
                                ap.grid_size//2+np.int_(beam_ratios[iw]*ap.grid_size//2)+1]
            f= interpolate.interp2d(list(range(dm_map.shape[0])), list(range(dm_map.shape[0])), dm_map)
            dm_map = f(np.linspace(0,dm_map.shape[0],nact),np.linspace(0,dm_map.shape[0],nact))
            # dm_map = proper.prop_magnify(CPA_map, map_spacing / act_spacing, nact)

            if tp.piston_error:
                mean_dm_map = np.mean(np.abs(dm_map))
                var = 1e-4  # 1e-11
                dm_map = dm_map + np.random.normal(0, var, (dm_map.shape[0], dm_map.shape[1]))


            dm_map = -dm_map * proper.prop_get_wavelength(wf_array[iw,io]) / (4 * np.pi)  # <--- here
            # dmap = proper.prop_dm(wfo, dm_map, dm_xc, dm_yc, N_ACT_ACROSS_PUPIL=nact, FIT=True)  # <-- here
            dmap = prop_dm(wf_array[iw,io], dm_map, dm_xc, dm_yc, act_spacing, FIT=True)  # <-- here

    # kludge to help with spiders
    for iw in range(shape[0]):
        phase_map = proper.prop_get_phase(wf_array[iw,0])
        amp_map = proper.prop_get_amplitude(wf_array[iw,0])

        lowpass = ndimage.gaussian_filter(phase_map, 1, mode='nearest')
        smoothed = phase_map- lowpass

        wf_array[iw,0].wfarr = proper.prop_shift_center(amp_map*np.cos(smoothed)+1j*amp_map*np.sin(smoothed))

    wfo.test_save('quick_ao')

    return

def flat_outside(wf_array):
    for iw in range(wf_array.shape[0]):
        for io in range(wf_array.shape[1]):
            proper.prop_circular_aperture(wf_array[iw,io], 1, NORM=True)

def quick_wfs(wf_vec, iter, r0):

    import scipy.ndimage
    from skimage.restoration import unwrap_phase

    sigma = [1, 1]
    CPA_maps = np.zeros((len(wf_vec),ap.grid_size,ap.grid_size))
    for iw in range(len(wf_vec)):
        CPA_maps[iw] = scipy.ndimage.filters.gaussian_filter(unwrap_phase(proper.prop_get_phase(wf_vec[iw])), sigma,
                                                             mode='constant')
        if tp.piston_error:
            var = 1e-4#1e-11 #0.1 wavelengths 0.1*1000e-9
            CPA_maps[iw] = CPA_maps[iw] + np.random.normal(0,var,(CPA_maps[iw].shape[0],CPA_maps[iw].shape[1]))

    return CPA_maps

def wfs_measurement(wfo, iter, iw,r0):#, obj_map, wfs_sample):
    # TODO verify that several processes running in parrellel does not mess this up for closed loop AO
    # print 'Including WFS Error'

    with open(iop.CPA_meas, 'rb') as handle:
        CPA_maps, iters = pickle.load(handle)

    import scipy.ndimage
    sigma = [1, 1]
    from skimage.restoration import unwrap_phase
    CPA_maps[0, iw] += scipy.ndimage.filters.gaussian_filter(unwrap_phase(proper.prop_get_phase(wfo)), sigma, mode='constant')
    if tp.servo_error:
        # print 'This might produce garbage if several processes are run in parrallel'
        CPA_maps[:,iw] = np.roll(CPA_maps[:,iw],1,0)
        required_servo = int(tp.servo_error[0]) # delay
        required_band = int(tp.servo_error[1]) # averaging

        CPA_maps[0,iw] = np.sum(CPA_maps[required_servo:-1,iw],axis=0)/ required_band


    with open(iop.CPA_meas, 'wb') as handle:
        pickle.dump((CPA_maps, iters+1), handle, protocol=pickle.HIGHEST_PROTOCOL)


