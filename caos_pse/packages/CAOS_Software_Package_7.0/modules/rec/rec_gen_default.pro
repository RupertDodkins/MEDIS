; $Id: rec_gen_default.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    rec_gen_default
;
; PURPOSE:
;    rec_gen_default generates the default parameter structure
;    for the REC module and save it in the rigth location.
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;    rec_gen_default
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: june 2002,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : october 2002,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -parameter "n_modes" added.
;                   : january/february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -"mod_type"->"mod_name"
;                     (for version 4.0 of the whole Software System CAOS").
;                    -"calib_file" now splitted into "mirdef_file" AND "matint_file".
;                    -all the parameters related to atmopshere-type outpur eliminated
;                     (since only the command-type output exists from now on).
;                    -added option for saving of w,u,v after SVD.
;                    -module's name from RCC to REC (eliminating old module REC).
;                   : january 2005,
;                     Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr]:
;                    -...
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;-
;
pro rec_gen_default

; obtain module infos
info = rec_info()

; generate module description structure
module = gen_def_module(info.mod_name, info.ver)

mirdef_file = ' '      ; mirror deformations filename
matint_file = ' '      ; interaction matrix filename
n_modes     = 496L     ; max mode nb untill which reconstruction
                       ; has to be performed

; parameter structure
par = $
   {  $
   rec,                        $ ; structure named rec
   module       : module,      $ ; module description structure
   mirdef_file  : mirdef_file, $ ; mirror deformations filename
   matint_file  : matint_file, $ ; interaction matrix filename
   n_modes      : n_modes,     $ ; max mode nb untill which reconstruction
                                 ; has to be performed
   svd_type     : 0,           $ ; choice between standard IDL svdc routine
                                 ; and LAPACK la_svd routine [0,1].
   save_wuv     : 2,           $ ; restore/save/do nothing [0,1,2] wrt
                                 ; w,u,v file ?
   save_wuv_file: ' '          $ ; filename for w,u,v after SVD calculation
   }

; save the default parameters structure in the file def_file
save, par, FILENAME=info.def_file

;back to calling program
end