; $Id: sav.pro,v 7.0 2016/05/03 marcel.carbillet $
;+
; NAME:
;    sav
;
; ROUTINE'S PURPOSE:
;    SAV executes the simulation for the data SAVing (SAV) module.
;
; MODULE'S PURPOSE:
;    Using SAV, output structures data of any kind can be saved.
;    To do so, SAV writes a prototype file (filename.sav - saved using the
;    IDL "save" function) and an actual data file (filename.xdr - written using
;    XDR format). The prototype file permits afterwards to read the data file
;    - that can be done easily using the ReSTore (RST) utility.
;
; CATEGORY:
;    main module's routine
;
; CALLING SEQUENCE:
;    error = sav(inp_yyy_t, $
;                par,       $
;                INIT=init  )
;
; OUTPUT:
;    error: long scalar (error code, see !caos_error var in caos_init.pro).
;
; INPUTS:
;    inp_yyy_t: structure of type yyy_t (a priori unknown type).
;    par      : parameters structure from sav_gui.
;
; KEYWORD PARAMETERS:
;    INIT: initialisation data structure
;
; COMMON BLOCKS:
;    common caos_block, tot_iter, this_iter
;
;    tot_iter   : total number of iteration during the simulation run.
;    this_iter  : current iteration number.
;
; SIDE EFFECTS:
;       none.
;
; RESTRICTIONS:
;       if the modules creating the output structures does not give a constant
;       (in means of size in bytes) output, the prototype structure does no more
;       make any sense and the saved file cannot be easily read anymore (at
;       least using the RST utility).
;
; CALLED NON-IDL FUNCTIONS:
;       none.
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: march 1999,
;                     Simone Esposito  (OAA) [esposito@arcetri.astro.it],
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : december 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 2.0 (CAOS).
;                   : january--march 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -use of variable "calibration" eliminited for version 4.0
;                     of the whole CAOS Software System.
;                   : may 2016,
;                     Ulysse Perruchon-Monge & Adama Sy (Dépt.Physique UNS),
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -moved from Soft.Pack.CAOS 5.2 to new package "Utilities"
;                     of new version (7.0) of the CAOS PSE,
;                    -simple IDL "save" format and FITS format added.
;
; MODULE MODIFICATION HISTORY:
;    module written : Simone Esposito  (OAA) [esposito@arcetri.astro.it],
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;                   : version 2.0
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -modified in order to be adapted to version 2.0 (CAOS)
;                   : for version 4.0,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -no more use of the common variable "calibration" and
;                     the tag "calib" (structure "info") for version 4.0 of
;                     the whole CAOS Software System.
;                   : for version 7.0,
;                     Ulysse Perruchon-Monge & Adama Sy (Dépt.Physique UNS),
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -moved from Soft.Pack.CAOS 5.2 to new package "Utilities"
;                     of new version (7.0) of the CAOS PSE,
;                    -simple IDL "save" format and FITS format added.
;                    -useless init.counter eliminated (this_iter used instead).
;-
;
function sav, inp_yyy_t, $ ; input structure
              par,       $ ; parameters from sav_gui
              INIT=init    ; initialization structure

common caos_block, tot_iter, this_iter

; initialization of the error code: set to "no error" as default
error = !caos_error.ok

; module's actions
if (this_iter eq 0) then begin
   ; initialisation section
   error = sav_init(inp_yyy_t, par, INIT=init)
endif else begin
   ; run section
   error = sav_prog(inp_yyy_t, par, INIT=init)
endelse

; back to calling program.
return, error                   ; back to calling program.
end