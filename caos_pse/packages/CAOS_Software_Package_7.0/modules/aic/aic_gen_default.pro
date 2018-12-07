; $Id: aic_gen_default.pro,v 7.0 2016/04/15 marcel.carbillet$
;
;+
; NAME:
;    aic_gen_default
;
; PURPOSE:
;    aic_gen_default generates the default parameter structure for the AIC
;    module and save it in the rigth location.
;    (see aic.pro's header --or file caos_help.html-- for details about the
;     module itself).
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;    aic_gen_default
; 
; ROUTINE MODIFICATION HISTORY:
;    routine written: september 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it],
;                     Christophe Verinaud (ESO) [cverinau@eso.org].
;    modifications  : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;-
;
pro aic_gen_default

; obtain module infos
info = aic_info()

; generate module description structure
module = gen_def_module(info.mod_name, info.ver)

; parameter structure
par = $
   {  $
   aic,                          $ ; structure named aic
   module       : module,        $ ; module description structure
   Rfac         : .5,            $ ; beamsplitter reflexion factor
   Tfac         : .5,            $ ; beamsplitter transmission factor
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