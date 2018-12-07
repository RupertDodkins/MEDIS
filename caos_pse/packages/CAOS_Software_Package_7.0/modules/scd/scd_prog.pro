; $Id: scd_prog.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    scd_prog
;
; PURPOSE:
;    scd_prog represents the program routine for the Save Calibration Data
;    (SCD) module, that is:
;
;    (see scd.pro's header --or file caos_help.html-- for details about the
;    module itself).
;
; CATEGORY:
;    module's program routine
;
; CALLING SEQUENCE:
;    error = scd_prog(inp_mes_t, $ ; mes_t input structure
;                     inp_atm_t, $ ; atm_t input structure
;                     par,       $ ; parameters structure
;                     INIT=init  $ ; initialisation data structure
;                     ) 
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.:
;    see module help for a detailed description. 
;
; ROUTINE MODIFICATION HISTORY: 
;    routine written: june 2002,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;-
; 
function scd_prog, inp_mes_t, $ ; mes_t input struc.
                   inp_atm_t, $ ; atm_t input struc.
                   par,       $ ; SCD parameters structure
                   INIT=init    ; SCD initialization data structure

; CAOS global common block
common caos_block, tot_iter, this_iter

; error code initialization
error = !caos_error.ok

ds1 = inp_mes_t.data_status
ds2 = inp_atm_t.data_status

if ds1 eq !caos_data.not_valid then message, $
   'the 1st input cannot have a not_valid data status.'

if ds1 eq !caos_data.wait then message, $
   'the 1st input cannot have a wait data status.'

if ds2 eq !caos_data.not_valid then message, $
   'the 2nd input cannot have a not_valid data status.'

if ds2 eq !caos_data.wait then message, $
   'the 2nd input cannot have a not_valid data status.'

init.matint[this_iter-1, *]    = inp_mes_t.meas
init.mirdef[*, *, this_iter-1] = inp_atm_t.screen

if this_iter eq tot_iter then begin
   matint = init.matint
   def    = init.mirdef
   save, def   , FILE=par.mirdef_file, /VERBOSE
   save, matint, FILE=par.matint_file, /VERBOSE
endif

return, error
end