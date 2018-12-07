; $Id: ibc_gen_default.pro,v 7.0 2016/04/29 marcel.carbillet $
;+
; NAME:
;    ibc_gen_default
;
; PURPOSE:
;    ibc_gen_default generates the default parameter structure
;    for the IBC module and save it in the rigth location.
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;    ibc_gen_default
; 
; ROUTINE MODIFICATION HISTORY:
;    routine written: april-october 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : december 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 2.0 (CAOS).
;                   : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -"mod_type"->"mod_name"
;                     (for version 4.0 of the whole Software System CAOS").
;                   : march 2005,
;                     Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr],
;                     Olivier Lardiere (LISE) [lardiere@obs-hp.fr]:
;                    -densification parameter added (for modelling the
;                     "densified pupil" case).
;                   : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
pro ibc_gen_default

; obtain module infos
info = ibc_info()

; generate the module description structure
module = gen_def_module(info.mod_name, info.ver)

; build the parameters structure
par = $
   {  $
   ibc,              $ ; structure named ibc
   module  : module, $ ; module description structure
   densification: 1.,    $ ; densification factor (if not 1: densified pupil mode)
   residual: 0.      $ ; residual diff. piston
                       ; (ratio wrt input diff. piston).
   }                   ; (0.=complete correction, 1.=no correction)

; save the default parameter structure
save, par, FILENAME=info.def_file

end