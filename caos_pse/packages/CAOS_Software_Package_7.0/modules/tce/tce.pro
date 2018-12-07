; $Id: tce.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    tce
;
; PURPOSE:
;    TCE executes the simulation for the Tip-tilt CEntroid (TCE) module.
;    Based on the choice of detector selected in this module's GUI, namely a
;    Quad-cell or a CCD, TCE will apply the Quad-cell calculus or the
;    barycenter calculus on the image formed over the chosen detector (and
;    obtained with a Tip-Tilt sensor module) to estimate the overall wavefront
;    tip-tilt. Then TCE outputs a out_com_t struc. where the estimated tip-tilt 
;    angles are passed to whatever module is next in the simulation.
;
; CATEGORY:
;    Module
;
; CALLING SEQUENCE:
;    error = tce(          $
;               inp_img_t, $  ; img_t input  structure
;               out_com_t, $  ; com_t output structure
;               par,       $  ; parameters structure
;               INIT=init  $  ; initialisation structure
;               )
;
; OUTPUT:
;    error: long scalar (error code, see !caos_error var in caos_init.pro).
;
; INPUTS:
;    inp_img_t: structure of type img_t. Structure containing the IMG
;               IMAGE, info on CCD used (#pixels, pixel size, covered
;               field, ...)
;    par      : parameters structure from tce_gui. At time of writing this
;               version it was unnecessary to pass any science parameter via
;               GUI, but it is left for completeness. Therefore, in this
;               version the par structure associated to TCE only contains
;               tags associated to the management of program, but no
;               parameter relevant to scientific program.
;
; INCLUDED OUTPUTS:
;    out_com_t: structure of type com_t telling the Tip-Tilt Mirror how to
;               act in order to correct a measured TipTilt. Tilt angles are
;               calculated  in radians.
;
; KEYWORD PARAMETERS:
;    INIT     : named variable undefined or containing a scalar when TCE is
;               called for the first time. As output the named variable will
;               contain a structure of the initialization data. For the
;               following calls of TCE, the keyword INIT has to be set to the
;               structure returned by the first call.
;
; COMMON BLOCKS:
;    common caos_block, tot_iter, this_iter
;
;    tot_iter   : int scalar. Total number of iteration during the
;                 simulation run.
;    this_iter  : int scalar. Number of the current iteration. It is
;                 defined only while status eq !caos_status.run.
;                 (this_iter >= 1).
;
; SIDE EFFECTS:
;    None.
;
; RESTRICTIONS:
;    None.
;
; CALLED NON-IDL FUNCTIONS:
;    None.
;
; EXAMPLE:
;    write here an example!
;
; MODIFICATION HISTORY:
;    program written: Feb 1999, 
;                     B. Femenia (OAA) [bfemenia@arcetri.astro.it]
;                    -written to match general style and requirements on
;                     how to manage initialization process, calibration
;                     procedure and time management according to  released
;                     templates on Feb 1999.
;                   : Nov 1999,
;                     B. Femenia   (OAA) [bfemenia@arcetri.astro.it]
;                    -adapted to new version CAOS (v 2.0).
;                   : Jan 2000,
;                     B. Femenia   (OAA) [bfemenia@arcetri.astro.it]
;                    -TCE now accepts inputs coming from IMG module whose
;                     output structure is now of type img_t.
;                   : April 2001,
;                     B. Femenia   (OAA) [bfemenia@arcetri.astro.it]
;                    -TCE_GUI considers a new field where Q-cell calibration
;                     constant is fed.
;                   : february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -common variable "calibration" eliminated.
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;-
;
FUNCTION tce, inp_img_t    , $  ; input  structure of type img_t
              out_com_t    , $  ; output structure of type com_t
              par          , $  ; parameters from tce_gui
              INIT=init         ; initialization structure

COMMON caos_block, tot_iter, this_iter


error = !caos_error.ok          ; Init error code: no error as default


IF (this_iter EQ 0) THEN BEGIN  ; INITIALIZATION 
                                ;===============
   error = tce_init(inp_img_t,out_com_t,par,INIT= init)

ENDIF ELSE BEGIN                ; NORMAL RUNNING: TCE does not consider
                                ;================ integration nor delay
   error = tce_prog(inp_img_t, out_com_t,par,INIT=init)
   
ENDELSE 

RETURN, error                   ; back to calling program.

END