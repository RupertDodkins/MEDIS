; $Id: rft.pro,v 1.0 last revision 2016/04/29 Andrea La Camera $
;+
; NAME:
;    rft
;
; ROUTINE'S PURPOSE:
;    rft manages the simulation for the Read FiTs file (RFT) module.
;
; MODULE'S PURPOSE:
;    RFT read a FITS file provided in input.
;    Both cases of 2D input images and 3D input image cubes are supported.
;    Header's keywords can be used as input parameters of the image structures,
;    if they are labeled as :
;       resolut  = pixel size [arcsec] [float]
;       lambda   = Filter center wavelength [meters] [float]
;       width    = Filter width [meters] [float]
;       psf      = psf choice (1=psf, 0=image) [byte/integer]
;    Otherwise, parameters have to be set up by means of the GUI of the module.
;
; CATEGORY:
;    main module's routine
;
; CALLING SEQUENCE:
;    error = rft(out_img_t, $ ; output structure
;                par        ) ; parameter structure
;
; OUTPUT:
;    error: long scalar (error code, see !caos_error var in caos_init.pro).
;
; INPUTS:
;    par      : parameters structure.
;
; INCLUDED OUTPUTS:
;    out_img_t: structure of type img_t.
;
; KEYWORD PARAMETERS:
;    none.
;
; COMMON BLOCKS:
;    common caos_block, tot_iter, this_iter
;
;    tot_iter   : total number of iteration during the simulation run.
;    this_iter  : current iteration number.
;
; SIDE EFFECTS:
;    none.
;
; RESTRICTIONS:
;    This module is designed for restoring of data cubes once, during the
;    initialization phase. It is not designed for sequencial restoring of
;    structures iteration after iteration. For this reason it is more likely
;    to be used within the package AIRY (Algorithms for Image Restoration in
;    interferometrY), than within the original CAOS (Code for Adaptive Optics
;    Systems) package. In addition it needs the astrolib package for restoring
;    of FITS format data cubes.
;
; CALLED NON-IDL FUNCTIONS:
;    routines of the astrolib package for the FITS format management.
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: oct 2000,
;                     Serge Correia (OAA) [marcel@arcetri.astro.it].
;    modifications  : february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -use of variable "calibration" eliminited for version 4.0
;                     of the whole system CAOS.
;
; MODULE MODIFICATION HISTORY:
;    module written : version beta,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it],
;                     Serge  Correia   (OAA) [marcel@arcetri.astro.it].
;    modifications  : for version 2.0,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -no more use of the common variable "calibration" and
;                     the tag "calib" (structure "info") for version 4.0 of
;                     the whole Software System CAOS.
;                   : for version 3.0,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -added better selection of central wavelength and band-width
;                    -global GUI reordering for better fitting in screens !
;                     Gabriele Desidera' (DISI) [desidera@disi.unige.it]:
;                    -added possibility to insert integration times in association
;                     with the loaded data cube.
;                   : february 2011,
;                     Andrea La Camera (DISI) [lacamera@disi.unige.it]:
;                    -"Insert hour angle" button and table added;
;                    -"Insert integration time" button and table changed;
;                    -New GUI design.
;                   : february 2012,
;                     Andrea La Camera (DISI) [lacamera@disi.unige.it]:
;                    -file "rft_time_gui.pro" and folder "rft_gui_lib" removed
;                     [unused and no more necessary]
;                    -New way to call AIRY_HELP. By using the "online_help" 
;                     routine, we resolved a known-issue of the Soft.Pack.
;                   : from CAOS_PSE v 7.0 (2016) 
;                    -this module has been moved from AIRY 6.1 to the new 
;                     package "Utilities". Version number has been
;                     reset to 1.0. 
;                    -parameters deleted: angle, angle_ok, read_keyword
;                    -the parameters can be now read from the FITS
;                     header. According to WFT module, they must be: PSF,
;                     NPIXEL, RESOLUT, LAMBDA, WIDTH, TIME_IN, TIME_IN*
;                    -the HEADER of the FITS file is now saved within
;                     the IMG_T structure and can be used/updated by
;                     other modules. 
;                    -Band L and M have been added to available filters
;                    -background is now an array NxNxP (event. P=1)
;-
;
function rft, out_img_t, $ ; output structure
              par          ; RFT parameters structure

; CAOS global common block
common caos_block, tot_iter, this_iter

; error code initialisation
error = !caos_error.ok

; module's actions
if (this_iter eq 0) then error = rft_init(out_img_t, par)

; back to calling program.
return, error
end
