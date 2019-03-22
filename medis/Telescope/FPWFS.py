#
import sys
import proper
import numpy as np
import pickle as pickle
# # import vip
# # import pyfits as pyfits
# import matplotlib.pylab as plt
# import copy
# import math
# # import deformable_mirror as DM
# from scipy.optimize import curve_fit
# # from scipy import interpolate
from medis.params import tp, cp, mp, ap, iop, fp
import medis.speckle_nulling.speckle_killer_v3 as skv3
import medis.speckle_nulling.dm_functions as DM
from medis.Utils.plot_tools import loop_frames, quicklook_wf, quicklook_im
import copy
from configobj import ConfigObj
from validate import Validator

controlregion = np.zeros((ap.grid_size, ap.grid_size))
controlregion[fp.controlregion[0]:fp.controlregion[1], fp.controlregion[2]:fp.controlregion[3]] = 1

def add_single_speck(wfo, iter):
    # if iter <4:
    xloc = ap.lods[0][0]
    yloc = ap.lods[0][1]
    wf_temp = copy.deepcopy(wfo)
    proper.prop_zernikes(wf_temp, [4], np.array([-1 * xloc]) * 1e-6)
    wfo.wfarr += wf_temp.wfarr*2.5

def speckle_killer(wf, phase_map):
    # with open(iop.phase_ideal, 'rb') as handle:
    #     phase_ideal = pickle.load(handle)

    # quicklook_im(phase_map, logAmp=False)

    ijofinterest = skv3.identify_bright_points(proper.prop_get_amplitude(wf), controlregion)
    xyofinterest = [p[::-1] for p in ijofinterest]
    print(xyofinterest, len(xyofinterest))
    if len(xyofinterest) == 0:
        y = int(np.random.uniform(fp.controlregion[0],fp.controlregion[1]))
        x = int(np.random.uniform(fp.controlregion[2], fp.controlregion[3]))
        xyofinterest = [(y,x)]
    if len(xyofinterest) < fp.max_specks:
        fp.max_specks = len(xyofinterest)
    print(fp.max_specks)
    fps = skv3.filterpoints(xyofinterest,max=fp.max_specks,rad=fp.exclusionzone)
    print(fps)


    null_map = np.zeros((tp.ao_act,tp.ao_act))
    for speck in fps:
        print(speck)
        kvecx, kvecy = DM.convert_pixels_kvecs(speck[0],speck[1],ap.grid_size/2,ap.grid_size/2,angle=0,lambdaoverd=fp.lod )
        dm_phase = phase_map[speck[1],speck[0]]
        s_amp = proper.prop_get_amplitude(wf)[speck[1],speck[0]]*5.3

        null_map += -DM.make_speckle_kxy(kvecx, kvecy, s_amp, dm_phase)#+s_ideal#- 1.9377
    null_map /= len(fps)

    area_sum = np.sum(proper.prop_get_amplitude(wf)*controlregion)
    print(area_sum)
    with open(iop.measured_var, 'ab') as handle:
        pickle.dump(area_sum, handle, protocol=pickle.HIGHEST_PROTOCOL)

    return null_map

def active_null(wf, iter, w):

    ip = iter % 4
    with open(iop.NCPA_meas, 'rb') as handle:
        Imaps, null_map, _ = pickle.load(handle)
    Imaps[ip] = piston_refbeam(wf, iter, w)

    # loop_frames(Imaps)
    # focal_map = None
    if (iter+1)%4 == 0:# and not np.any(Imaps[:,1,1] == 0): #iter >= 3
        focal_map = measure_phase(Imaps)
        # quicklook_wf(wf, show=True)
        # quicklook_im(proper.prop_get_phase(wf), logAmp=False, show=False, colormap="jet", vmin=-3.14, vmax=3.14)
        # quicklook_im(phase_map, logAmp=False, show=False, colormap="jet", vmin=-3.14, vmax=3.14)
        # quicklook_im(proper.prop_get_phase(wf)-phase_map, logAmp=False, show=False, colormap="jet", vmin=-3.14, vmax=3.14)

    # if iter >= tp.active_converge_steps*4:
    # if focal_map != None:
        print('running speckle killer')
        null_map += speckle_killer(wf, focal_map)

    with open(iop.NCPA_meas, 'wb') as handle:
        pickle.dump((Imaps, null_map, iter+1), handle, protocol=pickle.HIGHEST_PROTOCOL)

def piston_refbeam(wf, iter, w):
    beam_ratio = 0.7 * ap.band[0] / w * 1e-9
    wf_ref = proper.prop_begin(tp.diam, w, ap.grid_size, beam_ratio)
    proper.prop_define_entrance(wf_ref)
    phase_mod = iter%4 * w/4#np.pi/2
    obj_map = np.ones((ap.grid_size,ap.grid_size))*phase_mod
    proper.prop_add_phase(wf_ref, obj_map)
    wf_ref.wfarr = wf.wfarr + wf_ref.wfarr
    Imap =proper.prop_shift_center(np.abs(wf_ref.wfarr) ** 2)
    return Imap

def measure_phase(Imaps):
    phase_map = -1*np.arctan2(Imaps[3]-Imaps[1],Imaps[0]-Imaps[2]) #*180/np.pi

    # phase_map = proper.prop_shift_center(phase_map)
    # phase_map = np.roll(np.roll(np.rot90(phase_map, 2), 1, 0), 1, 1)  # to convert back to how it is by the DM
    return phase_map

def modulate(wfo, w, iter):
    # phase_mod = np.ones((ap.grid_size,ap.grid_size))*(iter%4) * w/4.
    # phase_arr = proper.prop_get_phase(wfo)
    # phase_mod[phase_arr == 0] = 0
    # proper.prop_add_phase(wfo, phase_mod)

    # phase_mod = (iter % 8) * w / 8. - w/4.
    # proper.prop_zernikes(wfo, [4], np.array([phase_mod])/4.)

    # import medis.speckle_nulling.dm_functions as DM
    # # speck.generate_flatmap(phase)
    # s_amp = DM.amplitudemodel(0.05, 30, c=1.6)
    # waffle = DM.make_speckle_kxy(3, 3, s_amp, np.pi/2.)
    # proper.prop_add_phase(wfo, waffle)

    # quicklook_wf(wfo)
    rms_error = 5e-7  # 500.e-9       # RMS wavefront error in meters
    c_freq = 0.005  # correlation frequency (cycles/meter)
    high_power = 2.  # high frewquency falloff (r^-high_power)
    phase_map = proper.prop_psd_errormap(wfo, rms_error, c_freq, high_power,
                             MAP="prim_map")

    # proper.prop_add_phase(wfo, phase_map)

def add_speckles(wfo, pair=True):
    sys.path.append(tp.FPWFSdir)
    import speckle_killer_v3 as skv3
    # speckle = np.roll(np.roll(wfo.wfarr, loc[0],1),loc[1],0)*I#[92,92]
    # wfo.wfarr = (wfo.wfarr+speckle)
    # if pair:
    #     speckle = np.roll(np.roll(wfo.wfarr, -1*loc[0],1),-1*loc[1],0)*I#[92,92]
    #     wfo.wfarr = (wfo.wfarr+speckle)
    # dm_z = proper.prop_fits_read('dm.fits')
    configfilename = tp.FPWFSdir+'speckle_null_config_Rupe.ini'
    configspecfile = tp.FPWFSdir+'speckle_null_config.spec'
    config = ConfigObj(configfilename, configspec=configspecfile)
    val = Validator()
    check = config.validate(val)

    num_speck = len(tp.speck_locs)
    for s in range(num_speck):
        # in creating speckle object it will measure speckle intensity (in the pupil plane), just assign after
        speck = skv3.speckle(proper.prop_get_amplitude(wfo), tp.speck_locs[s][0], tp.speck_locs[s][1], config)
        # tp.speck_phases = [-np.pi]
        phase = tp.speck_phases[s]
        speck.intensity = tp.speck_peakIs[s]
        dm_z = speck.generate_flatmap(phase)#*4*I
        FPWFS.propagate_DM(wfo, tp.f_lens, dm_z)