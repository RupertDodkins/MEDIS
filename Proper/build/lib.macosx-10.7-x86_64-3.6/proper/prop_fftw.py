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
import _pickle as pickle
import multiprocessing as mp


def prop_fftw(a, directionFFTW = 'FFTW_FORWARD', NTHREADS = None):
    """Compute FFT of wavefront array using FFTW or MKL Intel FFT library routines

    Parameters
    ----------
    a : numpy ndarray
        Input wavefront

    directionFFTW : str
        Direction for the Fourier transform

    Returns
    ----------
    out : numpy ndarray
        Fourier transform of input complex array

    Raises
    ------
    ValueError
        Input array is not 2D.

    ValueError
        Data type is not double complex.
    """
    # Check array size and type
    if len(a.shape) != 2:
        raise ValueError('PROP_FFTW: Input array is not 2D. Stopping.')

    # check if the data type is double complex
    if a.dtype != np.complex128:
        raise ValueError('PROP_FFTW: Data type is not double complex. Stopping.')

    if proper.use_ffti:
        if directionFFTW == 'FFTW_FORWARD':
            out = proper.prop_ffti.fft2(a)

        if directionFFTW == 'FFTW_BACKWARD':
            out = proper.prop_ffti.ifft2(a)
    else:
        try:
            import pyfftw
        except ImportError:
            raise ImportError('Unable to import pyFFTW package. Stopping.')

        num_threads =  mp.cpu_count()

        ## Create the output directory
        out = pyfftw.empty_aligned((a.shape), dtype = a.dtype)
        if NTHREADS:
            if NTHREADS < mp.cpu_count():
                num_threads = NTHREADS
            elif proper.prop_fftw_nthreads() != 0:
                num_threads  = proper.prop_fftw_nthreads()

        ## 1 May 2018 - Navtej - Bug report #6 and code snippet by Bryn Jeffries
        ## Trying to write and read the wisdom file in multiple processes is
        ## causing race condition. We would only use wisdom file if already
        ## exists otherwise FFTW_ESTIMATE would be used
        gridsize = a.shape[0]
        wisdompath = os.path.join(proper.lib_dir, '.{}pix_wisdomfile'.format(str(gridsize)))
        if os.path.exists(wisdompath):
            if proper.verbose:
                print('Loading FFTW wisdom file : %s' %wisdompath)

            with open(wisdompath, 'rb') as infile:
                wisdom = pickle.load(infile)
                pyfftw.import_wisdom(wisdom)
        else:
            if proper.verbose:
                print('Using FFTW ESTIMATE')       

        if directionFFTW == 'FFTW_FORWARD':
            out = pyfftw.builders.fft2(a)()
        else:
            out = pyfftw.builders.ifft2(a)()

    return out
