; $Id: wft_gen_default.pro,v 1.0 last revision 2016/04/29 Andrea La Camera$
;+
; NAME:
;    wft_gen_default
;
; PURPOSE:
;    wft_gen_default generates the default parameter structure
;    for the WFT module and save it in the right location.
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;    wft_gen_default
; 
; ROUTINE MODIFICATION HISTORY:
;    routine written: october 2000,
;                     Serge Correia (OAA) [correia@arcetri.astro.it].
;    modifications  : february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -"mod_type"->"mod_name"
;                     (for version 4.0 of the whole system CAOS).
;                   : from CAOS_PSE v 7.0 (2016) 
;                    -this module has been moved from AIRY 6.1 to the new 
;                     package "Utilities". Version number has been
;                     reset to 1.0. 
;-
;
pro wft_gen_default

; obtain module infos
info = wft_info()

; generate module description structure.
module = gen_def_module(info.mod_name, info.ver)

par =   $
   {    $
   wft, $                ; structure named wft
   module    : module, $ ; module description structure
   data_file : '',     $ ; data file name
                         ; (no extension like .sav or .xdr or .fits)
   end_iter  : 0,      $ ; save image at the very end of the simulation ?
                         ; (no=0, yes=1), if yes then par.iteration=tot_iter
                         ;                if no  then par.iteration=...
   iteration : 1       $ ; number of iterations per saving operations
   }

; save the default parameter structure in the default file
save, par, FILENAME=info.def_file

end
