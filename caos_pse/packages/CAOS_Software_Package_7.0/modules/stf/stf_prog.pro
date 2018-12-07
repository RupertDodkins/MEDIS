; $Id: stf_prog.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    stf_prog
;
; PURPOSE:
;    stf_prog represents the scientific algorithm for
;    STructure Function (STF) module.
;
; CATEGORY:
;    module's program routine
;
; CALLING SEQUENCE:
;    error = stf_prog(          $
;                    inp_wfp_t, $ ; wfp_t input structure
;                    out_stf_t, $ ; stf_t output structure
;                    par,       $ ; parameters structure
;                    INIT=init  $ ; initialisation structure
;                    ) 
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.:
;    see module help for a detailed description. 
;
; ROUTINE MODIFICATION HISTORY: 
;    routine written: march 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : december 1999-may 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 2.0 (CAOS).
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;-
;
function stf_prog, inp_wfp_t, $
                   out_stf_t, $
                   par,       $
                   INIT=init

; initial stuff
error = !caos_error.ok

; routine's actions
ds1 = inp_wfp_t.data_status

if ds1 eq !caos_data.not_valid then message, 'the 1st input cannot be not_valid'

if ds1 eq !caos_data.valid then begin

   init.iter  = init.iter + 1
   screen     = inp_wfp_t.screen
   init.struc = ( init.struc*(init.iter-1)                 $
                 +stf_simu(screen,PUPIL=inp_wfp_t.pupil) ) $
               /init.iter

   ; update output structure
   out_stf_t.data_status = !caos_data.valid
   out_stf_t.struc       = init.struc            ; simulated structure function
   out_stf_t.iter        = init.iter             ; number of screens used

endif

; final stuff
return, error
end