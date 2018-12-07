; $Id: ibc.pro,v 7.0 2016/04/29 marcel.carbillet $
;+
; NAME:
;    ibc
;
; ROUTINE'S PURPOSE:
;    ibc executes the simulation for the Interferometric Beam Combiner
;    (IBC) module.
;
; MODULE'S PURPOSE:
;    IBC simulates an Interferometric Beam Combiner.
;
; CATEGORY:
;    main module's routine
;
; CALLING SEQUENCE:
;    error = ibc(in1_wfp_t, $
;                in2_wfp_t, $
;                out_wfp_t, $
;                par,       $
;                INIT=init  )
;
; OUTPUT:
;    error: error code [long scalar] (see !caos_error in caos_init.pro).
;
; INPUTS:
;    in1_wfp_t: structure of type wfp_t.
;    in2_wfp_t: structure of type wfp_t.
;    par      : parameters structure from ibc_gui.
;
; INCLUDED OUTPUTS:
;    out_wfp_t: structure of type wfp_t.
;
; KEYWORD PARAMETERS:
;    ...
;
; COMMON BLOCKS:
;    ...
;
; SIDE EFFECTS:
;    none.
;
; RESTRICTIONS:
;    none.
;
; CALLED NON-IDL FUNCTIONS:
;    none.
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: april-october 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it],
;                     Serge  Correia   (OAA) [correia@arcetri.astro.it]:
;    modifications  : december 1999--february 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 2.0 (CAOS).
;                   : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -use of variable "calibration" eliminited for version 4.0
;                     of the whole CAOS Software System.
;                   : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
; MODULE MODIFICATION HISTORY:
;    module written : Marcel Carbillet (OAA) [marcel@arcetri.astro.it],
;                     Serge  Correia   (OAA) [correia@arcetri.astro.it]:
;    modifications  : for version 2.0,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 2.0 (CAOS).
;                   : for version 3.0,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -partial diff. piston correction now taken into account.
;                   : for version 4.0,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -no more use of the common variable "calibration" and
;                     the tag "calib" (structure "info") for version 4.0 of
;                     the whole CAOS Software System.
;                   : for version 5.1,
;                     Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr],
;                     Olivier Lardiere (LISE) [lardiere@obs-hp.fr]:
;                    -densification feature added (for modelling the
;                     "densified pupil" case).
;                   : for version 7.0,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
;;;;;;;;;;;;;;;
; module code ;
;;;;;;;;;;;;;;;
;
function ibc, in1_wfp_t, $ ; input structure
              in2_wfp_t, $ ; input structure
              out_wfp_t, $ ; output structure
              par,       $ ; parameters from ibc_gui
              INIT=init    ; initialization structure

; CAOS global common block
common caos_block, tot_iter, this_iter

; initialization of the error code: set to "no error" as default
error = !caos_error.ok

; module's actions
if (this_iter eq 0) then begin
   ; initialisation section
   error = ibc_init(in1_wfp_t, in2_wfp_t, out_wfp_t, par, INIT=init)
endif else begin
   ; run section
   error = ibc_prog(in1_wfp_t, in2_wfp_t, out_wfp_t, par, INIT=init)
endelse

; back to calling program.
return, error                   ; back to calling program.
end