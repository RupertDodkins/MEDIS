; $Id: mds_prog.pro,v 7.0 2016/04/29 marcel.carbillet $
;+
; NAME: 
;    mds_init 
; 
; PURPOSE: 
;    mds_prog executes ...
;    (see mds.pro's header --or file caos_help.html-- for details
;    about the module itself).
; 
; CATEGORY: 
;    module's initialisation routine 
; 
; CALLING SEQUENCE: 
;    error = mds_prog(out_atm_t, $ ; atm_t output
;                     par,       $ ; MDS parameters structure
;                     INIT=init)   ; initialisation data structure
; 
; INPUTS/OUTPUTS/KEYWORDS/ETC.: 
;       see mds.pro's help for a detailed description. 
;
; ROUTINE MODIFICATION HISTORY: 
;       program written: june 2002,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it],
;                        Christophe Verinaud (OAA) [verinaud@arcetri.astro.it].
;       modifications  : july 2002
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -Zernike and user-defined deformations are now both well
;                        ordered (piston is defined for iter 0 and then the
;                        usefull deformations are sent).
;                      : april 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;-
;
FUNCTION mds_prog, out_atm_t, $
                   par,       $
                   INIT=init

; CAOS global common block
common caos_block, tot_iter, this_iter

; initialization of the error code: no error as default
error = !caos_error.ok

; program itself

out_atm_t.screen = init.coeff[this_iter] * init.mirdef[*,*,this_iter]*init.pupil
out_atm_t.data_status = !caos_data.valid

return, error
END