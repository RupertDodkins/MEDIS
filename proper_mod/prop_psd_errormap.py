#   Copyright 2016, 2017 California Institute of Technology
#   Users must agree to abide by the restrictions listed in the
#   file "LegalStuff.txt" in the PROPER library directory.
#
#   PROPER developed at Jet Propulsion Laboratory/California Inst. Technology
#   Original IDL version by John Krist
#   Python translation by Navtej Saini, with Luis Marchen and Nikta Amiri



import os
import proper
import numpy as np
from numpy.fft import fft2


def prop_psd_errormap(wf, amp, b, c, **kwargs):
    """Create a realization of a two-dimensional surface, wavefront, or amplitude
    error map for a specified power spectral density (PSD) profile. This map is
    applied to the current wavefront.

    Parameters
    ----------
    wf : obj
        WaveFront class object

    amp : float
        Low spatial frequency RMS error per spatial frequency.  By default, this
        is the wavefront error (meters^4). If the MIRROR switch is set, this is
        assumed to be the RMS surface error (meters^4). If the RMS switch is
        set, then the entire error map will be renormalized to have an RMS of
        "amp" (if the PSD is vastly dominated by very low spatial frequency
        errors, then the map in this case may not have the specified RMS over
        the area of the beam but will over the grid, leading to unexpected
        errors). If the AMPLITUDE keyword is specified, then "amp" is assumed
        to be the RMS amplitude error of the entire map (the /RMS switch is
        ignored).

    b : float
        Correlation length parameter (cycles/meter); this basically indicates
        where the PSD curve transitions from a horizontal line at low spatial
        frequencies to a sloping line at high ones

    c : float
        High frequency falloff power law exponent


    Returns
    -------
    dmap : numpy ndarray
        2D PSD error map.


    Other Parameters
    ----------------
    MAX_FREQUENCY : float
        Maximum spatial frequency (cycles/meter) in the generated map. This can
        be used to prevent high spatial frequency components from generating
        aliasing errors when a map is resampled.

    RMS : bool
        (Ignored if AMPLITUDE is set); Indicates that the error map array is to
        be normalized to have an RMS value about the mean specified by "amp".
        By default, "amp" specifies the RMS amplitude of just the low-spatial-frequency
        error component of the PSD.  WARNING: The map is renormalized only
        during the initial creation - if a map of the same name was previously
        created and so is read in from a file, the map in the file will not be
        renormalized.

    TPF : bool
        Indicates that the TPF 2D PSD shape is to be used:

         .. math:: PSD\_2D(k) = \\frac{amp}{1 + (\\frac{k}{b})^c}

        where k and b are in cycles/meter. The default PSD shape is used if
        TPF is not specified:

         .. math::  PSD\_2D(k) = \\frac{amp}{(1 + (\\frac{k}{b})^2)^{(c+1)/2}}


        This is the K-correlation form (see Church et al., Proc. of the SPIE,
        v. 1165, 136 (1989)).

    MIRROR : bool
        Indicates that the specified PSD is for the surface error on a mirror,
        so the resulting wavefront error will be twice the map error.  The map
        returned in the keyword MAP will be surface, not wavefront, error.

    AMPLITUDE : float
        Indicates that an amplitude error map will be created with a maximum
        amplitude of "amplitude". Remember that intensity is the square of the
        amplitude, so specifying AMPLITUDE=0.9 will result in a maximum
        intensity transmission of 0.81. Because the map is normalized by the
        maximum value in the entire array, the maximum amplitude may be lower
        within the illuminated region of the beam.

    FILE : str
        The filename containing the error map generated by this routine. This is
        used in one of two ways:
            1) If the file exists, it is read in and that map is used instead of
               creating a new map. In this case, the parameters on the command
               line are ignored, except when AMPLITUDE is specified, in which
               case the map read from the file will be assumed to be an amplitude
               error map and will be adjusted to have a mean value of specified
               by the AMPLITUDE keyword value over the entire array.

               There are no checks made to verify the the command line parameters
               and those used to generate the error map in the file are the same.
            2) If the file doesn't exist, a map is generated and written to that
               file.

    INCLINATION : float

    ROTATION : float
        These optional keywords specify the inclination in the Y-axis and rotation
        about the Z-axis of the surface or wavefront error plane relative to the
        incoming beam.  This approximately accounts for the projection of the
        beam onto the inclined surface and the resulting difference in spatial
        frequency scales of errors along the wavefront axes. See the PSD section
        of the manual for more info.

    NO_APPLY : bool
        If this switch is set, then a map will be generated but not applied to
        the wavefront (added if wavewfront or surface, multiplied if amplitude).
        This is useful if you wish to use the map for some custom purpose.
    """
    n = proper.prop_get_gridsize(wf)

    # Look for pre-existing map
    f = ""

    if "FILE" in kwargs:
        fname = kwargs["FILE"]
        if os.path.exists(fname):
            f = os.path.abspath(fname)

    i = complex(0.,1.)

    if f == "":
        # if map does not exist, create it
        if proper.print_it:
            if not "AMPLITUDE" in kwargs:
                print("  Creating phase aberration map from PSD")
            else:
                print("  Creating amplitude aberration map from PSD")

        dk = 1. / (n * proper.prop_get_sampling(wf))

        if not "INCLINATION" in kwargs:
            inc_angle = 0.
        else:
            inc_angle = kwargs["INCLINATION"]*np.pi/180.

        if not "ROTATION" in kwargs:
            rot_angle = 0.
        else:
            rot_angle = kwargs["ROTATION"]*np.pi/180.

        if "PHASE_HISTORY" in kwargs:
            phase_history = kwargs["PHASE_HISTORY"]
        else:
            phase_history = False

        xk = np.tile(np.arange(n, dtype = np.float64), (n,1)) - int(n/2)
        yk = xk.T

        xk = xk * np.cos(-rot_angle) - yk * np.sin(-rot_angle)
        yk = xk * np.sin(-rot_angle) + yk * np.cos(-rot_angle)
        yk = yk * np.cos(-inc_angle)
        kpsd = np.sqrt(xk**2 + yk**2) * dk   # cycles/meter
        if ("TPF" in kwargs and kwargs["TPF"]):
            psd2d = amp / (1. + (kpsd/b)**c)
        else:
            psd2d = amp / (1. + (kpsd/b)**2)**((c+1)/2.)

        psd2d[n//2,n//2] = 0.    # no piston
        rms_psd = np.sqrt(np.sum(psd2d)) * dk      # RMS error from PSD

        # Create realization of PSD using random phases
        # Need to normalize FFT in numpy to match IDL FFT result
        if not np.any(phase_history):
            phase = 2 * np.pi * np.random.uniform(size = (n,n)) - np.pi
        else:
            phase = phase_history

        # if specified, zero-out spatial frequencies > max_frequency
        if "MAX_FREQUENCY" in kwargs:
            max_frequency = kwargs["MAX_FREQUENCY"]
            kpsd[kpsd > max_frequency] = 0.0
            psd2d = psd2d * (kpsd)

        if proper.prop_use_fftw() == 1:
            dmap_fft = proper.prop_fftw(proper.prop_shift_center(np.sqrt(psd2d)/dk*np.exp(i*phase)), directionFFTW = 'FFTW_FORWARD') / np.size(psd2d)
        else:
            dmap_fft = fft2(proper.prop_shift_center(np.sqrt(psd2d)/dk*np.exp(i*phase))) / np.size(psd2d)
        dmap =  dmap_fft.real / (n**2 * proper.prop_get_sampling(wf)**2)

        # force realized map to have RMS expected from PSD
        rms_map = np.std(dmap)

        if (not "RMS" in kwargs and not "AMPLITUDE" in kwargs):
            dmap *= rms_psd / rms_map
        else:
            dmap *= amp / rms_map
    else:
        # if map does exist, read it in
        if proper.print_it:
            if "AMPLITUDE" in kwargs:
                print("  PSD-realization amplitude map exists. Reading in %s" %kwargs["FILE"])
            else:
                print("  PSD-realization phase map exists. Reading in %s" %kwargs["FILE"])

        dmap = proper.prop_readmap(wf, kwargs["FILE"])

    if "AMPLITUDE" in kwargs:
        maptype = "amplitude"
        max_map = np.max(dmap)
        dmap += kwargs["AMPLITUDE"] - max_map
        if ("NO_APPLY" in kwargs and kwargs["NO_APPLY"]):
            pass
        else:
            wf.wfarr *= dmap
    elif ("MIRROR" in kwargs and kwargs["MIRROR"]):
        maptype = "mirror surface"
        if ("NO_APPLY" in kwargs and kwargs["NO_APPLY"]):
            pass
        else:
            wf.wfarr *= np.exp(4*np.pi*i/wf.lamda*dmap)
    else:
        maptype = "wavefront"
        if ("NO_APPLY" in kwargs and kwargs["NO_APPLY"]):
            pass
        else:
            wf.wfarr *= np.exp(2*np.pi*i/wf.lamda*dmap)

    dmap = proper.prop_shift_center(dmap)

    if "FILE" in kwargs and f == "":
        print("  Writing out PSD realization map to %s" %kwargs["FILE"])

        header = {}
        header["MAPTYPE"] = (maptype, " error map type")
        if ("TPF" in kwargs and kwargs["TPF"]):
            header["PSDTYPE"] = (kwargs["TPF"], "")
        header["X_UNIT"] = ("meters", " X-Y units")
        header["PIXSIZE"] = (proper.prop_get_sampling(wf), " spacing in meters")
        if maptype != "amplitude":
            header["Z_UNIT"] = ("meters", " Error units")
            header["PSD_AMP"] = (amp, " PSD low frequency RMS amplitude (m^4)")
        else:
            header["PSD_AMP"] = (amp, " PSD low frequency RMS amplitude (amp^2m^4)")

        header["PSD_B"]  = (b, " PSD correlation length (cycles/m)")
        header["PSD_C"]  = (c, " PSD high frequency power law")
        header["XC_PIX"] = (n//2, " Center X pixel coordinate")
        header["YC_PIX"] = (n//2, " Center Y pixel coordinate")
        if "MAX_FREQUENCY" in kwargs:
            header["MAXFREQ"] = (max_frequency, ' Maximum spatial frequency in cycles/meter')

        proper.prop_fits_write(kwargs["FILE"], dmap, HEADER = header)

    return dmap
