; $Id: iws_gen_default.pro,v 7.0 2016/04/29 marcel.carbillet $
;+
; NAME:
;       iws_gen_default
;
; PURPOSE:
;       iws_gen_default generates the default parameter structure for the IWS
;       module and save it in the rigth location. (see iws.pro's header --or
;       file caos_help.html-- for details about the module itself). 
; 
; CATEGORY:
;       module's utility routine
;
; CALLING SEQUENCE:
;       iws_gen_default 
; 
; MODIFICATION HISTORY:
;       program written: april 2015,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr].
;
;       modifications  : april 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
pro iws_gen_default

info = iws_info()              ; obtain module infos

module = gen_def_module(info.mod_name, info.ver)
                               ; generate module descrip. structure

par = { IWS                , $ ; Structure named IWS
        module    : module , $ ; Standard module description structure
        radial_order:  8   , $ ; Zernike radial degree desired 
        part_corr   :  1.    $ ; Partial AO correction desired
      }

SAVE, par, FILENAME=info.def_file

RETURN
END