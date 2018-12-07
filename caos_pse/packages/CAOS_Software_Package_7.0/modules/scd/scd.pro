; $Id: scd.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    scd
;
; ROUTINE'S PURPOSE:
;    scd manages the simulation for the Save Calibration Data (SCD) module,
;    that is:
;       1-call the module's initialisation routine scd_init at the first
;         iteration of the simulation project,
;       2-call the module's program routine scd_prog otherwise.
;
; MODULE'S PURPOSE:
;
; CATEGORY:
;    main module's routine
;
; CALLING SEQUENCE:
;    error = scd(inp_mes_t, $ ; mes_t input structure
;                inp_atm_t, $ ; atm_t input structure
;                par,       $ ; parameter structure
;                INIT=init  ) ; initialisation data structure
;
; OUTPUT:
;    error: long scalar (error code, see !caos_error var in caos_init.pro).
;
; INPUTS:
;    inp_atm_t: structure of type atm_t.
;    inp_zzz_t: structure of type mes_t.
;    par      : parameters structure.
;
; INCLUDED OUTPUTS:
;    none.
;
; KEYWORD PARAMETERS:
;    INIT: initialisation data structure.
;
; COMMON BLOCKS:
;    common caos_block, tot_iter, this_iter
;
;    tot_iter   : total number of iteration during the simulation run.
;    this_iter  : current iteration number.
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
;    routine written: june 2002,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;
;    modifications  : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -use of variable "calibration" eliminited for version 4.0
;                     of the whole CAOS Software System.
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
; MODULE MODIFICATION HISTORY:
;    module written : Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;
;    modifications  : for version 4.0,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -no more use of the common variable "calibration" and
;                     the tag "calib" (structure "info") for version 4.0 of
;                     the whole CAOS Software System.
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
function scd, inp_mes_t,   $ ; mes_t input structure
              inp_atm_t,   $ ; atm_t input structure
              par,         $ ; SCD parameters structure
              INIT=init      ; SCD initialization structure

; CAOS global common block
common caos_block, tot_iter, this_iter

; error code initialisation
error = !caos_error.ok

; module's actions
if (this_iter eq 0) then begin
   ; initialisation section
   error = scd_init(inp_mes_t, inp_atm_t, par, INIT=init)
endif else begin
   ; run section
   error = scd_prog(inp_mes_t, inp_atm_t, par, INIT=init)
endelse

; back to calling program.
return, error
end