import numpy as np
import proper
import os
# import vip


class astro_params():
    def __init__(self):
        # Total number of photons on the array for a timestep shared between all wavelengths
        self.star_photons = int(1e5) # # A 5 apparent mag star 1e6 cts/cm^2/s
        self.companion=True
        self.contrast = [0.05]
        self.C_spec = 1.5 #the gradient of the increase in contrast towards shorter wavelengths
        self.lods = [[-1.0, 1.0]] # initial location (no rotation)
        self.exposure_time = 0.001
        self.startframe=0 # useful for things like RDI
        self.numframes = 5000

class caos_params():
    def __init__(self):
        self.rootdir = '/Users/dodkins/ScienceData/medis/' # possibly redundant with iop class
        self.data = 'atmos' # possibly redundant with iop class
        self.date = '180320/'# possibly redundant with iop class
        self.script= 'ATMOS_test'# possibly redundant with iop class
        self.atmosdir= os.path.join(self.rootdir,self.data,self.date) # possibly redundant with iop class
        self.idl_params = os.path.join(self.rootdir,self.data,'idl_params.csv')
        self.show_caosparams= True # for control over all other variables
        self.frame_time = 0.001 # this is the maximum frame rate of the simulation
        self.vary_r0 = False
        self.r0s = []
        self.scalar_r0 = 'med'
        self.r0s_idx = -1

class telescope_params():
    def __init__(self):
        self.grid_size = 128 #128            # grid size
        # self.lamda = 1        # wavelength (microns)
        self.nwsamp = 3 # number of wavefronts created in PROPER to sample from
        self.w_bins = 8 # number of bins in the resultant datacube
        self.interp_sample = True
        # self.band = np.array([1100,1400]) #J band
        self.band = np.array([800,1500]) # whole DARKNESS band
        self.rot_rate = 0#1 # deg/s
        self.use_spiders = True
        self.use_hex = False
        self.use_atmos = True # have to for now because ao wfs reads in map produced but not neccessary
        self.use_ao = True#True
        self.quick_ao = True
        self.ao_act = 60#41 #32
        self.servo_error= [0,1]#[0,1]#False # No delay and rate of 1/frame_time
        self.active_null = False
        self.active_converge_steps = 1#10
        self.active_modulate=False
        # self.null_ao_act=66
        self.wfs_measurement_error = False
        self.piston_error = True
        self.wfs_scale = 3
        # self.occulter_type ='8th_Order'#'GAUSSIAN' None#'SOLID'#
        self.occulter_type ='Vortex'#'Gaussian'# None#
        # self.occulter_type = None#
        self.occult_loc = [0,0]#[3,-5] #correspond to normal x y direction
        self.use_apod = True
        self.apod_gaus = 1
        # self.CPA_type = 'Static'#'Quasi'# None
        # self.NCPA_type = 'Static'#'Wave'# #None
        self.aber_params = {'CPA': True,
                          'NCPA': True,
                          'QuasiStatic': False,  # or 'Static'
                          'Phase': True,
                          'Amp': False,
                            'n_surfs':2,
                            'OOPP':[8,4]} # fraction of a focal length where mirror(s) is located
        self.aber_vals = {'a': [7.2e-17, 3e-17],
                        'b': [0.8, 0.2],
                        'c': [3.1,0.5],
                          'a_amp':[0.05,0.01]}
        self.use_zern_ab = False
        self.diam = 5.0 #8.0              # telescope diameter in meters
        self.f_lens = 200.0 * self.diam
        self.platescale = 13.61 #mas # have to run get_sampling at the focus to find this
        self.beam_ratio = 25/64.#0.39#0.3#0.25#0.5
        # self.detector = 'MKIDs'#
        self.detector = 'ideal'#
        self.satelite_speck = False
        self.speck_locs = [[50,60]]
        self.speck_phases = [np.pi/2.]
        self.speck_peakIs = [0.05]
        self.abertime = 0.5  #time scale of optic aberrations
        self.samp = 0.2#0.125
        self.rootdir = os.path.realpath(__file__)[:-16]
        # self.data = 'data/aberrations'
        # self.date = '180210/'
        # self.aberdir = os.path.join(self.rootdir,self.data,self.date)
        self.FPWFSdir = self.rootdir+'/MEDIS/speckle_nulling/speckle_nulling/'
        self.check_args()
        self.pix_shift = False

    def check_args(self):
        assert self.occulter_type in [None, 'None', 'Solid', 'Gaussian', '8th_Order', 'Vortex', 'None (Lyot Stop)']
        # assert self.aber_params['CPA'] in [None, 'Static', 'Quasi', 'Wave', 'Amp', 'test','Both','Phase']
        # assert self.aber_params['NCPA'] in [None, 'Static', 'Quasi', 'Wave', 'Amp']

class mkid_params():
    def __init__(self):
        self.bad_pix = False
        # self.interp_sample=True # avoids the quantization error in creating the datacube
        self.response_map = None
        self.wavecal_coeffs = [1./12, -157] #assume linear for now 800nm = -90deg, 1500nm = -30deg
        self.rootdir = os.path.realpath(__file__)[:-16]#'/Data/PythonProjects/MEDIS/Data'
        self.data = 'data/obsfiles'
        # self.date = '180324/'
        # self.datadir= os.path.join(self.rootdir,self.data, self.date)
        # self.obsfile = 'r0varyObsfile.h5'
        # self.proc_dir = 'data/processed'
        self.phase_uncertainty = False#True
        self.phase_background = False
        self.respons_var = False
        self.remove_close= False
        self.array_size = np.array([129,129])#np.array([125,80])#np.array([125,125])#
        # self.total_pix = self.array_size[0] * self.array_size[1]
        self.pix_yield=0.9
        self.hot_pix = 0
        # self.wave_coeffs = [0.1,-200]
        self.threshold_phase = 0#-30 # quite close to 0, basically all photons will be detected.

        # ct_rate = 1.e6 # G type star 10ly away gives 1e6 cts/cm^2/s
        # dish_area = 20. # Palomar is 20 m^2 including hole. 
        # total_ct_rate = ct_rate * dish_area/1e-4
        self.max_count = 2500. # cts/s
        self.dead_time = 1./self.max_count
        self.bin_time = 2e-3 # minimum time to bin counts for stat-based analysis
        # self.frame_time = 0.001#atm_size*atm_spat_rate/(wind_speed*atm_scale) # 0.0004
        self.total_int = 1 #second
        self.frame_int = 1./20
        self.t_frames = int(self.total_int/self.frame_int)
        # wind_speed = 5. # m/s
        # atm_scale = 512.
        # atm_size = 1. # m
        # atm_spat_rate = 1. # pix shift
        # frame_time = 0.001#atm_size*atm_spat_rate/(wind_speed*atm_scale) # 0.0004
        # self.directory='/home/dodkins/PythonProjects/MEDIS/Data/'
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

        self.lod = 8 #8 pixels in these upsampled images = one lambda/d
        self.nlod = 10 #3 #how many lambda/D do we want to calculate out to

class H2RG_params():
    def __init__(self):
        self.use_readnoise=True
        self.readnoise=30
        self.erate = 1

class simulation_params():
    def __init__(self):
        self.num_processes = 1 #multiprocessing.cpu_count()
        self.show_wframe = False
        self.show_cube = True
        self.cbar = None
        self.vmax = None
        self.vmin = None
        self.variable = None
        self.save_obs = True
        self.return_cube=True
        self.get_ints = {'w':[0],
                          'c':[0]}#False

class io_params():
    def __init__(self, date='180406b/'):
        # self.rootdir = os.path.realpath(__file__)[:-16]#'/Data/PythonProjects/MEDIS/Data'
        self.proc_dir = 'medis/Processed'
        # self.datadir = os.path.join(self.rootdir, self.proc_dir, date)
        # self.datadir = os.path.join('/Users/dodkins/ScienceData', self.proc_dir, date)
        self.datadir = os.path.join(os.environ['MKID_RAW_PATH'], self.proc_dir, date)
        self.obsfile = os.path.join(os.environ['MKID_DATA_DIR'], 'medis', mp.data, date,'r0varyObsfile.h5')
        self.LCmapFile = os.path.join(self.datadir, 'LCmap.pkl')
        self.IratioFile = os.path.join(self.datadir,'Iratio.pkl')
        self.DSFile = os.path.join(self.datadir,'DS.pkl')
        # self.hyperFile = os.path.join(self.datadir,'Hypercube.pkl')
        self.hyperFile = os.path.join(self.datadir,'Hypercube.hdf')
        # self.IQpixel = os.path.join(self.datadir,'./novary64act_medr0_piston.txt')
        self.saveIQ = True
        self.int_maps = os.path.join(self.datadir, 'int_maps.pkl')
        self.IQpixel = os.path.join(self.datadir,'./novary64act_medr0_piston.txt')
        self.device_params = os.path.join(self.datadir,'deviceParams.pkl')
        self.NCPA_meas = os.path.join(self.datadir,'NCPA_meas.pkl')
        self.CPA_meas = os.path.join(self.datadir,'CPA_meas.pkl')
        # self.phase_ideal = os.path.join(self.datadir,'phase_ideal.pkl')
        self.measured_var= os.path.join(self.datadir,'measured_var.pkl')
        # self.data = 'data/aberrations'
        # self.date = '180210/'
        self.aberdir = os.path.join(os.environ['MKID_RAW_PATH'], 'medis', 'aberrations/181201/')
        self.coron_temp = os.path.join(os.environ['MKID_RAW_PATH'], self.proc_dir, date,'coron_maps/')
    def update(self, date='180406b/'):
        self.__init__(date=date)

class device_params():
    '''A object which contains the calculated parameters of the array'''
    def __init__(self):
        self.response_map = None
        self.Rs = None
        self.sigs = None
        self.basesDeg = None
        self.hot_pix = None

class FPWFS_params():
    '''Replaces the role of M. Bottom's Config file for speckle_killer_v3'''
    def __init__(self):
        self.max_specks = 1
        # self.imparams =
        self.lod = 2.62
        self.exclusionzone = 12.
        # self.controlregion = [50,80,35,50] # x1, x2, y1, y2
        self.controlregion = [40,100,20,60] # y1, y2, x1, x2

ap = astro_params()
cp = caos_params()
tp = telescope_params()
mp = mkid_params()
hp = H2RG_params()
sp = simulation_params()
iop = io_params()
dp = device_params()
fp = FPWFS_params()

proper.print_it = False
# proper.print_it = False
# proper.prop_init_savestate()
# datadir = '/Data/PythonProjects/MEDIS/Data/time/1KwRMS_2nd/'#'/home/rupert/PythonProjects/MkidCoronSim/Data/1KwRMS/'
# datadir = '/Data/PythonProjects/MEDIS/caos_pse/work_caos/'



