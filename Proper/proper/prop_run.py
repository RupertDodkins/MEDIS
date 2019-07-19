#   Copyright 2016, 2017 California Institute of Technology
#   Users must agree to abide by the restrictions listed in the
#   file "LegalStuff.txt" in the PROPER library directory.
#
#   PROPER developed at Jet Propulsion Laboratory/California Inst. Technology
#   Original IDL version by John Krist
#   Python translation by Navtej Saini, with Luis Marchen and Nikta Amiri



import os
import proper
import importlib
import numpy as np
from time import time


def prop_run(routine_name, lambda0, gridsize, **kwargs):
    """Execute a prescription.

    Parameters
    ----------
    routine_name : str
        Filename (excluding extension) of the python routine containing the
        prescription.

    lambda0 : float
        Either the wavelength in microns at which to propagate the wavefront,
        or the name of a text file containing a list of wavelength and weight
        pairs. In the latter case, the prescription is run for each wavelength
        and the results added together with the respective weights.

    gridsize : int
        Size of the computational grid (arrays are gridsize by gridsize). Must
        be power of 2.


    Returns
    -------
    psf : numpy ndarray
        Image containing result of the propagation pf the prescription routine.

    pixscale : float
        Returns sampling of "result" in meters per element.  It is the
        responsibility of the prescription to return this value (which is
        returned from function end).


    Other Parameters
    ----------------
    QUIET : bool
        If set, intermediate messages and surface labels will not be printed.

    PHASE_OFFSET : bool
        If set, a phase offset is added as the wavefront is propagated. For
        instance, if a wavefront is propagated over a distance of 1/4 wavelength,
        a phase offset of pi/2 radians will be added. This is useful in cases
        where the offset between separate beams that may be combined later may
        be important (e.g. the individual arms of an interferometer). By default,
        a phase offset is not applied.

    VERBOSE : bool
        If set, informational messages will be printed.

    PASSVALUE : dict
        Points to a value (which could be a constant or a variable) that is
        passed to the prescription for use as the prescription desires.

    TABLE : bool
        If set, prints out a table of sampling and beam size for each surface.

    PRINT_INTENSITY : bool
        If set, print intensity values
    """

    if (int(gridsize) & int(gridsize-1)) != 0:
        print("ERROR: grid size must be a power of 2")

        # This is very naughty
        print("... but we'll continue anyway")
        # return

    if ("TABLE" in kwargs and kwargs["TABLE"]):
        proper.do_table = True

    if ("PRINT_INTENSITY" in kwargs and kwargs["PRINT_INTENSITY"]):
        proper.print_total_intensity = True

    proper.n = gridsize
    proper.layout_only = 0

    if ("VERBOSE" in kwargs and kwargs["VERBOSE"]):
        if kwargs["VERBOSE"] == True:
            proper.verbose = True

    if ("QUIET" in kwargs and kwargs["QUIET"]):
        proper.print_it = False

    if ("PHASE_OFFSET" in kwargs and kwargs["PHASE_OFFSET"]):
        proper.phase_offset = True

    if type(lambda0) == str:
        try:
            lam, throughput = np.loadtxt(lambda0, umpack = True, usecols = (0,1))
        except IOError:
            raise IOError("Unable to open wavelength file %s" %(lambda0))

        lam *= 1.e-6
    else:
        lam = np.array([lambda0 * 1.e-6])
        throughput = np.ones(shape = 1, dtype = np.float64)

    # Set which FFT library to use - numpy, pyFFTW or Intel MKL FFT
    proper.use_ffti = False
    proper.use_fftw = False

    if os.path.isfile(os.path.join(proper.lib_dir, '.use_ffti')):
        proper.use_ffti = True
        proper.use_fftw = True
    elif os.path.isfile(os.path.join(proper.lib_dir, '.use_fftw')):
        proper.use_fftw = True

    start_time = time()

    proper.first_pass = 0
    proper.action_num = 0

    nlams = len(lam)
    for ilam in range(nlams):
        if proper.print_it:
            print("Lambda = %2.4E   Throughput = %3.2f" %(lam[ilam], throughput[ilam]))

        try:
            module = importlib.import_module(routine_name)
        except ImportError:
            raise ImportError("Unable to run %s prescription. Stopping." %routine_name)

        func = getattr(module, routine_name.split('.')[-1])

        if "PASSVALUE" in kwargs:
            psf_ilam, pixscale = func(lam[ilam], gridsize, kwargs["PASSVALUE"])
        else:
            psf_ilam, pixscale = func(lam[ilam], gridsize)

        psf_ilam *= throughput[ilam]

        if ilam == 0:
            psf = psf_ilam
        else:
            psf += psf_ilam

        psf_ilam = 0

    end_time = time()

    if proper.print_it:
        print("Total elapsed time (seconds) = %8.4f" %(end_time - start_time))

    return (psf, pixscale)
