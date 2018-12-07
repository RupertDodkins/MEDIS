; $Id: mds.pro,v 7.0 2016/04/29 marcel.carbillet $
;+
; NAME:
;    mds
;
; ROUTINE'S PURPOSE:
;    mds manages the simulation for the Mirror Deformations Sequencer (MDS)
;    module, that is:
;       1-call the module's initialisation routine mds_init at the first
;         iteration of the project
;       2-call the module's program routine mds_prog otherwise.
;
; MODULE'S PURPOSE:
;    MDS generates a sequence of mirror deformations.
;
; CATEGORY:
;    main module's routine
;
; CALLING SEQUENCE:
;    error = mds(out_atm_t, par, INIT=init)
;
; OUTPUT:
;    error: long scalar (error code). see !caos_error var in caos_init.pro.
;
; INPUTS:
;    none.
;
; INCLUDED OUTPUTS:
;    out_atm_t: the output structure of ATM, of type "atm_t", containing:
;    -screen : 3-variables array of the ensemble of layers' wavefronts of
;              the turbulent atmosphere [m]
;    -scale  : spatial scale [m/px]
;    -delta_t: base-time [s]
;    -alt    : vector of altitudes of the layers [m]
;    -dir    : vector of direction of the wind [rd].
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
; CALLED NON-IDL FUNCTIONS
;    none.
;
; ROUTINE MODIFICATION HISTORY:
;    program written: june 2002,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it],
;                     Christophe Verinaud (OAA) [verinaud@arcetri.astro.it].
;    modifications  : july 2002,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -Zernike and user-defined deformations are now both well
;                     ordered (piston is defined for iter 0 and then the
;                     usefull deformations are sent).
;                   : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -use of variable "calibration" eliminited for version 4.0
;                     of the whole CAOS Software System.
;                   : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
; MODULE MODIFICATION HISTORY:
;    module written : Marcel Carbillet (OAA) [marcel@arcetri.astro.it],
;                     Christophe Verinaud (OAA) [verinaud@arcetri.astro.it].
;    modifications  : for version 4.0,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -no more use of the common variable "calibration" and
;                     the tag "calib" (structure "info") for version 4.0 of
;                     the whole CAOS Software System.
;                   : for version 7.0,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
function mds, out_atm_t, $
              par,       $
              INIT=init

; CAOS global common block
common caos_block, tot_iter, this_iter

; initialization of the error code
error = !caos_error.ok

; module's actions
if (this_iter eq 0) then begin
   ; initialisation section
   error = mds_init(out_atm_t, par, INIT=init)
   error = mds_prog(out_atm_t, par, INIT=init)
endif else begin
   ; run section
   error = mds_prog(out_atm_t, par, INIT=init)
endelse

return, error
end