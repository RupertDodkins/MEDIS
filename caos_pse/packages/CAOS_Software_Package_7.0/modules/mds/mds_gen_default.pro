; $Id: mds_gen_default.pro,v 7.0 2016/04/29 marcel.carbillet $
;+
; NAME:
;    mds_gen_default
;
; PURPOSE:
;    mds_gen_default generates the default parameter structure
;    for the MDS module and save it in the rigth location.
;    The user doesn't need to use mds_gen_default, it is used
;    only for developing and upgrading purposes. (see mds.pro's header
;    --or file caos_help.html-- for details about the module itself).
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;    mds_gen_default
;
; ROUTINE MODIFICATION HISTORY:
;    program written: june 2002,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it],
;                     Christophe Verinaud (OAA) [verinaud@arcetri.astro.it].
;    modifications  : january/february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -"mod_type"->"mod_name"
;                     (for version 4.0 of the whole Software System CAOS").
;                    -influence functions generation added (PZT case).
;                   : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
pro mds_gen_default

info = mds_info()

; Generate module description structure
module = gen_def_module(info.mod_name, info.ver)

par =   $
   {    $
   mds, $                      ; structure named mds
   module          : module, $ ; std tag: module desc. structure
   length          : 8.,     $ ; wf length [m]
   alt             : 0.,     $ ; layers' altitudes [m]
   mirdef_choice   : 0,      $ ; choice on mirror deformations type
                               ; [0=user-defined,
                               ;  1=Zernike polynomials,
                               ;  2=PZT influence functions (model),
                               ;  3=bimorph influence functions (model)]
; user-defined case:
   mirdef_file     : ' ',    $ ; file containing the mirror
; all other cases:
   dim             : 128,    $ ; wf nb of linear pixels
; Zernike case:
   zern_rad_degree : 90,     $ ; consider up to this radial degree for Zernike
; (square) PZT case:
   nb_act          : 8,      $ ; linear number of actuators
   eps             : .1,     $ ; pupil central obscuration
; bimorph case: TBD
; all cases:
   mirdef_amplitude: 2E-6    $ ; mirror deformations amplitude
   }

; save the default parameter structure in the default file
save, par, FILENAME=info.def_file

end