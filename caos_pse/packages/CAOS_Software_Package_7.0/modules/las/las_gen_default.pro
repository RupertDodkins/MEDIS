; $Id: las_gen_default.pro,v 7.0 2016/04/29 marcel.carbillet $
;+
; NAME:
;    las_gen_default
;
; PURPOSE:
;    las_gen_default generates the default parameter structure
;    for the LAS module and save it in the rigth location.
;    (see las.pro's header --or file caos_help.html-- for details about the
;     module itself).
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;    las_gen_default
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: june 1998,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : february 1999,
;                     Elise Viard (ESO) [eviard@eso.org]:
;                    -a few modifications for version 1.0.
;                   : March 1999,
;                     Bruno Femenia (OAA) [bfemenia@arcetri.astro.it]:
;                    -par.off_axis and par.off_axis are double precission.
;                   : december 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 2.0 (CAOS).
;                   : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -"mod_type"->"mod_name"
;                     (for version 4.0 of the whole Software System CAOS").
;                   : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                   -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
pro las_gen_default

info = las_info()
module = gen_def_module(info.mod_name, info.ver)

par = $
   {  $
    LAS,                $ ; LAS default structure
    module  : module,   $ ; module description
    power   : 5.,       $ ; laser power [W]
    waist   : 0.5,      $ ; profile waist [units of
                          ; projector telescope radius]
    dist_foc: 90000.,   $ ; proj. tel. focusing dist. [m]
    off_axis: 0.d0,     $ ; final spot off-axis and
    pos_ang : 0.d0,     $ ; final spot position angle
                          ; (wrt main telescope axis)
    constant: 0B        $ ; is the upward propagation
                        $ ; considered only once ?
   }

save, par, FILENAME=info.def_file

end