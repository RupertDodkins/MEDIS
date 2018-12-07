; $Id: psg_gen_default.pro,v 6.0 2016/03/22 marcel.carbillet $
;+
; NAME:
;    psg_gen_default
;
; CATEGORY:
;    utility routine
;
; CALLING SEQUENCE:
;    psg_gen_default
;
; PROGRAM MODIFICATION HISTORY:
;    program written: february 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : november 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 2.0 (CAOS).
;                   : september 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -covariance matrix file address changed.
;                   : april 2005,
;                     Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr]:
;                    -file addresses were managed the old way... resulting in
;                     a bug when using PSG alone (not within ATM).
;                     (debugged thanks to a bug report from S.Hippler)
;                   : march 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr],
;                     Andrea La Camera (DIBRIS) [andrea.lacamera@unige.it],
;                     Nicolò Ginatta (DIBRIS) (Dip. Fisica, Genova, Italy):
;                    -default file address debugged.
;
;-
;
pro psg_gen_default

info = atm_info()
add_covmat = filepath("l_d4186_sparse.sav", ROOT=!caos_env.modules, $
                      SUB=[info.pack_name+!caos_env.delim+"modules" $
                      +!caos_env.delim+"atm"+!caos_env.delim+"atm_data"])

par =   $
   {    $
   psg, $ ; structure named psg

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   cal       : 0B,                        $ ; independent screens generation
                                            ; [DO NOT CHANGE THIS PARAMETER !!]
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   dim       : 512,                       $ ; screens nb of linear pixels
   length    : 512.,                      $ ; screens length [m]
   L0        : 512*40./32.,               $ ; wf outer-scale [m]
   method    : 0,                         $ ; computing method
                                            ;(0=FFT+SHA, 1=Zernike+Jacobi)
   model     : 1,                         $ ; atmospheric model
                                            ;(0=Kolmogorov, 1=von Karman)
   seed1     : 7897L,                     $ ; seeds for random nb generation
   seed2     : 2657L,                     $ ;(seed1=FFT/Zer, seed2=SHA/nothing)
   add_covmat: add_covmat,                $ ; covariance matrix address
                                          $ ;(for Zernike polynomials)
   n_layers  : 10,                         $ ; nb of screens to be generated
   sha       : 5,                         $ ; nb of sub-harmonics to be added
   psg_add   : './phase_screens.xdr',     $ ; phase screens file address

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;   
   lps       : 0,                         $ ; [NOT USED !!]
   r0        : 0.,                        $ ; [NOT USED !!]
   alt       : 0.,                        $ ; [NOT USED !!]
   weight    : 0.,                        $ ; [NOT USED !!]
   wind      : 0.,                        $ ; [NOT USED !!]
   dir       : 0.,                        $ ; [NOT USED !!]
   delta_t   : 0.                         $ ; [NOT USED !!]
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   }

; save the default parameter structure in the default file
save, par, FILENAME=!caos_env.modules+!caos_env.delim+info.pack_name $
                   +!caos_env.delim+"pack_lib"+!caos_env.delim+"psg" $
                   +!caos_env.delim+"psg_default.sav"

end