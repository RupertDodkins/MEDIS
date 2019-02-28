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


def prop_ptp(wf, dz):
    """Propagate an planar input wavefront over some distance, keeping it planar. 
    
    This routine is used by propagate function to propagate a planar input wavefront
    over some distance to produce an planar output wavefront. This occurs when
    both the start and end point are both within the Rayleigh distance of focus.
    
    
    Parameters
    ----------
    wf : obj
        WaveFront class object
        
    dz : float
        Distance to propagate in meters from current position
        
        
    Returns
    -------
        None 
        Replaces wf object with a new one. 
    
    
    Raise
    -----
    ValueError
        Input reference surface not planar.
    
    
    Notes
    -----
    Intended only for use by propagate function. Not a user-callable routine.
    """
    ngrid = wf.ngrid
    
    if np.abs(dz) < 1e-12:
        return
    
    if proper.verbose:
        print("  PTP: dz = ", dz)
    
    if wf.reference_surface != "PLANAR":
        raise ValueError("  PTP: Input reference surface not planar. Stopping.")
        
    wf.reference_surface = "PLANAR"
    wf.z = wf.z + dz
    
    i = np.array([0+1j], dtype = np.complex128)
    
    # IDL FFT is normalized by design, we need to normalize numpy FFT to match
    if proper.use_fftw:
        if proper.verbose:
            print("prop_ptp, FFTW_FORWARD") 
        x = proper.prop_fftw(wf.wfarr, directionFFTW = 'FFTW_FORWARD') / np.size(wf.wfarr)
        wf.wfarr = x
    else:
        wf.wfarr = fft2(wf.wfarr) / np.size(wf.wfarr)
    
    if proper.verbose:
        print(" FFT2 prop_ptp  ")
    
    wf.wfarr = wf.wfarr * ngrid
    
    samp = wf.dx
    xrhosqr = np.tile(((np.arange(ngrid, dtype = np.float64) - int(ngrid/2)) / (ngrid * samp))**2, (ngrid, 1))
    rhosqr = xrhosqr + np.transpose(xrhosqr)
    rhosqr = np.roll(np.roll(rhosqr, int(ngrid/2), 0), int(ngrid/2), 1)
    
    wf.wfarr = wf.wfarr * np.exp((-i*np.pi*wf.lamda*dz)*rhosqr)
    
    # IDL FFT is normalized by design, we need to normalize numpy FFT to match
    if proper.use_fftw:
        if proper.verbose:
            print("prop_ptp: FFTW_BACKWARD")
        xi = proper.prop_fftw(wf.wfarr, directionFFTW = 'FFTW_BACKWARD') * np.size(wf.wfarr) 
        wf.wfarr = xi
    else:
        wf.wfarr = ifft2(wf.wfarr) * np.size(wf.wfarr)

    if proper.verbose:
        print(" IFFT2 prop_ptp  ")
        
    wf.wfarr = wf.wfarr / ngrid
    
    if proper.phase_offset:
        wf.wfarr = wf.wfarr * np.exp(complex(0.,1.) * 2 * np.pi * dz/wf.lamda)
    
    if proper.verbose:    
        print("  PTP: z = ", wf.z, "  dx = ", wf.dx)

    return
