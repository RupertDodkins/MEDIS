import numpy as np
# import matplotlib.pylab as plt
import proper
# from medis.Utils.plot_tools import quicklook_im, quicklook_wf, loop_frames,quicklook_IQ
from medis.params import tp, cp, mp, ap,iop#, fp
# from medis.Utils.misc import dprint


def offset_companion(wf_array, atmos_map):
    cont_scaling = np.linspace(1./ap.C_spec, 1, ap.nwsamp)
    shape = wf_array.shape
    for iw in range(shape[0]):
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


def add_obscurations(wfo, diam, legs=True):
    # print('Including Obscurations')
    proper.prop_circular_obscuration(wfo, diam/2)
    if legs:
        proper.prop_rectangular_obscuration(wfo, 0.05*diam, diam*1.3, ROTATION=20)
        proper.prop_rectangular_obscuration(wfo, diam*1.3, 0.05*diam, ROTATION=20)

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