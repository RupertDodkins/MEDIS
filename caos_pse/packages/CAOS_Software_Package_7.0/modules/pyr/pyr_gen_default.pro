; $Id: pyr_gen_default.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    pyr_gen_default
;
; PURPOSE:
;    pyr_gen_default generates the default parameter structure for the PYR
;    module and save it in the rigth location.
;    (see pyr.pro's header --or file caos_help.html-- for details about the
;     module itself).
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;    pyr_gen_default
; 
; ROUTINE MODIFICATION HISTORY:
;    routine written: june 2001,
;                     Christophe Verinaud (OAA) [verinaud@arcetri.astro.it].
;    modifications  : september 2001,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -a few modifications.
;                   : october 2002,
;                     Christophe Verinaud (OAA) [verinaud@arcetri.astro.it].
;                    -new tags for phase mask alternative.
;                   : january/february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -"info.mod_type"->"info.mod_name"
;                    -init and calib stuff eliminated.
;                     (both for version 4.0 of the whole Software System CAOS").
;                   : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
pro pyr_gen_default

; obtain module infos
info = pyr_info()

; generate module description structure
module = gen_def_module(info.mod_name, info.ver)

time_integ = fix(1)>1           ; short integer, scalar and ge 1.
                                ; number of iterations for which the output
                                ; is integrated (summed).

time_delay = fix(0)>0           ; short integer, scalar and ge 0.
                                ; the number of iteration for which the output
                                ; is delayed.

; parameter structure
par = $
   {  $
   pyr,                            $ ; structure named pyr
   module       : module,          $ ; module description structure

   time_integ   : 1,               $ ; integration time [base-time unit]
   time_delay   : 0,               $ ; delay time [base-time unit]

   n_pyr        : 1,               $ ; nb of pyramids(used only by MAOS pack)
   pxsize	: 1.,	           $ ; in each quadrant 1 subap. = 1 px
   geom_type 	: 0,               $ ; 0 = square
   sep          : 1.28125,         $ ; separation between centre of 2 pupils in pyr detector
   psf_sampling : 4,               $ ; number of pix per Lamb/D in image on top of pyr
   nxsub	: 16,	           $ ; linear nb of subapertures
   lambda	: 700e-9,          $ 
   width	: 400e-9,          $
   qe_type      : 0,               $ ; type of QE profile 0=uniform QE
                                   $ ;  1=standard EEV CCD profile [N/A]
   qe           : 1.,              $ ; constant or maximum QE 
   noise        : 0B,              $ ; include effect of noise? [0=no,1=yes]
   background   : 0B,              $
   pyr_fov      : 2.,              $ ; Fov of pyramid (circular diaphragm)
   rnoise       : 0.,              $ ; rms read noise [e-]
   dark         : 0.,              $ ; dark noise [e- per second]
   threshold    : 0,               $ ; threshold on WFS in counts (>=0)
   fvalid       : .6,              $ ; ratio of illumination for which a
                                     ; subaperture is considered valid
   modul        : replicate(0.,1), $ ; modulation (+-) in lambda/D
   step	        : replicate(1.,1), $ ; number of steps of modulation (about 8 per lambda/D)
   wfsdiam      : 1.,              $
   fftwnd       : 0B,              $ ; use FFTW
   mod_type     : 1B,              $ ; 1B: circular or 0B:square modulation
   optcoad      : 0B,              $ ; for Layer Oriented only (used by MAOS pack)
   algo         : 1B	           $ ; 1B phase mask or 0B :transmission mask
}

; save the default parameters structure in the file def_file
save, par, FILENAME=info.def_file

;back to calling program
end