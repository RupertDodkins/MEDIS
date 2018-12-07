; $Id: com.pro,v 7.0 2016/04/27 marcel.carbillet $
;+
; NAME:
;    com
;
; ROUTINE'S PURPOSE:
;    com manages the simulation for the COMbine measurements (COM) module,
;    that is:
;       1-call the module's initialisation routine com_init at the first
;         iteration of the simulation (or calibration) project,
;       2-call the module's program routine com_prog otherwise, managing
;         at the same time the possible time integration/delay.
;
; MODULE'S PURPOSE:
;
; CATEGORY:
;    main module's routine
;
; CALLING SEQUENCE:
;    error = com(inp_mes_t1, $ ; 1st input structure
;                inp_mes_t2, $ ; 2nd input structure
;                out_mes_t,  $ ; output structure
;                par         ) ; parameter structure
;
; OUTPUT:
;    error: long scalar (error code, see !caos_error var in caos_init.pro).
;
; INPUTS:
;    inp_mes_t1: structure of type mes_t.
;    inp_mes_t2: structure of type mes_t.
;    par       : parameters structure.
;
; INCLUDED OUTPUTS:
;    out_mes_t: structure of type mes_t.
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
;    routine written: february-march 2001,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : march 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to new CAOS system (4.0) and building of
;                     Software Package MAOS 1.0.
;                   : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
; MODULE MODIFICATION HISTORY:
;    module written : Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : for version 7.0,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
function com, inp_mes_t2,  $ ; BACK input structure
              inp_mes_t1,  $ ; UP   input structure
              out_mes_t,   $ ; output structure
              par            ; COM parameters structure

; CAOS global common block
common caos_block, tot_iter, this_iter

; error code initialisation
error = !caos_error.ok

; module's actions
if (this_iter eq 0) then begin
   ; initialisation section
   error = com_init(inp_mes_t1, inp_mes_t2, out_mes_t, par)
endif else begin
   ; run section
   error = com_prog(inp_mes_t1, inp_mes_t2, out_mes_t, par)
endelse

; back to calling program.
return, error
end