; $Id: ave_prog.pro,v 7.0 2016/04/27 marcel.carbillet$
;+
; NAME:
;       ave_prog
;
; PURPOSE:
;       ave_prog represents the scientific algorithm for the signals Averaging 
;       (AVE) module.
;
; CATEGORY:
;       scientific program
;
; CALLING SEQUENCE:
;       err = ave_prog(inp_mes_t, out_mes_t, par)
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.:
;       see module help for a detailed description. 
;
; MODIFICATION HISTORY:
;       program written: april 2008,
;                        Marcel Carbillet (Fizeau) [marcel.carbillet@unice.fr],
;                        Brice Le Roux (OAMP-LAM) [brice.leroux@oamp.fr].
;       modifications  : april 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
FUNCTION ave_prog, inp_mes_t, out_mes_t, par

error= !caos_error.ok                   ;Init error code: no error as default

;TESTING DATA_STATUS OF INPUTS
;=============================
ds1 = inp_mes_t.data_status

CASE ds1 OF
    !caos_data.not_valid: MESSAGE,'mes_t input cannot be not_valid.'
    !caos_data.wait     : MESSAGE,'mes_t input data cannot be wait.'
    !caos_data.valid    : ds1= ds1
    ELSE                : MESSAGE,'mes_t input has an invalid data status.'
ENDCASE

; AVERAGE SIGNALS
;================
nmod=n_elements(out_mes_t.meas)
dummy=fltarr(nmod)
for i=0, par.nstars-1L do dummy+=inp_mes_t.meas[i*nmod:(i+1L)*nmod-1L]/par.nstars
out_mes_t.meas=dummy

RETURN, error
END