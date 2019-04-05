from proper_mod import prop_run
import proper
import numpy as np
from medis.Utils.plot_tools import quicklook_wf, quicklook_im



def prescription_gui(wavelength, gridsize):
    selec_E_fields = []

    # Define entrance aperture diameter and other quantities
    d_objective = 5.0  # objective diameter in meters
    fl_objective = 20.0 * d_objective  # objective focal length in meters
    fl_eyepiece = 0.021  # eyepiece focal length
    fl_eye = 0.022  # human eye focal length
    beam_ratio = 0.3  # initial beam width/grid width

    # Define the wavefront
    wfo = proper.prop_begin(d_objective, wavelength, gridsize, beam_ratio)

    # Define a circular aperture
    proper.prop_circular_aperture(wfo, d_objective / 2)

    # Define entrance
    proper.prop_define_entrance(wfo)

    # quicklook_wf(wfo, show=True)
    selec_E_fields.append(proper.prop_shift_center(wfo.wfarr))

    # Define a lens
    proper.prop_lens(wfo, fl_objective, "objective")

    # Propagate the wavefront
    proper.prop_propagate(wfo, fl_objective + fl_eyepiece, "eyepiece")

    # Define another lens
    proper.prop_lens(wfo, fl_eyepiece, "eyepiece")

    exit_pupil_distance = fl_eyepiece / (1 - fl_eyepiece / (fl_objective + fl_eyepiece))
    proper.prop_propagate(wfo, exit_pupil_distance, "exit pupil at eye lens")

    proper.prop_lens(wfo, fl_eye, "eye")
    proper.prop_propagate(wfo, fl_eye, "retina")

    # quicklook_wf(wfo)
    selec_E_fields.append(proper.prop_shift_center(wfo.wfarr))

    # (wfo, sampling) = proper.prop_end(wfo)
    selec_E_fields = np.array(selec_E_fields)

    return selec_E_fields, None  # The None is because you need to return a tuple to work with prop_run
