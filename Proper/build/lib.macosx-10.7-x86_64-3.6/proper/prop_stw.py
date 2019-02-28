#   Copyright 2016, 2017 California Institute of Technology
#   Users must agree to abide by the restrictions listed in the
#   file "LegalStuff.txt" in the PROPER library directory.
#
#   PROPER developed at Jet Propulsion Laboratory/California Inst. Technology
#   Original IDL version by John Krist
#   Python translation by Navtej Saini, with Luis Marchen and Nikta Amiri



import proper
import numpy as np
from numpy.fft import fft2, ifft2


def prop_stw(wf, dz = 0.0):
    """Propagate from a spherical reference surface that is outside the Rayleigh 
    limit from focus to a planar one that is inside. Used by propagate function.
    
    Parameters
    ----------
    wf : obj
        WaveFront class object
        
    dz : float
        Distance in meters to propagate
        
    Returns
    -------
        None 
        Modifies the wavefront.
    """
    ngrid = wf.ngrid
    
    if proper.verbose:
        print("  STW: dz = %3.6f" %(dz))
    
    if wf.reference_surface != "SPHERI":
        print("  STW: Input reference surface not spherical. Using PTP")
        proper.prop_ptp(wf, dz)
        return
        
    if dz == 0.0:
        dz = wf.z_w0 - wf.z
        
    wf.z = wf.z + dz
    wf.dx = wf.lamda * np.abs(dz) / (ngrid * wf.dx)
    
    direct = dz >= 0.0
    
    if direct:                 # forward transform
        if proper.use_fftw:
            if proper.verbose:
                print("using fftw for prop_stw FFTW_FORWARD")
            x = proper.prop_fftw(wf.wfarr,directionFFTW = 'FFTW_FORWARD') / np.size(wf.wfarr)
            wf.wfarr = x
        else:
            wf.wfarr = fft2(wf.wfarr) / np.size(wf.wfarr)

        if proper.verbose:
            print(" FFT2 prop_stw   ")
        
        wf.wfarr *= ngrid
    else:
        if proper.use_fftw:
            if proper.verbose:
                print("using fftw for prop_stw FFTW_BACKWARD")
            xi = proper.prop_fftw(wf.wfarr, directionFFTW = 'FFTW_BACKWARD') * np.size(wf.wfarr)
            wf.wfarr = xi
        else:
            wf.wfarr = ifft2(wf.wfarr) * np.size(wf.wfarr)
        wf.wfarr /= ngrid
        if proper.verbose:
            print("IFFT2 prop_stw  ")
    proper.prop_qphase(wf, dz)
    
    if proper.phase_offset:
        wf.wfarr = wf.wfarr * np.exp(complex(0.,1.) * 2*np.pi*dz/wf.lamda)
    
    if proper.verbose:
        print("  STW: z = %4.6f    dx = %.6e" %(wf.z, wf.dx))
    
    wf.reference_surface = "PLANAR"
    
    return
