; $Id: ima_gen_default.pro,v 7.0 2016/04/29 marcel.carbillet$
;+
; NAME:
;       ima_gen_default
;
; PURPOSE:
;       ima_gen_default generates the default parameter structure for the IMA
;       module and save it in the rigth location. (see ima.pro's header --or
;       file caos_help.html-- for details about the module itself). 
; 
; CATEGORY:
;       module's utility routine
;
; CALLING SEQUENCE:
;       ima_gen_default 
; 
; MODIFICATION HISTORY:
;       program written: september 2003,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;       modifications  : april 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;-
;
pro ima_gen_default

info = ima_info()              ; obtain module infos

module = gen_def_module(info.mod_name, info.ver)
                               ; generate module descrip. structure

par = { IMA                , $ ; Structure named IMA
        module    : module , $ ; Standard module description structure
        wb        :  1.0   , $ ; Weight assigned to first input 
                             $ ;     (in AppBuilder, bottom box!!)
        wt        :  1.0     $ ; Weight assigned to second input 
      }                        ;     (in AppBuilder, top box!!)

SAVE, par, FILENAME=info.def_file

RETURN
END