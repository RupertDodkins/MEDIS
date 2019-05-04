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

def get_filename(dir, samp, it, wsamp):
    wave = eformat(wsamp, 3, 2)
    return f'{dir}/telz_t{samp*it:.3f}_w{wave}.fits'

def generate_maps(plot=False):
    dprint("Making New Atmosphere Model")

    pupil_grid = hcipy.make_pupil_grid(ap.grid_size, tp.diam)

    # Make multi-layer atmosphere
    layers = hcipy.make_standard_atmospheric_layers(pupil_grid, cp.outer_scale)
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


            filename = get_filename(iop.atmosdir, ap.sample_time, it, wsamples[iw])
            print(filename)
            hdu = fits.ImageHDU(wf2.phase.reshape(ap.grid_size, ap.grid_size))
            hdu.header['PIXSIZE'] = tp.diam/ap.grid_size
            hdu.writeto(filename, overwrite=True)

            if plot:
                plt.figure()
                hcipy.imshow_field(wf2.phase, cmap=sunlight)
                plt.colorbar()
                plt.show(block=True)