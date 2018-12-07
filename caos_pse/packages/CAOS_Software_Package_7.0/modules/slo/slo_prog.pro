; $Id: slo_prog.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    slo_prog
;
; PURPOSE:
;    slo_prog represents the program routine for the slotroiding computation
;    (slo) module.
;    (see slo.pro's header --or file caos_help.html-- for details about the
;    module itself).
;
; CATEGORY:
;    module's program routine
;
; CALLING SEQUENCE:
;    error = slo_prog(inp_mim_t, $
;                     out_mes_t, $
;                     par,       $
;                     INIT=init  )
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.:
;    see module help for a detailed description.
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: june 2001,
;                     Christophe Verinaud (OAA) [verinaud@arcetri.astro.it].
;    modifications  : february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:    
;                    -cleaned from very old useless commented stuff.
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;-
;
function slo_prog, inp_mim_t, $
                   out_mes_t, $
                   par,       $
                   INIT=init

; error code initialization
error = !caos_error.ok

ds1 = inp_mim_t.data_status

if ds1 eq !caos_data.not_valid then message,'the 1st input cannot be not_valid.'

if ds1 eq !caos_data.wait then begin
   out_mes_t.data_status = !caos_data.wait
   return, error
endif

if ds1 eq !caos_data.valid then begin

   error = slope(inp_mim_t, meas,par.algo_type)
   IF error NE 0 THEN return, error

   pointer = where(meas EQ -1000, counts)
   IF counts NE 0 THEN meas[pointer] = init.ref_mes[pointer]
   ; the measurements where the flux is too low are set to the calibration
   ; meas.

   meas = temporary(meas) - init.ref_mes

   out_mes_t.data_status = !caos_data.valid
   out_mes_t.meas = meas

   return, error

endif

message, 'the 1st output has an invalid data status'

return, error
end