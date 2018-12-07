; $Id: bsp_prog.pro,v 7.0 2016/04/27 marcel.carbillet $
;
;+
; NAME:
;       bsp_prog
;
; PURPOSE:
;       bsp_prog represents the scientific algorithm for the Beam SPliter (BSP)
;       module.
;
; CATEGORY:
;       scientific program
;
; CALLING SEQUENCE:
;       err = bsp_prog(inp_wfp_t, out_wfp_t1, out_wfp_t2, par)
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.:
;       see module help for a detailed description. 
;
; MODIFICATION HISTORY:
;       program written: March 1999,
;                        B. Femenia   (OAA) [bfemenia@arcetri.astro.it]
;
;       modifications  : Nov 1999,
;                        Bruno Femenia (OAA)  [bfemenia@arcetri.astro.it]
;                       -adapted to version 2.0 (CAOS code)
;                      : april 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
;;;;;;;;;;;;;;;
; module code ;
;;;;;;;;;;;;;;;
;
FUNCTION bsp_prog, inp_wfp_t, out_wfp_t1, out_wfp_t2, par

error = !caos_error.ok                  ;Init error code: no error as default

;TESTING DATA_STATUS OF INPUTS
;=============================

ds1 = inp_wfp_t.data_status

CASE ds1 OF
    !caos_data.not_valid: MESSAGE,'Input wfp_t cannot be not_valid.'
    !caos_data.wait     : MESSAGE,'Input wfp_t data cannot be wait.'
    !caos_data.valid    : ds1= ds1
    ELSE                : MESSAGE,'Input wfp_t has an invalid data status.'
ENDCASE

; SPLIT INCIDENT INTENSITY AS SPCIFIED BY par.frac
;=================================================

out_wfp_t1           = inp_wfp_t
out_wfp_t1.n_phot    = inp_wfp_t.n_phot*par.frac
out_wfp_t1.background= inp_wfp_t.background*par.frac

out_wfp_t2           = inp_wfp_t
out_wfp_t2.n_phot    = inp_wfp_t.n_phot*(1.-par.frac)
out_wfp_t2.background= inp_wfp_t.background*(1.-par.frac)

RETURN, error
END