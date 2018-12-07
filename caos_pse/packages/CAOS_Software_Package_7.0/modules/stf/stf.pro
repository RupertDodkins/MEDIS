; $Id: stf.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    stf
;
; ROUTINE'S PURPOSE:
;    stf manages the simulation for the STructure Function calculation (STF)
;    module.
;
; MODULE'S PURPOSE:
;    STF computes the theoretical structure function from
;    the input parameters r0 and L0, and the simulated one from the
;    input wavefronts, updating it at each iteration of the
;    simulation.
;
; CATEGORY:
;    main module's routine
;
; CALLING SEQUENCE:
;    error = stf(inp_wfp_t, out_stf_t, par, INIT=init)
;
; INPUT:
;    inp_wfp:  structure of type wfp_t
;
; KEYWORD PARAMETERS:
;    INIT: ...
;
; OUTPUTS:
;    error: long scalar (error code).
;
; COMMON BLOCKS:
;    none.
;
; SIDE EFFECTS:
;    none.
;
; RESTRICTIONS:
;    The simulated structure is performed only along the x- and the
;    y-axis of the pupil, and then averaged.
;
; PROCEDURE:
;    none.
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: july 1998,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : december 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 2.0 (CAOS).
;                   : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -use of variable "calibration" eliminited for version 4.0
;                     of the whole CAOS Software System.
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
; MODULE MODIFICATION HISTORY:
;    module written : version 1.0,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : version 2.0,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 2.0 (CAOS).
;                   : for version 4.0,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -no more use of the common variable "calibration" and
;                     the tag "calib" (structure "info") for version 4.0 of
;                     the whole CAOS Software System.
;                   : for version 7.0,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted..
;-
;
function stf, inp_wfp_t, $
              out_stf_t, $
              par,       $
              INIT=init

common caos_block, tot_iter, this_iter

; initialization of the error code
error = !caos_error.ok

; module's actions

if this_iter eq 0 then begin
   ; initialisation section
   error = stf_init(inp_wfp_t, out_stf_t, par, INIT=init)
endif else begin
   ; run section
   error = stf_prog(inp_wfp_t, out_stf_t, par, INIT=init)
endelse

return, error                   ; back to calling program.
end