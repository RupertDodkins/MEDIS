#   Copyright 2016, 2017 California Institute of Technology
#   Users must agree to abide by the restrictions listed in the
#   file "LegalStuff.txt" in the PROPER library directory.
#
#   PROPER developed at Jet Propulsion Laboratory/California Inst. Technology
#   Original IDL version by John Krist
#   Python translation by Navtej Saini, with Luis Marchen and Nikta Amiri



import numpy as np

def prop_sinc(x):
    """Sinc interploation function.
    
    Parameters
    ----------
    x : scalar or numpy ndarray
        Input variable
        
    Returns
    -------
    float or numpy array
        Sinc interpolated value    
    """
    if type(x) != np.ndarray and type(x) != list:
        if x == 0:
            return 1.
        else:
            return np.sin(x)/x
    else:
        xarr = np.asarray(x)
            
        y = np.sin(xarr)
    
        with np.errstate(divide = "ignore"):
            y = y / xarr
    
        w0 = np.where(xarr == 0)
        if w0[0].shape[0] != 0:
            y[w0] = 1.
        
        return y
