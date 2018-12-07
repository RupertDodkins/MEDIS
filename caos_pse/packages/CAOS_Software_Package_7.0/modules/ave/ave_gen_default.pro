; $Id: ave_gen_default.pro,v 7.0 2016/04/27 marcel.carbillet$
;+
; NAME:
;       ave_gen_default
;
; PURPOSE:
;       ave_gen_default generates the default parameter structure for the AVE
;       module and save it in the rigth location. (see ave.pro's header --or
;       file maos_help.html-- for details about the module itself). 
; 
; CATEGORY:
;       module's utility routine
;
; CALLING SEQUENCE:
;       ave_gen_default 
; 
; MODIFICATION HISTORY:
;       program written: september 2008,
;                        Marcel Carbillet (Fizeau) [marcel.carbillet@unice.fr].
;       modifications  : april 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
pro ave_gen_default

info = ave_info()              ; obtain module infos

module = gen_def_module(info.mod_name, info.ver)
                               ; generate module descrip. structure

par = { AVE                , $ ; Structure named AVE
        module    : module , $ ; Standard module description structure
        nstars    : 3L       $ ; Nb of stars' signals to average 
      }

SAVE, par, FILENAME=info.def_file

RETURN
END