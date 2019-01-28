import sys, os
sys.path.append('D:/dodkins/MEDIS/MEDIS')
import numpy as np
import matplotlib.pylab as plt
from medis.params import ap,cp,tp,mp
# import medis.Detector.readout as read
import medis.Detector.pipeline as pipe
# import medis.Detector.temporal as temp
from medis.Utils.plot_tools import view_datacube, quicklook_im, loop_frames
import cPickle as pickle

framesFile = 'backup/frames.pkl'
if os.path.isfile(framesFile):
    with open(framesFile, 'rb') as handle:
        frames =pickle.load(handle)
else:
    frames=[]
    max_photons=1e6
    for i in range(10):
        start = i*max_photons
        print start, start+max_photons
        packets = pipe.read_obs(max_photons=max_photons,start=start)

        image = pipe.make_intensity_map_packets(packets)
        # quicklook_im(image)
        frames.append(image)  
    frames = np.array(frames)
    with open(framesFile, 'wb') as handle:
        pickle.dump(frames, handle, protocol=pickle.HIGHEST_PROTOCOL)  

loop_frames(frames)
