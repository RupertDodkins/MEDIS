import pickle
import matplotlib.pylab as plt
import numpy as np

savefile = 'acc_temp.pkl'

with open(savefile, 'rb') as handle:
    cur_seg, pred_seg_res = pickle.load(handle)

plt.imshow(cur_seg, aspect='auto')
plt.figure()
plt.imshow(pred_seg_res, aspect='auto')
plt.figure()
plt.imshow(pred_seg_res - cur_seg, aspect='auto')
plt.show(block=True)