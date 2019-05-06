"""
This is the main configuration file. It contains default global variables (as in they are read in by the relevant modules)
that define the parameters of the whole telescope system. These parameters can be redefined at the beginning of the
example module the user is running

"""

import numpy as np
import proper
import os
from pathlib import Path


class IO_params:
    """
    Define file tree/structure to import and save data
    """
    def __init__(self, testname='example1', datadir=None):  # testname should be the name of the particular example you are running,
                                                # for example 'BetaPic' or 'simple_telescope'
        # High Level Paths
        if datadir is None:
            self.datadir = os.path.join(str(Path.home()), 'medis_data')  # Default Base path where results are stored (outside repository)
        else:
            self.datadir = datadir
        self.rootdir = os.path.dirname(os.path.realpath(__file__))  # Path to Codebase (location of repository)

        # Atmosphere Metadata
        self.atmosroot = 'atmos'  # directory with the FITS Files for Atmosphere created by caos (get this from Rupert, don't recreate this on your own!!)
        self.atmosdata = '190501'
        self.atmosdir = os.path.join(self.datadir, self.atmosroot, self.atmosdata)  # full path to FITS files
        self.idl_params = os.path.join(self.atmosroot, 'idl_params.csv')  # path to params files to make new atmosphere model using caos

        # Aberration Metadata
        self.aberroot = 'aberrations'
        self.aberdata = 'Palomar'
        self.aberdir = os.path.join(self.datadir, self.aberroot, self.aberdata)
        self.NCPA_meas = os.path.join(self.aberdir, 'NCPA_meas.pkl') #
        self.CPA_meas = os.path.join(self.aberdir, 'CPA_meas.pkl')
        self.quasi = os.path.join(self.aberdir, 'quasi')

        # Unprocessed Photon Science Data
        self.sciroot = 'observations'
        self.scidir = os.path.join(self.datadir, self.sciroot)  # self.savedata
        self.testname = testname  # set this up in the definition line, but can update it with iop.update('newname')
        self.testdir = os.path.join(self.scidir, self.testname)  # Save results in new sub-directory
        self.obs_seq = os.path.join(self.testdir, 'ObsSeq.h5')  # a x/y/t/w cube of data
        self.fields = os.path.join(self.testdir, 'fields.h5')
        self.obs_table = os.path.join(self.testdir, 'ObsTable.h5')  # a photon table with 4 coloumns
        self.device_params = os.path.join(self.testdir, 'deviceParams.pkl')  # detector metadata
        self.coron_temp = os.path.join(self.testdir, 'coron_maps/') # required by vortex coron function

        #Post Processing Data
        self.LCmapFile = os.path.join(self.testdir, 'LCmap.pkl')
        self.IratioFile = os.path.join(self.testdir, 'Iratio.pkl')
        self.DSFile = os.path.join(self.testdir, 'DS.pkl')
        self.saveIQ = True
        self.int_maps = os.path.join(self.testdir, 'int_maps.pkl')
        self.IQpixel = os.path.join(self.testdir, './novary64act_medr0_piston.txt')
        self.measured_var = os.path.join(self.testdir, 'measured_var.pkl')

        print(self.datadir)

    def update(self, new_name='example1'):
        datadir = self.datadir
        self.__init__(testname=new_name, datadir=datadir)

    def makedir(self):
        print(self.datadir, self.testdir, self.atmosroot, self.atmosdir, self.aberdir, self.scidir, self.coron_temp, self.quasi)
        if not os.path.isdir(self.datadir):
            os.makedirs(self.datadir, exist_ok=True)
        if not os.path.isdir(self.testdir):
            os.makedirs(self.testdir, exist_ok=True)
        # if not os.path.isdir(self.atmosroot):
        #     os.makedirs(self.atmosroot, exist_ok=True)
        if not os.path.isdir(self.atmosdir):
            os.makedirs(self.atmosdir, exist_ok=True)
        # if not os.path.isdir(self.aberroot):
        #     os.makedirs(self.aberroot, exist_ok=True)
        if not os.path.isdir(self.aberdir):
            os.makedirs(self.aberdir, exist_ok=True)
        # if not os.path.isdir(self.sciroot):
        #     os.makedirs(self.sciroot, exist_ok=True)
        if not os.path.isdir(self.scidir):
            os.makedirs(self.scidir, exist_ok=True)
        if not os.path.isdir(self.coron_temp):
            os.makedirs(self.coron_temp, exist_ok=True)
        if not os.path.isdir(self.quasi):
            os.makedirs(self.quasi, exist_ok=True)


class Simulation_params:
    """
    Default parameters for outputs of the simulation. What plots you want to see etc
    """
    def __init__(self):
        self.timing = True  # True will print timing statements in run_medis()
        self.num_processes = 1 #multiprocessing.cpu_count()
        self.show_wframe = False
        self.show_cube = True
        self.use_gui = False
        self.play_gui = True
        self.cbar = None
        self.fig = None
        self.vmax = None
        self.vmin = None
        self.variable = None
        self.save_obs = False
        self.return_E = False
        # self.get_ints = False
        self.save_locs = None
        self.gui_map_type = None


class Astro_params:
    """
    Default parameters for the astronomical system under investigation
    exposure_time, startframe and numframes may seem a bit out of place here. Perhaps this class could be renamed
    """
    def __init__(self):
        # Total number of photons on the array for a timestep shared between all wavelengths
        self.star_photons = int(1e5) # # A 5 apparent mag star 1e6 cts/cm^2/s
        self.companion = True
        self.contrast = [0.05]
        self.C_spec = 1.5  # the gradient of the increase in contrast towards shorter wavelengths
        self.lods = [[-1.0, 1.0]]  # initial location (no rotation)
        self.sample_time = 0.01
        self.startframe = 0  # useful for things like RDI
        self.numframes = 100  # number of timesteps in the simulation

        # Wavelength and Wavefront Array Settings
        # In optics_propagate(), proper initially takes N  discreet wavelengths evenly spaced in ap.band, where N is
        # given by ap.nwsamp. Later, in gen_timeseries(), the 3rd axis of the spectral cube is interpolated so that
        # there are ap.w_bins over the range in ap.band.
        self.nwsamp = 3  # initial number of wavefronts in spectral cube (later sampled by MKID detector)
        self.w_bins = 8  # final number of wavefronts in spectral cube after interpolation
        self.band = np.array([800, 1500])  # wavelength range in nm
        # eg. DARKNESS band is [800, 1500], J band =  [1100,1400])
        self.samp = 0.2  # 0.125  This is a hacked parameter, to scale the atmos fits files to the wf_array
        self.grid_size = 128  # creates a nxn array (of samples of the wavefront)
        # must be bigger than the beam size to avoid FT effects at edges; must be factor of 2
        # NOT the size of your detector/# of pixels
        self.interp_sample = True  # Set to interpolate wavelengths from ap.nwsamp to ap.w_bins


class Telescope_params:
    """
    This contains most of the parameters you will probably modify when running tests
    """
    def __init__(self):
        # Foreoptics + AO Settings
        self.pix_shift = [0, 0]  # False?  Shifts the central star to off-axis (circular shift) (mimics conex mirror)
        self.rot_rate = 0  # deg/s
        self.obscure = False  # Turns on obscurations (spiders and secondary obscuration,
                             # but can turn spiders off when called with legs=False)
        self.use_hex = False  # include aberrations from hexagonal segmented mirror shape of primary
        self.use_atmos = True  # have to for now because ao wfs reads in map produced but not neccessary
        self.use_ao = True  # True
        self.quick_ao = True
        self.ao_act = 60  # 41 #32
        self.servo_error = [0, 1]  # [0,1] # False # No delay and rate of 1/frame_time
        self.active_null = False
        self.active_converge_steps = 1  # 10
        self.active_modulate = False
        # self.null_ao_act=66
        self.wfs_measurement_error = False
        self.piston_error = True
        self.wfs_scale = 3
        self.occulter_type = 'Vortex'  # 'Gaussian'# None# '8th_Order'#'GAUSSIAN' None#'SOLID'#
        self.occult_loc = [0,0]  # [3,-5] #correspond to normal x y direction
        self.use_apod = True
        self.apod_gaus = 1

        # Aberrations
        self.abertime = 0.5  # time scale of optic aberrations in seconds
        self.use_zern_ab = False
        self.aber_params = {'CPA': True,
                            'NCPA': True,
                            'QuasiStatic': False,  # or 'Static'
                            'Phase': True,
                            'Amp': False,
                            'n_surfs': 2,
                            'OOPP': [8,4]}  # fraction of a focal length where mirror(s) is located
        self.aber_vals = {'a': [7.2e-17, 3e-17],
                           'b': [0.8, 0.2],
                           'c': [3.1,0.5],
                           'a_amp': [0.05,0.01]}

        # Optics + Detector
        self.diam = 5.0  # telescope diameter in meters
        self.f_lens = 200.0 * self.diam
        self.platescale = 13.61  # mas # have to run get_sampling at the focus to find this
        self.beam_ratio = 25/64.  # parameter dealing with the sampling of the beam in the pupil/focal plane vs grid size
        self.detector = 'ideal'  # 'MKIDs'

        # Speckles
        self.satelite_speck = False
        self.speck_locs = [[50, 60]]
        self.speck_phases = [np.pi/2.]
        self.speck_peakIs = [0.05]

        self.check_args()

        # ct_rate = 1.e6 # G type star 10ly away gives 1e6 cts/cm^2/s
        # dish_area = 20. # Palomar is 20 m^2 including hole.
        # total_ct_rate = ct_rate * dish_area/1e-4

    def check_args(self):
        assert self.occulter_type in [None, 'None', 'Solid', 'Gaussian', '8th_Order', 'Vortex', 'None (Lyot Stop)']
        # assert self.aber_params['CPA'] in [None, 'Static', 'Quasi', 'Wave', 'Amp', 'test','Both','Phase']
        # assert self.aber_params['NCPA'] in [None, 'Static', 'Quasi', 'Wave', 'Amp']


class MKID_params:
    def __init__(self):
        self.bad_pix = False
        # self.interp_sample=True # avoids the quantization error in creating the datacube
        self.response_map = None
        self.wavecal_coeffs = [1./12, -157]  # assume linear for now 800nm = -90deg, 1500nm = -30deg
        self.phase_uncertainty = False  # True
        self.phase_background = False
        self.respons_var = False
        self.remove_close = False
        self.array_size = np.array([129,129])#np.array([125,80])#np.array([125,125])#
        # self.total_pix = self.array_size[0] * self.array_size[1]
        self.pix_yield = 0.9
        self.hot_pix = 0  # Number of hot pixels
        self.hot_bright = 1000  # Number of counts/time a hot pixel registers
        self.threshold_phase = 0#-30 # quite close to 0, basically all photons will be detected.

        self.max_count = 2500.  # cts/s
        self.dead_time = 1./self.max_count
        self.bin_time = 2e-3 # minimum time to bin counts for stat-based analysis
        # self.frame_time = 0.001#atm_size*atm_spat_rate/(wind_speed*atm_scale) # 0.0004
        self.total_int = 1 #second
        self.frame_int = 1./20
        self.t_frames = int(self.total_int/self.frame_int)
        # self.xnum= self.array_size[0]
        # self.ynum= self.array_size[1]

        # for distributions
        self.res_elements = self.array_size[0]
        self.g_mean = 0.95
        self.g_sig = 0.025
        self.bg_mean = -10
        self.bg_sig = 30
        self.R_mean = 50
        self.R_sig = 2

        self.lod = 8  # 8 pixels in these upsampled images = one lambda/d
        self.nlod = 10  # 3 #how many lambda/D do we want to calculate out to


class Device_params:
    """
    This is different from MKID_params in that it contains an instance of these random multidimensional parameters
    Perhaps it could be part of MKID_params
    """
    def __init__(self):
        self.response_map = None
        self.Rs = None
        self.sigs = None
        self.basesDeg = None
        self.hot_pix = None


class H2RG_params:
    def __init__(self):
        self.use_readnoise = True
        self.readnoise = 30
        self.erate = 1


class FPWFS_params:
    """Replaces the role of M. Bottom's Config file for speckle_killer_v3"""
    def __init__(self):
        self.max_specks = 1
        # self.imparams =
        self.lod = 2.62
        self.exclusionzone = 12.
        # self.controlregion = [50,80,35,50] # x1, x2, y1, y2
        self.controlregion = [40,100,20,60] # y1, y2, x1, x2


class CAOS_params:
    """
    # TODO make redundant with new atmosphere model
    Default parameters for the atmosphere. Now uses HCIpy not CAOS but ap was taken by Astro_params

    :model: either single frozen layer, hcipy_standard or evolving (apply variation to frozen some parameter)
    """
    def __init__(self):
        self.model = 'single'  # single|hcipy_standard|evolving
        self.show_caosparams= True  # for control over all other variables
        self.cn = 0.22 * 1e-12
        self.L0 = 10
        self.v = 5
        self.h = 100

        # original parameters
        # self.frame_time = 0.01  # this determines the maximum frame rate of the simulation
        self.vary_r0 = False
        self.r0s = []
        self.scalar_r0 = 'med'
        self.r0s_idx = -1
        self.outer_scale = 20

        # Settings Taken from MKID_params that seem to be relevant here:
        # wind_speed = 5. # m/s
        # atm_scale = 512.
        # atm_size = 1. # m
        # atm_spat_rate = 1. # pix shift


ap = Astro_params()
cp = CAOS_params()
tp = Telescope_params()
mp = MKID_params()
hp = H2RG_params()
sp = Simulation_params()
iop = IO_params()
dp = Device_params()
fp = FPWFS_params()

proper.print_it = False
# proper.prop_init_savestate()

if os.path.exists(f'{os.path.dirname(__file__)}/user_params.py'):
    from medis.user_params import update
    ap, cp, tp, mp, hp, sp, iop, dp, fp = update((ap, cp, tp, mp, hp, sp, iop, dp, fp))
