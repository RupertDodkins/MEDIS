; $Id: ssc.pro, Soft.Pack.CAOS v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    ssc
;
; ROUTINE'S PURPOSE:
;    ssc manages the simulation for the State-Space Control (SSC) module,
;    that is:
;       1-call the module's initialisation routine ssc_init at the first
;         iteration of the simulation project,
;       2-call the module's program routine ssc_prog otherwise, managing
;         at the same time the possible time integration/delay.
;
; MODULE'S PURPOSE:
;
; CATEGORY:
;    main module's routine
;
; CALLING SEQUENCE:
;    error = ssc(inp_mes_t, $ ; input structure
;                out_com_t, $ ; output structure
;                par,       $ ; parameter structure
;                INIT=init  ) ; initialisation data structure
;
; OUTPUT:
;    error: long scalar (error code, see !caos_error var in caos_init.pro).
;
; INPUTS:
;    inp_mes_t: structure of type com_t.
;    par      : parameters structure.
;
; INCLUDED OUTPUTS:
;    out_com_t: structure of type com_t.
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
;    none.
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: february 2012,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr].
;    modifications  : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
; MODULE MODIFICATION HISTORY:
;    module written : Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr].
;    modifications  : for version 7.0,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted.
;-
;
function ssc, inp_mes_t,   $ ; input structure
              out_com_t,   $ ; output structure
              par,         $ ; SSC parameters structure
              INIT=init      ; SSC initialization structure

; CAOS global common block
common caos_block, tot_iter, this_iter

; error code initialisation
error = !caos_error.ok

; module's actions
if (this_iter eq 0) then begin
   ; initialisation section
   error = ssc_init(inp_mes_t, $
                    out_com_t, $
                    par,       $
                    INIT=init  )
endif else begin
   ; run section
   error = ssc_prog(inp_mes_t, $
                    out_com_t, $
                    par,       $
                    INIT=init  )


endelse

; back to calling program.
return, error
end