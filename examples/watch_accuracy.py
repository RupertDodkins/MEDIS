import pickle
import matplotlib.pylab as plt
from mpl_toolkits.mplot3d import Axes3D
from matplotlib.colors import LogNorm
import numpy as np
from medis.params import iop, ap

num_epoch = 32
iop.datadir = '/mnt/data0/dodkins/medis_save'
# iop.update()
iop.update("AIPD/")

with open(iop.ml_meta, 'rb') as handle:
    alldata = [pickle.load(handle) for i in range(num_epoch)]

# print(alldata.shape, alldata.T.shape)
cur_seg, pred_seg_res, cur_data = alldata[0]
print(cur_data.shape)

# for ground, pred in zip(cur_seg[num_epoch-1:], pred_seg_res[num_epoch-1:]):
for cur_seg, pred_seg_res, cur_data in alldata[-1:]:
    plt.figure()
    plt.imshow(cur_seg, aspect='auto')
    plt.figure()
    plt.imshow(pred_seg_res, aspect='auto')
    plt.figure()
    plt.imshow(pred_seg_res - cur_seg, aspect='auto')



    colors = ['green','orange','purple','blue',]

    true_neg = np.logical_and(cur_seg==0, pred_seg_res==0)
    true_pos = np.logical_and(cur_seg==1, pred_seg_res==1)
    false_neg = np.logical_and(cur_seg==1, pred_seg_res==0)
    false_pos = np.logical_and(cur_seg==0, pred_seg_res==1)

    scores = np.array([np.sum(true_pos), np.sum(false_pos)])/np.sum(cur_seg==1)
    print(scores)
    scores = np.array([np.sum(true_neg), np.sum(false_neg)])/np.sum(cur_seg==0)
    print(scores)
    # metrics = [true_pos, false_neg, false_pos, true_neg]
    metrics = [true_pos, false_neg, false_pos]
    fig = plt.figure(figsize=(12, 9))
    ax = fig.add_subplot(111, projection='3d')
    for metric, c in zip(metrics, colors[:len(metrics)]):
        red_data = cur_data[metric]
        ax.scatter(red_data[:,0], red_data[:,1], red_data[:,2], c=c, marker='o', s=2)  # , marker=pids[0])
    ax.view_init(elev=10., azim=-10)

    fig.tight_layout()

    plt.figure()
    H, _, _ = np.histogram2d(cur_data[:,:,1].flatten(),cur_data[:,:,2].flatten(),bins=[range(ap.grid_size), range(ap.grid_size)])
    plt.imshow(H, norm=LogNorm())

    plt.figure()
    positives = cur_data[pred_seg_res==1]
    H, _, _ = np.histogram2d(positives[:,1],positives[:,2],bins=[range(ap.grid_size), range(ap.grid_size)])
    plt.imshow(H, norm=LogNorm())

plt.show(block=True)