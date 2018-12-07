; $Id: cor_gen_default.pro,v 7.0 2016/04/27 marcel.carbillet$
;
;+
; NAME:
;    cor_gen_default
;
; PURPOSE:
;    cor_gen_default generates the default parameter structure for the COR
;    module and save it in the rigth location.
;    (see cor.pro's header --or file caos_help.html-- for details about the
;     module itself).
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;    cor_gen_default
; 
; ROUTINE MODIFICATION HISTORY:
;    routine written: september 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it],
;                     Olivier Lardiere (OAA) [lardiere@arcetri.astro.it].
;    modifications  : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
pro cor_gen_default

; obtain module infos
info = cor_info()

; generate module description structure
module = gen_def_module(info.mod_name, info.ver)

; parameter structure
par = $
   {  $
   cor,                          $ ; structure named cor
   module       : module,        $ ; module description structure
   corono       : 1,             $ ; coronagraph type [0=none, 1=Lyot, 2=Roddier&Roddier,
                                   ;                   3=four quadrant phase mask]
   dim_mask     : 6.5,           $ ; mask dimension [unit of lambda/D]
   nlyot        : .78,           $ ; Lyot-stop dimension [unit of D]
   psf_sampling : 8,             $ ; nb of pixel per resel (1 resel=lambda/D) [px]
   band         : "K",           $ ; observing band
   pos_ang      : 45.,           $ ; planet position angle [deg.]
   off_axis     : 0.5,           $ ; planet off-axis [arcsec]
   int_ratio    : 1E-4           $ ; intensity ratio between host star and planet
   }

; save the default parameters structure in the file def_file
save, par, FILENAME=info.def_file

;back to calling program
end