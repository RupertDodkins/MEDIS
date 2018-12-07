; $Id: ttm.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;       ttm
;
; PURPOSE:
;       TTM executes the simulation for the Tip-Tilt Mirror (TTS) module.  This
;       module receives a wavefront and a command from a Tip-Tilt Sensor (TTS)
;       so that the mirror is tilted by a given ammount in order to substract to
;       the input wavefront the previously measured atmospheric-induced 
;       tip-tilt. At this stage, this module symply substracts a tilted plane to
;       a wavefront. This corresponds to an ideal Tip-Tilt Mirror since no
;       dynamic behaviour has been considered within the module. Nevertheless,
;       the user can simulate any dynamic behaviour with the TFL module.
;
; CATEGORY:
;       Module
;
; CALLING SEQUENCE:
;       err = ttm(inp_wfp_t, inp_com_t, out_wfp_t1, out_wfp_t2, par, INIT= init)
;
; OUTPUT:
;       error: long scalar (error code, see !caos_error var in caos_init.pro).
;
; INPUTS:
;       inp_wfp_t : structure of type wfp_t containing the incident wavefront on
;                   the mirror.
;       inp_com_t : structure of type com_t. This structure contains the set of
;                   commands sent by the reconstructor (i.e TCE) If undefined (at
;                   the first time), the commands are set to 0.
;       par       : parameters structure from ttm_gui. At time of writing this
;                   version it was unnecessary to pass any science parameter via
;                   GUI, but it is left for completeness. Therefore, in this
;                   version the par structure associated to TTM only contains
;                   tags associated to the management of program, but no
;                   parameter relevant to scientific program.
;
; INCLUDED OUTPUTS:
;       out_wfp_t1: structure of type wfp_t containing the original incident
;                   wavefront on the mirror but with a tilted plane substracted.
;
;       out_wfp_t2: struct of type wfp_t containing the correction (in this case
;                   a tilted plane) applied to incoming wavefront.
;
; KEYWORD PARAMETERS:
;       INIT     : named variable undefined or containing a scalar when ttm is
;                  called for the first time. As output the named variable will
;                  contain a structure of the initialization data. For the
;                  following calls of ttm, the keyword INIT has to be set to the
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
;       No dynamic behaviour considerations. PArticular behaviours due to the
;       dynamical characteristics of a real mirror can still be simulated
;       through proper design of filter response with TFL module.
;
; EXAMPLE:
;       Write here an example!
;
; ROUTINE MODIFICATION HISTORY:
;       program written: Nov 1998,
;                        B. Femenia   (OAA) [bfemenia@arcetri.astro.it]
;                        M. Carbillet (OAA) [marcel@arcetri.astro.it]
;       modifications  : january 2003,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -use of variable "calibration" eliminited for version 4.0
;                        of the whole CAOS Software System.
;                      : may 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;
; MODULE MODIFICATION HISTORY:
;       module written : Nov 1998,
;                        B. Femenia   (OAA) [bfemenia@arcetri.astro.it]
;                        M. Carbillet (OAA) [marcel@arcetri.astro.it]
;       modifications  : for version 1.0,
;                        B. Femenia (OAA) [bfemenia@arcetri.astro.it]
;                       -rewritten to match general style and requirements on
;                        how to manage initialization process, calibration
;                        procedure and time management according to released
;                        templates on Feb 1999.
;                      : for version 2.0,
;                        B. Femenia   (OAA) [bfemenia@arcetri.astro.it]
;                       -adapted to new version CAOS (v 2.0).
;                      : for version ?.? (1999),
;                        B. Femenia   (OAA) [bfemenia@arcetri.astro.it]
;                       -a second output containing the CORRECTION is added
;                        in order to allow the use of COMBINER feature.
;                      : for version 4.0,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -no more use of the common variable "calibration" and
;                        the tag "calib" (structure "info") for version 4.0 of
;                        the whole CAOS Software System.
;                      : for version 7.0,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted.
;-
;
FUNCTION ttm, inp_wfp_t , $ ; input structure 
              inp_com_t , $ ; input structure 
              out_wfp_t1, $ ; output structure: BOTTOM BOX =>  correction.
              out_wfp_t2, $ ; output structure: TOP    BOX =>  input wf+corr.
              par       , $ ; parameters from ttm_gui
              INIT= init    ; initialization structure

COMMON caos_block, tot_iter, this_iter

error = !caos_error.ok                                           ; Init error code: no error as default


IF (this_iter EQ 0) THEN BEGIN                                   ; INITIALIZATION 
                                                                 ;===============
   error = ttm_init(inp_wfp_t ,inp_com_t , $
                    out_wfp_t1,out_wfp_t2, $
                    par,INIT=init)

ENDIF ELSE BEGIN                                                 ; NORMAL RUNNING: TTM does not consider 
                                                                 ;===============  integration nor delay
   error = ttm_prog(inp_wfp_t ,inp_com_t , $
                    out_wfp_t1,out_wfp_t2, $
                    par,INIT=init)

ENDELSE 

RETURN, error
END