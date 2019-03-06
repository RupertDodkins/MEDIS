import numpy as np
rom medis.params import tp, mp, cp, sp, ap, iop
from get_photon_data import run_medis
import get_photon_data as gpd
from medis.Utils.plot_tools import view_datacube
import medis.Utils.rawImageIO as rawImageIO
from medis.Utils.plot_tools import quicklook_im
import proper
mport matplotlib.pyplot as plt


sp.show_wframe = True
sp.show_cube=False
sp.save_obs= False
ap.companion = False
tp.diam=8.
tp.use_spiders = False
tp.use_atmos = False
tp.quick_ao=False
tp.use_ao = True
tp.ao_act = 50
tp.detector = 'ideal'
tp.NCPA_type = None#'Static'
tp.CPA_type = None
tp.aber_params = {'CPA':False,
                  'NCPA':True,
                  'QuasiStatic':False,#or 'Static'
                  'Phase':True,
                  'Amp':False,
                  'n_surfs':2}
mp.date = '180424/'
tp.active_null = True
iop.update(mp.date)
sp.num_processes = 1
tp.occulter_type = 'None'#'Gaussian'#
num_exp =100 #5000
ap.exposure_time = 0.001  # 0.001
ap.numframes = int(num_exp * ap.exposure_time / cp.frame_time)
tp.piston_error = False
tp.band = np.array([860, 1250])
tp.nwsamp = 1
tp.rot_rate = 0  # deg/s
lod = 8
# sp.num_processes = 5

# acts = [8,16,32,64]
#
# datacube=[]
# tp.use_ao = False
# if __name__ == '__main__': datacube.append(gpd.run()[0])
#
# tp.use_ao=True
# for act in acts:
#     tp.ao_act = act
#     if __name__ == '__main__': datacube.append(gpd.run()[0])
#
# datacube = np.array(datacube)
# view_datacube(datacube)

if __name__ == '__main__':
    obs_sequence = gpd.run_medis()