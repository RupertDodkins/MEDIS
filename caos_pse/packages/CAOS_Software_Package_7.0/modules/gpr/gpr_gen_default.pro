; $Id: gpr_gen_default.pro,v 7.0 2016/04/21 marcel.carbillet $
;+
; NAME:
;    gpr_gen_default
;
; PURPOSE:
;    gpr_gen_default generates the default parameter structure
;    for the GPR module and save it in the rigth location.
;    (see gpr.pro's header --or file caos_help.html-- for details about
;    the module itself).
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;    gpr_gen_default
;
; MODIFICATION HISTORY:
;    program written: june 1998,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : february 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -a few modifications for version 1.0.
;                   : march 1999,
;                     Bruno Femenia (OAA) [bfemenia@arcetri.astro.it]:
;                    -par.angle is double precision.
;                   : december 1999--february 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -enhanced and adapted to version 2.0 (CAOS).
;                   : january/february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -"mod_type"->"mod_name"
;                     (for version 4.0 of the whole Software System CAOS").
;                    -telescope altitude parameter eliminated (was usefull
;                     only to obsolete module SHS)...
;
;-
;
pro gpr_gen_default

; obtain module infos
info = gpr_info()

; generate module description structure
module = gen_def_module(info.mod_name, info.ver)

; parameter structure
par =   $
   {    $
   gpr, $
   module: module, $
   D     : 8.,     $  ; telescope diameter [m]
   eps   : .1,     $  ; telescope obscuration ratio
   tel   : 0,      $  ; telescope type of position [0=[0,0,0], 1=elsewhere]
   dist  : 0.,     $  ; distance (r) of telescope from position [0,0,0] ([m])
   angle : 0.d0    $  ; position angle of telescope [deg]
   }

; save the default parameters structure in the file def_file
save, par, FILENAME=info.def_file

; back to calling program
end