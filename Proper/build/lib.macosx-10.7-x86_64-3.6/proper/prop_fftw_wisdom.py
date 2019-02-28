#   Copyright 2016, 2017 California Institute of Technology
#   Users must agree to abide by the restrictions listed in the
#   file "LegalStuff.txt" in the PROPER library directory.
#
#   PROPER developed at Jet Propulsion Laboratory/California Inst. Technology
#   Original IDL version by John Krist
#   Python translation by Navtej Saini, with Luis Marchen and Nikta Amiri


import os
import proper
import _pickle as pickle
import multiprocessing


def prop_fftw_wisdom(gridsize, nthreads = None, direction = 'FFTW_FORWARD'):
    '''Determine FFTW wisdom for a given array size and number of threads.

    Write the results out to a "wisdom file" that can be used by prop_fftw.


    Parameters
    ----------
    gridsize : int
        Wavefront grid size

    nthreads : int
        Number of threads

    direction : {'FFTW_FORWARD', 'FFTW_BACKWARD'}
        Fourier transform direction


    Returns
    -------
    wisdomFilePath : str
        Path to the wisdom file
    '''
    try:
        import pyfftw
    except ImportError:
        raise ImportError("pyfftw is not installed. Stopping.")

    ## Check the number of processors
    nCpu = multiprocessing.cpu_count()

    if nthreads:
        if nthreads < nCpu:
            numThread = nthreads

    if proper.prop_fftw_nthreads() != 0:
        numThread = proper.prop_fftw_nthreads()

    data = pyfftw.empty_aligned((gridsize,gridsize), dtype = 'complex128')

    data_k = pyfftw.empty_aligned((gridsize,gridsize), dtype = 'complex128')


    if direction =='FFTW_FORWARD':
        pyfftw.FFTW(data, data_k, direction = 'FFTW_FORWARD',
                              axes=(0,1), threads = numThread)
    else:

        pyfftw.FFTW(data_k, data, direction = 'FFTW_BACKWARD',
                               axes=(0,1), threads = numThread)


    # Export the wisdom file
    wisdom = pyfftw.export_wisdom()
    with open(os.path.join(proper.lib_dir,'.{}pix_wisdomfile'.format(str(gridsize))), 'wb') as outfile:
        pickle.dump(wisdom, outfile, -1)

    return  os.path.join(proper.lib_dir,'.{}pix_wisdomfile'.format(str(gridsize)))
