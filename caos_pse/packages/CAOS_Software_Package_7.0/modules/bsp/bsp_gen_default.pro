; $Id: bsp_gen_default.pro,v 7.0 2016/04/27 marcel.carbillet $
;+
; NAME:
;       bsp_gen_default
;
; PURPOSE:
;       bsp_gen_default generates the default parameter structure for the BSP
;       module and save it in the rigth location. (see bsp.pro's header --or
;       file caos_help.html-- for details about the module itself). 
;
; CATEGORY:
;       module's utility routine
;
; CALLING SEQUENCE:
;       bsp_gen_default 
; 
; MODIFICATION HISTORY:
;       program written: March 1999,
;                        B. Femenia (OAA) [bfemenia@arcetri.astro.it]
;
;       modifications  : Nov 1999, 
;                        B. Femenia   (OAA) [bfemenia@arcetri.astro.it]
;                       -adapted to new version CAOS (v 2.0).
;                      : january 2003,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -"mod_type"->"mod_name"
;                        (for version 4.0 of the whole Software System CAOS").
;                       -useless parameters "init_file" and "init_save" eliminated.
;                       -useless call to mk_par_name eliminated.
;                      : april 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
pro bsp_gen_default

info = bsp_info()                ; obtain module infos

module = gen_def_module(info.mod_name, info.ver)
                                 ; generate module descrip.
                                 ; structure

par = { BSP                , $   ; Structure named BSP
        module    : module , $   ; Standard module description structure
        frac      : 0.5      $   ; Fraction of total intensity sent to first 
      }                          ;   output (in AppBuilder, bottom box!!)

SAVE, par, FILENAME=info.def_file

RETURN
END