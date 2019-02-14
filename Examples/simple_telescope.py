
import proper
import matplotlib.pyplot as plt
from medis.Utils.plot_tools import view_datacube, quicklook_wf, quicklook_im
import numpy as np

def simple_telescope(wavelength, gridsize):

    # Define entrance aperture diameter and other quantities
    d_objective = 5.0                        # objective diameter in meters
    fl_objective = 20.0 * d_objective          # objective focal length in meters
    fl_eyepiece = 0.021                        # eyepiece focal length
    fl_eye = 0.022                             # human eye focal length
    beam_ratio = 0.3                           # initial beam width/grid width

    # Define the wavefront
    wfo = proper.prop_begin(d_objective, wavelength, gridsize, beam_ratio)

    # print d_objective, wavelength, gridsize, beam_ratio
    # Define a circular aperture
    proper.prop_circular_aperture(wfo, d_objective/2)
    

    # proper.prop_propagate(wfo, fl_objective)
    # proper.prop_propagate(wfo, fl_objective)
    # proper.prop_propagate(wfo, fl_objective)

    # plt.imshow(proper.prop_get_amplitude(wfo))
    # plt.show()

    # Define entrance
    proper.prop_define_entrance(wfo)
    # plt.imshow(proper.prop_get_amplitude(wfo))
    # plt.show()

    # proper.prop_propagate(wfo, fl_objective+fl_eyepiece, "eyepiece")
    # # plt.imshow(proper.prop_get_amplitude(wfo))
    # # plt.show()
    #
    # proper.prop_propagate(wfo, fl_objective+fl_eyepiece, "eyepiece")
    # plt.imshow(proper.prop_get_amplitude(wfo))
    # plt.show()
    #
    # proper.prop_propagate(wfo, fl_objective+fl_eyepiece, "eyepiece")
    # plt.imshow(proper.prop_get_amplitude(wfo))
    # plt.show()

    # Define a lens
    proper.prop_lens(wfo, fl_objective, "objective")
    # plt.imshow(proper.prop_get_amplitude(wfo))
    # plt.show()
    # Propagate the wavefront
    proper.prop_propagate(wfo, fl_objective+fl_eyepiece, "eyepiece")
    # plt.imshow(proper.prop_get_amplitude(wfo))
    # plt.show()

    # Define another lens
    proper.prop_lens(wfo, fl_eyepiece, "eyepiece")
    # plt.imshow(proper.prop_get_amplitude(wfo))
    # plt.show()

    exit_pupil_distance = fl_eyepiece / (1 - fl_eyepiece/(fl_objective+fl_eyepiece))
    proper.prop_propagate(wfo, exit_pupil_distance, "exit pupil at eye lens")
    # quicklook_wf(wfo)
    # plt.imshow(proper.prop_get_amplitude(wfo))
    # plt.show()

    proper.prop_lens(wfo, fl_eye, "eye")
    proper.prop_propagate(wfo, fl_eye, "retina")
    # plt.imshow(proper.prop_get_amplitude(wfo))
    # plt.show()

    quicklook_wf(wfo)
    phase_map = proper.prop_get_phase(wfo)
    amp_map = proper.prop_get_amplitude(wfo)
    # quicklook_im(phase_map)

    amp_map[80:100,80:100] = 0
    quicklook_im(amp_map, logAmp=True)

    wfo.wfarr = proper.prop_shift_center(amp_map * np.cos(phase_map) + 1j * amp_map * np.sin(phase_map))
    # quicklook_wf(wf_array[iw,0])
    proper.prop_propagate(wfo, fl_eye, "retina")
    proper.prop_lens(wfo, fl_eye, "eye")
    quicklook_wf(wfo)

    # End
    (wfo, sampling) = proper.prop_end(wfo)

    return wfo, sampling


#proper.prop_run('simple_telescope', 1.1, 128, PHASE_OFFSET=1)
