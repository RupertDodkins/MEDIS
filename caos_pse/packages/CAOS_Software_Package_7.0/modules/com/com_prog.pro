; $Id: com_prog.pro,v 7.0 2016/04/27 marcel.carbillet $
;+
; NAME:
;    com_prog
;
; PURPOSE:
;    com_prog represents the program routine for the COMbine measurements
;    (COM) module, that is combining the measurements of two input structures
;    of type 'mes_t' --> usefull when doing multiconjugate adaptive optics.
;
;    (see com.pro's header --or file caos_help.html-- for details about the
;    module itself).
;
; CATEGORY:
;    module's program routine
;
; CALLING SEQUENCE:
;    error = com_prog(inp_mes_t1, $ ; mes_t input structure
;                     inp_mes_t2, $ ; mes_t input structure
;                     out_mes_t,  $ ; mes_t output structure
;                     par         $ ; parameters structure
;                     ) 
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.:
;    see module help for a detailed description. 
;
; ROUTINE MODIFICATION HISTORY: 
;    routine written: february 2001,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to new CAOS system (4.0) and building of
;                     Software Package MAOS 1.0.
;                   : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
;-
; 
function com_prog, inp_mes_t1, $ ; 1st input struc.
                   inp_mes_t2, $ ; 2nd input struc.
                   out_mes_t,  $ ; output struc.
                   par           ; COM parameters structure

; CAOS global common block
common caos_block, tot_iter, this_iter

; error code initialization
error = !caos_error.ok

ds1 = inp_mes_t1.data_status
ds2 = inp_mes_t2.data_status

; the 1st input is not optional
if ds1 eq !caos_data.not_valid then message, $
   'the 1st input cannot have a not_valid data status.'

; the 2nd input is not optional
if ds2 eq !caos_data.not_valid then message, $
   'the 2nd input cannot have a not_valid data status.'

; combine the measurements
out_mes_t.meas        = [inp_mes_t1.meas, inp_mes_t2.meas]
out_mes_t.data_status = !caos_data.valid

return, error
end