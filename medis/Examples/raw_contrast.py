'''Takes a exposure with and without the coronagraph and creates contrast curve'''

import sys, os
sys.path.append('/Data/PythonProjects/MEDIS/MEDIS')
sys.path.append('/Data/PythonProjects/MEDIS/MEDIS/Telescope')
import glob

import proper
import numpy as np
np.set_printoptions(threshold=np.inf)

import matplotlib.pylab as plt
import Utils.colormaps as cmaps
plt.register_cmap(name='viridis', cmap=cmaps.viridis)
plt.register_cmap(name='plasma', cmap=cmaps.plasma)

from params import ap,cp,tp,mp
import Detector.analysis as ana
import Detector.MKIDs as MKIDs
import Telescope.run_system as run_system 

# tp.nwsamp = 1
tp.occulter_type =None# None#
# tp.use_prim_ab = True                                                                                                                  

if tp.detector == 'MKIDs':
    MKIDs.initialize()

#code to run CAOS
if tp.use_atmos and glob.glob(cp.atmosdir+'*.fits') == []:
    import Atmosphere.caos as caos #import here since pidly can stay open sometimes and that's annoying
    caos.make_idl_params()
    caos.generate_maps()

# hypercube = []
for t in range(1):
    print 'propagating frame:', t
    kwargs = {'iter':t, 'atmos_map': cp.atmosdir+'telz%f.fits' % (t*mp.frame_time)}
    no_occult = proper.prop_run("run_system", 1, tp.grid_size, PASSVALUE=kwargs, VERBOSE = False, PHASE_OFFSET = 1 )[0][0]

tp.occult_loc = (4,-6) #opposit sense to normal x y direction
tp.occulter_type ='GAUSSIAN'# None#

for t in range(1):
    print 'propagating frame:', t
    kwargs = {'iter':t, 'atmos_map': cp.atmosdir+'telz%f.fits' % (t*mp.frame_time)}
    occult = proper.prop_run("run_system", 1, tp.grid_size, PASSVALUE=kwargs, VERBOSE = False, PHASE_OFFSET = 1 )[0][0]

print np.shape(no_occult)
plt.imshow(no_occult,cmap="Blues_r")
plt.figure()
plt.imshow(occult,cmap="Blues_r")
plt.show()

# norm = np.max(no_occult)#[tp.grid_size/2,tp.grid_size/2]
# no_occult = no_occult/norm
# occult = occult/norm

images = [no_occult, occult]
labels = ['Unocculted PSF Profile', 'Coronagraphic PSF Profile']
ana.make_cont_plot(images, labels)


