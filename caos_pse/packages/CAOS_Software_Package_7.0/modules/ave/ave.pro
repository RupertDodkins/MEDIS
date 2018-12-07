; $Id: ave.pro,v 7.0 2016/04/27 marcel.carbillet$
;+
; NAME:
;       ave
;
; ROUTINE'S PURPOSE:
;       AVE manages the simulation for the signals AVEraging (AVE) module,
;       that is:
;       1-call the module's initialisation routine ave_init at the first
;         iteration of the simulation project
;       2-call the module's program routine ave_prog otherwise.
;
; MODULE'S PURPOSE:
;       AVE receives two vectors of measures (signals) as inputs and returns their
;       averaging.
;
; CATEGORY:
;       main module's routine
;
; CALLING SEQUENCE:
;       err = ave(inp_mes_t, out_mes_t, par)
;
; OUTPUT:
;       error:long scalar (error code, see !caos_error var in caos_init.pro).
;
; INPUTS:
;       inp_mes_t:incoming measures (signals) vector. (Bottom input in Application builder)
;
;       par      :parameters structure from ave_gui. In addition to the usual
;                 tags associated with the overall management of the program,
;                 it contains the following tags:
;
;                 par.nstars: nb of stars from which signals are averaged.
;
; INCLUDED OUTPUTS:
;       out_mes_t :output vector of measures (signals).
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
;
; CALLED NON-IDL FUNCTIONS:
;       none.
;
; MODIFICATION HISTORY:
;       program written: april 2008,
;                        Marcel Carbillet (Fizeau) [marcel.carbillet@unice.fr].
;       modifications  : april 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
FUNCTION ave, inp_mes_t,  $ ; input structure 
              out_mes_t , $ ; output structure
              par           ; parameters from ave_gui

COMMON caos_block, tot_iter, this_iter

error = !caos_error.ok                                      ; Init error code: no error as default

IF (this_iter EQ 0) THEN BEGIN                              ; INITIALIZATION 
   error = ave_init(inp_mes_t, out_mes_t, par)
ENDIF ELSE BEGIN                                            ; NORMAL RUNNING
   error = ave_prog(inp_mes_t, out_mes_t, par)
ENDELSE 

RETURN, error
END