; $Id: rft_gen_default.pro,v 1.0 last revision 2016/04/29 Andrea La Camera $
;+
; NAME:
;    rft_gen_default
;
; PURPOSE:
;    rft_gen_default generates the default parameter structure for the RFT
;    module and save it in the right location.
;    (see rft.pro's header --or file airy_help.html-- for details about the
;     module itself).
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;    rft_gen_default
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: october 2000,
;                     serge correia (OAA) [correia@arcetri.astro.it].
;    modifications  : february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -"mod_type"->"mod_name"
;                     (for version 4.0 of the whole system CAOS).
;                   : december 2005,
;                     Gabriele Desidera' (DISI) [desidera@disi.unige.it]:
;                    -added parameters "int_time" and "delta_t" containing
;                     respectively the choice (YES or NO) to insert or not the 
;                     integration times
;                     for the loaded data cube and the integration times inserted.
;                   : february 2011,
;                     Andrea La Camera (DISI) [lacamera@disi.unige.it]:
;                    -delta_t variable modified in order to manage 360 values,
;                     instead of six. 
;                    -(old)int_time variable removed.
;                    -(old)delta_t has been renamed in (new)int_time.
;                    -int_time_ok and angle_ok variables inserted. 
;                   : from CAOS_PSE v 7.0 (2016) 
;                    -this module has been moved from AIRY 6.1 to the new 
;                     package "Utilities". Version number has been
;                     reset to 1.0. 
;                    -parameters deleted: angle, angle_ok, read_keywords
;-
;
pro rft_gen_default

; obtain module infos
info = rft_info()

; generate module description structure
module = gen_def_module(info.mod_name, info.ver)

int_time= make_array(360,2)
int_time[*,1]=1.

; parameter structure
par = $
   {  $
   rft,                     $ ; structure named rft
   module        : module,  $ ; module description structure
   filename      : '',      $ ; filename
   resolution    : 0.005,   $ ; pixel size [arcsec]
   int_time_ok   : 0B,      $ ; Insert Integration Times for image loaded 
                              ; (yes = 1B, no = 0B)
   int_time      : int_time,$ ; integration time for loaded image/psf data cube
   lambda        : 1.65e-6, $ ; filter center wavelength [meters]
   width         : 0.3e-6,  $ ; filter width [meters]
   psf           : 0B      $  ; psf choice (yes = 1B, no = 0B)
   }

; save the default parameters structure in the file def_file
save, par, FILENAME=info.def_file

;back to calling program
end
