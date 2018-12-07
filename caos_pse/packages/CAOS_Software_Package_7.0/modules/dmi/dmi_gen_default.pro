; $Id: dmi_gen_default.pro,v 7.0 2016/04/29 marcel.carbillet $
;+
; NAME:
;    dmi_gen_default
;
; PURPOSE:
;    dmi_gen_default generates the default parameter structure
;    for the DMI module and save it in the rigth location.
;    (see dmi.pro's header --or file caos_help.html-- for details about the
;     module itself).
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;    dmi_gen_default
; 
; ROUTINE MODIFICATION HISTORY:
;    routine written: may 1998,
;                     Francoise Delplancke (ESO) [fdelplan@eso.org].
;    modifications  : december 1999--january 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -enhanced and adapted to version 2.0 (CAOS).
;                   : january/february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -"mod_type"->"mod_name"
;                     (for version 4.0 of the whole Software System CAOS").
;                    -variables "init_save" and "init_file" eliminated.
;                    -influence generation part moved to module MDS
;                     (and old "advanced parameters" part eliminated in
;                      between because uncertain & not used).
;                    -"time_integ" variable eliminated (useless).
;                   : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
pro dmi_gen_default

info = dmi_info()               ; obtain module infos

module = gen_def_module(info.mod_name, info.ver)
                                ; generate module descrip. structure

par = $
   {  $
   dmi,                   $ ; structure named dmi
   module       : module, $ ; standard module description structure
   mirdef_file  : ' ',    $ ; mirror deformations file name
   time_delay   : 0,      $ ; time delay [base unit]
   stroke       : 5.      $ ; maximal stroke of actuators [microns]
   }

save, par, FILENAME=info.def_file

end