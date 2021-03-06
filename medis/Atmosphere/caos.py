#!/usr/bin/env python
import os
# import pidly
import numpy as np
import matplotlib.pyplot as plt
# import pyfits
# import astropy.io.fits as pyfits
import glob

from medis.params import cp, tp, iop
import medis.Utils.rawImageIO as rawImageIO
import medis.Utils.misc as misc
from medis.Detector.distribution import lognorm, Distribution


def make_idl_params():
    print('Making IDL params csv')
    with open(cp.idl_params, 'wb') as csvfile:
        line = '%i,%s,%s,%s' % (cp.numframes, iop.atmosdir, cp.show_caosparams, cp.r0_identifier)
        csvfile.write(line)


def load_maps(location):
    filenames = rawImageIO.read_folder(location)
    # print filenames

    input_shape = np.shape(rawImageIO.read_image(filenames[0]))  # hopefully all files are the same size!
    atmos_maps = np.zeros((len(filenames), input_shape[0], input_shape[1]))

    for ifn, filename in enumerate(filenames):
        # cube = rawImageIO.datacube()
        atmos_maps[ifn] = rawImageIO.read_image(filename)

    return atmos_maps


def gen_maps_r0():
    x = np.linspace(0.1, 2.5, 1000)
    mu, sigma = 0.1, 0.4
    r0 = lognorm(x, mu, sigma)
    # plt.plot(x, r0)
    dist = Distribution(lognorm(x, mu, sigma), interpolation=True)
    R0s = (dist(10)[0] * 0.5 / float(len(x)))
    print(R0s)
    # plt.plot(np.histogram(R0s)[1][:-1], np.histogram(R0s)[0])
    # plt.show()
    # TODO Fix hard-coded path, maybe add setting in params.py
    dprint('If you get to here, there is some hard-coded stuff Rupert probably needs to fix')
    fullfilename = '/Data/PythonProjects/MEDIS/caos_pse/work_caos/Projects/ATMOS_test/atm_00001.sav'
    cp.numframes = 10000
    cp.show_caosparams = False  # for control over all other variables
    for R0 in R0s:
        idl = pidly.IDL('/Local/bin/idl')
        idl("RESTORE, '%s'" % fullfilename)
        # idl("print, par")
        idl("par.r0 = '%s'" % R0)
        # idl("print, par")
        idl("SAVE, /VARIABLES, FILENAME = '%s'" % fullfilename)
        print(R0)
        cp.r0_identifier = R0
        make_idl_params()
        idl.pro(cp.script)
        idl.close()
        scale_phasemaps()

def random_r0walk(idx, values):
    if idx > 0 and idx < len(values) -1:
        move = int(np.random.random()*3)-1
    elif idx == 0:
        move = int(np.random.random()*2)
    else:
        move = int(np.random.random()*2)-1
    print(move)
    idx += move
    return idx

def get_r0s():
    startframes = glob.glob(iop.atmosdir + '/telz0.000000_*.fits')
    r0s = []
    for frame in startframes:
        r0s.append(float(frame[-10:-5]))
    r0s = np.sort(r0s)
    cp.r0s = r0s
    if cp.scalar_r0 == 'med':
        cp.r0s_idx = int(len(r0s)/2)



def generate_maps():
    dprint('If "generate_maps" fails, make sure you have run caos_env.sh first')
    idl = pidly.IDL('/Local/bin/idl')
    idl.pro(cp.script)
    dprint('Generated maps using CAOS')
    # scale_phasemaps()
    # filename = '/Data/PythonProjects/MEDIS/data/atmos/180208/telz0.fits'
    # scidata, hdr = rawImageIO.read_image(filename, prob_map=False)
    # scidata = rawImageIO.resize_image(scidata, (4000,4000))
    # pyfits.update(filename, scidata, hdr,0)
    # rawImageIO.scale_phasemaps()


def scale_phasemaps():
    # filenames = rawImageIO.read_folder(iop.atmosdir)
    import multiprocessing
    filenames = glob.glob(iop.atmosdir + '*0.067*')
    scidata, hdr = rawImageIO.read_image(filenames[0], prob_map=False)
    scalefactor = 5.19751 #np.pi * 1e-6 / np.max(np.abs(scidata))  # *0.8 * 4./3 #kludge for now until you include AO etc
    # print filenames
    # # print 'Stretching the phase maps to size (%i,%i)' % (size,size)
    dprint('Scaling the phase maps by a factor %s' % scalefactor)
    p = multiprocessing.Pool(10)
    for ifn, filename in enumerate(filenames):
        if ifn % 10 == 0: misc.progressBar(value=ifn, endvalue=len(filenames))
        # scidata, hdr = rawImageIO.read_image(filename, prob_map=False)
        # scidata = rawImageIO.resize_image(scidata, (size,size), warn=False)
        # pyfits.update(filename, scidata, hdr,0)

        # rawImageIO.scale_image(filename, scalefactor)
        p.apply_async(rawImageIO.scale_image, (filename, scalefactor))
    p.close()
    p.join()

def plot_phasemaps():
    atmosdir = os.path.join(cp.rootdir, cp.data, '180422/')
    # import pyfits
    # fits = pyfits.open(fname)
    # hypercube[w, t, :, :] = fits[0].data
    filenames= rawImageIO.read_folder(atmosdir)
    cube = []
    import medis.Analysis.phot
    for filename in filenames:
        phase = rawImageIO.read_image(filename, prob_map=False)[0]
        ap.grid_size=80
        phase = phase*Analysis.phot.aperture(ap.grid_size/2,ap.grid_size/2,ap.grid_size/2)
        cube.append(phase)
    from medis.Utils.plot_tools import compare_images, view_datacube,indep_images, quicklook_im
    # indep_images(cube, titles=['$\phi$']*3)
    # quicklook_im(cube[0], logAmp=False)
    # cube = np.array(cube)/(2*np.pi*1000*10**-9)
    cube = np.array(cube)/(10**-6)

    # compare_phasemaps(cube, title='$\phi$ (radians)')
    compare_phasemaps(cube, title='$\delta$ ($\mu$m)')


def compare_phasemaps(datacube, logAmp=False, axis=None, width=None, title=None, annos=None, scale=1):
    MEDIUM_SIZE = 14
    plt.rc('font', size=MEDIUM_SIZE)  # controls default text sizes
    '''Like view_datacube by colorbar on the right and apply annotations'''
    '''axis = anno/None/True'''
    if not width:
        width = len(datacube)
    if title == None:
        title = r'  $I / I^{*}$'
    # fig =plt.figure(figsize=(14,7))

    if width == 4 or width != 2:
        fig, axes = plt.subplots(nrows=1, ncols=width,figsize=(14,3.4))
    elif width == 2:
        fig, axes = plt.subplots(nrows=1, ncols=width,figsize=(7,3.1))
    # maps = len(datacube)
    # print maps, width

    # norm = np.sum(datacube[0])
    # datacube = datacube/norm

    peaks, troughs = [], []
    for image in datacube:
        peaks.append(np.max(image))
        troughs.append(np.min(image))

    print(troughs, peaks)
    print(scale, 'scale')
    vmin = np.min(troughs)
    # print vmin
    # if vmin<=0:
    #     troughs = np.array(troughs)
    #     vmin = min(troughs[troughs>0])
    # vmin *= scale
    print('new', vmin)
    vmax = np.max(peaks)
    print(vmin, vmax)
    # if vmax <= 0: vmax = np.abs(vmax) + 1e-20
    labels = ['a','b','c','d','e']
    for m, ax in enumerate(axes):
        # ax = fig.add_subplot(1,width,m+1)
        # axes.append(ax)
        if logAmp:
            print('yes', np.min(datacube[m]))
            if np.min(datacube[m]) <= 0:
                datacube[m] = np.abs(datacube[m]) + 1e-20
                print('yes', np.min(datacube[m]))
            im = ax.imshow(datacube[m], interpolation='none', origin='lower', vmin= vmin, vmax = vmax, norm= LogNorm(), cmap="YlGnBu_r")
        else:
            im = ax.imshow(datacube[m], interpolation='none', origin='lower', vmin= vmin, vmax = vmax, cmap="jet")
        if annos:
            ax.text(0.05, 0.05, annos[m],transform=ax.transAxes, fontweight='bold', color='w', fontsize=22)
        ax.set_xticks(np.linspace(-0.5, 80 - 0.5, 5))  # -0.5
        ax.set_yticks(np.linspace(-0.5, 80 - 0.5, 5))  # -0.5
        ticks = np.linspace(0, 8, 5)
        ticklabels = ["{:0.1f}".format(i) for i in ticks]
        ax.set_xticklabels(ticklabels)
        ax.set_yticklabels(ticklabels)
        ax.set_xlabel('x (m)')
        ax.set_ylabel('y (m)')
        # ax.arrow(97, 47.5, -10, 0, head_width=5, head_length=3, fc='w', ec='w')
        # ax.grid(color='w', linestyle='--')
        ax.text(0.05, 0.9, labels[m], transform=ax.transAxes, fontweight='bold', color='k', fontsize=22, family='serif')
    # axes[0].text(0.84, 0.9, '0.2"', transform=axes[0].transAxes, fontweight='bold', color='w', ha='center', fontsize=14, family='serif')
    # axes[0].plot([0.78, 0.9], [0.87, 0.87],transform=axes[0].transAxes, color='w', linestyle='-', linewidth=3)

    print(width)
    if width == 3:
        cax = fig.add_axes([0.9, 0.17, 0.015, 0.72])
    elif width ==2:
        cax = fig.add_axes([0.84, 0.01, 0.02, 0.89])
    else:
        cax = fig.add_axes([0.94, 0.01, 0.01, 0.87])
    cb = fig.colorbar(im, cax=cax, orientation='vertical')
    # cb = fig.colorbar(im, cax=cax, orientation='vertical', format=ticker.FuncFormatter(fmt))
    cb.ax.set_title(title, fontsize=16)#

    if width != 2:
        plt.subplots_adjust(left=0.01, right=0.92, top=0.9, bottom=0.17, wspace=0.12)
    elif width == 2:
        plt.subplots_adjust(left=0.01, right=0.82, top=0.9, bottom=0.01, wspace=0.05)
    plt.show()

if __name__ == '__main__':
    # gen_maps_r0()
    # get_R0_dist()
    # scale_phasemaps()
    plot_phasemaps()