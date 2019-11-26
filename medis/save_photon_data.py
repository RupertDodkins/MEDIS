"""Top level code that takes a atmosphere phase map and propagates a wavefront through the system"""

import os
import numpy as np
import traceback
import multiprocessing
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
    """
    This object stores the relevant info for different timesteps to communicate and generates a timeseries of
    obeservations with them.

    Parameters
    ----------

    inqueue : mp.queue
        used to pass the simulation timestep indices to this object
    savequeue : mp.queue
        used to pass the timestep output to detector.readout and get saved
    conf_obj_tup : tuple
        "global" configuration parameters need to be passed as args to gen_timesteries and proper.prop_run for
        multiprocessing reasons

    Returns
    -------
     A series of E fields arrays (spatial, wavelengths, different objects, different optical planes) that are added to
     a h5 file with detector.readout

    """
    def __init__(self, inqueue, savequeue, conf_obj_tup):
        """
        inqueue:
            time index for parallelization (used by multiprocess)
        savequeue:
            photon table (list of photon packets) in the multiprocessing format
        CPA_maps : np.array
            a list of the 2D wavefront phase maps measured by the WFS to iterative converge on the optimal DM map (closed
            loop mode), or to be averaged or np.roll()ed to account for AO frame rate or servo lag
        tiptilt: np.array
            a list of 2D wavefront phase maps to be used to converge on the optimal tiptilt map

        """
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

        Returns
        -------
        Series of e fields


        """

        (tp,ap,sp,iop,cp,mp,i) = self.conf_obj_tup  # This is neccessary AFAICT

        try:

            start = time.time()

            for it, t in enumerate(iter(self.inqueue.get, sentinel)):

                if sp.verbose: print('timestep %i, using process %i' % (it, i))
                kwargs = {'iter': t, 'params': [ap, tp, iop, sp], 'CPA_maps': self.CPA_maps, 'tiptilt': self.tiptilt}
                sampling, save_E_fields = prop_run('medis.Telescope.optics_propagate', 1, ap.grid_size, PASSVALUE=kwargs,
                                                   VERBOSE=False, PHASE_OFFSET=1)

                if sp.cont_save:
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
    if tp.aber_params['CPA'] or tp.aber_params['NCPA']:
        aber.initialize_aber_maps()

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

def realtime_save_cont(spectralcube, t, savequeue):
    """
    Handle the passing othe E fields to the h5 saving function, but also interpolate before hand

    TODO
    Asses perhaps this isn't the best place for the interpolation in terms of code layout?

    Parameters
    ----------
    spectralcube : np.ndarray
        single timestep, multiwavelength, multiobject, multiplane complex E field
    t : int
        the timestep index to locate where to save the spectral cube
    savequeue : mp.queue
        queue to store the timestep

    Returns
    -------

    """
    if ap.interp_sample and ap.nwsamp>1 and ap.nwsamp<ap.w_bins:

        wave_samps = np.linspace(0, 1, ap.nwsamp)
        f_out = interp1d(wave_samps, spectralcube, axis=1)
        new_heights = np.linspace(0, 1, ap.w_bins)
        spectralcube = f_out(new_heights)

    savequeue.put((t, spectralcube))

sentinel = None  # initialise outside of run_medis()

def postfacto(inqueue):
    """
    Name comes from the origin of this function in get_photon_data where it (as opposed to realtime()) was called if
    the user didn't want to see the E fields in realtime with the GUI

    TODO
    Assess whether GUI functionality should be added here

    Parameters
    ----------
    inqueue : mp.queue
        timestep indices

    """
    for t in range(ap.startframe, ap.numframes):
        inqueue.put(t)

    for i in range(sp.num_processes):
        # Send the sentinal to tell Simulation to end
        inqueue.put(sentinel)

def run_medis():

    if not os.path.isfile(iop.fields):
        print(f'No file found at {iop.fields}')
        print('Creating New MEDIS Simulation')

        # Start the clock
        begin = time.time()

        initialize_telescope()

        inqueue = multiprocessing.Queue()
        save_queue = multiprocessing.Queue()

        jobs = []

        # start the process responsible for taking the save_queue and adding to the h5 file
        if sp.cont_save and tp.detector == 'ideal':
            eshape = (len(sp.save_locs), ap.w_bins, len(ap.contrast) + 1, ap.grid_size, ap.grid_size)
            proc = multiprocessing.Process(target=read.save_step_const, args=(save_queue, iop.fields, eshape))
            proc.start()

        # start the process that generates the data as timesteps are fed
        for i in range(sp.num_processes):
            p = multiprocessing.Process(target=Timeseries, args=(inqueue, save_queue, (tp,ap,sp,iop,cp,mp,i)))
            jobs.append(p)
            p.start()

        # feed the timesteps
        postfacto(inqueue)

        for i, p in enumerate(jobs):
            p.join()

        save_queue.put((None, None))

        if sp.cont_save and tp.detector == 'ideal':
            proc.join()

        print('MEDIS Data Run Completed')
        finish = time.time()
        if sp.timing is True:
            print(f'Time elapsed: {(finish-begin)/60:.2f} minutes')
        print('**************************************')

    # This takes the data saved to disk. Reads it in to memory to be returned
    fields = read.open_fields(iop.fields)  #TODO make this optional for larger datasets
    return fields

if __name__ == '__main__':
    sp.timing = True
    run_medis()