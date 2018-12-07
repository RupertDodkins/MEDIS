; $Id: rec_prog.pro,v 7.0 2016/05/19 marcel.carbillet$
;+
; NAME:
;    rec_prog
;
; PURPOSE:
;    rec_prog represents the program routine for the wavefront REConstruction
;    (REC) module.
;    (see rec.pro's header --or file caos_help.html-- for details about the
;    module itself).
;
; CATEGORY:
;    module's program routine
;
; CALLING SEQUENCE:
;    error = rec(inp_mes_t, $
;                out_com_t, $
;                par,       $
;                INIT=init  )
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.:
;    see module help for a detailed description.
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: june 2002,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -atmosphere-type output eliminated (useless wrt command-type
;                     output + use of new module DMC).
;                    -module's name from RCC to REC (eliminating old module REC).
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;-
;
function rec_prog, inp_mes_t, $ ; measures from the GS
                   out_com_t, $ ; output
                   par,       $ ; parameters
                   INIT=init    ; intialisation structure

; error code initialization
error = !caos_error.ok

; consider input status before updating output structure
ds1 = inp_mes_t.data_status

if ds1 eq !caos_data.not_valid then message, 'the input cannot be "not_valid".'

if ds1 eq !caos_data.wait then out_com_t.data_status = !caos_data.wait

if ds1 eq !caos_data.valid then begin
   ; measurements
   mis = inp_mes_t.meas
   ; performing reconstruction
   init.z_rec = (SVSOL(init.u, init.w, init.v, mis))[0:n_elements(init.z_rec)-1]
   ; updating com_t output structure
   nz0=0 & nz1=init.n_modes
   out_com_t.command = init.z_rec[nz0:nz1-1]
   out_com_t.data_status = !caos_data.valid
endif

return, error
end