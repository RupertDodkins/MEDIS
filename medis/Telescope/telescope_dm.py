import os
import proper
import numpy as np
import matplotlib.pylab as plt
from . import FPWFS
from medis.Utils.plot_tools import quicklook_im, quicklook_wf, loop_frames,quicklook_IQ
import medis.Utils.rawImageIO as rawImageIO
import medis.Utils.misc as misc
from medis.params import tp, cp, mp, ap,iop#, fp
from scipy import interpolate
from configobj import ConfigObj
from validate import Validator
import sys
import pickle as pickle
# print proper.__file__
from medis.Utils.misc import dprint
import copy
from scipy import ndimage
# import scipy

# print tp.active_null, 'active null'
# if tp.active_null:

def add_speckles(wfo, pair=True):
    sys.path.append(tp.FPWFSdir)
    import speckle_killer_v3 as skv3
    # speckle = np.roll(np.roll(wfo.wfarr, loc[0],1),loc[1],0)*I#[92,92]
    # wfo.wfarr = (wfo.wfarr+speckle)
    # if pair:
    #     speckle = np.roll(np.roll(wfo.wfarr, -1*loc[0],1),-1*loc[1],0)*I#[92,92]
    #     wfo.wfarr = (wfo.wfarr+speckle)
    # dm_z = proper.prop_fits_read('dm.fits')
    # tp.diam = 0.1                 # telescope diameter in meters
    configfilename = tp.FPWFSdir+'speckle_null_config_Rupe.ini'
    configspecfile = tp.FPWFSdir+'speckle_null_config.spec'
    config = ConfigObj(configfilename, configspec=configspecfile)
    val = Validator()
    check = config.validate(val)

    num_speck = len(tp.speck_locs)
    for s in range(num_speck):
        # in creating speckle object it will measure speckle intensity (in the pupil plane), just assign after 
        speck = skv3.speckle(proper.prop_get_amplitude(wfo), tp.speck_locs[s][0], tp.speck_locs[s][1], config)
        # print tp.speck_phases 
        # tp.speck_phases = [-np.pi]
        # print tp.speck_phases
        phase = tp.speck_phases[s]
        speck.intensity = tp.speck_peakIs[s] 
        dm_z = speck.generate_flatmap(phase)#*4*I
        # quicklook_im(dm_z, logAmp=False)
        FPWFS.propagate_DM(wfo, tp.f_lens, dm_z)

class error_params():
    def __init__(self):
        tp.Imaps = np.zeros((4, tp.grid_size, tp.grid_size))
        tp.phase_map = np.zeros((tp.grid_size, tp.grid_size))

def initialize_CPA_meas():
    required_servo = int(tp.servo_error[0])
    # if tp.wfs_bandwidth_error:
    required_band = int(tp.servo_error[1])
    required_nframes = required_servo + required_band + 1
    CPA_maps = np.zeros((required_nframes,tp.nwsamp, tp.grid_size,tp.grid_size))

    # CPA_map = np.zeros((tp.grid_size, tp.grid_size))
    with open(iop.CPA_meas, 'wb') as handle:
        pickle.dump((CPA_maps, np.arange(0,-required_nframes,-1)), handle, protocol=pickle.HIGHEST_PROTOCOL)

def initialize_NCPA_meas():
    Imaps = np.zeros((4, tp.grid_size, tp.grid_size))
    phase_map = np.zeros((tp.ao_act,tp.ao_act))#np.zeros((tp.grid_size,tp.grid_size))
    # # Imaps = (np.zeros((4)), np.zeros((4, tp.grid_size, tp.grid_size)))
    # tp.Imaps = np.zeros((4, tp.grid_size, tp.grid_size))
    # tp.phase_map = np.zeros((tp.grid_size,tp.grid_size))
    with open(iop.NCPA_meas, 'wb') as handle:
        pickle.dump((Imaps, phase_map, 0), handle, protocol=pickle.HIGHEST_PROTOCOL)
    # ep = error_params()
    # return ep

# def active_null(wf, iter, w):
#     # if iter <= tp.active_converge_steps * 4:#6:
#
#     # tdm.piston_center(wf)
#     ip = iter % 4
#     # if tp.Imaps == None: tp.Imaps = np.zeros((4, tp.grid_size, tp.grid_size)) # initially creating a large array slows things down
#     # tp.Imaps[0][ip] = iter
#     # tp.Imaps[1][ip] = piston_refbeam(wf, iter, w)
#     with open(iop.NCPA_meas, 'rb') as handle:
#         Imaps, phase_map, _ = pickle.load(handle)
#     Imaps[ip] = piston_refbeam(wf, iter, w)
#     # loop_frames(tp.Imaps, logAmp=False)
#     # quicklook_im(proper.prop_get_phase(wf), logAmp=False, show=False, colormap="jet", vmin=-3.14, vmax=3.14)
#     # print tp.Imaps[3, 1, 1], tp.Imaps[1, 1, 1], tp.Imaps[0, 1, 1], tp.Imaps[2, 1, 1]
#     # print iter, ip
#     # print Imaps[3,1,1],Imaps[1,1,1],Imaps[0,1,1],Imaps[2,1,1]
#     # print np.any(Imaps[:,1,1] == 0)
#     if (iter+1)%4 == 0:# and not np.any(Imaps[:,1,1] == 0): #iter >= 3
#         phase_map += -1 * measure_phase(Imaps)
#         quicklook_wf(wf, show=True)
#         quicklook_im(proper.prop_get_phase(wf), logAmp=False, show=False, colormap="jet", vmin=-3.14, vmax=3.14)
#         quicklook_im(phase_map, logAmp=False, show=False, colormap="jet", vmin=-3.14, vmax=3.14)
#         quicklook_im(proper.prop_get_phase(wf)-phase_map, logAmp=False, show=False, colormap="jet", vmin=-3.14, vmax=3.14)
#     # else:
#     #     phase_map = np.zeros((tp.grid_size,tp.grid_size))
#     # quicklook_im(proper.prop_get_phase(wf), logAmp=False, show=False, colormap="jet", vmin=-3.14, vmax=3.14)
#     # quicklook_im(proper.prop_get_phase(wf), logAmp=False, show=False, colormap="jet")
#     # quicklook_wf(wf, show=True)
#     #     quicklook_im(phase_map, logAmp=False, show=False, colormap="jet", vmin=-3.14, vmax=3.14)
#     #     quicklook_im(np.rot90(phase_map,2), logAmp=False, show=False, colormap="jet", vmin=-3.14, vmax=3.14)
#     #     quicklook_im(NCPA_phasemap- np.roll(np.roll(np.rot90(phase_map,2), 1, 0), 1, 1), logAmp=False, colormap="jet", vmin=-3.14, vmax=3.14, show=False)
#     #     quicklook_im(proper.prop_get_phase(wf) - phase_map, logAmp=False, colormap="jet", vmin=-3.14, vmax=3.14)
#     # quicklook_im(phase_map, logAmp=False, show=False, colormap="jet", vmin=-3.14, vmax=3.14)
#     # quicklook_im(phase_map, logAmp=False, show=False, colormap="jet")
#     with open(iop.NCPA_meas, 'wb') as handle:
#         pickle.dump((Imaps, phase_map, iter+1), handle, protocol=pickle.HIGHEST_PROTOCOL)
#     # proper.prop_lens(wf, tp.f_lens)
#     # proper.prop_propagate(wf, tp.f_lens)

# def piston_refbeam(wf, iter, w):
#     # quicklook_wf(wf)
#     # wf_ref = copy.deepcopy(wf)
#     # quicklook_wf(wf_ref)
#     beam_ratio = tp.beam_ratio * tp.band[0] / w * 1e-9
#     wf_ref = proper.prop_begin(tp.diam, w, tp.grid_size, beam_ratio)
#     proper.prop_circular_aperture(wf_ref, tp.diam / 2)
#     if tp.use_spiders:
#         add_spiders(wf_ref, tp.diam)
#     proper.prop_define_entrance(wf_ref)
#     # quicklook_wf(wf_ref)
#     # proper.prop_lens(wf_ref, tp.f_lens)
#     # proper.prop_propagate(wf_ref, tp.f_lens)
#     # quicklook_wf(wf_ref)
#     # phase_vals = np.arange(0,4)*np.pi/2
#     phase_mod = iter%4 * w/4#np.pi/2
#     # obj_map = np.ones((tp.null_ao_act,tp.null_ao_act))*phase_mod
#     obj_map = np.ones((tp.grid_size,tp.grid_size))*phase_mod
#     phase_arr = proper.prop_get_amplitude(wf_ref)
#     obj_map[phase_arr == 0] = 0
#     # quicklook_im(obj_map)
#     # FPWFS.propagate_DM(wf_ref, tp.f_lens, obj_map)
#     proper.prop_add_phase(wf_ref, obj_map)
#     # quicklook_wf(wf_ref)
#     proper.prop_propagate(wf, tp.f_lens)
#     proper.prop_lens(wf, tp.f_lens)
#     proper.prop_propagate(wf, tp.f_lens)
#     if tp.use_spiders:
#         add_spiders(wf_ref, tp.diam)
#     proper.prop_circular_aperture(wf, tp.diam / 2)
#     # quicklook_wf(wf)
#     # Imap = wf.wfarr + wf_ref.wfarr
#     # quicklook_IQ(wf)
#     # quicklook_IQ(wf_ref)
#     wf_ref.wfarr = wf.wfarr + wf_ref.wfarr
#     # quicklook_IQ(wf)
#     Imap = proper.prop_shift_center(proper.prop_get_amplitude(wf_ref))
#     # quicklook_wf(wf)
#     # proper.prop_lens(wf, tp.f_lens)
#     # proper.prop_propagate(wf, tp.f_lens)
#     # quicklook_wf(wf_ref)
#     # quicklook_im(Imap)
#     # Imap = proper.prop_shift_center(proper.prop_get_amplitude(wf))
#     # # quicklook_im(proper.prop_shift_center(Imap))
#     return Imap

def abs_zeros(wf_array):
    shape = wf_array.shape
    for iw in range(shape[0]):
        for io in range(shape[1]):
            bad_locs = np.logical_or(np.real(wf_array[iw,io].wfarr) == -0,
                              np.imag(wf_array[iw,io].wfarr) == -0)
                              # np.real(wf_array[iw, io].wfarr) <= 1e-6)
            wf_array[iw,io].wfarr[bad_locs] = 0 +0j

    return wf_array
def modulate(wfo, w, iter):
    # phase_mod = np.ones((tp.grid_size,tp.grid_size))*(iter%4) * w/4.
    # phase_arr = proper.prop_get_phase(wfo)
    # phase_mod[phase_arr == 0] = 0
    # # quicklook_wf(wfo)
    # proper.prop_add_phase(wfo, phase_mod)

    # phase_mod = (iter % 8) * w / 8. - w/4.
    # proper.prop_zernikes(wfo, [4], np.array([phase_mod])/4.)
    # # quicklook_wf(wfo)

    # import medis.speckle_nulling.dm_functions as DM
    # # speck.generate_flatmap(phase)
    # s_amp = DM.amplitudemodel(0.05, 30, c=1.6)
    # waffle = DM.make_speckle_kxy(3, 3, s_amp, np.pi/2.)
    # quicklook_im(waffle, logAmp=False)
    # proper.prop_add_phase(wfo, waffle)

    # quicklook_wf(wfo)
    rms_error = 5e-7  # 500.e-9       # RMS wavefront error in meters
    c_freq = 0.005  # correlation frequency (cycles/meter)
    high_power = 2.  # high frewquency falloff (r^-high_power)
    phase_map = proper.prop_psd_errormap(wfo, rms_error, c_freq, high_power,
                             MAP="prim_map")

    # quicklook_im(phase_map, logAmp=False)
    # proper.prop_add_phase(wfo, phase_map)
    # quicklook_wf(wfo)


def offset_companion(wf_array, atmos_map):
    # [x,y] = tp.grid_size/2 - np.array(ap.comp_loc)
    # disp = np.zeros((2))
    # for id, dim in enumerate([x,y]):
    #     angle = dim*tp.platescale/(1000.*3600.)
    #     print dim, angle,
    #     radius = proper.prop_get_beamradius(wf)
    #     print radius,
    #     disp[id] = np.tan(angle)*2*radius
    #     print disp[id]
    # proper.prop_zernikes(wf, [2, 3], disp)

    cont_scaling = np.linspace(1./ap.C_spec, 1, tp.nwsamp)
    # dprint(cont_scaling)
    shape = wf_array.shape
    for iw in range(shape[0]):
        for io in range(shape[1]):

            xloc = ap.lods[io][0]
            yloc = ap.lods[io][1]

            if tp.rot_rate:
                time = float(atmos_map[-19:-11])
                rotate_angle = tp.rot_rate * time
                rotate_angle = np.pi * rotate_angle/180.
                rot_matrix = [[np.cos(rotate_angle),-np.sin(rotate_angle)],[np.sin(rotate_angle),np.cos(rotate_angle)]]
                # print rotate_angle, 'rotate', xloc, yloc
                xloc, yloc = np.matmul(rot_matrix,[xloc,yloc])

            proper.prop_zernikes(wf_array[iw,io], [2, 3], np.array([xloc,yloc])*1e-6)
            # dprint(ap.contrast[io]*cont_scaling[iw])
            if io == shape[1]-1:
                cont_scaling = np.ones_like(cont_scaling)
                # dprint('doing this')
            wf_array[iw, io].wfarr = wf_array[iw,io].wfarr * np.sqrt(ap.contrast[io]*cont_scaling[iw])

def generate_maps2(Loc='CPA'):
    import random

    if not os.path.isdir(iop.aberdir+'/quasi'):
        os.mkdir(iop.aberdir+'quasi')

    print('Generating optic aberration maps using Proper')
    wfo = proper.prop_begin(tp.diam, 1., tp.grid_size, tp.beam_ratio)
    # # rms_error = 5e-6#500.e-9       # RMS wavefront error in meters
    # # c_freq = 0.005             # correlation frequency (cycles/meter)
    # # high_power = 1.          # high frewquency falloff (r^-high_power)
    # rms_error = 2.5e-3  # 500.e-9       # RMS wavefront error in meters
    # c_freq = 0.000005  # correlation frequency (cycles/meter)
    # high_power = 1.  # high frewquency falloff (r^-high_power)
    aber_cube = np.zeros((ap.numframes, tp.aber_params['n_surfs'], tp.grid_size, tp.grid_size))
    for surf in range(tp.aber_params['n_surfs']):

        rms_error = np.random.normal(tp.aber_vals['a'][0], tp.aber_vals['a'][1])
        c_freq = np.random.normal(tp.aber_vals['b'][0], tp.aber_vals['b'][1])  # correlation frequency (cycles/meter)
        high_power = np.random.normal(tp.aber_vals['c'][0], tp.aber_vals['c'][1])  # high frewquency falloff (r^-high_power)

        # tp.abertime = [0.5,2,10] # characteristic time for each aberation in secs

        perms = np.random.rand(ap.numframes, tp.grid_size, tp.grid_size)-0.5
        perms *= 1e-7

        phase = 2 * np.pi * np.random.uniform(size=(tp.grid_size, tp.grid_size)) - np.pi
        aber_cube[0, surf] =proper.prop_psd_errormap(wfo, rms_error, c_freq, high_power, TPF=True,  PHASE_HISTORY = phase)
                        # proper.prop_psd_errormap(wfo, rms_error, c_freq, high_power,
                        #          MAP="prim_map", PHASE_HISTORY = phase)  # FILE=td.aberdir+'/telzPrimary_Map.fits')
        # quicklook_im(aber_cube[0], logAmp=False)

        filename = '%s%s_Phase%f_v%i.fits' % (iop.aberdir+'quasi/', Loc, 0, surf)
        rawImageIO.saveFITS(aber_cube[0, surf], filename)

        for a in range(1,ap.numframes):
            if a % 100 == 0: misc.progressBar(value=a, endvalue=ap.numframes)
            # quicklook_im(aber_cube[a], logAmp=False)
            perms = np.random.rand(tp.grid_size, tp.grid_size) - 0.5
            perms *= 0.05
            phase += perms
            # print phase[:5,:5]
            aber_cube[a, surf] = proper.prop_psd_errormap(wfo, rms_error, c_freq, high_power,
                                 MAP="prim_map",TPF=True, PHASE_HISTORY = phase)

            filename = '%s%s_Phase%f_v%i.fits' % (iop.aberdir+'quasi/', Loc, a * cp.frame_time, surf)
            rawImageIO.saveFITS(aber_cube[a, surf], filename)

        plt.plot(aber_cube[:, surf, 20, 20])
        plt.show()

    loop_frames(aber_cube[:, 0, :, :], logAmp=False)
    loop_frames(aber_cube[0, :, :, :], logAmp=False)


    # if not os.path.isdir(iop.aberdir+'/quasi'):
    #     os.mkdir(iop.aberdir+'quasi')
    # for f in range(0,ap.numframes,1):
    #     # print 'saving frame #', f
    #     if f%100==0: misc.progressBar(value = f, endvalue=ap.numframes)
    #     for surf in range(tp.aber_params['n_surfs']):
    #         filename = '%s%s_Phase%f_v%i.fits' % (iop.aberdir, Loc, f * cp.frame_time, surf)
    #         rawImageIO.saveFITS(aber_cube[f, surf], '%stelz%f.fits' % (iop.aberdir, f*cp.frame_time))
            # quicklook_im(aber_cube[f], logAmp=False, show=True)


def generate_maps():
    import random
    print('Generating optic aberration maps using Proper')
    wfo = proper.prop_begin(tp.diam, 1., tp.grid_size, tp.beam_ratio)
    # rms_error = 5e-6#500.e-9       # RMS wavefront error in meters
    # c_freq = 0.005             # correlation frequency (cycles/meter)
    # high_power = 1.          # high frewquency falloff (r^-high_power)
    rms_error = 2.5e-3#500.e-9       # RMS wavefront error in meters
    c_freq = 0.000005             # correlation frequency (cycles/meter)
    high_power = 1.          # high frewquency falloff (r^-high_power)

    # tp.abertime = [0.5,2,10] # characteristic time for each aberation in secs
    tp.abertime = [100] # if beyond numframes then abertime will be auto set to duration of simulation
    abercubes = []
    for abertime in tp.abertime:
        # ap.numframes = 100
        aberfreq = 1./abertime
        # tp.abertime=2 # aberfreq: number of frames goals per sec?
        num_longframes = aberfreq * ap.numframes*cp.frame_time
        #print(num_longframes, ap.numframes, cp.frame_time)
        aber_cube = np.zeros((ap.numframes+1,tp.grid_size,tp.grid_size))
        lin_size = tp.grid_size**2
        # spacing = int(ap.numframes/num_longframes)
        # frame_idx = np.int_(np.linspace(0,ap.numframes,num_longframes+1))
        c = list(range(0,ap.numframes))
        #print(num_longframes)
        frame_idx = np.sort(random.sample(c,int(num_longframes+1-2)))
        # frame_idx = np.int_(np.sort(np.round(np.random.uniform(0,ap.numframes,num_longframes+1-2))))
        frame_idx = np.hstack(([0],frame_idx,[ap.numframes]))
        # frame_idx = [0,  15,   69,  278,  418,  703, 1287, 1900, 3030, 3228, 5000]
        #print(frame_idx)
        for f in frame_idx:
            aber_cube[f] = proper.prop_psd_errormap(wfo, rms_error, c_freq, high_power, MAP = "prim_map")#FILE=td.aberdir+'/telzPrimary_Map.fits')
            # quicklook_im(aber_cube[f], logAmp=False)
        for i,f in enumerate(frame_idx[:-1]):
            spacing = int(frame_idx[i+1]- frame_idx[i])
            # quicklook_im(aber_cube[f], logAmp=False, show=False)

            frame1 = aber_cube[f]
            frame2 = aber_cube[frame_idx[i+1]]
            lin_map = [np.linspace(f1,f2,spacing) for f1, f2 in zip(frame1.reshape(lin_size),frame2.reshape(lin_size))]
            interval_cube = np.array(lin_map).reshape(tp.grid_size,tp.grid_size,spacing)
            interval_cube = np.transpose(interval_cube)
            print(i, f, frame_idx[i], frame_idx[i+1], np.shape(interval_cube))
            # loop_frames(interval_cube, logAmp=False)
            aber_cube[f:frame_idx[i+1]] = interval_cube
        abercubes.append(aber_cube)
        plt.plot(aber_cube[:,20,20])
        plt.show()
    abercubes = np.array(abercubes)
    # print abercubes.shape
    # plt.plot(aber_cube[:,20,20])
    aber_cube = np.sum(abercubes,axis=0)
    plt.plot(aber_cube[:, 20, 20])
    plt.show()
    if not os.path.isdir(iop.aberdir):
        os.mkdir(iop.aberdir)
    for f in range(0,ap.numframes,1):
        # print 'saving frame #', f
        if f%100==0: misc.progressBar(value = f, endvalue=ap.numframes)
        rawImageIO.saveFITS(aber_cube[f], '%stelz%f.fits' % (iop.aberdir, f*cp.frame_time))
        # quicklook_im(aber_cube[f], logAmp=False, show=True)

    plt.show()

def circularise(prim_map):
    x = np.linspace(-1,1,128) * np.ones((128,128))
    y = np.transpose(np.linspace(-1, 1, 128) * np.ones((128, 128)))
    circ_map = np.zeros((2, 128,128))
    circ_map[0] = x*np.sqrt(1-(y**2/2.))
    circ_map[1] = y*np.sqrt(1-(x**2/2.))
    circ_map*= 64
    new_prim = np.zeros((128,128))
    for x in range(128):
        for y in range(128):
            ix = circ_map[0][x,y]
            iy = circ_map[1][x, y]
            new_prim[ix,iy] = prim_map[x,y]
    new_prim = proper.prop_shift_center(new_prim)
    new_prim = np.transpose(new_prim)
    # quicklook_im(new_prim, logAmp=False, colormap="jet")
    return new_prim

def add_single_speck(wfo, iter):
    # if iter <4:
    xloc = ap.lods[0][0]
    yloc = ap.lods[0][1]
    wf_temp = copy.deepcopy(wfo)
    wf_temp2 = copy.deepcopy(wfo)
    wf_temp3 = copy.deepcopy(wfo)
    # proper.prop_zernikes(wf_temp, [2], np.array([-1*xloc]) * 1e-6)
    proper.prop_zernikes(wf_temp, [4], np.array([-1 * xloc]) * 1e-6)
    # proper.prop_zernikes(wf_temp2, [2,3], np.array([-1*xloc, 0.5]) * 1e-6)
    # proper.prop_zernikes(wf_temp3, [2,3], np.array([-1*xloc, 1]) * 1e-6)
    wfo.wfarr += wf_temp.wfarr*2.5
    # wfo.wfarr += wf_temp2.wfarr / 10
    # wfo.wfarr += wf_temp3.wfarr / 20

def add_aber(wf_array,f_lens,aber_params,aber_vals, step=0,Loc='CPA'):
    if aber_params['QuasiStatic'] == False:
        step = 0
    else:
        dprint((iop.aberdir, iop.aberdir[-6:]))
        if iop.aberdir[-6:] != 'quasi/':
            iop.aberdir = iop.aberdir+'quasi/'
    # print aber_params
    phase_maps = np.zeros((aber_params['n_surfs'],tp.grid_size,tp.grid_size))
    amp_maps = np.zeros_like(phase_maps)

    shape = wf_array.shape
    for iw in range(shape[0]):
        for io in range(shape[1]):
            if aber_params['Phase']:
                for surf in range(aber_params['n_surfs']):
                    if aber_params['OOPP']:
                        proper.prop_lens(wf_array[iw,io], f_lens, "OOPP")
                        proper.prop_propagate(wf_array[iw,io],f_lens/aber_params['OOPP'][surf])
                    #     quicklook_wf(wfo)
                    if iw == 0 and io == 0:
                        filename = '%s%s_Phase%f_v%i.fits' % (iop.aberdir, Loc, step * cp.frame_time, surf)
                        rms_error = np.random.normal(aber_vals['a'][0], aber_vals['a'][1])
                        # quicklook_wf(wfo)
                        # print rms_error
                        c_freq = np.random.normal(aber_vals['b'][0],
                                                  aber_vals['b'][1])  # correlation frequency (cycles/meter)
                        high_power = np.random.normal(aber_vals['c'][0],
                                                      aber_vals['c'][1])  # high frewquency falloff (r^-high_power)
                        phase_maps[surf] = proper.prop_psd_errormap(wf_array[0,0], rms_error, c_freq, high_power, FILE=filename, TPF=True)
                    else:
                        proper.prop_add_phase(wf_array[iw,io], phase_maps[surf])
                    if aber_params['OOPP']:
                        proper.prop_propagate(wf_array[iw,io],f_lens+f_lens*(1-1./aber_params['OOPP'][surf]))
                        proper.prop_lens(wf_array[iw,io], f_lens, "OOPP")
                        # quicklook_wf(wfo)
                # quicklook_im(phase_maps[0]*1e9, logAmp=False, colormap="jet", show=True, axis=None, title='nm', pupil=True)

            if aber_params['Amp']:
                # filename = '%s%s_Amp%f.fits' % (iop.aberdir, Loc, step * cp.frame_time)
                for surf in range(aber_params['n_surfs']):
                    filename = '%s%s_Amp%f_v%i.fits' % (iop.aberdir, Loc, step * cp.frame_time, surf)
                    # print filename
                    rms_error = np.random.normal(aber_vals['a_amp'][0],aber_vals['a_amp'][1])
                    c_freq = np.random.normal(aber_vals['b'][0],
                                              aber_vals['b'][1])  # correlation frequency (cycles/meter)
                    high_power = np.random.normal(aber_vals['c'][0],
                                                  aber_vals['c'][1])  # high frewquency falloff (r^-high_power)
                    # quicklook_wf(wfo)
                    if aber_params['OOPP']:
                        proper.prop_lens(wf_array[iw, io], f_lens, "OOPP")
                        proper.prop_propagate(wf_array[iw, io], f_lens / aber_params['OOPP'][surf])
                    # quicklook_wf(wfo)
                    if iw == 0 and io == 0:
                        if iw == 0 and io == 0:
                            amp_maps[surf] = proper.prop_psd_errormap(wf_array[0, 0], rms_error, c_freq, high_power,
                                                                        FILE=filename, TPF=True)
                        else:
                            proper.prop_multiply(wf_array[iw, io], amp_maps[surf])
                    if aber_params['OOPP']:
                        proper.prop_propagate(wf_array[iw, io], f_lens + f_lens * (1 - 1. / aber_params['OOPP'][surf]))
                        proper.prop_lens(wf_array[iw, io], f_lens, "OOPP")
                        # quicklook_wf(wfo)
                        # quicklook_im(prim_map*1e9, logAmp=False, colormap="jet", show=True, axis=None, title='nm', pupil=True)

                    # quicklook_wf(wfo)
                # quicklook_im(amp_maps[0], logAmp=False, colormap="jet", show=True, axis=None, title='nm')

def add_static(wfo, f_lens, loc = 'CPA', type='phase'):
    # print 'Including Static Aberations'
    # rms_error = 1.e-3#500.e-9       # RMS wavefront error in meters
    # c_freq = 0.000005             # correlation frequency (cycles/meter)
    # high_power = 1.          # high frewquency falloff (r^-high_power)
    #
    # prim_map = proper.prop_psd_errormap(wfo, rms_error, c_freq, high_power)
    # quicklook_im(prim_map, logAmp=False, colormap="jet")
    #
    # rms_error = 1.e-3#500.e-9       # RMS wavefront error in meters
    # c_freq = 0.0000005             # correlation frequency (cycles/meter)
    # high_power = 2.          # high frewquency falloff (r^-high_power)
    #
    # prim_map = proper.prop_psd_errormap(wfo, rms_error, c_freq, high_power)
    # quicklook_im(prim_map, logAmp=False, colormap="jet")

    # rms_error = 5.e4#500.e-9       # RMS wavefront error in meters
    # c_freq = 5e-7             # correlation frequency (cycles/meter)
    # high_power = 2.          # high frewquency falloff (r^-high_power)

    # rms_error = 1e-12#500.e-9       # RMS wavefront error in meters
    # c_freq = 0.1             # correlation frequency (cycles/meter)
    # high_power = 3.          # high frewquency falloff (r^-high_power)

    rms_error = 7.2e-16#500.e-9       # RMS wavefront error in meters
    c_freq = 0.35             # correlation frequency (cycles/meter)
    high_power = 3.1          # high frewquency falloff (r^-high_power)

    # quicklook_wf(wfo)
    if type == 'Amp' or type == 'Both':
        rms_error = 2.  # 500.e-9       # RMS wavefront error in meters
        c_freq = 1  # correlation frequency (cycles/meter)
        high_power = 3.  # high frewquency falloff (r^-high_power)
        prim_map = proper.prop_psd_errormap(wfo, rms_error, c_freq, high_power, FILE=iop.aberdir + loc + '_static_amp.fits', AMPLITUDE=1.0)
        print('yep')
    else:
        prim_map = proper.prop_psd_errormap(wfo, rms_error, c_freq, high_power, FILE=iop.aberdir + loc + '_static_2.fits', TPF=True)


    # quicklook_wf(wfo)
    # quicklook_im(prim_map*1e9, logAmp=False, colormap="jet", show=True, axis=None, title='nm')
    #
    # rms_error = 5.e4#500.e-9       # RMS wavefront error in meters
    # c_freq = 0.1             # correlation frequency (cycles/meter)
    # high_power = 5.          # high frewquency falloff (r^-high_power)
    #
    # prim_map = proper.prop_psd_errormap(wfo, rms_error, c_freq, high_power)
    # quicklook_im(prim_map*1e9, logAmp=False, colormap="jet", show=True, axis=None, title='nm')
    #
    # rms_error = 5.e4#500.e-9       # RMS wavefront error in meters
    # c_freq = 0.1             # correlation frequency (cycles/meter)
    # high_power = 7.          # high frewquency falloff (r^-high_power)
    #
    # prim_map = proper.prop_psd_errormap(wfo, rms_error, c_freq, high_power)
    # quicklook_im(prim_map*1e9, logAmp=False, colormap="jet", show=True, axis=None, title='nm')
    #
    # rms_error = 5.e4#500.e-9       # RMS wavefront error in meters
    # c_freq = 0.2             # correlation frequency (cycles/meter)
    # high_power = 11.          # high frewquency falloff (r^-high_power)
    #
    # prim_map = proper.prop_psd_errormap(wfo, rms_error, c_freq, high_power)
    # quicklook_im(prim_map*1e9, logAmp=False, colormap="jet", show=True, axis=None, title='nm')




    # import medis.Analysis.phot as phot
    # mask = phot.aperture(64,64,64)
    # prim_map = prim_map*mask
    # quicklook_im(prim_map*1e9, logAmp=False, colormap="jet", show=True, axis=None, title='nm')


def add_IFS_ab(wfo, f_lens, w):
    # print 'Including Static Aberations'
    rms_error = 1.e-3#500.e-9       # RMS wavefront error in meters
    c_freq = 0.000005             # correlation frequency (cycles/meter)
    high_power = 1.          # high frewquency falloff (r^-high_power)

    proper.prop_psd_errormap(wfo, rms_error, c_freq, high_power, FILE=iop.aberdir+str(w)+'_IFS.fits')





def add_quasi(wfo, f_lens, step):
    # print 'Including Static Aberations'
    # rms_error = 0.01#500.e-9       # RMS wavefront error in meters
    # c_freq = 20.             # correlation frequency (cycles/meter)
    # high_power = 3.          # high frewquency falloff (r^-high_power)
    # samp = proper.prop_get_sampling(wfo)
    # samp = 0.125
    # print samp


    # prim_map = proper.prop_psd_errormap(wfo, rms_error, c_freq, high_power, MAP = "prim_map")# , FILE='Primary_Map.fits'
    filename = '%stelz%f.fits' % (iop.aberdir, step*cp.frame_time)
    # print filename, tp.samp
    proper.prop_errormap(wfo, filename, WAVEFRONT=True, SAMPLING=tp.samp)
    # obj_map = obj_map*2#1.5

    # quicklook_im(prim_map)

    # proper.prop_zernikes( wfo, [4], np.array([0.5])*1.0e-6 )
    # [2,3], [0.5,0.5]*1.0e-6
    # FPWFS.quicklook_wf(wfo)
    # proper.prop_lens(wfo, f_lens, "objective")

    # #propagate through focus to pupil
    # proper.prop_propagate(wfo, f_lens*2, "telescope pupil imaging lens")
    # proper.prop_lens(wfo, f_lens, "telescope pupil imaging lens")
    # proper.prop_propagate(wfo, f_lens, "DM")
    # # FPWFS.quicklook_wf(wfo)

    # return prim_map

def add_zern_ab(wfo,f_lens):
    proper.prop_zernikes( wfo, [2,3,4], np.array([175,150,200])*1.0e-9 )
    # # [2,3], [0.5,0.5]*1.0e-6
    # # FPWFS.quicklook_wf(wfo)
    # proper.prop_lens(wfo, f_lens, "objective")
    #
    # #propagate through focus to pupil
    # proper.prop_propagate(wfo, f_lens*2, "telescope pupil imaging lens")
    # proper.prop_lens(wfo, f_lens, "telescope pupil imaging lens")
    # proper.prop_propagate(wfo, f_lens, "DM")

def add_atmos(wf_array, f_lens, w, atmos_map, correction=False):
    dprint("Adding Atmosphere")
    obj_map = None
    samp = proper.prop_get_sampling(wf_array[0,0])*tp.band[0]*1e-9/w
    #dprint((atmos_map,samp))

    shape = wf_array.shape
    if tp.piston_error:
        pist_error = np.random.lognormal(0,0.5,1)
        pist_error = 1.1*pist_error/6.9
        #dprint(pist_error)
    else:
        pist_error = 0
    for iw in range(shape[0]):
        for io in range(shape[1]):
            if iw == 0 and io == 0:
                try:
                    # rawImageIO.scale_image(atmos_map, 1e6)
                    obj_map = proper.prop_errormap(wf_array[0,0], atmos_map, MULTIPLY = (1+pist_error)/3, WAVEFRONT=True, MAP = "obj_map", SAMPLING=tp.samp)# )##FILE='telescope_objtest.fits'
                    # quicklook_im(obj_map, logAmp=False)
                except IOError:
                    print('*** Using exception hack for name rounding error ***')
                    i = 0
                    up = True
                    indx = float(atmos_map[-19:-11])
                    while not os.path.isfile(atmos_map):
                        # print atmos_map[:11],  atmos_map[13:]
                        # atmos_map = atmos_map[:-12]+ str(i) + atmos_map[-11:]

                        # print atmos_map
                        # print indx, indx +i, '%1.6f' % (indx +i)
                        atmos_map = atmos_map[:-19]+ '%1.6f' % (indx +i) + atmos_map[-11:]
                        # dprint(atmos_map)
                        if up:
                            i+=1e-6
                        else:
                            i-=1e-6
                        if i >= 50e-6:
                            i = 0
                            up = 0
                        elif i <= -50e-6:
                            dprint('Last found atmos map is %s',atmos_map)
                            print('No file found')
                            exit()

                        # rawImageIO.scale_image(atmos_map, 1e-6)
                    obj_map = proper.prop_errormap(wf_array[0,0], atmos_map, MULTIPLY=(1+pist_error)/2, WAVEFRONT=True, MAP = "obj_map", SAMPLING=tp.samp)
            else:
                proper.prop_add_phase(wf_array[iw,io], obj_map)


    # quicklook_im(obj_map, logAmp=False)
    # return obj_map

def rotate_atmos(wf, atmos_map):
    time = float(atmos_map[-19:-11])
    rotate_angle = tp.rot_rate * time
    # print  rotate_angle, 'rotate'
    # quicklook_wf(wf)
    wf.wfarr = proper.prop_shift_center(wf.wfarr)
    wf.wfarr = proper.prop_rotate(wf.wfarr, rotate_angle)
    wf.wfarr = proper.prop_shift_center(wf.wfarr)
    # quicklook_wf(wf)

def add_spiders(wfo, diam, legs=True):
    # print 'Including Spiders'
    proper.prop_circular_obscuration(wfo, (diam/3)/2.5)
    if legs:
        proper.prop_rectangular_obscuration(wfo, 0.05*diam, diam*1.3, ROTATION=20)
        proper.prop_rectangular_obscuration(wfo, diam*1.3, 0.05*diam, ROTATION=20)

def add_hex(wfo):
    print('Including Mirror Segments')
    print('** add code here **')

def interfero_test():
    '''Mask the input and observe speckles'''
    # proper.prop_circular_obscuration(wfo, (ps.tp.diam/3)/4, -(ps.tp.diam/3)/2, -0.5538)
    # wf_temp = copy.deepcopy(wfo)
    # wf_temp2 = copy.deepcopy(wfo)
    # proper.prop_circular_aperture(wf_temp, (ps.tp.diam/3)/2, 0.0, (ps.tp.diam/3)) 
    # proper.prop_circular_aperture(wf_temp2, (ps.tp.diam/3)/2, -0.07, -0.041)
    # proper.prop_circular_aperture(wfo, (ps.tp.diam/3)/2, 0.07, -0.041)
    # proper.prop_add_wavefront(wfo, proper.prop_get_amplitude(wf_temp))
    # proper.prop_add_wavefront(wfo, proper.prop_get_amplitude(wf_temp2)) 
    # # proper.prop_circular_obscuration(wfo, (ps.tp.diam/3)/4, (ps.tp.diam/3)/2, -0.5477)
    # FPWFS.quicklook_wf(wfo)

def prop_mid_optics(wfo, f_lens):
    # proper.prop_propagate(wfo, f_lens)
    # quicklook_wf(wfo)

    proper.prop_lens(wfo, f_lens)
    # print 'here'
    # quicklook_wf(wfo)
    # propagate through focus to pupil
    # proper.prop_propagate(wfo, f_lens*2)
    # proper.prop_lens(wfo, f_lens)
    proper.prop_propagate(wfo, f_lens)
    # from numpy.fft import fft2, ifft2
    # wfo.wfarr = fft2(wfo.wfarr) / np.size(wfo.wfarr)
    # quicklook_wf(wfo)


# def prop_no_coron(wfo, f_lens):
#     proper.prop_propagate(wfo, f_lens, "telescope pupil imaging lens")
#     proper.prop_lens(wfo, f_lens, "telescope pupil imaging lens")
#     proper.prop_propagate(wfo, f_lens, "DM")

def do_apod(wfo, grid_size, beam_ratio, apod_gaus):
    # print 'Including Apodization'
    r = proper.prop_radius(wfo)
    rad = int(np.round(grid_size*(1-beam_ratio)/2)) # beam is a fraction (0.3) of the grid size
    r = r/r[grid_size/2,rad]
    w = apod_gaus
    gauss_spot=np.exp(-(r/w)**2)
    # plt.imshow(gauss_spot)
    # plt.figure()
    # plt.plot(gauss_spot[128])
    # plt.show()
    proper.prop_multiply(wfo, gauss_spot)
    # plt.plot(proper.prop_get_amplitude(wfo)[128])
    # plt.figure()
    # plt.imshow(np.sqrt(proper.prop_get_amplitude(wfo)), origin = "lower", cmap = plt.cm.gray)
    # plt.show()

def adaptive_optics(wfo, iwf, iw, f_lens, beam_ratio, iter):
    # print 'Including Adaptive Optics'
    # PSF = proper.prop_shift_center(np.abs(wfo.wfarr)**2)

    # quicklook_im(obj_map, logAmp=False)

    # code to distort measured phase map goes here....
    # print 'add code to distort phase measurment'
    nact = tp.ao_act#49                       # number of DM actuators along one axis
    nact_across_pupil = nact-2#/1.075#nact #47          # number of DM actuators across pupil
    dm_xc = (nact / 2) -0.5#-1#0.5#- 0.5
    dm_yc = (nact / 2) -0.5#-1#0.5#- 0.5
    d_beam = 2 * proper.prop_get_beamradius(wfo)        # beam diameter
    # dprint((d_beam, d_beam/nact_across_pupil))
    act_spacing = d_beam / (nact_across_pupil)     # actuator spacing
    map_spacing = proper.prop_get_sampling(wfo)        # map sampling

    # have passed through focus, so pupil has rotated 180 deg;
	# need to rotate error map (also need to shift due to the way
	# the rotate() function operates to recenter map)    
    # obj_map = np.roll(np.roll(np.rot90(obj_map, 2), 1, 0), 1, 1)
    # obj_map = np.roll(obj_map, 1, -1)
    # quicklook_im(obj_map[45:83,45:83], logAmp=False, show=False)
    # plt.figure()
    # plt.plot(range(44, 84), obj_map[64, 44:84])

    # print map_spacing
    # interpolate map to match number of DM actuators
    # print map_spacing/act_spacing
    
    # print 'Interpolation boundary uncertainty is likely because of beam ratio causing a non-integer'
    # print '128*0.3 ~ 38 so thats what is being used for now. Needs some T.L.C.'

    # true_width = tp.grid_size*beam_ratio
    # width = int(np.ceil(true_width))
    # # width = int(np.ceil(tp.grid_size*beam_ratio))
    # if width%2 != 0:
    #     width += 1
    # exten = width/true_width
    # print exten
    # mid = int(tp.grid_size/2.)
    # lower = int(mid-width/2.)
    # upper = int(mid+width/2.)
    # print width, mid, lower, upper
    # #
    # # f= interpolate.interp2d(range(width+1), range(width+1), obj_map[lower:upper, lower:upper])
    # # dm_map = f(np.linspace(0,width+1,nact),np.linspace(0,width+1,nact))
    #
    # import skimage.transform
    # dm_map = skimage.transform.resize(obj_map[lower:upper, lower:upper], (nact,nact))
    # print map_spacing, act_spacing, map_spacing/act_spacing

    try:
        with open(iop.CPA_meas, 'rb') as handle:
            CPA_maps, iters = pickle.load(handle)
    except EOFError:
        print('CPA file not ready?')
        import time
        time.sleep(10)
        with open(iop.CPA_meas, 'rb') as handle:
            CPA_maps, iters = pickle.load(handle)

    # loop_frames(CPA_maps, logAmp=False)
    if iwf[:9] == 'companion':
        CPA_map = CPA_maps[1,iw]
    else:
        CPA_map = CPA_maps[0,iw]

    # loop_frames(CPA_maps, logAmp=False)

    # quicklook_im(CPA_map, logAmp=False)

    # dprint((map_spacing, act_spacing, map_spacing/act_spacing))
    # dm_map = proper.prop_magnify(CPA_map, map_spacing/act_spacing, nact)

    dm_map = CPA_map[tp.grid_size/2-(beam_ratio*tp.grid_size/2):tp.grid_size/2+(beam_ratio*tp.grid_size/2)+1, tp.grid_size/2-(beam_ratio*tp.grid_size/2):tp.grid_size/2+(beam_ratio*tp.grid_size/2)+1]
    f= interpolate.interp2d(list(range(dm_map.shape[0])), list(range(dm_map.shape[0])), dm_map)
    dm_map = f(np.linspace(0,dm_map.shape[0],nact),np.linspace(0,dm_map.shape[0],nact))
    # quicklook_im(dm_map, logAmp=False, show=True)
    dm_map = -dm_map*proper.prop_get_wavelength(wfo)/(4*np.pi) #<--- here
    # dm_map = -dm_map * proper.prop_get_wavelength(wfo) / (2 * np.pi)
    # dm_map = np.zeros((65,65))
    # quicklook_im(dm_map, logAmp=False, show=True, colormap='jet')
    # if tp.piston_error:
    #     mean_dm_map = np.mean(np.abs(dm_map))
    #     var = mean_dm_map/200.#40.
    #     print var
    #     # var = 0.001#1e-11
    #     if var != 0.0:
    #         dm_map = dm_map + np.random.normal(0, var, (dm_map.shape[0], dm_map.shape[1]))
    # quicklook_im(dm_map, logAmp=False, show=True, colormap='jet')
    # plt.figure()
    # quicklook_wf(wfo)
    # plt.plot(np.linspace(44, 84, nact),dm_map[16])
    # plt.figure()
    # quicklook_im( obj_map[lower:upper, lower:upper], logAmp=False, show=True)
    # act_spacing /= 0.625
    # print act_spacing, proper.prop_get_beamradius(wfo)
    # Need to put on opposite pattern; convert wavefront error to surface height
    # plt.plot(range(44,84), proper.prop_get_phase(wfo)[64, 44:84])
    # proper.prop_add_phase(wfo, waffle)




    # quicklook_im(dm_map)
    if tp.active_null:
        with open(iop.NCPA_meas, 'rb') as handle:
            _, null_map,_ = pickle.load(handle)
        # dprint('null_map')
        # quicklook_im(null_map, logAmp=False)
        # dm_NCPA = -proper.prop_magnify(NCPA_map, map_spacing / act_spacing, nact)
        dm_NCPA = null_map*proper.prop_get_wavelength(wfo)/(4*np.pi)

        # quicklook_im(dm_map, logAmp=False)
        dm_map += dm_NCPA
        # quicklook_im(dm_map, logAmp=False, show=True, colormap ='jet')
        # dm_map /= 2

    # if tp.speckle_kill:
    #     with open(iop.NCPA_meas, 'rb') as handle:
    #         Imaps, NCPA_map,_ = pickle.load(handle)
        # quicklook_im(NCPA_map, logAmp=False)
        # loop_frames(Imaps+1e-9, logAmp=True)
        # with open(iop.NCPA_meas, 'rb') as handle:
        #     _, NCPA_map,_ = pickle.load(handle)
        # quicklook_im(NCPA_map, logAmp=False)
        #
        # dm_NCPA = -proper.prop_magnify(NCPA_map, map_spacing / act_spacing, nact)
        # dm_NCPA = dm_NCPA*proper.prop_get_wavelength(wfo)/(4*np.pi)
        #
        # # quicklook_im(dm_map, logAmp=False)
        # dm_map = dm_NCPA

    if tp.active_modulate and iter >=8:
        # import medis.speckle_nulling.dm_functions as DM
        # # speck.generate_flatmap(phase)
        # s_amp = DM.amplitudemodel(0.05, 30, c=1.6)
        # tp.null_ao_act = tp.ao_act
        # xloc, yloc = 4, 0
        # # rotate_angle = iter%30 * 360/30
        # # rotate_angle = np.pi * rotate_angle / 180.
        # # rot_matrix = [[np.cos(rotate_angle), -np.sin(rotate_angle)], [np.sin(rotate_angle), np.cos(rotate_angle)]]
        # # xloc, yloc = np.matmul(rot_matrix, [xloc, yloc])
        #
        # phase = iter % 10 * 2 * np.pi / 10.
        # s_amp = iter % 5 * s_amp/ 5.
        # print xloc, yloc, phase
        # waffle = DM.make_speckle_kxy(xloc, yloc, s_amp, phase) / 1e6
        # waffle += DM.make_speckle_kxy(yloc, xloc, s_amp, -phase) / 1e6
        # waffle += DM.make_speckle_kxy(0.71 * xloc, 0.71 * xloc, s_amp, -phase) / 1e6
        # waffle += DM.make_speckle_kxy(0.71 * xloc, -0.71 * xloc, s_amp, -phase) / 1e6
        # waffle /= 4
        # # quicklook_im(waffle, logAmp=False)
        # # print dm_map.shape
        # # print waffle.shape
        #
        # dmap =proper.prop_dm(wfo, waffle, dm_xc, dm_yc, N_ACT_ACROSS_PUPIL=nact, FIT = True)
        # dm_map = -dm_map * proper.prop_get_wavelength(wfo) / (4 * np.pi * 5) * (iter % 10 - 5)
        print(1/5. * (iter % 10 - 5))
        dm_map = dm_map/5. * (iter % 10 - 5)
        # dmap = proper.prop_dm(wfo, pattern, dm_xc, dm_yc,
        #                       N_ACT_ACROSS_PUPIL=nact, FIT=True)
    # quicklook_wf(wfo)

    # quicklook_wf(wfo)
    # dmap =proper.prop_dm(wfo, dm_map, dm_xc, dm_yc, N_ACT_ACROSS_PUPIL=nact, FIT = True) #<-- here

    dmap = proper.prop_dm(wfo, dm_map, dm_xc, dm_yc, act_spacing, FIT = True) #<-- here

    # quicklook_im(dmap, logAmp=False, show=True)
    # quicklook_im(CPA_map*proper.prop_get_wavelength(wfo)/(4*np.pi), logAmp=False)
    # quicklook_im(CPA_map*proper.prop_get_wavelength(wfo)/(4*np.pi) + dmap, logAmp=False, show=True)



    # # # There's a boundary effect that needs to be mitigated
    # phase_map = proper.prop_get_phase(wfo)
    # artefacts = np.abs(phase_map) > 1
    # # print np.shape(artefacts), np.shape(phase_map)
    # # quicklook_im(phase_map, logAmp=False)
    #
    # width = round(tp.grid_size*beam_ratio)
    # mid = int(tp.grid_size/2.)
    # lower = int(mid-width/2.)
    # upper = int(mid+width/2.)
    # mask = np.zeros((tp.grid_size, tp.grid_size))
    # mask[upper,:] = 1
    # mask[:, upper] = 1
    # mask[lower,:] = 1
    # mask[:,lower] = 1
    # mask = mask*artefacts
    #
    # # print width, upper
    #
    # # wfo.wfarr[upper] = phase_map[tp.grid_size/2,tp.grid_size/2]
    # # quicklook_im( phase_map*mask, logAmp=False)
    #
    # proper.prop_add_phase(wfo,-phase_map*mask*proper.prop_get_wavelength(wfo)/(2*np.pi))
    # quicklook_IQ(wfo)

    # I = np.real(wfo.wfarr)
    # Q = np.imag(wfo.wfarr)
    # I = proper.prop_shift_center(I)
    # Q = proper.prop_shift_center(Q)
    # Q[89] = 0
    # Q[:,89] = 0
    # # Q[39] = 0
    # # Q[:,39] = 0
    # I = proper.prop_shift_center(I)
    # Q = proper.prop_shift_center(Q)
    # wfo.wfarr = I+1j*Q
    # quicklook_wf(wfo)

    # quicklook_IQ(wfo)
    # print phase_map[artefacts]
    # plt.imshow(phase_map)
    # # plt.figure()
    # # plt.imshow(dmap)
    # #
    # plt.show()
    # #
    # proper.prop_propagate(wfo, f_lens, "coronagraph lens")
    # quicklook_wf(wfo)
    return


def quick_ao(wf_array, iwf, f_lens, beam_ratios, iter, CPA_maps):
    nact = tp.ao_act  # 49                       # number of DM actuators along one axis
    nact_across_pupil = nact -2 # 47          # number of DM actuators across pupil
    dm_xc = (nact / 2)-0.5
    dm_yc = (nact / 2)-0.5

    # if tp.atmos_vary:
    #     n_zern = 3
    #     pist_error = np.random.lognormal(0,0.5,n_zern)
    #     pist_error = (pist_error)/6.9
    #     print pist_error
    #     # pist_error = pist_error/(6.9)
    #     # pist_error = np.max(pist_error)- 1
    #     # pist_error = pist_error - 0.8
    #
    #     # quicklook_im(wmap, logAmp=False)

    shape = wf_array.shape

    for iw in range(shape[0]):
        for io in range(shape[1]):
            d_beam = 2 * proper.prop_get_beamradius(wf_array[iw,io])  # beam diameter
            act_spacing = d_beam / nact_across_pupil  # actuator spacing
            # map_spacing = proper.prop_get_sampling(wf_array[iw,io])  # map sampling

            # dm_map = np.zeros((65, 65))
            # quicklook_im(CPA_maps[iw], logAmp=False, vmin=-3.14, vmax=3.14)
            # Compensating for chromatic beam size
            dm_map = CPA_maps[iw,tp.grid_size//2-np.int_(beam_ratios[iw]*tp.grid_size//2):
                                tp.grid_size//2+np.int_(beam_ratios[iw]*tp.grid_size//2)+1,
                                tp.grid_size//2-np.int_(beam_ratios[iw]*tp.grid_size//2):
                                tp.grid_size//2+np.int_(beam_ratios[iw]*tp.grid_size//2)+1]
            # quicklook_im(dm_map, logAmp=False)
            f= interpolate.interp2d(list(range(dm_map.shape[0])), list(range(dm_map.shape[0])), dm_map)
            dm_map = f(np.linspace(0,dm_map.shape[0],nact),np.linspace(0,dm_map.shape[0],nact))
            # dm_map = proper.prop_magnify(CPA_map, map_spacing / act_spacing, nact)

            # quicklook_im(dm_map, logAmp=False)
            # quicklook_wf(wf_array[iw,io])
            if tp.piston_error:
                # dprint('doing this')
                mean_dm_map = np.mean(np.abs(dm_map))
                # var = mean_dm_map/50.
                var = 1e-4  # 1e-11
                # var = 1  # 1e-11
                dm_map = dm_map + np.random.normal(0, var, (dm_map.shape[0], dm_map.shape[1]))


            dm_map = -dm_map * proper.prop_get_wavelength(wf_array[iw,io]) / (4 * np.pi)  # <--- here
            # dmap = proper.prop_dm(wfo, dm_map, dm_xc, dm_yc, N_ACT_ACROSS_PUPIL=nact, FIT=True)  # <-- here
            dmap = proper.prop_dm(wf_array[iw,io], dm_map, dm_xc, dm_yc, act_spacing, FIT=True)  # <-- here
            # wmap = proper.prop_zernikes(wf_array[iw, io], range(1, n_zern + 1), pist_error * 1*10**-9)
            # quicklook_wf(wf_array[iw,io])

    # # kludge to help with spiders
    for iw in range(shape[0]):
        phase_map = proper.prop_get_phase(wf_array[iw,0])
        amp_map = proper.prop_get_amplitude(wf_array[iw,0])
        # quicklook_im(phase_map)

        lowpass = ndimage.gaussian_filter(phase_map, 1, mode='nearest')
        smoothed = phase_map- lowpass
        # quicklook_im(lowpass)
        # quicklook_im(smoothed)
        wf_array[iw,0].wfarr = proper.prop_shift_center(amp_map*np.cos(smoothed)+1j*amp_map*np.sin(smoothed))
        # quicklook_wf(wf_array[iw,0])

    return


# def createObjMapsEmpty():
#     required_servo, required_band = 1, 1
#     # if tp.servo_lag:
#     required_servo = int(tp.servo_error[0]/cp.frame_time)
#     # if tp.wfs_bandwidth_error:
#     required_band = int(tp.servo_error[1]/cp.frame_time)
#     required_nframes = required_servo + required_band
#     tp.obj_maps = np.zeros((required_nframes,tp.grid_size,tp.grid_size))

def flat_outside(wf_array):
    for iw in range(wf_array.shape[0]):
        for io in range(wf_array.shape[1]):
            proper.prop_circular_aperture(wf_array[iw,io], 1, NORM=True)

def quick_wfs(wf_vec, iter, r0):
    # CPA_map = proper.prop_get_phase(wfo)

    import scipy.ndimage
    from skimage.restoration import unwrap_phase
    # quicklook_im(CPA_map, logAmp=False)
    sigma = [1, 1]
    CPA_maps = np.zeros((len(wf_vec),tp.grid_size,tp.grid_size))
    for iw in range(len(wf_vec)):
        CPA_maps[iw] = scipy.ndimage.filters.gaussian_filter(unwrap_phase(proper.prop_get_phase(wf_vec[iw])), sigma,
                                                             mode='constant')
        # CPA_map = unwrap_phase(CPA_map)
        # quicklook_im(CPA_map, logAmp=False)
        if tp.piston_error:
            # from medis.Utils.misc import debprint
            # var = 0.27*(tp.diam/(r0 * tp.ao_act))*(5/3)
            var = 1e-4#1e-11 #0.1 wavelengths 0.1*1000e-9
            # debprint(var)
            CPA_maps[iw] = CPA_maps[iw] + np.random.normal(0,var,(CPA_maps[iw].shape[0],CPA_maps[iw].shape[1]))

    # loop_frames(CPA_maps, logAmp=False)
    return CPA_maps

def wfs_measurement(wfo, iter, iw,r0):#, obj_map, wfs_sample):
    # print 'Including WFS Error'
    # quicklook_wf(wfo)
    # quicklook_im(obj_map, show=False, logAmp=False)

    with open(iop.CPA_meas, 'rb') as handle:
        CPA_maps, iters = pickle.load(handle)
    # quicklook_im(proper.prop_get_phase(wfo), logAmp=False)


    # quicklook_im(CPA_maps[0,iw], logAmp=False)
    # if iter < 20 or iter > 35:
    import scipy.ndimage
    sigma = [1, 1]
    # dmap = scipy.ndimage.filters.gaussian_filter(dmap, sigma, mode='constant')
    from skimage.restoration import unwrap_phase
    CPA_maps[0, iw] += scipy.ndimage.filters.gaussian_filter(unwrap_phase(proper.prop_get_phase(wfo)), sigma, mode='constant')
    # CPA_maps[0, iw] += proper.prop_get_phase(wfo)
    # quicklook_im(CPA_maps[0,iw], logAmp=False)
    # for d in [1]:#range(0,2,1):


    # quicklook_im(CPA_maps[0], logAmp=False)
    # CPA_maps[0,iw] = unwrap_phase(CPA_maps[0,iw])

    # quicklook_im(CPA_maps[0], logAmp=False)

    # CPA_maps[0] += proper.prop_get_phase(wfo)
    # loop_frames(CPA_maps, logAmp=False)
    # # print tp.servo_error
    if tp.servo_error:
        # print 'This might produce garbage if several processes are run in parrallel'
        # loop_frames(tp.obj_maps, logAmp=False)
        CPA_maps[:,iw] = np.roll(CPA_maps[:,iw],1,0)
        # tp.obj_maps[0] = CPA_maps[0]
        # if tp.servo_lag:
        required_servo = int(tp.servo_error[0]) # delay
        # obj_map = tp.obj_maps[required_servo]
        required_band = int(tp.servo_error[1]) # averaging
        # if tp.wfs_bandwidth_error:
        CPA_maps[0,iw] = np.sum(CPA_maps[required_servo:-1,iw],axis=0)/ required_band

        # loop_frames(tp.obj_maps, logAmp=False)
        # print obj_map
    # quicklook_im(obj_map, logAmp=False)

    # if tp.piston_error:
    #     # from medis.Utils.misc import debprint
    #     # var = 0.27*(tp.diam/(r0 * tp.ao_act))*(5/3)
    #     var = 0.001#1e-11 #0.1 wavelengths 0.1*1000e-9
    #     # debprint(var)
    #     CPA_maps[0,iw] = CPA_maps[0,iw] + np.random.normal(0,var,(CPA_maps[0,iw].shape[0],CPA_maps[0,iw].shape[1]))

    # if tp.wfs_measurement_error:
    #     '''Downsample subarrays and then convert back to original size (interpolation might
    #         be better than repeats'''
    #
    #     print '*** not used in a while! ***'
    #     def sub_sums_ophion(arr, nrows, ncols):
    #         h, w = arr.shape
    #         h = (h // nrows)*nrows
    #         w = (w // ncols)*ncols
    #         arr = arr[:h,:w]
    #         return np.einsum('ijkl->ik', arr.reshape(h // nrows, nrows, -1, ncols))
    #
    #     down_sample = sub_sums_ophion(obj_map, tp.wfs_sample, tp.wfs_sample) / tp.wfs_sample**2
    #     obj_map = np.repeat(np.repeat(down_sample,tp.wfs_sample, axis=0), tp.wfs_sample, axis=1)
    # return obj_map

    # if tp.active_null:
    #     with open(iop.NCPA_meas, 'rb') as handle:
    #         _, NCPA_map, _ = pickle.load(handle)
    #     # quicklook_im(CPA_map, logAmp=False)
    #     # dprint('CPA_map')
    #     # quicklook_im(NCPA_map, logAmp=False)
    #     # dprint('NCPA_map')
    #     CPA_maps[0] += NCPA_map
    #     # quicklook_im(CPA_map, logAmp=False)

    with open(iop.CPA_meas, 'wb') as handle:
        pickle.dump((CPA_maps, iters+1), handle, protocol=pickle.HIGHEST_PROTOCOL)


