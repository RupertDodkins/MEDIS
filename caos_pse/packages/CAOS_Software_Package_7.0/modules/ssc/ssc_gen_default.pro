; $Id: ssc_gen_default.pro, Soft.Pack.CAOS v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    ssc_gen_default
;
; PURPOSE:
;    ssc_gen_default generates the default parameter structure for the SSC
;    module and save it in the rigth location.
;    (see ssc.pro's header --or file caos_help.html-- for details about the
;     module itself).
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;    ssc_gen_default
; 
; ROUTINE MODIFICATION HISTORY:
;    routine written: february 2012,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr].
;    modifications  : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;-
;
pro ssc_gen_default

; obtain module infos
info = ssc_info()

; generate module description structure
module = gen_def_module(info.mod_name, info.ver)

; parameter structure
par = $
   {  $
   ssc,                   $ ; structure named ssc
   module: module,        $ ; module description structure
   dir   : ''             $ ; directory where the command law FITS files K_A,
   }                        ; K_B, K_C, and K_D can be found

; save the default parameters structure in the file def_file
save, par, FILENAME=info.def_file

;back to calling program
end