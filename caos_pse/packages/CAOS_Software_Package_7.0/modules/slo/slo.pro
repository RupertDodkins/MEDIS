; $Id: slo.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    slo
;
; ROUTINE'S PURPOSE:
;    slo manages the simulation for the slope computation (slo) module for PYR,
;    that is:
;       1-call the module's initialisation routine slo_init at the first
;         iteration of the simulation project,
;       2-call the module's program routine slo_prog otherwise.
;
; MODULE'S PURPOSE:
;    It takes the image coming out of the Pyramid wavefront sensor and
;    computes the x- and y signals positions for each sub-aperture.
;   
;    GUI details
;    -----------
;   select algorithm : normalise by total energy or by intensity in each sub.
;
; CATEGORY:
;    main module's routine
;
; CALLING SEQUENCE:
;    error = slo(inp_mim_t, $
;                out_mes_t, $
;                par,       $
;                INIT=init  )
;
; OUTPUT:
;    error: long scalar (error code, see !caos_error var in caos_init.pro).
;
; INPUT:
;    inp_mim_t: structure of type mim_t. 
;               It contains the Pyramid wavefront sensor image
;               and some geometrical parameters of the PYR.
;
; INCLUDED OUTPUT:
;    out_mes_t: structure of type mes_t.
;               It contains the vector of the sensor measurements
;               (here, the x-slopes followed by the y-slopes) as well as
;               some info about the sensor shape in case this information
;               has to be checked by the reconstructor.
;
; KEYWORD PARAMETERS:
;    INIT: initialisation data structure.
;
; COMMON BLOCKS:
;    common caos_block, tot_iter, this_iter
;
;    tot_iter   : total number of iteration during the simulation run.
;    this_iter  : current iteration number.
;
; SIDE EFFECTS:
;    none.
;
; RESTRICTIONS:
;    none.
;
; CALLED NON-IDL FUNCTIONS:
;    slope.pro
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: june 2001,
;                     Christophe Verinaud (OAA) [verinaud@arcetri.astro.it].
;    modifications  : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -use of variable "calibration" eliminited for version 4.0
;                     of the whole CAOS Software System.
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
; MODULE MODIFICATION HISTORY:
;    module written : Christophe Verinaud (OAA) [verinaud@arcetri.astro.it].
;    modifications  : october 2002,
;                     Christophe Verinaud (OAA) [verinaud@arcetri.astro.it]:
;                    -normalization alternative added.
;                   : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -no more use of the common variable "calibration" and
;                     the tag "calib" (structure "info") for version 4.0 of
;                     the whole CAOS Software System.
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;-
;
function slo, inp_mim_t, $ ; input structure
              out_mes_t, $ ; output structure
              par,       $ ; parameters from slo_gui
              INIT=init    ; initialization structure

common caos_block, tot_iter, this_iter

error = !caos_error.ok

; module's actions
if (this_iter eq 0) then begin
   ; initialisation section
   error = slo_init(inp_mim_t, out_mes_t, par, INIT=init)
endif else begin
   ; run section
   error = slo_prog(inp_mim_t, out_mes_t, par, INIT=init)
endelse

return, error
end