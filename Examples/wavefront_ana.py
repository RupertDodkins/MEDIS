'''Apparently cannot communicate between queues on Windows. This may work on U(/Li)nux'''
import sys, os

sys.path.append('D:/dodkins/MEDIS/MEDIS')
import glob
import numpy as np
# np.set_printoptions(threshold=np.inf)
import cPickle as pickle
import multiprocessing
import time
from functools import partial
import matplotlib.pylab as plt
from medis.params import ap, cp, tp, mp, sp, iop
# import medis.Detector.analysis as ana
import medis.Detector.readout as read
import medis.Detector.pipeline as pipe
# import medis.Detector.temporal as temp
import medis.Detector.spectral as spec
from medis.Detector.distribution import gaussian, poisson, MR, gaussian2
from scipy.optimize import curve_fit
from medis.Utils.plot_tools import view_datacube, quicklook_im, loop_frames, add_subplot_axes, annotate_axis
import medis.Utils.misc as misc
import medis.Detector.get_photon_data as gpd
from medis.Utils.misc import dprint
import Examples.SSD_example as SSD
import medis.Analysis.stats as stats
import traceback
import itertools

# os.system("taskset -p 0xfffff %d" % os.getpid())
ap.star_photons = int(1e5)
ap.companion = True
ap.contrast = [0.01]#[0.1,0.1]
ap.lods = [[-2.5,2.5]]
ap.numframes = 2000
tp.detector = 'ideal'
sp.save_obs = True
# mp.date = '180406b/'
# iop.update('180406b/')
mp.date = '180421/'
iop.update(mp.date)
sp.show_cube = False
sp.return_cube = False
cp.vary_r0 = False
cp.r0s_idx  = -1
tp.use_atmos = True
tp.ao_act = 40
tp.use_ao = True  # True
tp.occulter_type = 'None'  #
# tp.occulter_type = '8TH_ORDER'  #
tp.NCPA_type = None
tp.CPA_type = None
tp.nwsamp = 1
tp.satelite_speck = False
tp.speck_peakIs = [0.05]#[0.01, 0.0025]
tp.speck_phases = [np.pi/2]#[np.pi / 2.,np.pi / 2.]
tp.speck_locs = [[64,30]]#[[50, 50], [100,100]]
tp.piston_error = True
cp.scalar_r0 = 'med'#'highest'#
if sp.show_wframe == 'continuous':
    sp.fig = plt.figure()
sp.num_processes = 8
iop.saveIQ = True

ints = np.empty(0)
times = np.empty(0)
max_photons = 5e7  # 5e7 appears to be the max Pool can handle irrespective of machine capability?
# ap.numframes=200
num_chunks = int(ap.star_photons * ap.numframes / max_photons)
if num_chunks < 1:
    num_chunks = 1
print num_chunks

mp.bin_time = 2e-3
num_ints = int(cp.frame_time * ap.numframes / mp.bin_time)

xlocs = range(0, 129)
ylocs = range(0, 129)

MEDIUM_SIZE = 17
plt.rc('font', size=MEDIUM_SIZE)  # controls default text sizes
from matplotlib import rcParams
rcParams['font.family'] = 'Times New Roman'
rcParams['mathtext.fontset'] = 'stix'
rcParams['mathtext.rm'] = 'Bitstream Vera Sans'
rcParams['mathtext.bf'] = 'Bitstream Vera Sans:bold'

# # preview mode
# sp.num_processes = 1
# tp.detector = 'ideal'
sp.show_wframe = False  # 'continuous'
# mp.date = 'placeholder/'
# mp.datadir = os.path.join(mp.rootdir, mp.data, mp.date)

# place in optics_propagate where you need it
# with open('wavefront50novaryaoacthigh.txt', 'a') as the_file:
#     complex_pix = wf.wfarr[50, 50]
#     the_file.write('%f, %f\n' % (np.real(complex_pix), np.imag(complex_pix)))

def just_core(x):
    fig, axes = plt.subplots(nrows=1, ncols=2, figsize=(10, 6))
    print np.shape(axes)
    complex = x[:, 0] + 1j * x[:, 1]
    axes[0].scatter(x[:, 0], x[:, 1], marker='.', alpha=0.25)
    axes[0].axis('equal')
    axes[0].tick_params(direction='in', which='both', right=True, top=True)
    axes[0].set_xlabel(r'$\operatorname{\mathbb{R}e}\{\Psi_2(r)\}$')
    axes[0].set_ylabel(r'$\operatorname{\mathbb{I}m}\{\Psi_2(r)\}$')

    hist, bins = np.histogram(np.abs(complex), bins=15)
    bins = bins[:-1]
    barwidth = (bins[-1] - bins[0]) / len(bins)
    print bins.shape, hist.shape, barwidth
    print bins, hist
    axes[1].bar(bins,hist, width=barwidth, edgecolor='k', facecolor='lightgrey')

    # axes[1].hist(np.abs(complex), bins=15)

    axes[1].set_xlabel(r'$|\Psi_2(r)|^2$')
    axes[1].tick_params(direction='in', which='both', right=True, top=True)
    labels = ['a', 'b']
    i = 0
    for ix in range(axes.shape[0]):
        axes[ix].text(0.05, 0.9, labels[i], transform=axes[ix].transAxes, fontweight='bold', color='k',
                              fontsize=22,
                              family='serif')
        i += 1
    plt.subplots_adjust(left=0.11, right=0.99, top=0.98, bottom=0.14, wspace=0.2)
    plt.show()

def just_speck(x):
    fig, axes = plt.subplots(nrows=1, ncols=2, figsize=(10, 6))
    print np.shape(axes)
    complex = x[:, 2] + 1j * x[:, 3]
    axes[0].scatter(x[:, 2], x[:, 3], marker='.', alpha=0.25)
    axes[0].axis('equal')
    axes[0].tick_params(direction='in', which='both', right=True, top=True)
    axes[0].set_xlabel(r'$\operatorname{\mathbb{R}e}\{\Psi_2(r)\}$')
    axes[0].set_ylabel(r'$\operatorname{\mathbb{I}m}\{\Psi_2(r)\}$')

    hist, bins = np.histogram(np.abs(complex), bins=15)
    bins = bins[:-1]
    barwidth = (bins[-1] - bins[0]) / len(bins)
    print bins.shape, hist.shape, barwidth
    print bins, hist
    axes[1].bar(bins,hist, width=barwidth, edgecolor='k', facecolor='lightgrey')

    # axes[1].hist(np.abs(complex), bins=15)

    axes[1].set_xlabel(r'$|\Psi_2(r)|^2$')
    axes[1].tick_params(direction='in', which='both', right=True, top=True)
    labels = ['a', 'b']
    i = 0
    for ix in range(axes.shape[0]):
        axes[ix].text(0.05, 0.9, labels[i], transform=axes[ix].transAxes, fontweight='bold', color='k',
                              fontsize=22,
                              family='serif')
        i += 1
    plt.subplots_adjust(left=0.11, right=0.99, top=0.98, bottom=0.14, wspace=0.2)
    plt.show()

def make_figure(x):
    fig, axes = plt.subplots(nrows=2, ncols=2, figsize=(10, 10))
    print np.shape(axes)
    complex = x[:, 2] + 1j * x[:, 3]
    axes[0,0].scatter(x[:, 2], x[:, 3], marker='.', alpha=0.25)
    axes[0, 0].axis('equal')
    axes[0,1].hist(np.abs(complex), bins=15)

    complex = x[:,0] + 1j*x[:,1]
    axes[1,0].scatter(x[:, 0], x[:, 1], marker='.', alpha=0.25)
    axes[1, 0].axis('equal')
    axes[1,1].hist(np.abs(complex), bins=15)


    labels = ['a', 'b', 'c', 'd']
    i = 0
    for ix in range(axes.shape[0]):
        for iy in range(axes.shape[1]):
            axes[ix,iy].text(0.05, 0.9, labels[i], transform=axes[ix,iy].transAxes, fontweight='bold', color='k', fontsize=22,
                    family='serif')
            i+=1
    # plt.subplots_adjust(left=0.01, right=0.92, top=0.99, bottom=0.01, wspace=0.12)
    plt.show()

if __name__ == '__main__':

    # if not os.path.isfile(mp.datadir + mp.obsfile):
    # hypercube = gpd.take_obs_data()
    x = np.loadtxt(iop.IQpixel, delimiter=',')
    # x = x*4
    # just_speck(x)
    # just_core(x)
    make_figure(x)
    # print np.shape(x)
    # complex = x[:,0] + 1j*x[:,1]
    # plt.scatter(x[:,0], x[:,1], marker='.', alpha=0.25)
    # plt.show()
    # plt.hist(np.abs(complex), bins=15)
    # plt.show()
    #
    # complex = x[:,2] + 1j*x[:,3]
    # plt.scatter(x[:,2], x[:,3], marker='.', alpha=0.25)
    # plt.show()
    # plt.hist(np.abs(complex), bins=15)
    # plt.show()
    #
    #
    # def compare_images(datacube, logAmp=False, axis=None, width=None, titles=None, annos=None):
    #     '''Like view_datacube by colorbar on the right and apply annotations'''
    #     '''axis = anno/None/True'''
    #     if not width:
    #         width = len(datacube)
    #     # fig =plt.figure(figsize=(14,7))
    #
    #     fig, axes = plt.subplots(nrows=1, ncols=width, figsize=(14, 3.4))
    #     # maps = len(datacube)
    #     # print maps, width
    #
    #     norm = np.sum(datacube[0])
    #     datacube = datacube / norm
    #
    #     peaks, troughs = [], []
    #     for image in datacube:
    #         peaks.append(np.max(image))
    #         troughs.append(np.min(image))
    #
    #     print troughs, peaks
    #
    #     vmin = np.min(troughs) * 1e2
    #     print vmin
    #     if vmin <= 0:
    #         troughs = np.array(troughs)
    #         vmin = min(troughs[troughs > 0]) * 5e2
    #     print 'new', vmin
    #     vmax = np.max(peaks)
    #     print vmax
    #     # if vmax <= 0: vmax = np.abs(vmax) + 1e-20
    #     labels = ['a', 'b', 'c', 'd']
    #     for m, ax in enumerate(axes):
    #         # ax = fig.add_subplot(1,width,m+1)
    #         # axes.append(ax)
    #         if logAmp:
    #             print 'yes', np.min(datacube[m])
    #             if np.min(datacube[m]) <= 0:
    #                 datacube[m] = np.abs(datacube[m]) + 1e-20
    #                 print 'yes', np.min(datacube[m])
    #             im = ax.imshow(datacube[m], interpolation='none', origin='lower', vmin=vmin, vmax=vmax, norm=LogNorm(),
    #                            cmap="magma")
    #         else:
    #             im = ax.imshow(datacube[m], interpolation='none', origin='lower', vmin=vmin, vmax=vmax, cmap="magma")
    #         if titles:
    #             ax.set_title(titles[m])
    #         if annos:
    #             ax.text(0.05, 0.05, annos[m], transform=ax.transAxes, fontweight='bold', color='w', fontsize=22)
    #         if axis == 'anno':
    #             annotate_axis(im, ax, datacube.shape[1])
    #         if axis == None:
    #             ax.axis('off')
    #         # ax.arrow(97, 47.5, -10, 0, head_width=5, head_length=3, fc='w', ec='w')
    #         # ax.grid(color='w', linestyle='--')
    #         ax.text(0.05, 0.9, labels[m], transform=ax.transAxes, fontweight='bold', color='w', fontsize=22,
    #                 family='serif')
    #
    #     # fig.subplots_adjust(bottom=0.1)
    #     cax = fig.add_axes([0.94, 0.065, 0.01, 0.87])
    #     # from matplotlib import colorbar
    #     # cax, kw = colorbar.make_axes([ax for ax in axes.flat])
    #     fig.colorbar(im, cax=cax, orientation='vertical')
    #     # plt.tight_layout(rect=[0.04,0.11,0.92,0.88])
    #     plt.subplots_adjust(left=0.01, right=0.92, top=0.99, bottom=0.01, wspace=0.12)
    #     plt.show()
