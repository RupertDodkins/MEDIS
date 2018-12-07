; $Id: sav_gen_default.pro,v 7.0 2016/05/03 marcel.carbillet $
;+
; NAME:
;    sav_gen_default
;
; PURPOSE:
;    sav_gen_default generates the default parameter structure
;    for the SAV module and save it in the rigth location.
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;    sav_gen_default
; 
; ROUTINE MODIFICATION HISTORY:
;    routine written: march 1999,
;                     Simone Esposito (OAA) [esposito@arcetri.astro.it].
;    modifications  : march 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -data file names defaults are now generic file names
;                     and contain the .../data directory path.
;                   : may 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -fixed default file address problem.
;                   : december 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 2.0 (CAOS).
;                   : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -"mod_type"->"mod_name"
;                     (for version 4.0 of the whole Software System CAOS").
;                   : may 2016,
;                     Ulysse Perruchon-Monge & Adama Sy (Dépt.Physique UNS),
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -moved from Soft.Pack.CAOS 5.2 to new package "Utilities"
;                     of new version (7.0) of the CAOS PSE,
;                    -simple IDL "save" format and FITS format added.
;-
;
pro sav_gen_default

; obtain module infos
info = sav_info()

; generate module description structure.
module = gen_def_module(info.mod_name, info.ver)

par =   $
   {    $
   sav, $                   ; structure named sav
   module    : module,    $ ; module description structure
   data_file : '',        $ ; generic data file name
                            ; (no extension .sav or .xdr or whatever)
   iteration : 1,         $ ; number of iterations per saving operations
   format    : 0          $ ; format for data saving (0: XDR format,
                            ;                         1: IDL save format,
                            ;                         2: FITS format)
   }

; save the default parameter structure in the default file
save, par, FILENAME=info.def_file

end