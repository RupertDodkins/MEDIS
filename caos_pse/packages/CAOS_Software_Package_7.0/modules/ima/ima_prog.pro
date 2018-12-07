; $Id: ima_prog.pro,v 7.0 2016/04/29 marcel.carbillet$
;+
; NAME:
;       ima_prog
;
; PURPOSE:
;       ima_prog represents the scientific algorithm for the IMage Adding 
;       (IMA) module.
;
; CATEGORY:
;       scientific program
;
; CALLING SEQUENCE:
;       err = ima_prog(inp_img_t1, inp_img_t2, out_img_t, par)
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.:
;       see module help for a detailed description. 
;
; MODIFICATION HISTORY:
;       program written: september 2003,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;       modifications  : april 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;-
;
FUNCTION ima_prog, inp_img_t1, inp_img_t2, out_img_t, par

error= !caos_error.ok                   ;Init error code: no error as default

;TESTING DATA_STATUS OF INPUTS
;=============================
ds1 = inp_img_t1.data_status

CASE ds1 OF
    !caos_data.not_valid: MESSAGE,'First img_t cannot be not_valid.'
    !caos_data.wait     : MESSAGE,'First img_t data cannot be wait.'
    !caos_data.valid    : ds1= ds1
    ELSE                : MESSAGE,'First img_t has an invalid data status.'
ENDCASE

ds2 = inp_img_t2.data_status

CASE ds1 OF
    !caos_data.not_valid: MESSAGE,'Second img_t cannot be not_valid.'
    !caos_data.wait     : MESSAGE,'Second img_t data cannot be wait.'
    !caos_data.valid    : ds2= ds2
    ELSE                : MESSAGE,'Second img_t has an invalid data status.'
ENDCASE

; COMBINE IMAGES AS SPECIFIED BY par.wb AND par.wt
;=================================================

out_img_t.image = inp_img_t1.image*par.wb + inp_img_t2.image*par.wt

RETURN, error
END