; $Id: ttm_prog.pro,v 7.0 2016/05/191 marcel.carbillet $
;+
; NAME:
;       ttm_prog
;
; PURPOSE:
;       ttm_prog represents the scientific algorithm for the 
;       Tip-Tilt Mirror (TTM) module.
;
; CATEGORY:
;       scientific program
;
; CALLING SEQUENCE:
;       err = ttm_prog(inp_wfp_t, inp_com_t, out_wfp_t1, out_wfp_t2, par)
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.:
;       see module help for a detailed description. 
;
; MODIFICATION HISTORY:
;       program written: Nov 1998,
;                        B. Femenia   (OAA) [bfemenia@arcetri.astro.it]
;                        M. Carbillet (OAA) [marcel@arcetri.astro.it]
;
;       modifications  : Feb 1999,
;                        B. Femenia (OAA) [bfemenia@arcetri.astro.it]
;                       -rewritten to match general style and requirements on
;                        how to manage initialization process, calibration
;                        procedure and time management according to  released
;                        templates on Feb 1999.
;                      : Jun 1999,
;                        B. Femenia (OAA) [bfemenia@arcetri.astro.it]
;                       -command to TTM contain correction in [arcsec].
;                      : Nov 1999,
;                        Bruno Femenia (OAA)  [bfemenia@arcetri.astro.it]
;                       -adapted to version 2.0 (CAOS code)
;                      : Dec 1999,
;                        B. Femenia   (OAA) [bfemenia@arcetri.astro.it]
;                       -a second output containing the CORRECTION is added
;                        in order to allow the use of COMBINER feature.
;                      : february 2003,
;                        Marcel Carbillet (2003) [marcel@arcetri.astro.it]:
;                       -correction commands are (finally!!) considered as negative
;                        (no more need of TFL for setting it before TTM).
;                      : may 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;-
;
;;;;;;;;;;;;;;;
; module code ;
;;;;;;;;;;;;;;;
;
FUNCTION ttm_prog, inp_wfp_t , $ ; input structure containing wavefront to be corrected.
                   inp_com_t , $ ; input structure containing commands to TTM.
                   out_wfp_t1, $ ; output structure: BOTTOM BOX =>  correction.
                   out_wfp_t2, $ ; output structure: TOP    BOX =>  input wavefront+correction
                   par       , $ ; parameters from ttm_gui
                   INIT= init    ; initialization structure

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


ds2 = inp_com_t.data_status

CASE ds2 OF
   !caos_data.valid: BEGIN                                         ;A NEW VALID COMMAND HAS ARRIVED =>
      dim=N_ELEMENTS(inp_wfp_t.screen[*,0])                        ; substract measured tip-tilt
      tip =REBIN(init.axis*inp_com_t.command[0],dim,dim)*4.848E-6  ;Tip command is in [arcsec]
      tilt=REBIN(init.axis*inp_com_t.command[1],dim,dim)*4.848E-6  ;Tilt command is in [arcsec]
      tilt=TRANSPOSE(tilt)
      init.tiptilt=inp_com_t.command                               ;Saving tiptilt in init structure.
   END

   !caos_data.wait: BEGIN                                          ;Mirror preserves position.
      dim= N_ELEMENTS(inp_wfp_t.screen[*,0])      
      tip= REBIN(init.axis*init.tiptilt[0],dim,dim)*4.848E-6
      tilt=REBIN(init.axis*init.tiptilt[1],dim,dim)*4.848E-6
      tilt=TRANSPOSE(tilt)
   END

   ELSE: BEGIN                                                     ;Mirror returns to flat position.
      tip = 0
      tilt= 0
   END

ENDCASE


; SUBSTRACT MIRROR'S TIP-TILT TO INCIDENT WAVEFRONT
;==================================================

out_wfp_t1            = inp_wfp_t                           ;Storing correction for a later
out_wfp_t1.screen     = -(tip+tilt)                         ; possible use with COMBINER.: BOTTOM BOX.       
out_wfp_t1.correction = 1B                                  ; this is a correcting wf

out_wfp_t2            = inp_wfp_t                           ;Add tiptilt introduced by
out_wfp_t2.screen     = inp_wfp_t.screen+out_wfp_t1.screen  ; tilt of TTM: UPPER BOX.
out_wfp_t2.correction = 0B                                  ; this is **NOT** a correcting wf

RETURN, error                                               ; back to calling program
END