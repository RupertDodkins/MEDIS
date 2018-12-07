; $Id: stf_gen_default.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    stf_gen_default
;
; PURPOSE:
;    stf_gen_default generates the default parameter structure
;    for the STF module and save it in the rigth location.
;    (see stf.pro's header --or file caos_help.html-- for details about the
;     module itself).
;
; CATEGORY:
;    module's utility routine
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: july 1998,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : march 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 1.0.
;                   : december 1999,
;                     Marcel Carbillet [marcel@arcetri.astro.it]:
;                    -adapted to version 2.0 (CAOS).
;                   : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -"mod_type"->"mod_name"
;                     (for version 4.0 of the whole Software System CAOS").
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;-
;
pro stf_gen_default

info = stf_info()
module = gen_def_module(info.mod_name, info.ver)

par = $
   {  $
   stf,            $ ; structure named STF
   module: module, $ ; standard module description structure
   model : 1,      $ ; theoretical atmospheric
                   $ ;model (0=Kolmogorov, 1=vonKarman)
   r0    : .15,    $ ; Fried parameter [m]
   L0    : 20.     $ ; w-f. outer-scale [m]
   }

save, par, FILENAME=info.def_file

end