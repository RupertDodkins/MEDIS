import numpy as np
# import matplotlib.pylab as plt
import proper
# from medis.Utils.plot_tools import quicklook_im, quicklook_wf, loop_frames,quicklook_IQ
from medis.params import tp, cp, mp, ap,iop#, fp
# from medis.Utils.misc import dprint
import medis.Atmosphere.atmos as atmos


def offset_companion(wf_array, it):
    cont_scaling = np.linspace(1./ap.C_spec, 1, ap.nwsamp)
    shape = wf_array.shape
    for iw in range(shape[0]):
        atmos_map = atmos.get_filename(iop.atmosdir, ap.sample_time, it, wf_array[iw, 0].lamda)
        for io in range(shape[1]):

            xloc = ap.lods[io][0]
            yloc = ap.lods[io][1]

            if tp.rot_rate:
                time = float(atmos_map[-19:-11])
                rotate_angle = tp.rot_rate * time
                rotate_angle = np.pi * rotate_angle/180.
                rot_matrix = [[np.cos(rotate_angle),-np.sin(rotate_angle)],[np.sin(rotate_angle),np.cos(rotate_angle)]]
                xloc, yloc = np.matmul(rot_matrix,[xloc,yloc])

            proper.prop_zernikes(wf_array[iw,io], [2, 3], np.array([xloc,yloc])*1e-6)
            if io == shape[1]-1:
                cont_scaling = np.ones_like(cont_scaling)
            wf_array[iw, io].wfarr = wf_array[iw,io].wfarr * np.sqrt(ap.contrast[io]*cont_scaling[iw])


def add_obscurations(wf, M2_frac=0, d_primary=0, d_secondary=0, legs_frac=0.05):
    """
    adds central obscuration (secondary shadow) and/or spider legs as spatial mask to the wavefront
    :param wf: proper wavefront
    :param M2_frac: ratio of tp.diam the M2 occupies
    :param d_primary: diameter of the primary mirror
    :param d_secondary: diameter of the secondary mirror
    :param legs_frac: fractional size of spider legs relative to d_primary
    :return: acts upon wfo, applies a spatial mask of s=circular secondary obscuration and possibly spider legs
    """
    # dprint('Including Obscurations')
    if M2_frac > 0 and d_primary>0:
        proper.prop_circular_obscuration(wf, M2_frac * d_primary)
    elif d_secondary > 0:
        proper.prop_circular_aperture(wf, d_secondary)
    else:
        raise ValueError('must either specify M2_frac and d_primary or d_secondary')
    if legs_frac > 0:
        proper.prop_rectangular_obscuration(wf, legs_frac * d_primary, d_primary*1.3, ROTATION=20)
        proper.prop_rectangular_obscuration(wf, d_primary*1.3, legs_frac * d_primary, ROTATION=20)


def add_hex(wfo):
    # TODO implement this
    dprint('Including Mirror Segments')
    dprint('** add code here **')
    raise NotImplementedError


def prop_mid_optics(wfo, f_lens, dist):
    proper.prop_lens(wfo, f_lens)
    proper.prop_propagate(wfo, dist)


def do_apod(wfo, grid_size, beam_ratio, apod_gaus):
    # dprint 'Including Apodization'
    r = proper.prop_radius(wfo)
    rad = int(np.round(grid_size*(1-beam_ratio)/2)) # beam is a fraction (0.3) of the grid size
    r = r/r[grid_size/2,rad]
    w = apod_gaus
    gauss_spot=np.exp(-(r/w)**2)
    proper.prop_multiply(wfo, gauss_spot)