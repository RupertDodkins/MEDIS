; $Id: pyr_init.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    pyr_init
;
; PURPOSE:
;    pyr_init executes the initialization for the PYRamid
;    wavefront sensor (PYR), that is:
;
;    0- check the formal validity of the input/output structure.
;    1- initialize the output structure out_pyr_t. 
;    (see pyr.pro's header --or file caos_help.html-- for details
;    about the module itself). 
; 
; CATEGORY:
;    module's initialisation routine
;
; CALLING SEQUENCE:
;    error = pyr_init(inp_wfp_t, $ ; wfp_t input structure
;                     out_mim_t1, $ ; mim_t output structure 
;                     out_img_t2, $ ; mim_t output structure 
;		      par      , $ ; parameters structure
;                     INIT=init  ) ; initialisation data structure
;
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.: 
;    see pyr.pro's help for a detailed description. 
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: june 2001,
;                     Christophe Verinaud (OAA) [verinaud@arcetri.astro.it].
;
;    modifications  : september 2001,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -option for FFTWND added.
;                   : october 2002,
;                     Christophe Verinaud (OAA) [verinaud@arcetri.astro.it].
;                    -phase mask alternative added.
;                    -second output containing the image on the pyramid vertex added.
;                   : january/february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -"info.mod_type"->"info.mod_name"
;                     (for version 4.0 of the whole Software System CAOS).
;                    -init file management eliminated.
;                    -second output in now an img_t (image type) instead of a
;                     mim_t (multiple image type). + corrected tags of it.
;                   : february 2003,
;                     Christophe Verinaud (ESO) [cverinau@eso.org]:
;                    - slight modification of out_mim_t.nxsub/npixpersub
;                      for permitting display of slo measurements
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;-
;
function pyr_init, inp_wfp_t, out_mim_t1, out_img_t2, par, INIT=init

; CAOS global common block
common caos_block, tot_iter, this_iter
common noise_seed,seed_pn,seed_ron,seed_dk

seed_pn  = 1001
seed_ron = 2002
seed_dk  = 3003

psf_sampling = par.psf_sampling

n_pyr = par.n_pyr ; Here =1 (>1 for MAOS pack)

; error code initialization
error = !caos_error.ok

; retrieve the module's informations
info  = pyr_info()

; get the individual output structure types
if info.out_type ne '' then out_type = str_sep(info.out_type,",")

; STANDARD CHECKS
; compute and test the requested number of pyr arguments
n_par = 1                     ; Parameter structure (GUI) always in args. list
IF info.inp_type NE '' THEN BEGIN
    inp_type = STR_SEP(info.inp_type,",")
    n_inp    = N_ELEMENTS(inp_type)
ENDIF ELSE BEGIN
    n_inp    = 0
ENDELSE
IF info.out_type NE '' THEN BEGIN
    out_type = STR_SEP(info.out_type,",")
    n_out    = N_ELEMENTS(out_type)
ENDIF ELSE BEGIN
    n_out    = 0
ENDELSE
n_par = n_par + n_inp + n_out
IF N_PARAMS() NE n_par THEN MESSAGE, 'wrong number of parameters'

; test the parameter structure
IF TEST_TYPE(par, /STRUCTURE, N_ELEMENTS=n) THEN $
   MESSAGE, 'pyr error: par must be a structure'             
IF n NE 1 THEN MESSAGE, 'pyr error: par cannot be a vector of structures'
IF STRLOWCASE(TAG_NAMES(par, /STRUCTURE_NAME)) NE info.mod_name THEN $
   MESSAGE, 'par must be a parameter structure for the module pyr'

; check the input arguments

; test if any optional input exists
IF n_inp GT 0 THEN BEGIN
    inp_opt = info.inp_opt
ENDIF

dummy = test_type(inp_wfp_t,TYPE=type)
IF (type EQ 0) THEN BEGIN         ; undefined variable
   inp_wfp_t = $
      {        $
      data_type  : inp_type[0],         $
      data_status: !caos_data.not_valid $
      }
ENDIF
IF test_type(inp_wfp_t, /STRUC, N_EL=n, TYPE=type) THEN $
  MESSAGE, 'pyr error: wrong input definition.'
IF (n NE 1) THEN MESSAGE, 'pyr error: input cannot be a vector of structures'

; test the data type
IF inp_wfp_t.data_type NE inp_type[0] THEN MESSAGE, $
  'wrong input data type: '+inp_wfp_t.data_type +' ('+inp_type[0]+' expected)'
IF (inp_wfp_t.data_status EQ !caos_data.not_valid) AND (NOT inp_opt[0]) THEN $
  MESSAGE, 'undefined input is not allowed'

; reporting WARNING message is inp_wfp_t.correction is detected
; => user may have not realized he/she is using a wf containing 
;    only correcting  mirror shape
IF inp_wfp_t.correction THEN BEGIN 
   st1= ['pyr has detected the WFP_T input is marked with flag CORRECTION  ', $
         '1B meaning that you will visualize a correcting mirror shape.    ', $
         ''                                                                 , $
         'If you agree with this just click on YES to continue the', $
         'program. Otherwise click on NO to abort the program.    ']
   dummy = DIALOG_MESSAGE(st1,/QUEST, TITLE='pyr warning')
   IF (dummy EQ 'No') THEN BEGIN 
      PRINT,'pyr: Simulation aborted as requested by user.'
      error = !caos_error.pyr.using_correction
      RETURN,error
   ENDIF 
ENDIF 


; STRUCTURE "INIT" DEFINITION
;
   size  = (size(inp_wfp_t.pupil))[1]
   pupil =  inp_wfp_t.pupil
   npixtot = 1*(par.nxsub) ; linear nb of px (abd subap) over one quadrant

; PYR SENSOR GEOMETRY BEEING BUILT (Pyramid itself (transmission or
; phase mask) +  definitionof subapertures (similar to SH))

   sensor_geom = makesensor_pyr(par,par.nxsub, par.fvalid, size, pupil,$ 
                                 psf_sampling,par.sep, par.modul[0:par.n_pyr-1],$
                                 par.step[0:par.n_pyr-1],par.fftwnd,$
				 (size(inp_wfp_t.screen))[1]*inp_wfp_t.scale_atm)
   mm = sensor_geom.masque				 
   sizen=sensor_geom.sizen
   px = sensor_geom.px

   size_CCD = npixtot
   ; linear number of CCD pixels in the sensor CCD image

   xspos_CCD = round(((sensor_geom.cen_pupil[0,*]+0.5)*size_CCD/sizen) - 0.5)
   yspos_CCD = round(((sensor_geom.cen_pupil[1,*]+0.5)*size_CCD/sizen) - 0.5)
   ; positions of the sub-aperture centers on the CCD_array
 
   ; Rebinning parameters from wfs image (size) to the CCD array (size_CCD)
   ;
   ; we take advantage of the x-y symmetry and of the fact that there is an
   ; integer number of sampling points on the wavefront sensor as well as an
   ; integer number of camera pixels on the same sensor.
 
  
   ; Initialisation for the number of photons received per pixel
   ;
   tpup = total(inp_wfp_t.pupil)

   IF inp_wfp_t.dist_z NE !values.f_infinity THEN flag = 1 ELSE flag = 0
   ; distinction between the NGS and LGS (monochromatic) cases

   qe    = fltarr(n_elements(inp_wfp_t.lambda))
   qe[*] =  par.qe

   phot_det=fltarr(n_pyr)
   back_det=fltarr(n_pyr)

;; TEST ON WAVELENGTH: if OK also compute total Nb of photons from source
;; and from sky background. 

dummy     = N_PHOT(1.,BAND=dummy1,LAMBDA=dummy2,WIDTH=dummy3)
band_tab  = dummy1
lambda_tab= dummy2
width_tab = dummy3
n_band    = N_ELEMENTS(band_tab)
f_band    = FLTARR(n_band)

for kk = 0, n_pyr  - 1 do begin

if n_pyr gt 1 then dummy   = WHERE(inp_wfp_t.n_phot[*,kk],c1); for MAOS only
if n_pyr eq 1 then dummy   = WHERE(inp_wfp_t.n_phot[*],c1)
lambda1 = par.lambda - par.width/2
lambda2 = par.lambda + par.width/2 

CASE 1 OF 

  (c1 EQ 1): BEGIN                                         ;This case corresponds to Na LGS!!
      
      band1         = lambda_tab[dummy[0]]-width_tab[dummy[0]]/2.
      band2         = lambda_tab[dummy[0]]+width_tab[dummy[0]]/2.
      f_band[dummy] = INTERVAL2(lambda1,lambda2,band1,band2,d1,d2)
      
   END 

   (c1 GT 1): BEGIN

      dummy   = CLOSEST(par.lambda,lambda_tab)

      IF ((ABS(par.lambda - lambda_tab[dummy]) LT 1e-12)  AND        $ ;;Wavelength range selected coincides with  
          (ABS(par.width  - width_tab[dummy ]) LT 1e-12)) THEN BEGIN   ;; a standard band.

         f_band[dummy] = 1.

      ENDIF ELSE BEGIN                                              ;;Wavelength range selected ooverlaps two or
                                                                    ;; more standard bands or is a fraction of a band
         FOR i=0,n_band-1 DO BEGIN
            band1 = lambda_tab[i]-width_tab[i]/2.
            band2 = lambda_tab[i]+width_tab[i]/2.
            f_band[i] = INTERVAL2(lambda1, lambda2, band1, band2, d1, d2)
            lambda1 = d1
            lambda2 = d2
         ENDFOR 

      ENDELSE 

   END 

   (c1 LT 1): MESSAGE,'Error: no photons in any band!!'

ENDCASE 


dummy = WHERE(f_band,c1)

IF (c1 EQ 0) THEN BEGIN

    MESSAGE,'IMG operating band is not within wavelength' + $
     ' range considered in SOURCE',CONT = NOT(!caos_debug)
    error = !caos_error.img.invalid_band
    RETURN, error
  
ENDIF ELSE  BEGIN 

 if n_pyr gt 1 then  n_phot = TOTAL(inp_wfp_t.n_phot[*,kk]*f_band)*$                ;Photons per base-time unit from SRC
     inp_wfp_t.delta_t
if n_pyr eq 1 then  n_phot = TOTAL(inp_wfp_t.n_phot[*]*f_band)*$                ;Photons per base-time unit from SRC
     inp_wfp_t.delta_t

ENDELSE 

 ; bg_sky = TOTAL(inp_wfp_t.background*f_band)* $           ;Photons per base-time per IMG pxl from SKY BACKG
 ;    inp_wfp_t.delta_t *par.pxsize^2


IF (n_phot LT 1e-6) THEN BEGIN 
   MESSAGE,'IMG operating band is not within SRC emitting' + $
     ' wavelength range (i.e. LGS)',CONT = NOT(!caos_debug)
   error = !caos_error.img.invalid_band
   RETURN, error
ENDIF 
   
phot_det[kk] = qe[0] * n_phot

;print,qe[0],n_phot

 
ENDFOR ; end of the loop on the guide stars


IF error NE !caos_error.ok THEN return, error
 
   starnph = phot_det / tpup 
 
   dark = par.dark * inp_wfp_t.delta_t

  skynph = qe[0]*TOTAL(inp_wfp_t.background[*,0]*f_band)* $           
    inp_wfp_t.delta_t /(4.*sensor_geom.nsp) *!DPI*(0.5*par.pyr_Fov)^2

;Photons per ; ;base-time per IMG pxl from SKY BACKG
   ref_image=dblarr(2*par.nxsub,2*par.nxsub)

posxk=dblarr(4) 

posyk=posxk 


;*** computation of distance in pixels between the pupils (phase mask only)***

le_shift = size*par.sep/2.

posxk[0] = -1.*le_shift
posyk[0] = -1.*le_shift

posxk[1] = 1.*le_shift
posyk[1] = -1.*le_shift

posxk[2] = 1.*le_shift
posyk[2] = 1.*le_shift

posxk[3] = -1.*le_shift
posyk[3] = 1.*le_shift

      
   ; Creating the structure characteristics of the pyramid geometry
   init = $
   {   $
   px 	       : px,		      $
   posxk       : posxk,		      $
   posyk       : posyk,               $
   size        : size,                $ ; pupil array size containing the wfs
   psf_sampling: psf_sampling,        $ ; psf_sampling points of the psf
   sizen       : sensor_geom.sizen,   $ ; new size of WFS (rebinned)
   pxsize      : par.pxsize,	      $ ; always=1 (irrelevant since in pupil plane)
   nsp         : sensor_geom.nsp,     $ ; total number of active sub-apertures
                                        ; [integer]
   tsp         : sensor_geom.tsp,     $ ; number of active sampling points
                                        ; per sub-ap [(nsp) vector of floats]
   masque      : sensor_geom.masque,  $ ; masque correspondign to one quadrant
;   mm          : mm,                  $
   sensor_s1   : sensor_geom.sensor_s1,$; sensor active sub-aperture image
   
   sub_map     : sensor_geom.sub_map, $ ; sub-ap maps [(ceil(nxp)+1,ceil(nxp+1),
                                        ; nsp) matrix of floats]
   xlim        : sensor_geom.xlim,    $ ; the inf and max limits of each sub-ap
                                        ; in size_ima^2 array
                                        ; [(2,nsp) matrix of long]
   ylim        : sensor_geom.ylim,    $ ; the inf and max limits of each sub-ap
                                        ; in size_ima^2 array
                                        ; [(2,nsp) matrix of long]
   size_CCD    : size_CCD,            $ ; wavefront sensor size in camera pixels
                                        ; [integer]
   xspos_CCD   : xspos_CCD,           $ ; sub-ap center x-positions on the CCD
                                        ; [nsp vector of floats]
   yspos_CCD   : yspos_CCD,           $ ; sub-ap center y-positions on the CCD
                                        ; [nsp vector of floats]
   tpyr        : sensor_geom.tpyr,    $ ; normalisation factor for intensity
                                        ; computation (takes into account all
                                        ; intensity in pupil and diffracted outside)
   starnph     : starnph,             $ ; nb of detected photons from star per
                                        ; sampling point in simulation time unit
  skynph      : skynph,              $ ; nb of detected photons from bckgnd per
   ;                                     ; sampling point in simulation time unit

   dark        : dark,                $ ; dark noise
                                        ; [nb of electrons]
   rnoise      : par.rnoise,          $ ; read-out-noise
                                        ; [rms number of electrons]
   noise       : par.noise,                  $ ; noise is always considered !!
   threshold   : par.threshold        $ ; threshold to apply [0<=threshold<=1]
   }


; INITIALIZE THE OUTPUT STRUCTURE
;

error = pyr_image(inp_wfp_t, init, par, ref_image,par.fftwnd)

; computes the pyr reference image, used by SLO for computing the
; reference measurement set
;if error ne !caos_error.ok then return, error


if par.optcoad eq 0B then begin
xspos = init.xspos_CCD
yspos = init.yspos_CCD
endif

if par.optcoad eq 1B then begin ; for Layer Oriented only (MAOS pack) 
xspos = le_shift
yspos = par.nxsub
endif

out_mim_t1 = $
   {         $
   data_type  : out_type[0],      $
   data_status: !caos_data.valid, $
   image      : ref_image,	  $
   npixpersub : 1        ,        $ ; (1 px = 1 sub-ap)
   pxsize     : 0.,               $ ; (this is not the image plane!!)
   nxsub      : par.nxsub,        	  $ ; (2x2 = 4 quadrants)
   convert    : inp_wfp_t.delta_t,$ ; [NOT USED AS CONVERT]
   nsp        : init.nsp,         $
   xspos_CCD  : xspos,	          $
   yspos_CCD  : yspos,            $
   step       : 0.,               $
   type       : 0,                $ ; square geometry
   lambda     : par.lambda,       $
   width      : par.width         $
   }

out_img_t2 = $
   {         $
   data_type  : out_type[1],      $
   data_status: !caos_data.valid, $
   image      : dblarr(size*psf_sampling,size*psf_sampling), $
   npixel     : size*psf_sampling,$ ;
   resolution : par.lambda/(inp_wfp_t.scale_atm*size)*!RADEG*3600./psf_sampling,	  $ ;
   lambda     : par.lambda,       $
   width      : par.width,        $
   time_integ : par.time_integ,   $
   time_delay : par.time_delay,   $
   psf        : 0B,               $ this is a priori not a PSF
   background : 0.,               $ [NOT USED]
   snr        : 0.                $ [NOT USED]
   }

return, error
end