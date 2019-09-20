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

class Timeseries():
    def __init__(self, inqueue, outqueue, conf_obj_tup):
        self.inqueue = inqueue
        self.outqueue = outqueue
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
        :param photon_table_queue: photon table (list of photon packets) in the multiprocessing format
        :param spectralcube_queue: series of intensity images (spectral image cube) in the multiprocessing format
        :param conf_obj_tup:
        :return:
        """
        (tp,ap,sp,iop,cp,mp,i) = self.conf_obj_tup

        try:

            start = time.time()

            # wfo = Wavefronts(inqueue, outqueue, conf_obj_tup)

            now = time.time()
            for it, t in enumerate(iter(self.inqueue.get, sentinel)):
                print('using process %i' % i)
                kwargs = {'iter': t, 'params': [ap, tp, iop, sp], 'CPA_maps': self.CPA_maps, 'tiptilt': self.tiptilt}
                sampling, save_E_fields = prop_run('medis.Telescope.optics_propagate', 1, ap.grid_size, PASSVALUE=kwargs,
                                                       VERBOSE=False, PHASE_OFFSET=1)

                # for o in range(len(ap.contrast) + 1):
                #     outqueue.put((t, save_E_fields[:, :, o]))
                self.outqueue.put((t, save_E_fields))


            elapsed = float(now - start) / 60.
            each_iter = float(elapsed) / (len(save_E_fields) + 1)

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

    print('Creating New MEDIS Simulation')
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

def applymkideffects(spectralcube, t, o, photon_table_queue, EfieldsThread=None, return_spectralcube=False):

    with open(iop.device_params, 'rb') as handle:
        dp = pickle.load(handle)

    spectrallist = read.get_packets(spectralcube, t, dp, mp)
    dprint(len(spectrallist))

    if sp.save_obs:
        if o == 0:
            photon_table_queue.put(('create_group', ('/', 't%i' % t)))
        command = read.get_obs_command(spectrallist, t, o)
        photon_table_queue.put(command)

    if return_spectralcube:
        spectralcube = MKIDs.makecube(spectrallist, mp.array_size)

        # if EfieldsThread:
        #     EfieldsThread.photons = spectrallist

        return spectralcube

sentinel = None
def realtime_stream(EfieldsThread, e_fields_sequence, inqueue, photon_table_queue, outqueue):
    EfieldsThread.e_fields_sequences = e_fields_sequence

    for t in range(ap.startframe, ap.numframes):
        inqueue.put(t)

    for i in range(sp.num_processes):
        # Send the sentinal to tell Simulation to end
        inqueue.put(sentinel)

    for t in range(ap.startframe, ap.numframes):
        print(EfieldsThread.save_E_fields[:].shape)
        EfieldsThread.qt, EfieldsThread.save_E_fields[:] = outqueue.get()

        for o in range(len(ap.contrast) + 1):
            spectralcube = np.abs(EfieldsThread.save_E_fields[-1, :, o]) ** 2

            if tp.detector == 'MKIDs':
                spectralcube = applymkideffects(spectralcube, t, o, photon_table_queue, EfieldsThread, return_spectralcube=True)

            # EfieldsThread.save_E_fields[-1] = spectralcube
            EfieldsThread.sct.integration += spectralcube
            EfieldsThread.sct.obs_sequence[EfieldsThread.qt - ap.startframe, o] = spectralcube

            e_fields_sequence[EfieldsThread.qt - ap.startframe, :, :, o] = EfieldsThread.save_E_fields[:, :, o]  # _fields_sequence[qt, :, :, o] = save_E_fields
            if o == EfieldsThread.fields_ob and EfieldsThread.qt % sp.gui_samp == 0:
                EfieldsThread.get_gui_images(o)
                EfieldsThread.newSample.emit(True)
                EfieldsThread.sct.newSample.emit(True)

        if sp.play_gui is False:
            ap.startframe = EfieldsThread.qt
            update_realtime_save()
            read.save_rt(iop.realtime_save, e_fields_sequence[:EfieldsThread.qt])
            sp.play_gui = True
            run_medis(EfieldsThread)
            return

    return e_fields_sequence

def postfacto(e_fields_sequence, inqueue, photon_table_queue, outqueue):
    for t in range(ap.startframe, ap.numframes):
        dprint(t)
        inqueue.put(t)

    for i in range(sp.num_processes):
        # Send the sentinal to tell Simulation to end
        inqueue.put(sentinel)

    for t in range(ap.startframe, ap.numframes):
        dprint(t)
        qt, save_E_fields = outqueue.get()

        for o in range(len(ap.contrast) + 1):
            spectralcube = np.abs(save_E_fields[-1, :, o]) ** 2

            if tp.detector == 'MKIDs':
                applymkideffects(spectralcube, t, o, photon_table_queue, return_spectralcube=False)

        if sp.save_fields or sp.save_ints or not sp.save_obs:
            e_fields_sequence[qt - ap.startframe] = save_E_fields

    # if just saving MKID obsfiles then you can save a lot of time by not returning e_fields_sequence
    if sp.save_fields or sp.save_ints or not sp.save_obs:
        return e_fields_sequence

def run_medis(EfieldsThread=None, realtime=False, plot=False):

    if EfieldsThread is not None:
        realtime = True

    # If complete savefile exists use that
    check = read.check_exists_fields(plot)
    if check:
        e_fields_sequence = read.open_fields(iop.fields)
        print(f"Shape of e_fields_sequence = {np.shape(e_fields_sequence)} (numframes [x savelocs] x nwsamp x nobj x grid x grid)")
        return e_fields_sequence

    # Start the clock
    begin = time.time()

    initialize_telescope()

    # Initialise the fields
    e_fields_sequence = np.zeros((ap.numframes, len(sp.save_locs),
                                  ap.nwsamp, 1 + len(ap.contrast),
                                  ap.grid_size, ap.grid_size), dtype=np.complex64)

    # If cache exists load it in
    update_realtime_save()
    if ap.startframe != 0 and os.path.exists(iop.realtime_save):
        #todo add parameteters check
        print('warning loading from cache. Are the parameters the same?')
        e_fields_sequence[:ap.startframe] = read.open_rt_save(iop.realtime_save, ap.startframe)

    inqueue = multiprocessing.Queue()
    outqueue = multiprocessing.Queue()
    photon_table_queue = multiprocessing.Queue()
    jobs = []

    if sp.save_obs and tp.detector == 'MKIDs':
        proc = multiprocessing.Process(target=read.handle_output, args=(photon_table_queue, iop.obs_table))
        proc.start()

    for i in range(sp.num_processes):
        p = multiprocessing.Process(target=Timeseries, args=(inqueue, outqueue, (tp,ap,sp,iop,cp,mp, i)))
        jobs.append(p)
        p.start()

    if realtime:
        e_fields_sequence = realtime_stream(EfieldsThread, e_fields_sequence, inqueue, photon_table_queue, outqueue)
    else:
        e_fields_sequence = postfacto(e_fields_sequence, inqueue, photon_table_queue, outqueue)

    #todo hanging here for some reason
    # for i, p in enumerate(jobs):
    #     p.join()

    if ap.interp_sample and ap.nwsamp>1 and ap.nwsamp<ap.w_bins:
        from scipy.interpolate import interp1d
        wave_samps = np.linspace(0, 1, ap.nwsamp)
        f_out = interp1d(wave_samps, e_fields_sequence, axis=2)
        new_heights = np.linspace(0, 1, ap.w_bins)
        e_fields_sequence = f_out(new_heights)

    # e_fields_sequence /= np.sum(np.abs(e_fields_sequence[0,-1,:,0,:,:])**2)

    photon_table_queue.put(None)
    outqueue.put(None)
    if sp.save_obs and tp.detector == 'MKIDs':
        proc.join()

    print('MEDIS Data Run Completed')
    finish = time.time()
    if sp.timing is True:
        print(f'Time elapsed: {(finish-begin)/60:.2f} minutes')
    print('**************************************')
    print(f"Shape of e_fields_sequence = {np.shape(e_fields_sequence)} (numframes x savelocs x nwsamp x nobj x grid x grid)")

    if sp.save_fields:
        dprint(iop.fields)
        read.save_fields(e_fields_sequence, fields_file=iop.fields)
    elif sp.save_ints:
        print('Integrating at science plane')
        e_fields_sequence = np.abs(e_fields_sequence[:, -1]) ** 2
        read.save_fields(e_fields_sequence, fields_file=iop.fields)

    return e_fields_sequence

if __name__ == '__main__':
    sp.timing = True
    run_medis()