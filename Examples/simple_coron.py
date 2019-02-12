import proper
import matplotlib.pyplot as plt
import numpy as np
# from medis.Utils.plot_tools import view_datacube, quicklook_wf, quicklook_im

def coronagraph(wfo, f_lens, occulter_type, diam):
    plt.figure(figsize=(12,8))
    plt.subplot(2,2,1)
    plt.imshow(proper.prop_get_phase(wfo), origin = "lower")
    plt.text(200, 10, "Entrance Pupil", color = "w")

    proper.prop_lens(wfo, f_lens, "coronagraph imaging lens")
    proper.prop_propagate(wfo, f_lens, "occulter")

    # occulter sizes are specified here in units of lambda/diameter;
    # convert lambda/diam to radians then to meters
    occrad_rad = 3 # lambda/D
    # lamda = proper.prop_get_wavelength(wfo)
    dx_m = proper.prop_get_sampling(wfo)
    occrad = 4. # occulter radius in lam/D occrad_rad = occrad * lamda / diam # occulter radius in radians dx_m = proper.prop_get_sampling(wfo)
    dx_rad = proper.prop_get_sampling_radians(wfo)
    occrad_m = occrad_rad * dx_m / dx_rad # occulter radius in meters


    if occulter_type == "GAUSSIAN":
        r = proper.prop_radius(wfo)
        h = np.sqrt(-0.5 * occrad_m**2 / np.log(1 - np.sqrt(0.5)))
        gauss_spot = 1 - np.exp(-0.5 * (r/h)**2)
        proper.prop_multiply(wfo, gauss_spot)
        plt.suptitle("Gaussian spot", fontsize = 18)
    elif occulter_type == "SOLID":
        proper.prop_circular_obscuration(wfo, occrad_m)
        plt.suptitle("Solid spot", fontsize = 18)
    elif occulter_type == "8TH_ORDER":
        proper.prop_8th_order_mask(wfo, occrad, CIRCULAR = True)
        plt.suptitle("8th order band limited spot", fontsize = 18)

    # After occulter
    plt.subplot(2,2,2)
    plt.imshow(np.sqrt(proper.prop_get_amplitude(wfo))**0.2, origin = "lower")
    plt.text(200, 10, "After Occulter", color = "w")
    proper.prop_propagate(wfo, f_lens, "pupil reimaging lens")
    proper.prop_lens(wfo, f_lens, "pupil reimaging lens")
    proper.prop_propagate(wfo, 2*f_lens, "lyot stop")
    plt.subplot(2,2,3)
    plt.imshow(proper.prop_get_amplitude(wfo)**0.2, origin = "lower")
    plt.text(200, 10, "Before Lyot Stop", color = "w")

    if occulter_type == "GAUSSIAN":
        proper.prop_circular_aperture(wfo, 0.75, NORM = True)
    elif occulter_type == "SOLID":
        proper.prop_circular_aperture(wfo, 0.84, NORM = True)
    elif occulter_type == "8TH_ORDER":
        proper.prop_circular_aperture(wfo, 0.50, NORM = True)
    proper.prop_propagate(wfo, f_lens, "reimaging lens")
    proper.prop_lens(wfo, f_lens, "reimaging lens")
    proper.prop_propagate(wfo, f_lens, "final focus")

    plt.subplot(2,2,4)
    plt.imshow(np.sqrt(proper.prop_get_amplitude(wfo))**0.2, origin = "lower")
    plt.text(200, 10, "Focal Plane", color = "w")
    plt.show(block=True)

    return

def simple_coron(wavelength, grid_size, PASSVALUE = {'occulter_type': 'GAUSSIAN', 'input_map':None}):

    diam = 0.1 # telescope diameter in meters f_lens = 24 * diam
    beam_ratio = 0.3
    f_lens = 0.5 * diam
    wfo = proper.prop_begin(diam, wavelength, grid_size, beam_ratio)

    proper.prop_circular_aperture(wfo, diam/2)
    proper.prop_define_entrance(wfo)

    phase_map = proper.prop_get_phase(wfo)
    amp_map = proper.prop_get_amplitude(wfo)

    phase_map += PASSVALUE['input_map']

    wfo.wfarr = proper.prop_shift_center(amp_map * np.cos(phase_map) + 1j * amp_map * np.sin(phase_map))

    coronagraph(wfo, f_lens, 'GAUSSIAN', diam)
    (wfo, sampling) = proper.prop_end(wfo)
    return (wfo, sampling)

def make_speckle_kxy(kx, ky, amp, dm_phase):
    """given an kx and ky wavevector,
    generates a NxN flatmap that has
    a speckle at that position"""
    dmx, dmy   = np.meshgrid(np.linspace(-0.5, 0.5, width),np.linspace(-0.5, 0.5, width))
    xm=dmx*kx*2.0*np.pi
    ym=dmy*ky*2.0*np.pi
    ret = amp*np.cos(xm + ym +  dm_phase)
    return ret

proper.print_it=False
width = 128

flat = np.ones((width,width))
proper.prop_run('simple_coron', 1.1, width, PHASE_OFFSET=1, PASSVALUE={'input_map': flat})

sine = make_speckle_kxy(10,10,np.pi,0)
proper.prop_run('simple_coron', 1.1, width, PHASE_OFFSET=1, PASSVALUE={'input_map': sine})