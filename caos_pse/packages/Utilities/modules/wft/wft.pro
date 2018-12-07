; $Id: wft.pro,v 1.0 last revision 2016/04/29 Andrea La Camera $
;+
; NAME:
;    wft
;
; ROUTINE'S PURPOSE:
;    WFT executes the simulation for the Write FiTs (WFT) module.
;
; MODULE'S PURPOSE:
;    Using WFT, output structures image (img_t) can be saved in .fits format 
;    which header contains parameters of the image structure.
;
; CATEGORY:
;    main module's routine
;
; CALLING SEQUENCE:
;    error = wft(inp_img_t, $
;                par  )
;
; OUTPUT:
;    error: long scalar (error code, see !caos_error var in caos_init.pro).
;
; INPUTS:
;    inp_img_t: structure of type img_t (image type).
;    par      : parameters structure from wft_gui.
;
; KEYWORD PARAMETERS:
;    none
;
; COMMON BLOCKS:
;    common caos_block, tot_iter, this_iter
;
;    tot_iter   : total number of iteration during the simulation run.
;    this_iter  : current iteration number.
;
; SIDE EFFECTS:
;       none.
;
; RESTRICTIONS:
;       none.
;
; CALLED NON-IDL FUNCTIONS:
;       
;    imstruc_to_fits.pro
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: october 2000,
;                     Serge Correia (OAA) [correia@arcetri.astro.it].
;    modifications  : february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -use of variable "calibration" eliminited for version 4.0
;                     of the whole system CAOS.
;
; MODULE MODIFICATION HISTORY:
;    module written : Serge Correia (OAA) [correia@arcetri.astro.it].
;    modifications  : for version 2.0,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -no more use of the common variable "calibration" and
;                     the tag "calib" (structure "info") for version 4.0 of
;                     the whole Software System CAOS.
;     modification  : for version 3.0,
;                     Gabriele Desidera' (DISI, Universita' di Genova) [desidera@disi.unige.it]
;                    -add the possibility to write multiple images for multiple iterations  
;                   : for version 5.0,
;                     Andrea La Camera (DISI) [lacamera@disi.unige.it],
;                     Gabriele Desidera' (DISI) [desidera@disi.unige.it]:
;                    -multi-frame case implemented,
;                    -FITS header completed (imstruc_to_fits.pro modified),
;                    -INIT eliminated (obsolete).
;                   : February 2012,
;                     Andrea La Camera (DISI) [lacamera@disi.unige.it]:
;                    -New way to call AIRY_HELP. By using the "online_help" 
;                     routine, we resolved a known-issue of the Soft.Pack.
;                   : from CAOS_PSE v 7.0 (2016) 
;                    -this module has been moved from AIRY 6.1 to the new 
;                     package "Utilities". Version number has been
;                     reset to 1.0. 
;                   : may 2016,
;                     Andrea La Camera (DIBRIS) [andrea.lacamera@unige.it]:
;                    -header (if present, defined by previous modules) is
;                     saved, together with the usual WFT keywords. 
;                    -TIME_IN change in EXPTIME (worldwide used)
;                    -small changes in imstruc_to_fits.pro
;-
;
function wft, inp_img_t, $ ; input structure
              par          ; parameters from wft_gui

common caos_block, tot_iter, this_iter

; initialization of the error code: set to "no error" as default
error = !caos_error.ok

; module's actions
if (this_iter eq 0) then begin
   ; initialisation section
   error = wft_init(inp_img_t, par)
endif else begin
   ; run section
   error = wft_prog(inp_img_t, par)
endelse

; back to calling program.
return, error                   ; back to calling program.
end
