; $Id: ssc_prog.pro, Soft.Pack.CAOS v 7.0 2012/02/23 marcel.carbillet $
;+
; NAME:
;    ssc_prog
;
; PURPOSE:
;    ssc_prog represents the program routine for the State-Space Control
;    (SSC) module, that is:
;
;**
;**  DESCRIBE HERE WHAT KIND OF OPERATIONS THE ROUTINE XXX_PROG PERFORMS,
;**  (POSSIBLY IN FUNCTION OF THE INPUTS DATA STATUS -- valid, not_valid,
;**  wait -- AND THE FACT THAT THEY WERE DEFINED AS OPTIONAL OR NOT IN
;**  XXX_INFO).
;**
;
;    (see ssc.pro's header --or file caos_help.html-- for details about the
;    module itself).
;
; CATEGORY:
;    module's program routine
;
; CALLING SEQUENCE:
;    error = ssc_prog(inp_mes_t, $ ; mes_t input structure
;                     out_com_t, $ ; com_t output structure
;                     par,       $ ; parameters structure
;                     INIT=init  $ ; initialisation data structure
;                     ) 
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.:
;    see module help for a detailed description. 
;
; ROUTINE MODIFICATION HISTORY: 
;    routine written: february 2012,
;                     Marcel Carbillet (Lagrange) [emarcel.carbillet@unice.fr].
;    modifications  : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;-
; 
function ssc_prog, inp_mes_t, $ ; input struc.
                   out_com_t, $ ; output struc.
                   par,       $ ; SSC parameters structure
                   INIT=init    ; SSC initialization data structure

; CAOS global common block
common caos_block, tot_iter, this_iter

; error code initialization
error = !caos_error.ok

ds1 = inp_mes_t.data_status

; the input is not optional
if ds1 eq !caos_data.not_valid then message, $
   'the 1st input cannot have a not_valid data status.'

if ds1 eq !caos_data.valid then begin
   out_com_t.data_status = !caos_data.valid
   out_com_t.command[0:init.Ncomm-1] = init.C##init.x
   init.x = init.A##init.x + init.B##inp_mes_t.meas
      
   ; just to keep history of what is done:
   init.xx[*,this_iter-1]=init.x
   init.yy[*,this_iter-1]=inp_mes_t.meas
   init.uu[*,this_iter-1]=out_com_t.command
endif

return, error
end