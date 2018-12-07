; $Id: dis_prog.pro,v 7.0 2016/04/21 marcel.carbillet $
;+
; NAME:
;    dis_prog
;
; PURPOSE:
;    dis_prog represents the scientific algorithm for the
;    data DISplay (DIS) module of package "Utilities".
;
; CATEGORY:
;    module's program routine
;
; CALLING SEQUENCE:
;       error = dis_prog(          $
;                       inp_yyy_t, $ ; yyy_t input structure
;                       out_bbb_t, $ ; bbb_t output structure 
;                       par,       $ ; parameters structure
;                       INIT=init  $ ; initialisation structure
;                       ) 
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.:
;       see module help for a detailed description. 
;
; ROUTINE MODIFICATION HISTORY:
;    program written: april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr],
;                     Andrea La Camera (DIBRIS) [andrea.lacamera@unige.it]:
;                    -global merging of dsp_init of module DSP (from Soft.
;                     Pack. AIRY 6.1 ) and dis_init of module DIS (from Soft.
;                     Pack. CAOS 5.2) for new CAOS Problem-Solving Env. 7.0.
;    modifications  : date,
;                     author (institute) [email@address]:
;                    -description of modification.
;-
;
function dis_prog, inp_yyy_t, $
                   par,       $
                   INIT=init

; initialization of the error code: no error as default
error = !caos_error.ok

init.dis_counter = init.dis_counter + 1
if (init.dis_counter/par.iteration*par.iteration EQ init.dis_counter) $
   then err = launch_dis(inp_yyy_t, par, init)

return, error
end