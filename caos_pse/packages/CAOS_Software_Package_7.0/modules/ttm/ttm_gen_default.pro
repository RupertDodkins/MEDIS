; $Id: ttm_gen_default.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;       ttm_gen_default
;
; PURPOSE:
;       ttm_gen_default generates the default parameter structure for the TTM
;       module and save it in the rigth location.  The user doesn't need to use
;       ttm_gen_default, it is used only for developing and upgrading
;       porpuses.In this version the par structure associated to TTM only
;       contains tags associated to the management of program, but no parameter
;       relevant to scientific program.
;
; CATEGORY:
;       Utility
;
; CALLING SEQUENCE:
;       ttm_gen_default 
; 
; MODIFICATION HISTORY:
;       program written: Feb 1999,
;                        B. Femenia (OAA) [bfemenia@arcetri.astro.it]
;                       -rewritten to match general style and requirements on
;                        how to manage initialization process, calibration
;                        procedure and time management according to  released
;                        templates on Feb 1999.
;       modifications  : Nov 1999,
;                        B. Femenia   (OAA) [bfemenia@arcetri.astro.it]
;                       -adapted to new version CAOS (v 2.0).
;                      : january 2003,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -"mod_type" --> "mod_name"
;                        (for version 4.0 of the whole Software System CAOS).
;                       -useless parameters "init_file" and "init_save" eliminated.
;                       -useless call to mk_par_name eliminated.
;                      : may 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;-
;
pro ttm_gen_default

info  = ttm_info()                                          ; obtain module infos
module= gen_def_module(info.mod_name, info.ver)             ; generate module descrip.
                                                            ; structure
par = { TTM            , $ ; Structure named TTM
        module: module   $ ; Standard module description structure
      }

save, par, FILENAME=info.def_file

return
end