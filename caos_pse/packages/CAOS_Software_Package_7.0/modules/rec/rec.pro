; $Id: rec.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    rec
;
; ROUTINE'S PURPOSE:
;    rec manages the simulation for the ReConstruction and Conjugation
;    (REC) module, that is:
;       1-call the module's initialisation routine rec_init at the first
;         iteration of the simulation project,
;       2-call the module's program routine rec_prog otherwise.
;
; MODULE'S PURPOSE:
;    This module reconstructs the sensed wavefront in terms of a set of mirror's
;    commands.
;
;    The interaction matrix is computed during an off-line calibration process,
;    using either Zernike polynomials or user-defined mirror deformations that
;    can be influence functions, or whatever set of mirror deformations.
;
;    The inversion process uses the singular value decomposition (SVD) algorithm.
;
;    In case of zonal reconstruction, be aware of not cutting the number of modes
;    (here the number of influence functions!) by setting a value to par.modes < the
;    number of influence functions, but rather calculate a brand new "wuv" resulting
;    from the SVD process performed during iteration zero.
;
; CATEGORY:
;    main module's routine
;
; CALLING SEQUENCE:
;    error = rec(inp_mes_t, $
;                out_com_t, $
;                par,       $
;                INIT=init  $
;
; OUTPUT:
;    error: long scalar (error code, see !caos_error var in caos_init.pro).
;
; INPUTS:
;    inp_mes_t: structure of type mes_t.
;    par      : parameters structure.
;
; INCLUDED OUTPUTS:
;    out_com_t: structure of type com_t.
;
; KEYWORD PARAMETERS:
;    INIT: initialisation data structure
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
;    none. 
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: june 2002,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : january/february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -use of variable "calibration" eliminited for version 4.0
;                     of the whole CAOS Software System.
;                    -atmosphere-type output eliminated (became useless wrt
;                     command-type output + use of new module DMC).
;                    -module's name from RCC to REC (eliminating old module REC).
;                   : help clarified in order to avoid bad behaviors when
;                     dealing with zonal reconstruction (influence functions).
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
; MODULE MODIFICATION HISTORY:
;    module written : Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;
;    modifications  : for version 4.0,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -no more use of the common variable "calibration" and
;                     the tag "calib" (structure "info") for version 4.0 of
;                     the whole CAOS Software System.
;                    -atmosphere-type output eliminated (became useless wrt
;                     command-type output + use of new module DMC).
;                    -module's name from RCC to REC (eliminating old module REC).
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
function rec, inp_mes_t, $
              out_com_t, $
              par,       $
              INIT=init

; CAOS global common block
common caos_block, tot_iter, this_iter

; error code initialisation
error = !caos_error.ok

; module's actions
if (this_iter eq 0) then begin
   ; initialisation section
   error = rec_init(inp_mes_t,out_com_t,par,INIT=init)
endif else begin
   ; run section
   error = rec_prog(inp_mes_t,out_com_t,par,INIT=init)
endelse

; back to calling program.
return, error
end