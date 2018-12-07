; $Id: iws.pro,v 7.0 2016/04/29 marcel.carbillet $
;+
; NAME:
;       iws
;
; ROUTINE'S PURPOSE:
;       IWS manages the simulation for the Ideal Wavefront Sensing (and
;       reconstruction) (IWS) module, that is:
;       1-call the module's initialisation routine iws_init at the first
;         iteration of the simulation project
;       2-call the module's program routine iws_prog otherwise.
;
; MODULE'S PURPOSE:
;       IWS receives a wavefront in input and returns a corrected version of it,
;       considering fitting error only.
;
; CATEGORY:
;       main module's routine
;
; CALLING SEQUENCE:
;       err = iws(inp_wfp_t, out_wfp_t, par, INIT=init)
;
; OUTPUT:
;       error:long scalar (error code, see !caos_error var in caos_init.pro).
;
; INPUTS:
;       inp_wfp_t: input wavefront.
;
;       par      : parameters structure from iws_gui. In addition to the usual
;                  tags associated with the overall management of the program,
;                  it contains the following tags:
;
;                  par.radial_order: Zernike radial order desired (correction).
;                  par.part_corr: partial correction desired (on Zernike modes
;                  corrected).
;
; INCLUDED OUTPUTS:
;       out_wfp_t :output corrected wavefront.
;
; KEYWORD PARAMETERS:
;       None.      
;
; COMMON BLOCKS:
;       common caos_block, tot_iter, this_iter
;
;       tot_iter   : total number of iteration during the simulation run.
;       this_iter  : current iteration number.
;
; SIDE EFFECTS:
;       None.
;
; RESTRICTIONS:
;       Fitting error only.
;
; CALLED NON-IDL FUNCTIONS:
;       none.
;
; MODIFICATION HISTORY:
;       program written: april 2015,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr].
;
;       modifications  : april 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;
; MODULE MODIFICATION HISTORY:
;       module written : Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr].
;
;       modifications  : for verison 7.0,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
FUNCTION iws, inp_wfp_t, $ ; input structure 
              out_wfp_t, $ ; output structure
              par,       $ ; parameters from iws_gui
              INIT=init


COMMON caos_block, tot_iter, this_iter

error = !caos_error.ok                                      ; Init error code: no error as default


IF (this_iter EQ 0) THEN BEGIN                              ; INITIALIZATION 
                                                            ;===============
   error = iws_init(inp_wfp_t, out_wfp_t, par, INIT=init)

ENDIF ELSE BEGIN                                            ; NORMAL RUNNING: IWS does not consider
                                                            ;===============  integration nor delay
   error = iws_prog(inp_wfp_t, out_wfp_t, par, INIT=init)

ENDELSE 

RETURN, error
END