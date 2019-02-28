#   Copyright 2016, 2017 California Institute of Technology
#   Users must agree to abide by the restrictions listed in the
#   file "LegalStuff.txt" in the PROPER library directory.
#
#   PROPER developed at Jet Propulsion Laboratory/California Inst. Technology
#   Original IDL version by John Krist
#   Python translation by Navtej Saini, with Luis Marchen and Nikta Amiri


import multiprocessing

def prop_fftw_nthreads(nthreads = None):
    '''Set the maximum number of threads that prop_fftw should use, if
    use of fftw is enabled.  
    
    By default, prop_fftw will use the same number of threads as there are 
    processors.  This value can be overridden per call to prop_fftw using its 
    NTHREADS keyword.
    
    
    Parameters
    -----------
    nthreads : int, optional 
        Number of threads


    Returns
    -----------
    num_fftw_threads : int
        Maximum number of threads that prop_fftw should use.
    '''
    if nthreads:
        num_fftw_threads = nthreads
        if nthreads > multiprocessing.cpu_count():
            print('Warning: Number of requested FFTW threads exceeds number of CPUs.')
            print('Number of threads will be set to number of CPUs.')
            num_fftw_threads = multiprocessing.cpu_count()

        elif nthreads < 1:
            print('Warning: Zero threads requested for FFTW. Setting to number of CPUs.')
            num_fftw_threads = multiprocessing.cpu_count()

        else:
            print("Number of threads is {}".format(num_fftw_threads))
        
    else:
        num_fftw_threads = multiprocessing.cpu_count()
        
    return num_fftw_threads 

