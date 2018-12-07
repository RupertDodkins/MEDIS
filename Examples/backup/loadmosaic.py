import os
import numpy as np
import matplotlib.pyplot as plt
import pickle

cpfn = "mypkl-cubes.pkl"
if os.path.isfile(cpfn):
    print "loadMosaicCube:  load from ", cpfn
    cube = pickle.load(open(cpfn, 'rb'))

for i in range(31):
    vmax = np.max(np.sqrt(cube[:, :, i]))
    # print wvlBins[i]
    plt.imshow(np.sqrt(cube[:, :, i]), cmap='coolwarm', origin='lower', vmax=0.4 * vmax)  # , norm=LogNorm())#,

    plt.show()