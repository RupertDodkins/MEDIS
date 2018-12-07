; $Id: com_gen_default.pro,v 7.0 2016/04/27 marcel.carbillet $
;+
; NAME:
;    com_gen_default
;
; PURPOSE:
;    com_gen_default generates the default parameter structure for the COM
;    module and save it in the rigth location.
;    (see com.pro's header --or file caos_help.html-- for details about the
;     module itself).
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;    com_gen_default
; 
; ROUTINE MODIFICATION HISTORY:
;    routine written: february 2001,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : march 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;                    -adapted to new CAOS system (4.0) and building of
;                     Software Package MAOS 1.0.
;                   : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
pro com_gen_default

; obtain module infos
info = com_info()

; generate module description structure
module = gen_def_module(info.mod_name, info.ver)

; parameter structure
par = $
   {  $
   com,                          $ ; structure named com
   module       : module         $ ; module description structure
   }

; save the default parameters structure in the file def_file
save, par, FILENAME=info.def_file

;back to calling program
end