; $Id: wfa_prog.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;       wfa_prog
;
; PURPOSE:
;       wfa_prog represents the scientific algorithm for the WaveFront Adding 
;       (WFA) module.
;
; CATEGORY:
;       scientific program
;
; CALLING SEQUENCE:
;       err = wfa_prog(inp_wfp_t1, inp_wfp_t2, out_wfp_t, par)
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.:
;       see module help for a detailed description. 
;
; MODIFICATION HISTORY:
;       program written: April 1999,
;                        B. Femenia   (OAA) [bfemenia@arcetri.astro.it]
;
;       modifications  : Dec 1999,
;                        Bruno Femenia (OAA)  [bfemenia@arcetri.astro.it]
;                       -adapted to version 2.0 (CAOS code).
;                      : april 2015,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]
;                       -2d input data status testing debugged (ds1>ds2).
;                      : may 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;-
;
FUNCTION wfa_prog, inp_wfp_t1, inp_wfp_t2, out_wfp_t, par

error= !caos_error.ok                   ;Init error code: no error as default


;TESTING DATA_STATUS OF INPUTS
;=============================

ds1 = inp_wfp_t1.data_status

CASE ds1 OF
    !caos_data.not_valid: MESSAGE,'First wfp_t cannot be not_valid.'
    !caos_data.wait     : MESSAGE,'First wfp_t data cannot be wait.'
    !caos_data.valid    : ds1= ds1
    ELSE                : MESSAGE,'First wfp_t has an invalid data status.'
ENDCASE


ds2 = inp_wfp_t2.data_status

CASE ds2 OF
    !caos_data.not_valid: MESSAGE,'Second wfp_t cannot be not_valid.'
    !caos_data.wait     : MESSAGE,'Second wfp_t data cannot be wait.'
    !caos_data.valid    : ds2= ds2
    ELSE                : MESSAGE,'Second wfp_t has an invalid data status.'
ENDCASE


; COMBINE WAVEFRONTS AS SPECIFIED BY par.wb AND par.wt
;=====================================================

IF inp_wfp_t1.correction THEN BEGIN             ; 1st input is a correction
   out_wfp_t = inp_wfp_t2                       ; 2nd input: object information
ENDIF ELSE BEGIN                                ; 2nd input is a correction  
   out_wfp_t = inp_wfp_t1                       ; 1st input: object information
endelse

out_wfp_t.screen = inp_wfp_t1.screen*par.wb + inp_wfp_t2.screen*par.wt 

RETURN, error
END