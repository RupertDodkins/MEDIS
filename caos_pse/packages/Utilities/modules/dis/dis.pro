; $Id: dis.pro,v 7.0 2016/04/21 marcel.carbillet $
;+
; NAME:
;   dis 
;
; PURPOSE:
;   DIS executes the simulation for the data DISplay (DIS) module
;   of package "Utilities".
;   It can display the relevant field of each defined output type
;   of the software package, i.e.:
;
;   -source type (src_t):
;       displays the 2D-map or the 3D-map, does not display anything if the
;       source is a point-like one.
;
;   -atmosphere type (atm_t):
;       displays the wavefronts of each turbulent layer.
;
;   -wavefront propagated type (wfp_t):
;       displays the propagated wavefront.
;
;   -structure function type (stf_t):
;       displays the theoretical and the simulated structure functions.
;
;   -image type (img_t):
;       displays the point-spread function or the image.
;
;   -multiple image type (mim_t):
;       displays the SH array of spots.
;
;   -commands type (com_t):
;       displays the commands sent to the mirror.
;
;   -centroiding measure type (mes_t):
;       displays the centroiding measures.
;
; CATEGORY:
;    main module's routine
;
; CALLING SEQUENCE:
;    error = dis(inp_yyy_t, par, INIT=init)
;
; OUTPUT:
;    error: long scalar (error code, see !caos_error var in caos_init.pro).
;
; INPUTS:
;    inp_yyy_t: structure of type yyy_t.
;    par      : parameters structure from dis_gui.
;
; KEYWORD PARAMETERS:
;    INIT: initialization structure.
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
;    launch_dis
;    display_3d
;    image_show2
;    win_pos_manager
;
; ROUTINE MODIFICATION HISTORY:
;    program written: april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr],
;                     Andrea La Camera (DIBRIS) [andrea.lacamera@unige.it]:
;                    -global merging of dsp.pro of module DSP (from Soft.
;                     Pack. AIRY 6.1 ) and dis.pro of module DIS (from Soft.
;                     Pack. CAOS 5.2) for new CAOS Problem-Solving Env. 7.0.
;    modifications  : date,
;                     author (institute) [email@address]:
;                    -description of modification.
;
; MODULE MODIFICATION HISTORY:
;    module written : Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr],
;                     Andrea La Camera (DIBRIS) [andrea.lacamera@unige.it].
;    modifications  : for version x.y,
;                     author (institute) [email address]:
;                    -description of modification.
;
;-
;
function dis, inp_yyy_t, $ ; input structure
              par,       $ ; parameters from dis_gui
              INIT=init    ; initialization structure

common caos_block, tot_iter, this_iter

; initialization of the error code: set to "no error" as default
error = !caos_error.ok

; module's actions
if (this_iter eq 0) then begin
   ; initialisation section

   error = dis_init(inp_yyy_t, par, INIT=init)

endif else begin
   ; run section

   if inp_yyy_t.data_status eq !caos_data.valid then begin

      error = dis_prog(inp_yyy_t, par, INIT=init)

   endif else begin

      return, error

   endelse

endelse

; back to calling program
return, error
end