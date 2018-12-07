; $Id: bqc.pro,v 7.0 2016/04/27 marcel.carbillet $
;
;+
; NAME:
;       bqc
;
; PURPOSE:
;       BQC executes the simulation for the Barycenter/Quad-dell Centroid (BQC) module.
;       Based on the choice of detector selected in this module's GUI, namely a
;       Quad-cell or a CCD, BQC will apply the Quad-cell calculus or the
;       barycenter calculus on the image formed over the chosen detector to estimate
;       the overall wavefront tip-tilt/loacal tilt on each subaperture. Then BQC outputs 
;       a out_mes_t structure where the estimated overall/local tip-tilt 
;       angles are passed to whatever module is next in the simulation.
;
; CATEGORY:
;       Module
;
; CALLING SEQUENCE:
;       error = bqc(inp_mim_t, $ ; mim_t input  structure 
;                   out_mes_t, $ ; mes_t ouptut structure
;                   par      , $ ; parameters   structure
;                   INIT=init  ) ; initialisation data structure
;
; OUTPUT:
;       error: long scalar (error code, see !caos_error var in caos_init.pro).
;
; INPUTS:
;       inp_mim_t: structure of type mim_t. Structure containing the SWS
;                  IMAGE, info on CCD used (#pixels, pixel size, covered
;                  field, ...)
;       par      : parameters structure from bqc_gui. 
;
; INCLUDED OUTPUTS:
;       out_mes_t: structure of type mes_t containing the vector of the sensor
;                  measurement (here, the x-slopes followed by the y-slopes) as well as
;                  some info needed by the reconstructor..
;
; KEYWORD PARAMETERS:
;       INIT     : named variable undefined or containing a scalar when BQC is
;                  called for the first time. As output the named variable will
;                  contain a structure of the initialization data. For the
;                  following calls of BQC, the keyword INIT has to be set to the
;                  structure returned by the first call.
;
; COMMON BLOCKS:
;       common caos_block, tot_iter, this_iter
;
;       tot_iter   : int scalar. Total number of iteration during the
;                    simulation run.
;       this_iter  : int scalar. Number of the current iteration. It is
;                    defined only while status eq !caos_status.run.
;                    (this_iter >= 1).
;
; SIDE EFFECTS:
;       None.
;
; RESTRICTIONS:
;       None.
;
; CALLED NON-IDL FUNCTIONS:
;       None.
;
; EXAMPLE:
;       write here an example!
;
; ROUTINE MODIFICATION HISTORY:
;       program written: Dec 2003, 
;                        B. Femenia (GTC) [bfemenia@ll.iac.es].
;       modifications  : december 2003,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -use of variable "calibration" eliminited for compatibility
;                        with version 4.0+ of the whole system CAOS.
;
; MODULE MODIFICATION HISTORY:
;       module written : Dec 2003,
;                        B. Femenia (GTC) [bfemenia@ll.iac.es].
;
;       modifications  : december 2003,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -for version 4.0+ of CAOS structure.
;                        no more use of the common variable "calibration" and
;                        the tag "calib" (structure "info") from version 4.0 of
;                        the whole system CAOS.
;
;                        December 2003,
;                        Bruno Femenia (GTC) [bfemenia@ll.iac.es]
;                       -this module does not require INIT structure.
;
;                        September 2004,
;                        Bruno Femenia (GTC) [bfemenia@ll.iac.es]
;                       -this module does require INIT structure.
;
;                        September 2004,
;                        Bruno Femenia (GTC) [bfemenia@ll.iac.es]
;                       -adapted to version 5.0 of the Software Package CAOS.
;
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
FUNCTION bqc, inp_mim_t, $  ;; input  structure of type mim_t
              out_mes_t, $  ;; output structure of type mes_t
              par,       $  ;; parameters structure from bqc_gui
              INIT=init     ;; initialisation data structure


   COMMON caos_block, tot_iter, this_iter


   error = !caos_error.ok                                   ;Init error code: no error as default


   IF (this_iter EQ 0) THEN                                  $ ;INITIALIZATION 
     error = bqc_init(inp_mim_t, out_mes_t, par, INIT=init)  $ ;==============
   ELSE                                                      $
     error = bqc_prog(inp_mim_t, out_mes_t, par, INIT=init)    ;NORMAL RUNNING: BQC does not consider
                                                               ;=============== integration nor delay
  
   RETURN, error                                            ;Back to calling program.

END