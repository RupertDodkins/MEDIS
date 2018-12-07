; $Id: nls_gen_default.pro,v 7.0 2016/04/29 marcel.carbillet $
;+
; NAME:
;    nls_gen_default
;
; PURPOSE:
;    nls_gen_default generates the default parameter structure
;    for the NLS module and save it in the rigth location.
;    (see nls.pro's header --or file caos_help.html-- for details about the
;     module itself).
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;    nls_gen_default
;
; ROUTINE MODIFICATION HISTORY:
;    program written: june 1998,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : february 1999,
;                     Elise Viard (ESO) [eviard@eso.org]:
;                    -a few modifications for version 1.0.
;                   : march 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -sky background stuff.
;                   : december 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 2.0 (CAOS).
;                   : may 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -the effective Na backscatter cross section (ecs)
;                     parameter and the atmosphere transmission (trans)
;                     parameter have no more a value fixed within nls_init.pro
;                     but are part of the free parameters set.
;                   : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -"mod_type"->"mod_name"
;                     (for version 4.0 of the whole Software System CAOS").
;                   : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
pro nls_gen_default

info = nls_info()
module = gen_def_module(info.mod_name, info.ver)

; get the sky background default magnitude in each pre-defined band
; (see .../lib/n_phot.pro)
dummy = n_phot(0., BACK_MAG=skymag)

; parameter structure
par =                  $
   {                   $
   nls,                $
   module    : module, $
   alt       : 90e3,   $
   width     : 10e3,   $
   n_sub     : 11,     $
   skymag    : skymag, $
   own       : 0,      $
   Na        : '',     $
   ecs       : 15E-16, $ ; effective Na backscatter cross section [m^2]
   trans     : 0.5     $ ; atmosphere transmission (upward propagation and
   }                     ; then downward propagation)

; save the default parameter structure in the default file
save, par, FILENAME=info.def_file

;back to calling program
end