; $Id: slo_gen_default.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    slo_gen_default
;
; PURPOSE:
;    slo_gen_default generates the default parameter structure
;    for the slo module and save it in the rigth location.
;    (see slo.pro's header --or file caos_help.html-- for details about the
;    module itself).
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;    slo_gen_default
; 
; ROUTINE MODIFICATION HISTORY:
;    routine written: june 2001,
;                     Christophe Verinaud (OAA) [verinaud@arcetri.astro.it].
;    modifications  : october 2002,
;                     Christophe Verinaud (OAA) [verinaud@arcetri.astro.it]:
;                    -parameter "algo_type" added for normalization alternative.
;                   : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -"mod_type"->"mod_name"
;                     (for version 4.0 of the whole Software System CAOS").
;                    -useless parameters "init_file" and "init_save" eliminated.
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;-
;
pro slo_gen_default

info = slo_info()               ; obtain module infos

module = gen_def_module(info.mod_name, info.ver)

par = $
   {  $
   slo,                  $ ; structure named slo
   module   : module,    $ ; standard module description structure
   algo_type: 0B         $
   }

save, par, FILENAME=info.def_file

end