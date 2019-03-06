import os
import numpy as np
# import matplotlib.pylab as plt
# from scipy import interpolate
import pickle as pickle
# import copy
# from scipy import ndimage
import proper
from proper_mod import prop_psd_errormap
# from medis.Utils.plot_tools import quicklook_im, quicklook_wf, loop_frames,quicklook_IQ
import medis.Utils.rawImageIO as rawImageIO
import medis.Utils.misc as misc
from medis.params import tp, cp, mp, ap,iop#, fp
from medis.Utils.misc import dprint

class error_params():
    def __init__(self):
        tp.Imaps = np.zeros((4, tp.grid_size, tp.grid_size))
        tp.phase_map = np.zeros((tp.grid_size, tp.grid_size))

def initialize_CPA_meas():
    required_servo = int(tp.servo_error[0])
    required_band = int(tp.servo_error[1])
    required_nframes = required_servo + required_band + 1
    CPA_maps = np.zeros((required_nframes,tp.nwsamp, tp.grid_size,tp.grid_size))

    with open(iop.CPA_meas, 'wb') as handle:
        pickle.dump((CPA_maps, np.arange(0,-required_nframes,-1)), handle, protocol=pickle.HIGHEST_PROTOCOL)

def initialize_NCPA_meas():
    Imaps = np.zeros((4, tp.grid_size, tp.grid_size))
    phase_map = np.zeros((tp.ao_act,tp.ao_act))#np.zeros((tp.grid_size,tp.grid_size))
    with open(iop.NCPA_meas, 'wb') as handle:
        pickle.dump((Imaps, phase_map, 0), handle, protocol=pickle.HIGHEST_PROTOCOL)

def abs_zeros(wf_array):
    shape = wf_array.shape
    for iw in range(shape[0]):
        for io in range(shape[1]):
            bad_locs = np.logical_or(np.real(wf_array[iw,io].wfarr) == -0,
                                     np.imag(wf_array[iw,io].wfarr) == -0)
            wf_array[iw,io].wfarr[bad_locs] = 0 +0j

    return wf_array

def generate_maps(Loc='CPA'):
    # TODO add different timescale aberations
    dprint('Generating optic aberration maps using Proper')
    wfo = proper.prop_begin(tp.diam, 1., tp.grid_size, tp.beam_ratio)
    aber_cube = np.zeros((ap.numframes, tp.aber_params['n_surfs'], tp.grid_size, tp.grid_size))
    for surf in range(tp.aber_params['n_surfs']):

        rms_error = np.random.normal(tp.aber_vals['a'][0], tp.aber_vals['a'][1])
        c_freq = np.random.normal(tp.aber_vals['b'][0], tp.aber_vals['b'][1])  # correlation frequency (cycles/meter)
        high_power = np.random.normal(tp.aber_vals['c'][0], tp.aber_vals['c'][1])  # high frewquency falloff (r^-high_power)

        perms = np.random.rand(ap.numframes, tp.grid_size, tp.grid_size)-0.5
        perms *= 1e-7

        phase = 2 * np.pi * np.random.uniform(size=(tp.grid_size, tp.grid_size)) - np.pi
        aber_cube[0, surf] = prop_psd_errormap(wfo, rms_error, c_freq, high_power, TPF=True,  PHASE_HISTORY = phase)

        filename = '%s%s_Phase%f_v%i.fits' % (iop.aberdir+'quasi/', Loc, 0, surf)
        rawImageIO.saveFITS(aber_cube[0, surf], filename)

        for a in range(1,ap.numframes):
            if a % 100 == 0: misc.progressBar(value=a, endvalue=ap.numframes)
            perms = np.random.rand(tp.grid_size, tp.grid_size) - 0.5
            perms *= 0.05
            phase += perms
            aber_cube[a, surf] = prop_psd_errormap(wfo, rms_error, c_freq, high_power,
                                 MAP="prim_map",TPF=True, PHASE_HISTORY = phase)

            filename = '%s%s_Phase%f_v%i.fits' % (iop.aberdir+'quasi/', Loc, a * cp.frame_time, surf)
            rawImageIO.saveFITS(aber_cube[a, surf], filename)

    # if not os.path.isdir(iop.aberdir+'/quasi'):
    #     os.mkdir(iop.aberdir+'quasi')
    # for f in range(0,ap.numframes,1):
    #     # print 'saving frame #', f
    #     if f%100==0: misc.progressBar(value = f, endvalue=ap.numframes)
    #     for surf in range(tp.aber_params['n_surfs']):
    #         filename = '%s%s_Phase%f_v%i.fits' % (iop.aberdir, Loc, f * cp.frame_time, surf)
    #         rawImageIO.saveFITS(aber_cube[f, surf], '%stelz%f.fits' % (iop.aberdir, f*cp.frame_time))
            # quicklook_im(aber_cube[f], logAmp=False, show=True)

def circularise(prim_map):
    # TODO test this
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
            iy = circ_map[1][x,y]
            new_prim[ix,iy] = prim_map[x,y]
    new_prim = proper.prop_shift_center(new_prim)
    new_prim = np.transpose(new_prim)
    return new_prim

def add_aber(wf_array,f_lens,aber_params,aber_vals, step=0,Loc='CPA'):
    #dprint("Adding Abberations")

    if aber_params['QuasiStatic'] == False:
        step = 0
    else:
        dprint((iop.aberdir, iop.aberdir[-6:]))
        if iop.aberdir[-6:] != 'quasi/':
            iop.aberdir = iop.aberdir+'quasi/'

    phase_maps = np.zeros((aber_params['n_surfs'],tp.grid_size,tp.grid_size))
    amp_maps = np.zeros_like(phase_maps)

    shape = wf_array.shape
    # The For Loop of Horror:
    for iw in range(shape[0]):
        for io in range(shape[1]):
            if aber_params['Phase']:
                for surf in range(aber_params['n_surfs']):
                    if aber_params['OOPP']:
                        proper.prop_lens(wf_array[iw,io], f_lens, "OOPP")
                        proper.prop_propagate(wf_array[iw,io],f_lens/aber_params['OOPP'][surf])
                    if iw == 0 and io == 0:
                        filename = '%s%s_Phase%f_v%i.fits' % (iop.quasi, Loc, step * cp.frame_time, surf)
                        rms_error = np.random.normal(aber_vals['a'][0], aber_vals['a'][1])
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
                # quicklook_im(phase_maps[0]*1e9, logAmp=False, colormap="jet", show=True, axis=None, title='nm', pupil=True)

            if aber_params['Amp']:
                for surf in range(aber_params['n_surfs']):
                    filename = '%s%s_Amp%f_v%i.fits' % (iop.quasi, Loc, step * cp.frame_time, surf)
                    rms_error = np.random.normal(aber_vals['a_amp'][0],aber_vals['a_amp'][1])
                    c_freq = np.random.normal(aber_vals['b'][0],
                                              aber_vals['b'][1])  # correlation frequency (cycles/meter)
                    high_power = np.random.normal(aber_vals['c'][0],
                                                  aber_vals['c'][1])  # high frewquency falloff (r^-high_power)
                    if aber_params['OOPP']:
                        proper.prop_lens(wf_array[iw, io], f_lens, "OOPP")
                        proper.prop_propagate(wf_array[iw, io], f_lens / aber_params['OOPP'][surf])
                    if iw == 0 and io == 0:
                        if iw == 0 and io == 0:
                            amp_maps[surf] = proper.prop_psd_errormap(wf_array[0, 0], rms_error, c_freq, high_power,
                                                                      FILE=filename, TPF=True)
                        else:
                            proper.prop_multiply(wf_array[iw, io], amp_maps[surf])
                    if aber_params['OOPP']:
                        proper.prop_propagate(wf_array[iw, io], f_lens + f_lens * (1 - 1. / aber_params['OOPP'][surf]))
                        proper.prop_lens(wf_array[iw, io], f_lens, "OOPP")


def add_zern_ab(wfo):
    proper.prop_zernikes(wfo, [2,3,4], np.array([175,150,200])*1.0e-9)


def add_atmos(wf_array, f_lens, w, atmos_map, correction=False):
    dprint("Adding Atmosphere--from the abberations module")
    obj_map = None
    samp = proper.prop_get_sampling(wf_array[0, 0])*tp.band[0]*1e-9/w

    shape = wf_array.shape
    if tp.piston_error:
        pist_error = np.random.lognormal(0, 0.5, 1)
        pist_error = 1.1*pist_error/6.9
    else:
        pist_error = 0

    for iw in range(shape[0]):
        for io in range(shape[1]):
            if iw == 0 and io == 0:
                try:
                    obj_map = proper.prop_errormap(wf_array[0, 0], atmos_map,
                                                   MULTIPLY=(1+pist_error)/3, WAVEFRONT=True, MAP="obj_map", SAMPLING=tp.samp)
                except IOError:
                    print('*** Using exception hack for name rounding error ***')
                    i = 0
                    up = True
                    indx = float(atmos_map[-19:-11])
                    while not os.path.isfile(atmos_map):

                        atmos_map = atmos_map[:-19]+ '%1.6f' % (indx +i) + atmos_map[-11:]
                        if up:
                            i+=1e-6
                        else:
                            i-=1e-6
                        if i >= 50e-6:
                            i = 0
                            up = 0
                        elif i <= -50e-6:
                            dprint('Last found atmos map is %s' % atmos_map)
                            print('No file found. Is your frame cadence too short for the atmosphere maps you have?')
                            exit()

                    obj_map = proper.prop_errormap(wf_array[0,0], atmos_map,
                                                   MULTIPLY=(1+pist_error)/2, WAVEFRONT=True, MAP="obj_map", SAMPLING=tp.samp)
            else:
                proper.prop_add_phase(wf_array[iw,io], obj_map)

def rotate_atmos(wf, atmos_map):
    time = float(atmos_map[-19:-11])
    rotate_angle = tp.rot_rate * time
    wf.wfarr = proper.prop_shift_center(wf.wfarr)
    wf.wfarr = proper.prop_rotate(wf.wfarr, rotate_angle)
    wf.wfarr = proper.prop_shift_center(wf.wfarr)
