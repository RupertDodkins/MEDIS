; $Id: cfb_gen_default.pro,v 7.0 2016/04/27 marcel.carbillet $
;+
; NAME:
;    cfb_gen_default
;
; PURPOSE:
;    cfb_gen_default generates the default parameter structure for the CFB
;    module and save it in the rigth location (see cfb.pro's header --or
;    file caos_help.html-- for details about the module itself).
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;    cfb_gen_default
; 
; MODIFICATION HISTORY:
;    program written: Nov 1999,
;                     B. Femenia   (OAA) [bfemenia@arcetri.astro.it]
;    modifications  : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -"mod_type"->"mod_name"
;                     (for version 4.0 of the whole Software System CAOS").
;                    -useless parameters "init_file" and "init_save" eliminated.
;                   : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
PRO cfb_gen_default

info = cfb_info()                                 ; obtain module infos

module = gen_def_module(info.mod_name, info.ver)  ; generate module description structure.

par = $
   {  $
     cfb                  , $  ; structure named cfb
     module   : module    , $  ; module description structure
     fwhm     : 0.5       , $  ; FWHM of geometric projection of fiber on
                            $  ;       plane where tts detector is placed [arcsecs]
     n_phot   : 1e8       , $  ; Number of photons/m^2/s from Fiber.
     diameter : 8.0       , $  ; Telescope diameter [m]
     wf_nb_pxl: 256l      , $  ; Linear number of pixels used to sample wavefront.
     eps      : 0.          $  ; Telescope obstruction ratio
   }


SAVE, par, FILENAME=info.def_file ; save the default parameters structure in the file def_file

return                            ;back to calling program
END