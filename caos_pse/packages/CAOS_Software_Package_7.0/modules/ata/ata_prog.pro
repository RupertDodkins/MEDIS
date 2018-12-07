; $Id: ata_prog.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;       ata_prog
;
; PURPOSE:
;       ata_prog represents the scientific algorithm for the WaveFront Adding 
;       (ATA) module.
;
; CATEGORY:
;       scientific program
;
; CALLING SEQUENCE:
;       err = ata_prog(inp_atm_t1, inp_atm_t2, out_atm_t, par)
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.:
;       see module help for a detailed description. 
;
; MODIFICATION HISTORY:
;       program written: March 2001,
;                        Bruno Femenia (OAA)  [bfemenia@arcetri.astro.it]
;                      : april 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;-
;
FUNCTION ata_prog, inp_atm_t1, inp_atm_t2, out_atm_t, par, INIT=init

error= !caos_error.ok                   ;Init error code: no error as default


;TESTING DATA_STATUS OF INPUTS
;=============================

ds1 = inp_atm_t1.data_status

CASE ds1 OF
    !caos_data.not_valid: MESSAGE,'First atm_t cannot be not_valid.'
    !caos_data.wait     : MESSAGE,'First atm_t cannot be wait.'
    !caos_data.valid    : ds1=ds1
    ELSE                : MESSAGE,'First atm_t has an invalid data status.'
ENDCASE


ds2 = inp_atm_t2.data_status

CASE ds2 OF
    !caos_data.not_valid: MESSAGE,'Second atm_t cannot be not_valid.'
    !caos_data.wait     : ds2=ds2
    !caos_data.valid    : ds2=ds2
    ELSE                : MESSAGE,'Second atm_t has an invalid data status.'
ENDCASE


; COMBINE WAVEFRONTS AS SPECIFIED BY par.wb AND par.wt
;=====================================================
out_atm_t.screen = 0.   ;; Resetting phase screens to remove any memory!!

FOR i=0,N_ELEMENTS(init.atm1_to_atm)-1 DO BEGIN 
   idx = init.atm1_to_atm[i]
   out_atm_t.screen[*,*,idx] = out_atm_t.screen[*,*,idx] + par.wb*inp_atm_t1.screen[*,*,i]
ENDFOR 

FOR i=0,N_ELEMENTS(init.atm2_to_atm)-1 DO BEGIN 
   idx = init.atm2_to_atm[i]
   out_atm_t.screen[*,*,idx] = out_atm_t.screen[*,*,idx] + par.wt*inp_atm_t2.screen[*,*,i]
ENDFOR 

RETURN, error
END