import sys
sys.path.append('D:/dodkins/MEDIS/MEDIS')
from params import tp, mp, cp,sp
from get_photon_data import run
from Utils.plot_tools import view_datacube
import numpy as np
import matplotlib.pyplot as plt

tp.detector = 'ideal'#
tp.show_wframe = False
cp.numframes = 1
mp.frame_time = 0.1
num_frames = [1,10,100]
tp.use_ao=True
tp.occulter_type ='GAUSSIAN'
cp.vary_r0 = False # turn off the automatic variation
sp.show_wframe = False
if sp.show_wframe == 'continuous':
    sp.fig = plt.figure()

if __name__ == '__main__':
    datacube=[]
    for nf in num_frames:
        # image = np.zeros((tp.grid_size,tp.grid_size))
        # for f in range(nf):
            # image += run()[0]
        cp.numframes = nf
        hypercube = run()
        # hypercube = np.array(hypercube)
        image = np.sum(hypercube,axis=0)/nf
        datacube.append(image[0])

    datacube = np.array(datacube)
    view_datacube(datacube)
