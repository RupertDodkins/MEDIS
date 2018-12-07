; $Id: wfa_gen_default.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;       wfa_gen_default
;
; PURPOSE:
;       wfa_gen_default generates the default parameter structure for the WFA
;       module and save it in the rigth location. (see wfa.pro's header --or
;       file caos_help.html-- for details about the module itself). 
; 
; CATEGORY:
;       module's utility routine
;
; CALLING SEQUENCE:
;       wfa_gen_default 
; 
; MODIFICATION HISTORY:
;       program written: April 1999,
;                        B. Femenia (OAA) [bfemenia@arcetri.astro.it]
;
;       modifications  : december 1999--february 2000, 
;                        Bruno  Femenia   (OAA) [bfemenia@arcetri.astro.it],
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -adapted to new version CAOS (v 2.0).
;                      : january 2003,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -"mod_type"->"mod_name"
;                        (for version 4.0 of the whole Software System CAOS").
;                       -useless parameters "init_file" and "init_save" eliminated.
;                      : may 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;-
;
pro wfa_gen_default

info = wfa_info()              ; obtain module infos

module = gen_def_module(info.mod_name, info.ver)
                               ; generate module descrip. structure

par = { WFA                , $ ; Structure named WFA
        module    : module , $ ; Standard module description structure
        wb        :  1.0   , $ ; Weight assigned to first input 
                             $ ;     (in AppBuilder, bottom box!!)
        wt        :  1.0     $ ; Weight assigned to second input 
      }                        ;     (in AppBuilder, top box!!)

SAVE, par, FILENAME=info.def_file

RETURN
END