function psg_empty_header

header = $
   {     $
   id_string: 'psg cube', $ ; string to check the file
   ver      : fix([1,0]), $ ; version number of the cube format 
   n_screens: long(0),    $ ; number of screens in the data cube
   dim_x    : fix(0),     $ ; wf x-dimension [px]
   dim_y    : fix(0),     $ ; wf y-dimension [px]
   method   : fix(0),     $ ; computing method (0=FFT+SHA, 1=Zernike+Jacobi)
   model    : fix(0),     $ ; atmospheric model (0=kolmogorov, 1=vonKarman)
   sha      : fix(0),     $ ; nb of added sub-harmonics
   L0       : float(0),   $ ; wf outer scale in pixel (dim) units
   seed1    : long(0),    $ ; starting seed for random gen. of base screen
   seed2    : long(0),    $ ; starting seed for random gen. of sub-harmonics
   double   : 0B          $ ; 1B: double, 0B: float
   }

return, header
end
