import sys
sys.path.append('/Data/PythonProjects/MEDIS/MEDIS')
from params import tp, mp, cp
from get_photon_data import run
import matplotlib.pyplot as plt
import cPickle as pickle
import numpy as np

cp.numframes = 1
tp.detector = 'ideal'#
tp.save_obs = False
tp.show_wframe = False#'continuous'
# tp.fig = plt.figure()
tp.use_atmos = True 
tp.use_ao = True
tp.CPA_type = None#'Static'#'Quasi'# None
tp.NCPA_type = None#'Static' #None
tp.active_null = False
tp.satelite_speck = True
tp.speck_locs = [[40,60], [40,70],[50,50]]#[[20,20],[40,30], [40,40]]
tp.speck_phases = [np.pi, np.pi/2, np.pi]
tp.speck_peakIs = np.ones((len(tp.speck_locs)))*0.05#*(1.1*len(tp.speck_locs))
mp.frame_time = 0.1


measured = []
for phase in np.linspace(0,6*np.pi,150):
	# tp.speck_phases = [-np.pi/2]#[phase]#
	run()
	measured.append(tp.variable)

# with open('test.pkl', 'wb') as handle:
#     pickle.dump(measured, handle, protocol=pickle.HIGHEST_PROTOCOL)

# with open('test.pkl', 'rb') as handle:
#     measured =pickle.load(handle)

# speck_phase = np.array(measured)#+1.9377
# # exceed = np.where(speck_phase >= 3.14)[0]
# # speck_phase[exceed] = speck_phase[exceed]-2*3.14
# plt.plot(np.linspace(-2*np.pi,6*np.pi,150) - speck_phase)
# # plt.xlabel('DM phase')
# # plt.xlim([0,2*np.pi])
# # plt.ylim([0,np.pi])
# # plt.ylabel('speck phase')
# plt.show()
