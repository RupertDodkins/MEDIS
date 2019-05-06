import os
import numpy as np
import matplotlib.pylab as plt
from decimal import Decimal
import astropy.io.fits as fits
import hcipy
from medis.Dashboard.twilight import sunlight
from medis.params import cp, ap, tp, iop
from medis.Utils.misc import dprint


def eformat(f, prec, exp_digits):
    s = "%.*e" % (prec, f)
    mantissa, exp = s.split('e')
    # add 1 to digits as 1 is taken by sign +/-
    return "%se%+0*d" % (mantissa, exp_digits + 1, int(exp))

def get_filename(it, wsamp):
    wave = eformat(wsamp, 3, 2)
    return f'{iop.atmosdir}/{cp.model}/telz_t{ap.sample_time*it:.3f}_w{wave}.fits'

def generate_maps(plot=False):
    dprint("Making New Atmosphere Model")

    if not os.path.isdir(os.path.join(iop.atmosdir, cp.model)):
        os.makedirs(os.path.join(iop.atmosdir, cp.model), exist_ok=True)

    pupil_grid = hcipy.make_pupil_grid(ap.grid_size, tp.diam)

    if cp.model == 'single':
        layers = [hcipy.InfiniteAtmosphericLayer(pupil_grid, cp.cn, cp.L0, cp.v, cp.h, 2)]
    elif cp.model == 'hcipy_standard':
        # Make multi-layer atmosphere
        layers = hcipy.make_standard_atmospheric_layers(pupil_grid, cp.outer_scale)
    elif cp.model == 'evolving':
        raise NotImplementedError

    atmos = hcipy.MultiLayerAtmosphere(layers, scintilation=False)

    # aperture = hcipy.circular_aperture(tp.diam)(pupil_grid)
    wsamples = np.linspace(ap.band[0], ap.band[1], ap.nwsamp) / 1e9

    wavefronts = []
    for wavelength in wsamples:
        wavefronts.append(hcipy.Wavefront(hcipy.Field(np.ones(pupil_grid.size), pupil_grid), wavelength))

    for it, t in enumerate(np.arange(0, ap.numframes*ap.sample_time, ap.sample_time)):
        print(t)

        atmos.evolve_until(t)
        for iw, wf in enumerate(wavefronts):
            wf2 = atmos.forward(wf)


            filename = get_filename(it, wsamples[iw])
            print(filename)
            hdu = fits.ImageHDU(wf2.phase.reshape(ap.grid_size, ap.grid_size))
            hdu.header['PIXSIZE'] = tp.diam/ap.grid_size
            hdu.writeto(filename, overwrite=True)

            if plot:
                plt.figure()
                hcipy.imshow_field(wf2.phase, cmap=sunlight)
                plt.colorbar()
                plt.show(block=True)