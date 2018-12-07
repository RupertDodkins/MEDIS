; $Id: las_init.pro,v 7.0 2016/04/29 marcel.carbillet $
;+
; NAME:
;    las_init
;
; PURPOSE:
;    las_init executes the initialization for the LASer (LAS) module.
;
; CATEGORY:
;    module's initialisation routine
;
; CALLING SEQUENCE:
;    error = las_init(out_src_t, par)
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.:
;    see module help for a detailed description.
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: july 1998,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it],
;                     Elise  Viard     (ESO) [eviard@eso.org].
;    modifications  : february 1999,
;                     Elise Viard (ESO) [eviard@eso.org]:
;                    -adaptation to the new templates.
;                    -tag "constant" added for the version 1.0 to be able
;                     to compute laser spot only in the initialization part
;                     for a quicker version of the code.
;                   : march 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -the parameters n_phot (the laser nb of photons) and
;                     background (here all zeros) are now vectors, with the
;                     Johnson bands (+ Na-band, see .../lib/n_phot) as index.
;                    -gaussian shape calculus is now done via the lib-routine
;                     .../lib/make_elong_gauss.
;                   : june 1999,
;                     Francoise Delplancke (ESO) [fdelplan@eso.org]:
;                    -adapted to Rayliegh scattering.
;                   : december 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -enhanced and adapted to version 2.0 (CAOS).
;                    -structure INIT took out (useless).
;                   : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -"mod_type"->"mod_name"
;                     (for version 4.0 of the whole Software System CAOS).
;                   : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
function las_init, out_src_t, par, INIT=init

; error code initialization
error = !caos_error.ok

; retrieve the module's informations
info  = las_info()

; get the individual output structure types
if info.out_type ne '' then out_type = str_sep(info.out_type,",")

; STANDARD CHECKS
;
; compute and test the requested number of las arguments
n_par = 1  ; the parameter structure is always present within the arguments
if info.inp_type ne '' then begin
   inp_type = str_sep(info.inp_type,",")
   n_inp    = n_elements(inp_type)
endif else n_inp = 0
if info.out_type ne '' then begin
   out_type = str_sep(info.out_type,",")
   n_out    = n_elements(out_type)
endif else n_out = 0
n_par = n_par + n_inp + n_out
if n_params() ne n_par then message, 'wrong number of arguments'

; test the parameter structure
if test_type(par, /STRUCTURE, N_ELEMENTS=n) then $
   message, 'LAS error: par must be a structure'
if n ne 1 then message, 'LAS error: par cannot be a vector of structures'
if strlowcase(tag_names(par, /STRUCTURE_NAME)) ne info.mod_name then $
   message, 'par must be a parameter structure for the module LAS'

; OUTPUT DEFINITION
;
; compute laser map:
dim   = 256                        ; linear dim are fixed to this value [px]
waist = par.waist*dim/2            ; waist: [radius unit] => [px]
map   = make_elong_gauss(dim, waist, waist)
                                   ; 2D normalised gaussian map
                                   ; shape: exp{- x^2/(2*sigma^2)}
                                   ; i.e. : exp{- x^2/  waist^2  }

; compute nb of photons per second:

dummy   = n_phot(0., BAND=band, LAMBDA=lambda, WIDTH=width)
n_bands = n_elements(band)         ; retrieve lambdas, widths and bands

n_phot     = fltarr(n_bands)       ; nb of photon and background vectors
background = fltarr(n_bands)

h = 6.626e-34 & c = 2.998e8        ; laser nb of photons is put in the Na-band
n_phot[n_bands-1] = par.power*lambda[n_bands-1]/(h*c)

constant =  [par.constant, par.power, par.waist, 0., 0.]
   ; parameter used for 3D spot and Rayleigh scattering computation (in SHS)
   ; par.constant : 0/1 if the 3D projection on the sub-apertures has to be
   ;                made at each time (0) or only once (1)
   ; power = laser power (for Rayleigh scattering)
   ; waist = laser beam diameter (for Rayleigh scattering)
   ; the next two parameters will be defined in GPR. They are :
   ;         the distance from the main telescope to the laser launch
   ;         the position angle of the line between both telescopes

; output definition
out_src_t= $
   {       $
   data_type  : info.out_type[0], $
   data_status: !caos_data.valid, $   
   off_axis   : par.off_axis,     $ ; angular pos. of laser [rd]
   pos_ang    : par.pos_ang,      $ ; spot wrt main tel.   [rd]
   dist_z     : -par.dist_foc,    $ ; focalisation distance [m]
                                    ; (for projector tel.)
   map        : map,              $ ; proj. tel. output map 
   scale_xy   : dim,              $ ; arbitrary scale
   coord      : 0.d0,             $ ; [not used]
   scale_z    : 0.,               $ ; [not used]

   n_phot     : n_phot,           $ ; nb of photons/s
   background : background,       $ ; sky background

   lambda     : lambda,           $ ; wavelengths [m]
   width      : width,            $ ; bandwidths [m]

   constant   : constant          $ ; constant (wrt time) source
   }

; back to calling program
return, error
end