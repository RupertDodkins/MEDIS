; $Id: iws_prog.pro,v 7.0 2016/04/29 marcel.carbillet $
;+
; NAME:
;       iws_prog
;
; PURPOSE:
;       iws_prog represents the scientific algorithm for the Ideal Wavefront
;       Sensing (and reconstruction) (IWS) module.
;
; CATEGORY:
;       scientific program
;
; CALLING SEQUENCE:
;       err = iws_prog(inp_wfp_t, out_wfp_t, par, INIT=init)
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.:
;       see module help for a detailed description. 
;
; MODIFICATION HISTORY:
;       program written: april 2015,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr].
;
;       modifications  : april 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
FUNCTION iws_prog, inp_wfp_t, out_wfp_t, par, INIT=init

error= !caos_error.ok                   ;Init error code: no error as default


;TESTING DATA_STATUS OF INPUTS
;=============================

ds1 = inp_wfp_t.data_status

CASE ds1 OF
    !caos_data.not_valid: MESSAGE,'wfp_t cannot be not_valid.'
    !caos_data.wait     : MESSAGE,'wfp_t data cannot be wait.'
    !caos_data.valid    : ds1= ds1
    ELSE                : MESSAGE,'wfp_t has an invalid data status.'
ENDCASE

; Wavefront ideal sensing and reconsturction
;===========================================

wf = inp_wfp_t.screen*inp_wfp_t.pupil
wf[init.idx] -= mean(wf[init.idx])

coeff = wf2modes(wf, init.DEF, /SVD, MAT=init.w2m)
rec = 0. & for i=0L, init.n_DEF-1L do rec += coeff[i]*init.DEF[*,*,i]

out_wfp_t.screen = inp_wfp_t.screen - par.part_corr*rec 

RETURN, error
END