"""Top level code that takes a atmosphere phase map and propagates a wavefront through the system"""

import os
import numpy as np
import traceback
import multiprocessing
import glob
import random
import pickle as pickle
import time
from proper_mod import prop_run
# from medis.Utils.plot_tools import quicklook_im, view_datacube, loop_frames
from medis.Utils.misc import dprint
from medis.params import ap,cp,tp,mp,sp,iop,dp
import medis.Detector.mkid_artefacts as MKIDs
import medis.Detector.H2RG as H2RG
import medis.Detector.pipeline as pipe
import medis.Detector.readout as read
import medis.Telescope.aberrations as aber
from medis.Telescope.optics_propagate import Wavefronts
import medis.Atmosphere.atmos as atmos
from scipy.interpolate import interp1d

class Timeseries():
    def __init__(self, inqueue, savequeue, conf_obj_tup):
        self.inqueue = inqueue
        self.savequeue = savequeue
        self.conf_obj_tup = conf_obj_tup
        required_servo = int(tp.servo_error[0])
        required_band = int(tp.servo_error[1])
        required_nframes = required_servo + required_band
        # self.CPA_maps = np.random.normal(0, 0.1, (required_nframes, ap.nwsamp, ap.grid_size, ap.grid_size))
        self.CPA_maps = np.zeros((required_nframes, ap.nwsamp, ap.grid_size, ap.grid_size))
        self.tiptilt = np.zeros((ap.grid_size, ap.grid_size))

        self.gen_timeseries()

    def gen_timeseries(self):
        """
        generates observation sequence by calling optics_propagate in time series

        It is the time loop wrapper for optics_propagate
        this is where the observation sequence is generated (timeseries of observations by the detector)
        thus, where the detector observes the wavefront created by optics_propagate (for MKIDs, the probability distribution)

        :param inqueue: time index for parallelization (used by multiprocess)
        :param save_queue: photon table (list of photon packets) in the multiprocessing format
        :param spectralcube_queue: series of intensity images (spectral image cube) in the multiprocessing format
        :param conf_obj_tup:
        :return:
        """
        (tp,ap,sp,iop,cp,mp,i) = self.conf_obj_tup

        try:

            start = time.time()

            # wfo = Wavefronts(inqueue, outqueue, conf_obj_tup)

            for it, t in enumerate(iter(self.inqueue.get, sentinel)):

                print('using process %i' % i)
                kwargs = {'iter': t, 'params': [ap, tp, iop, sp], 'CPA_maps': self.CPA_maps, 'tiptilt': self.tiptilt}
                sampling, save_E_fields = prop_run('medis.Telescope.optics_propagate', 1, ap.grid_size, PASSVALUE=kwargs,
                                                   VERBOSE=False, PHASE_OFFSET=1)

                if sp.cont_save:
                    # realtime_save(save_E_fields, t)
                    realtime_save_cont(save_E_fields, t, self.savequeue)
                elif tp.detector == 'MKIDs':
                    for o in range(len(ap.contrast) + 1):
                        spectralcube = np.abs(save_E_fields[-1, :, o]) ** 2
                        applymkideffects(spectralcube, t, o, return_spectralcube=False)

            now = time.time()
            elapsed = float(now - start) / 60.
            each_iter = float(elapsed) / (ap.numframes + 1)

            print('***********************************')
            dprint(f'{elapsed:.2f} minutes elapsed, each time step took {each_iter:.2f} minutes') #* ap.numframes/sp.num_processes TODO change to log #

        except Exception as e:
            traceback.print_exc()
            # raise e
            pass

def update_realtime_save():
    iop.realtime_save = f"{iop.realtime_save.split('.')[0][:-4]}{str(ap.startframe).zfill(4)}.pkl"

def initialize_telescope():
    iop.makedir()  # make the directories at this point in case the user doesn't want to keep changing params.py

    print('********** Taking Obs Data ***********')

    try:
        multiprocessing.set_start_method('spawn')
    except RuntimeError:
        pass

    # initialize atmosphere
    print("Atmosdir = %s " % iop.atmosdir)
    if tp.use_atmos:
        atmos.prepare_maps()

    # initialize telescope
    if glob.glob(iop.quasi+'/*.fits') == []:
        aber.generate_maps(tp.f_lens)
        if tp.aber_params['NCPA']:
            aber.generate_maps(tp.f_lens)

    # if tp.servo_error:
    #     aber.createObjMapsEmpty()

    aber.initialize_CPA_meas()

    if tp.active_null:
        aber.initialize_NCPA_meas()

    # initialize MKIDs
    if tp.detector == 'MKIDs' and not os.path.isfile(iop.device_params):
        MKIDs.initialize()

    if sp.save_obs and os.path.exists(iop.obs_table):
        os.remove(iop.obs_table)

    if ap.companion is False:
        ap.contrast = []

    if sp.save_locs is None:
        sp.save_locs = []
    if 'detector' not in sp.save_locs:
        sp.save_locs = np.append(sp.save_locs, 'detector')
        sp.gui_map_type = np.append(sp.gui_map_type, 'amp')

def applymkideffects(spectralcube, t, o, save_queue, return_spectralcube=False):

    with open(iop.device_params, 'rb') as handle:
        dp = pickle.load(handle)

    spectrallist = read.get_packets(spectralcube, t, dp, mp)
    dprint(len(spectrallist))

    if sp.save_obs:
        if o == 0:
            save_queue.put(('create_group', ('/', 't%i' % t)))
        command = read.get_obs_command(spectrallist, t, o)
        save_queue.put(command)

    if return_spectralcube:
        spectralcube = MKIDs.makecube(spectrallist, mp.array_size)

        return spectralcube

def realtime_save(spectralcube, t):
    if ap.interp_sample and ap.nwsamp>1 and ap.nwsamp<ap.w_bins:

        wave_samps = np.linspace(0, 1, ap.nwsamp)
        f_out = interp1d(wave_samps, spectralcube, axis=1)
        new_heights = np.linspace(0, 1, ap.w_bins)
        spectralcube = f_out(new_heights)

    read.save_step(('create_group', ('/', 't%i' % t)))
    read.save_step(('create_array', ('/t%i' % t, 'data', spectralcube)))

def realtime_save_cont(spectralcube, t, savequeue):
    if ap.interp_sample and ap.nwsamp>1 and ap.nwsamp<ap.w_bins:

        wave_samps = np.linspace(0, 1, ap.nwsamp)
        f_out = interp1d(wave_samps, spectralcube, axis=1)
        new_heights = np.linspace(0, 1, ap.w_bins)
        spectralcube = f_out(new_heights)

    # savequeue.put(('create_group', ('/', 't%i' % t)))
    # savequeue.put(('create_array', ('/t%i' % t, 'data', spectralcube)))
    savequeue.put(spectralcube)

sentinel = None
def postfacto(inqueue):
    for t in range(ap.startframe, ap.numframes):
        dprint(t)
        inqueue.put(t)

    for i in range(sp.num_processes):
        # Send the sentinal to tell Simulation to end
        inqueue.put(sentinel)

def run_medis():
    # if os.path.isfile(iop.fields):
    #     e_fields_sequence = read.open_fields(iop.fields)
    #     print(f"Shape of e_fields_sequence = {np.shape(e_fields_sequence)} (numframes [x savelocs] x nwsamp x nobj x grid x grid)")
    #     return e_fields_sequence

    if not os.path.isfile(iop.fields):
        print(f'No file found at {iop.fields}')
        print('Creating New MEDIS Simulation')

        # Start the clock
        begin = time.time()

        initialize_telescope()

        inqueue = multiprocessing.Queue()
        save_queue = multiprocessing.Queue()

        jobs = []

        if sp.cont_save and tp.detector == 'ideal':
            shape = (0, len(sp.save_locs), ap.w_bins, len(ap.contrast) + 1, ap.grid_size, ap.grid_size)
            proc = multiprocessing.Process(target=read.save_step_const, args=(save_queue, iop.fields, shape))
            proc.start()

        for i in range(sp.num_processes):
            p = multiprocessing.Process(target=Timeseries, args=(inqueue, save_queue, (tp,ap,sp,iop,cp,mp,i)))
            jobs.append(p)
            p.start()

        postfacto(inqueue)

        #todo hanging here for some reason
        for i, p in enumerate(jobs):
            p.join()

        save_queue.put(None)

        if sp.cont_save and tp.detector == 'ideal':
            proc.join()

        print('MEDIS Data Run Completed')
        finish = time.time()
        if sp.timing is True:
            print(f'Time elapsed: {(finish-begin)/60:.2f} minutes')
        print('**************************************')

    fields = read.open_fields(iop.fields)
    return fields

if __name__ == '__main__':
    sp.timing = True
    run_medis()