; $Id: rft_init.pro,v 1.0 last revision 2016/05/17 Andrea La Camera $
;+
; NAME:
;    rft_init
;
; PURPOSE:
;    rft_init executes the initialization for the Read FiTs file (RFT) module, 
;    that is:
;       0- check the formal validity of the output structure
;       1- initialize the output structure out_img_t
;    (see rft.pro's header --or file airy_help.html-- for details
;    about the module itself).
;
; CATEGORY:
;    module's initialization routine
;
; CALLING SEQUENCE:
;    error = rft_init(out_img_t, $ ; img_t output structure
;                     par        $ ; parameters structure
;                     )
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.:
;    see rft.pro's help for a detailed description.
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: october 2000,
;                     Serge Correia (OAA) [correia@arcetri.astro.it].
;    modifications  : february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -"mod_type"->"mod_name".
;                     (for version 4.0 of the whole system CAOS).
;                   : november 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -output tags "background" and "snr" are now already
;                     defined as vectors.
;                   : december 2005,
;                     Gabriele Desidera' (DISI) [desidera@disi.unige.it]:
;                    -output tags "time_integ" is now active for the output
;                     structure.
;                   : may 2007,
;                     Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr]:
;                    -now works also with one-dimensional data (n_img
;                     definition adapted).
;                   : february 2011,
;                     Andrea La Camera (DISI) [lacamera@disi.unige.it]:
;                    -tags "angle", "snr" and "int_time" added to output structure
;                   : from CAOS_PSE v 7.0 (2016) 
;                    -this module has been moved from AIRY 6.1 to the new 
;                     package "Utilities". Version number has been
;                     reset to 1.0. 
;                    -angle has been deleted
;                    -header is now saved within the img_t structure
;                     by using a pointer
;                    -background is now an array NxNxP (event. P=1)
;                    -simplified the init procedure
;-
;
function rft_init, out_img_t, $ ; output structure
                   par          ; RFT parameters structure

; error code initialization
error = !caos_error.ok

; retrieve the module's informations
info = rft_info()

; get the individual output structure types
if info.out_type ne '' then out_type = str_sep(info.out_type,",")

; STANDARD CHECKS
;
; compute and test the requested number of rft arguments
n_par = 1  ; the parameter structure is always present within the arguments
if info.inp_type ne '' then begin
   inp_type = str_sep(info.inp_type,",")
   n_inp    = n_elements(inp_type)
endif else n_inp = 0
if info.out_type ne '' then begin
   out_type = str_sep(info.out_type,",")
   n_out    = n_elements(out_type)
endif else n_out = 0
n_par = n_par + n_inp + n_out
if n_params() ne n_par then message, 'wrong number of arguments'

; test the parameter structure
if test_type(par, /STRUCTURE, N_ELEMENTS=n) then $
   message, 'RFT error: par must be a structure'
if n ne 1 then message, 'RFT error: par cannot be a vector of structures'
if strlowcase(tag_names(par, /STRUCTURE_NAME)) ne info.mod_name then $
   message, 'par must be a parameter structure for the module RFT'
;
; END OF STANDARD CHECKS


image = readfits(par.filename, header)

;image assumed to be a square
npixel = (size(image))[1]

;nb of images
dummy  = (size(image))[0]
if (dummy eq 1 or dummy eq 2) then n_img = 1 $
else if (dummy eq 3) then n_img = (size(image))[3]

if dummy EQ 1 then bg = fltarr(npixel) else bg = fltarr(npixel,npixel,n_img)

;Integration Times for loaded image
if par.int_time_ok then begin
    int_time = par.int_time 
endif else begin
    int_time= make_array(360,2)
    int_time[*,1]=1.
endelse


; initializing output structure
out_img_t =                           $
   {                                  $
   data_type  : out_type[0],          $
   data_status: !caos_data.valid,     $
   image      : image,                $ ; image/psf data cube
   header     : PTR_NEW(''),          $ ; header of the FITS file
   npixel     : npixel,               $ ; number of pixels
   time_integ : int_time,             $ ; Integration time for each image [s]
   time_delay : 0.,                   $ ; [NOT USED WITHIN AIRY]
   psf        : par.psf,              $ ; This indicates that this is an IMAGE
                                        ; from a convolution of the PSF with
                                        ; the object contained in the input.
   resolution : par.resolution,       $ ; Pixel size [arcsec/pix]
   lambda     : par.lambda,           $ ; Mean detection wavelength [m]
   width      : par.width,            $ ; Wavelength band width [m]
   background : bg,                   $ ; an array !
   snr        : fltarr(360)           $ ; [NOT YET EVALUATED]
   }

*out_img_t.header = header ; update the pointer

; back to calling program
return, error
end
