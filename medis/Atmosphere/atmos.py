import os
import numpy as np
import matplotlib.pylab as plt
from decimal import Decimal
import astropy.io.fits as fits
import hcipy
import proper
from medis.Dashboard.twilight import sunlight
from medis.params import cp, ap, tp, iop, sp
from medis.Utils.misc import dprint, eformat
# from medis.Utils.plot_tools import quicklook_wf, quicklook_im
import medis.Utils.rawImageIO as rawImageIO
from skimage.restoration import unwrap_phase

def get_filename(it):
    # wave = eformat(wsamp, 3, 2)
    return f'{iop.atmosdir}/telz_t{ap.sample_time*it:.5f}.fits'

def prepare_maps():
    """
    Wrapper for generate maps that takes backups if neccessary

    Returns
    -------
    A series of phase maps with time and wavelength

    """
    if not os.path.exists(iop.atmosdir):
        generate_maps()
    elif not os.path.exists(iop.atmosconfig):
        backup_old_maps()
        generate_maps()
    elif not compare_configs():
        backup_old_maps()
        generate_maps()

def backup_old_maps():
    """
    Copy and rename the dir containing the maps
    Returns
    -------

    """
    from datetime import datetime
    now = datetime.now().strftime("%m:%d:%Y_%H-%M-%S")
    os.rename(iop.atmosdir, iop.atmosdir + '_backup_' + now)

def compare_configs():
    """
    Compare a text file of the relevant atmosphere parameters to a previously made one

    Returns
    -------
    False if anything is awry
    """
    try:
        old_config = np.genfromtxt(iop.atmosconfig, delimiter=',', dtype=None, encoding='ASCII')
        this_config = [ap.sample_time, ap.grid_size, ap.w_bins, ap.numframes, cp.cn, cp.L0, cp.h, cp.v, cp.model]
        floats = (np.float_(old_config[:-2]) == np.float_(this_config[:-2])).all()
        arrays = np.float_(old_config[-2]) == np.float_(this_config[-2])
        strings = old_config[-1] == this_config[-1]
        match = np.array([floats, arrays, strings]).all()
    except Exception as e:
        if sp.verbose: print(e)
        match = False
    return match

def generate_maps(plot=False):
    dprint("Making New Atmosphere Model")

    if not os.path.isdir(os.path.join(iop.atmosdir)):
        os.makedirs(os.path.join(iop.atmosdir), exist_ok=True)

    wsamples = np.linspace(ap.band[0], ap.band[1], ap.nwsamp) / 1e9

    if cp.model == 'zernike':
        beam_ratios = np.zeros_like((wsamples))
        for iw, w in enumerate(wsamples[:1]):
            beam_ratios[iw] = tp.beam_ratio * ap.band[0] / w * 1e-9
            wf = proper.prop_begin(tp.diam, w, ap.grid_size, beam_ratios[iw])

            for t, a in zip(np.arange(0, ap.numframes),
                            np.arange(0, ap.numframes*np.pi/512., np.pi/512.)):
                xloc = np.sin(a)
                yloc = np.cos(a)
                proper.prop_zernikes(wf, [2, 3], np.array([xloc, yloc]) * 1e-7)
                filename = get_filename(t, wsamples[iw])
                hdu = fits.ImageHDU(proper.prop_get_phase(wf))
                hdu.header['PIXSIZE'] = tp.diam / ap.grid_size
                hdu.writeto(filename, overwrite=True)
        return

    if cp.model == 'sine':
        for t in np.arange(0, ap.numframes):
            screen = np.ones((ap.grid_size, ap.grid_size)) * np.pi * np.sin(
            np.arange(t * np.pi / 512., t * np.pi / 512. + ap.grid_size * np.pi / 2., np.pi / 2.))[:128]
            # plt.plot(np.sin(np.arange(t * np.pi / 64., t * np.pi / 64. + ap.grid_size * np.pi / 16., np.pi / 16.))[:128])
            # # quicklook_im(screen)
            # plt.show()
        # proper.prop_add_phase(wf, screen)

            filename = get_filename(t, wsamples[0])
            hdu = fits.ImageHDU(screen)
            hdu.header['PIXSIZE'] = tp.diam / ap.grid_size
            hdu.writeto(filename, overwrite=True)
        return

    pupil_grid = hcipy.make_pupil_grid(ap.grid_size, tp.diam)

    if cp.model == 'single':
        # cn = hcipy.Cn_squared_from_fried_parameter(cp.r0, 1000e-9)
        layers = [hcipy.InfiniteAtmosphericLayer(pupil_grid, cp.cn, cp.L0, cp.v, cp.h, 2)]
    elif cp.model == 'multiple':
        layers = []
        cp.cn = 0.2 * 1e-12
        layers.append(hcipy.InfiniteAtmosphericLayer(pupil_grid, cp.cn, cp.L0, 10, cp.h, 2))
        layers.append(hcipy.InfiniteAtmosphericLayer(pupil_grid, cp.cn, cp.L0, -10, 1000, 2))
    elif cp.model == 'hcipy_standard':
        # Make multi-layer atmosphere
        layers = hcipy.make_standard_atmospheric_layers(pupil_grid, cp.outer_scale)
    elif cp.model == 'evolving':
        raise NotImplementedError

    atmos = hcipy.MultiLayerAtmosphere(layers, scintilation=False)

    # aperture = hcipy.circular_aperture(tp.diam)(pupil_grid)

    wf = hcipy.Wavefront(hcipy.Field(np.ones(pupil_grid.size), pupil_grid), wsamples[0])

    np.savetxt(iop.atmosconfig, [ap.sample_time, ap.grid_size, ap.w_bins, ap.numframes, cp.cn, cp.L0, cp.h, cp.v, cp.model], fmt='%s')

    for it, t in enumerate(np.arange(0, ap.numframes*ap.sample_time, ap.sample_time)):
        atmos.evolve_until(t)
        wf2 = atmos.forward(wf)

        filename = get_filename(it)
        if sp.verbose: print(f'saving {filename}')

        obj_map = wf2.phase.reshape(ap.grid_size, ap.grid_size)

        obj_map = unwrap_phase(obj_map) * wsamples[0]/(2*np.pi)

        hdu = fits.ImageHDU(obj_map)
        hdu.header['PIXSIZE'] = tp.diam/ap.grid_size
        hdu.writeto(filename, overwrite=True)

        if plot:
            plt.figure()
            hcipy.imshow_field(wf2.phase, cmap=sunlight)
            plt.colorbar()
            plt.show(block=True)

        plt.show()
