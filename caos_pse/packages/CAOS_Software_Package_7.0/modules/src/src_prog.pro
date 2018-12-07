; $Id: src_prog.pro,v 7.0 2016/04/21 marcel.carbillet $
;+
; NAME:
;       src_prog
;
; PURPOSE:
;       src_prog represents the program routine for the [PUT HERE THE NAME]
;       (SRC) module, that is:
;
;       (see src.pro's header --or file caos_help.html-- for details about the
;        module itself).
;
; CATEGORY:
;       module's program routine
;
; CALLING SEQUENCE:
;       error = src_prog(out_src_t, $
;                        par,       $
;                        INIT=init  $
;                       )
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.:
;       see module help for a detailed description.
;
; MODIFICATION HISTORY:
;       program written: february 1999,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;       modifications  : Dec 1999,
;                        B. Femenia   (OAA) [bfemenia@arcetri.astro.it]
;                       -adapted to new version CAOS (v 2.0).
;                      : february 2003,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -no more use of common variable "calibration".
;                      : april 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;-
;
function src_prog, out_src_t, $
                   par,       $
                   INIT=init

; CAOS global common block
common caos_block, tot_iter, this_iter

; error code initialization
error = !caos_error.ok

; output structure update
out_src_t.data_status = !caos_data.valid

return, error
end