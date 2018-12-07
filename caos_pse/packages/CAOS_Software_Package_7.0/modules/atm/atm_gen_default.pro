; $Id: atm_gen_default.pro,v 7.0 2016/04/21 marcel.carbillet $
;+
; NAME:
;    atm_gen_default
;
; PURPOSE:
;    atm_gen_default generates the default parameter structure
;    for the ATM module and save it in the rigth location.
;    The user doesn't need to use atm_gen_default, it is used
;    only for developing and upgrading purposes. (see atm.pro's header
;    --or file caos_help.html-- for details about the module itself).
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;    atm_gen_default
;
; ROUTINE MODIFICATION HISTORY:
;    program written: february 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : may 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -fixed default file address problem.
;                   : november 1999-april 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -enhanced and adapted for version 2.0 (CAOS).
;                   : May 2000,
;                     Bruno Femenia (OAA) [bfemenia@arcetri.astro.it]
;                    -debugged: time-base must be defined as floating-point.
;                   : september 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -covariance matrix file address as well as default
;                     wavefront stripes file address changed.
;                   : december 2000,
;                     Bruno Femenia (OAA) [bfemenia@arcetri.astro.it]:
;                    -parameter "zern_rad_degree" added.
;                   : january/february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -"mod_type"->"mod_name"
;                     (for version 4.0 of the whole Software System CAOS").
;                    -paths updated.
;                   : october 2014-january 2015,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -6 layers > 10 layers. In order to have even more
;                     turbulent layers, add values to vectors "alt", "weight",
;                     "wind" and "dir" hereafter, and then run the present
;                     routine, by just typing ".r atm_gen_default" at the
;                     CAOS/IDL promt, before opening a *new* occurence of
;                     module ATM.
;                   : march 2016,
;                     Ulysse Perruchon-Monge & Adama Sy (Dépt. Physique UNS),
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -turbulence can now be switched off ("turnatmos" tag
;                     added to the parameters structure).
;
;-
;
pro atm_gen_default

info = atm_info()

; Generate module description structure
module = gen_def_module(info.mod_name, info.ver)

alt    = [0., 10., 1E2, 5E2, 7E2, 1E3, 5E3, 7E3, 10E3, 15E3]
weight = [.2, .2 , .2 , .1 , .05, .05, .05, .05, .05 , .05 ]
wind   = [5., 5. , 5. , 5. , 5. , 10., 10., 10., 15. , 15. ]
dir    = [0., 90.,180., 0. ,270., 90., 0. ,180., 0.  , 270.]/!RADEG

add_covmat = filepath("l_d4186_sparse.sav", ROOT=!caos_env.modules, $
                      SUB=[info.pack_name+!caos_env.delim+"modules" $
                          +!caos_env.delim+"atm"+!caos_env.delim+"atm_data"])
psg_add    = filepath("phase_stripes.xdr",  ROOT=!caos_env.modules, $
                      SUB=[info.pack_name+!caos_env.delim+"modules" $
                          +!caos_env.delim+"atm"+!caos_env.delim+"atm_data"])

par =   $
   {    $
   atm, $ ; structure named atm
   module    : module,                    $ ; std tag: module desc. structure
   cal       : 0B,                        $ ; type of calculation (0=time evol,
                                          $ ;1=statistical averaging)
   dim       : 256,                       $ ; wf nb of linear pixels
   length    : 16.,                       $ ; wf length [m]
   L0        : 20.,                       $ ; wf outer-scale [m]
   lps       : 1,                         $ ; layers' phase screens
                                            ;(0=already-computed ones,
                                            ;1=to-be-generated ones)
   psg_add   : psg_add,                   $ ; wf file address
                                          $ ;(if generation is not desired)
   method    : 0,                         $ ; computing method (0=FFT
                                            ;+SHA, 1=Zernike+Jacobi)
   model     : 1,                         $ ; atmospheric model
                                            ;(0=kolmogorov, 1=vonKarman)
   seed1     : 21L,                       $ ; seeds for random nb gen.
   seed2     : 12L,                       $
   add_covmat: add_covmat,                $ ; covariance matrix address
                                          $ ; (for Zernike polynomials)
   n_layers  : (size(alt))[1],            $ ; nb of turbulent layers
   r0        : 0.2,                       $ ; Fried parameter @500nm [m]
   alt       : alt,                       $ ; layers' altitudes [m]
   weight    : weight,                    $ ; Cn2 ratio for each layer
   wind      : wind,                      $ ; wind speed for each layer
   dir       : dir,                       $ ; wind direction angle for each
                                            ; layer [rd]
   sha       : 0,                         $ ; nb of sub-harmonics to be added
   delta_t   : 1E-3,                      $ ; time-base for temp. evol. [s]
   zern_rad_degree: 90,                   $ ; Consider up to this radial degree
                                          $ ; (90 yields 4186 Zernike terms) 
   turnatmos : 1B                         $ ; turn off or turn on atmospheric
                                          $ ; turbulence ? [0B or 1B]
   }

if (par.method eq 0) then begin
   if (par.model eq 1) then begin
      ratio = .99
      par.sha = ceil(alog(par.L0/par.length/sqrt(ratio^(-6/5.)-1)) / alog(3))
      if (par.sha lt 0) then par.sha=0
   endif else par.sha = 10
endif

; save the default parameter structure in the default file
save, par, FILENAME=info.def_file

end