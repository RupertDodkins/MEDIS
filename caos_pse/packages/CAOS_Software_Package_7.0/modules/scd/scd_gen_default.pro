; $Id: scd_gen_default.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    scd_gen_default
;
; PURPOSE:
;    scd_gen_default generates the default parameter structure for the SCD
;    module and save it in the rigth location.
;    (see scd.pro's header --or file caos_help.html-- for details about the
;     module itself).
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;    scd_gen_default
; 
; ROUTINE MODIFICATION HISTORY:
;    routine written: june 2002,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : january/february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -"mod_type"->"mod_name"
;                     (for version 4.0 of the whole Software System CAOS").
;                    -now saves the interaction matrix AND the mirror deformations
;                     in two separated files (needed by new module DMC and new
;                     version of module DMI).
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;-
;
pro scd_gen_default

; obtain module infos
info = scd_info()

; generate module description structure
module = gen_def_module(info.mod_name, info.ver)

; parameter structure
par = $
   {  $
   scd,                 $ ; structure named scd
   module     : module, $ ; module description structure
   matint_file: ' ',    $ ; interaction matrix file address
   mirdef_file: ' '     $ ; mirror deformations file address
   }

; save the default parameters structure in the file def_file
save, par, FILENAME=info.def_file

;back to calling program
end