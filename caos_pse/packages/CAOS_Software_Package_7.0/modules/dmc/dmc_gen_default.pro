; $Id: dmc_gen_default.pro,v 7.0 2016/04/29 marcel.carbillet $
;+
; NAME:
;    dmc_gen_default
;
; PURPOSE:
;    dmc_gen_default generates the default parameter structure
;    for the DMC module and save it in the rigth location.
;    (see dmc.pro's header --or file caos_help.html-- for details about the
;     module itself).
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;    dmc_gen_default
; 
; ROUTINE MODIFICATION HISTORY:
;    routine written: february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
pro dmc_gen_default

info = dmc_info()               ; obtain module infos

module = gen_def_module(info.mod_name, info.ver)
                                ; generate module descrip. structure
time_delay = 0                  ; "delay" over 0 iterations

mirdef_file = " "
alt         = 0.
stroke      = 5.

par = $
   {  $
   dmc,                         $ ; structure named dmi
   module     : module,         $ ; standard module description structure
   time_delay : time_delay,     $ ;
   mirdef_file: mirdef_file,    $ ; mirror deformations file address
   alt        : alt,            $ ; conjugation altitude [m]
   tel        : 0,              $ ; mirror type of position [0=[0,0,0], 1=elsewhere]
   dist       : 0.,             $ ; distance (r) of mirror from position [0,0,0] ([m])
   angle      : 0.d0,           $ ; position angle of mirror [deg]
   stroke     : stroke          $ ; maximum stroke [microns]
   }

save, par, FILENAME=info.def_file
end