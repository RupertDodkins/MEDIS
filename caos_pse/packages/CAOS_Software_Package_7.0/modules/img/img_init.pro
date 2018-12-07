; $Id: img_init.pro,v 7.0 2016/05/27 marcel.carbillet $
;+ 
; NAME: 
;    img_init 
; 
; PURPOSE: 
;    img_init executes the initialization for the IMaGer (IMG)
;    module, that is:
;
;    0- check the formal validity of the input/output structure.
;    1- initialize the output structure out_img_t. 
;
;    (see img.pro's header --or file caos_help.html-- for details
;    about the module itself). 
; 
; CATEGORY: 
;    Initialisation program.
; 
; CALLING SEQUENCE: 
;    error = img_init(inp_wfp_t , $ ; wfp_t input structure
;                     out_img_t1, $ ; img_t1 output structure 
;                     out_img_t2, $ ; img_t2 output structure
;                     par       , $ ; parameters structure
;                     INIT=init   $ ; initialisation data structure
;                     )
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.: 
;    see img.pro's help for a detailed description. 
; 
; MODIFICATION HISTORY: 
;    program written: Jan 2000,
;                     Bruno Femenia (OAA) [bfemenia@arcetri.astro.it]
;
;    modifications  : Feb 2000, 
;                     B. Femenia (OAA) [bfemenia@arcetri.astro.it]
;                    -Adding necessary tags to out_img_t structres 
;                     (new tags: lambda, width, time_integ,time_delay;
;                      changing name of pxsize  to resolution). 
;                   : february 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -quantum efficiency is now taken into account.
;                   : april 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -function air_ref_idx moved to CAOS library.
;                   : may 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -image type (of the outputs) updated.
;                   : october 2001,
;                     B. Femenia (OAA) [bfemenia@arcetri.astro.it]
;                    -IDL 5.4 handles SEEDs in calls to RANDOM such that now
;                     the initial seed has to be fed. Now having control
;                     over seeds to generate noise.
;                    -any user-defined spectral band can be selected now.
;                   : september 2002,
;                     B. Femenia (GTC) [bfemenia@ll.iac.es]
;                    -controlling noise seeds via COMMON blocks will result
;                     ambiguous in project with two or more IMG modules.
;                   : january/february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -!caos_error.img.* variables eliminated for
;                     compliance with the CAOS Software System, version 4.0.
;                    -"mod_type"->"mod_name"
;                    -no more use of common variable "calibration".
;                   : March 2003,
;                     B. Femenia (GTC) [bfemenia@ll.iac.es]
;                    -merging versions at OAA and GTC.
;                   : april 2014,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -image type (of the outputs) updated (tag "angle" added).
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;                    -image type (of the outputs) updated (tag "angle" eliminated).
;
;-
;
FUNCTION img_init, inp_wfp_t, out_img_t1, out_img_t2, par, INIT=init
   
   ;; CAOS global common block
   ;;=========================
   COMMON caos_block, tot_iter, this_iter

   ;; STANDARD CHECKS
   ;;================
   error = !caos_error.ok            ;Init error code: no error as default
   info  = img_info()                ;Retrieve the Input & Output info.

   ;; test the number of passed parameters corresponds to what there is in info
   ;;--------------------------------------------------------------------------
   n_par = 1                          ;Parameter structure (GUI) always in args. list

   IF info.inp_type NE '' THEN BEGIN
      inp_type = STR_SEP(info.inp_type, ",")
      n_inp    = N_ELEMENTS(inp_type)
   ENDIF ELSE BEGIN
      n_inp    = 0
   ENDELSE

   IF info.out_type NE '' THEN BEGIN
      out_type = STR_SEP(info.out_type, ",")
      n_out    = N_ELEMENTS(out_type)
   ENDIF ELSE BEGIN
      n_out    = 0
   ENDELSE

   n_par = n_par + n_inp + n_out

   IF N_PARAMS() NE n_par THEN MESSAGE, 'wrong number of parameters'

   ; test the parameter structure
   ;-----------------------------
   IF TEST_TYPE(par, /STRUCTURE, N_ELEMENTS=n) THEN $
     MESSAGE, 'IMG: par must be a structure'             
   
   IF n NE 1 THEN MESSAGE, 'IMG: par cannot be a vector of structures'

   IF STRLOWCASE(TAG_NAMES(par, /STRUCTURE_NAME)) NE info.mod_name THEN $
     MESSAGE, 'par must be a parameter structure for the module IMG'

   ; test if any optional input exists
   ;-----------------------------------
   IF n_inp GT 0 THEN BEGIN
      inp_opt = info.inp_opt
   ENDIF

   ; test the input argument
   ;-------------------------
   dummy = test_type(inp_wfp_t, TYPE=type)
   IF (type EQ 0) THEN BEGIN                          ; undefined variable
      inp_wfp_t = { $
                    data_type  : inp_type[0],         $
                    data_status: !caos_data.not_valid $
                  }
   ENDIF

   IF test_type(inp_wfp_t, /STRUC, N_EL=n, TYPE=type) THEN $
     MESSAGE, 'inp_wfp_t: wrong input definition.'

   IF (n NE 1) THEN MESSAGE, 'inp_wfp_t cannot be a vector of structures'

   ; test the data type
   ;-------------------
   IF inp_wfp_t.data_type NE inp_type[0] THEN MESSAGE, $
     'Wrong input data type: '+inp_wfp_t.data_type +' ('+inp_type[0]+' expected)'

   IF (inp_wfp_t.data_status EQ !caos_data.not_valid) AND (NOT inp_opt[0]) THEN $
     MESSAGE, 'Undefined input is not allowed'


   ;Reporting WARNING message is inp_wfp_t.correction is detected
   ; => user may have not realized he/she is using a 
   ; wf containing only correcting mirror shape
   ;-------------------------------------------------------------
   IF inp_wfp_t.correction THEN BEGIN 
      st1 = ['IMG has detected the WFP_T input is marked with flag CORRECTION  ', $
             '1B meaning that you will visualize a correcting mirror shape.    ', $
             '',                                                                  $
             'If you agree with this just click on YES to continue the',          $
             'program. Otherwise click on NO to abort the program.    '           ]
      dummy = DIALOG_MESSAGE(st1, /QUEST, TITLE='IMG warning')
      IF (dummy EQ 'No') THEN BEGIN 
         PRINT, 'IMG: Simulation aborted as requested by user.'
         error = !caos_error.module_error
         RETURN, error
      ENDIF
   ENDIF 

   ;;========================
   ;;1/ Defining useful vars.
   ;;========================

   np    = par.npixel                       ;Nb pixels on IMG detector
   nx    = N_ELEMENTS(inp_wfp_t.pupil[*,0]) ;Nb pixels to sample WF x&y-axes
   D     = inp_wfp_t.scale_atm*nx           ;Pupil diameter in [m]
   psIMG = par.pxsize                       ;Original IMG pixel size.
   scale = (air_ref_idx(par.lambda)/air_ref_idx(500e-9))*2.*!PI/par.lambda*COMPLEX(0,1)
                                            ;Accounts for wf lambda dependence,

   increase  = 1.                           ;Matrix Increasing factor. Comp'd later.
   rebin_fac = 1.                           ;Rebin factor. Computed later.
   axisMir   = (FINDGEN(nx)-(nx-1.)/2.)*inp_wfp_t.scale_atm
                                            ;Mirror axis in [m]

   ;==============================================================================
   ;2/ Expand PUPIL properly so that image through (FFT)^2 happens to be sampled
   ; with a px size which is that of IMG detector (if IMG requires a smaller pixel
   ; size that lambda/D) or an int. fraction of lambda/D (in case lambda/D>IMG px)
   ;==============================================================================

   increase = (par.lambda/D)/(par.pxsize*4.84814E-6)

   IF (ABS(increase-1.) LT 1e-3) THEN BEGIN ;Handles very special case where
      increase  = 1.                        ;pixel size = lambda/D
      rebin_fac = 1.
   ENDIF ELSE BEGIN 
      IF (increase LT 1.) THEN BEGIN        ;Finding factor to increase resolution
         dummy = CEIL(1./increase)          ;so to have an image sampled such      
         REPEAT BEGIN                       ;that the IMG pxl is an integer number
            factor = (dummy*increase)       ;of times the pixel image (to do REBIN) 
            dummy = dummy+ 1.
         ENDREP UNTIL NOT(dummy MOD 2) AND (ABS(factor-ROUND(factor))/ factor LT 0.99)
                                            ;The rebin factor is forced to be an odd number.

         rebin_fac   = ROUND(dummy-1.)
         increase    = factor
         IF (np GT 2) THEN par.increase = 1 ;PAR.INCREASE not considered for NxN 
                                            ;detector (N>2) with IMG pxl > WF pxl.
      ENDIF
   ENDELSE

   dim = ROUND(nx*increase)*par.increase   ;Size of new Pupil.
   rebin_fac = rebin_fac  *par.increase    ;Total REBIN factor.
   IF (dim MOD 2) THEN dim = dim+1         ;Forcing dim to be even.
   increase = FLOAT(dim)/FLOAT(nx)         ;FINAL increasing factor.

   IF (dim GE 4096) THEN BEGIN
      MESSAGE, 'Resolution parameters yield matrix larger than 4096x4096', /INFO
   ENDIF


   ps        = (par.lambda/D/increase)*rebin_fac
                             ;;New IMG pxl(slightly modified) in [rad]
   ps        = ps/4.84814e-6 ;;Now in [arcsec]
   pxsize_im = ps/rebin_fac  ;;Pxl size of image from FFT in [arcsec].

;Display information on image pixel changes
;------------------------------------------

   IF (ABS(ps-par.pxsize)/par.pxsize GT  0.01) THEN PRINT, FORMAT='(a,2x,f6.4,a)', $
                                               +'IMG pixel has changed.'           $
                                               +'New pixel is ', ps/par.pxsize,    $
                                               +' times original pixel'
                             ;;Inform the user if new pxsize differs in more than 1% wrt
                             ;; pxsize given by user in GUI.

   dummy = ROUND(par.pxsize/pxsize_im)

   par.pxsize = ps           ;;UPGRADING IMG PXSIZE IN PAR !!! In [arcsec].

   ;===============================================================================
   ;3/ Checking whether sampling of wavefront on pupil produces a FOV smaller that
   ;   the FOV of IMG detector. If that is the case, stop the program and report 
   ;   values concerning IMG pixel size and/or number of IMG pixels to use instead.
   ;===============================================================================

   fov_atm = dim*pxsize_im
   fov_img = np*par.pxsize

   IF (fov_atm LT fov_img) THEN BEGIN 
      
      CASE 1 OF 
         (np LT 10  ): st1 = STRING(np, FORMAT='(i2)')
         (np LT 100 ): st1 = STRING(np, FORMAT='(i3)')
         (np LT 1000): st1 = STRING(np, FORMAT='(i4)')
         ELSE        : st1 = STRING(np)
      ENDCASE 
      
      np_new = FLOOR(fov_atm/par.pxsize)
      CASE 1 OF
         (np_new MOD 2) AND NOT(np MOD 2): np_new = np_new-1
         NOT(np_new MOD 2) AND (np MOD 2): np_new = np_new-1
         ELSE: np_new = np_new
      ENDCASE 
      CASE 1 OF 
         (np_new LT 10  ): st2 = STRING(np_new, FORMAT='(i2)')
         (np_new LT 100 ): st2 = STRING(np_new, FORMAT='(i3)')
         (np_new LT 1000): st2 = STRING(np_new, FORMAT='(i4)')
         ELSE            : st2 = STRING(np_new)
      ENDCASE 
      
      st3 = ['Field of View selected in IMG GUI not compat' + $ 
             'ible with FOV in ATM module. Going like this',  $
             'would mean the presence of a FIELD STOP which'+ $
             ' is INEXISTENT in the system. By clicking on ', $
             'YES the number of IMG pixels will be changed ', $
             '',                                              $
             'from:'+st1,                                     $
             '',                                              $
             'to  :'+st2,                                     $
             '',                                              $
             'Otherwise click on NO and the program will '  + $
             'be aborted!!!',                                 $
             '',                                              $
             '',                                              $
             'SHALL I CHANGE THE NUMBER OF PIXELS IN IMG '  + $
             'DETECTOR?'                                      ]

      dummy = DIALOG_MESSAGE(st3, /QUEST, TITLE='IMG FOV warning')
      
      IF (dummy EQ 'No') THEN BEGIN 
         MESSAGE, 'Incompatible Fields of View defined in ' + $
                  'ATM and IMG modules. Define apropriate values!!', $
                  CONT=NOT(!caos_debug)
         error = !caos_error.module_error
         RETURN, error
      ENDIF ELSE BEGIN
         MESSAGE, 'Changing the number of IMG pixels to mak'+ $
                  'e its FOV compatible with that defined in ATM '+ $
                  'module. Number of IMG pixels was intially'+st1 + $
                  ' and has been changed to'+ st2, /INFO
         np        = np_new
         par.npixel = np
         
      ENDELSE
      
   ENDIF 

   ;;==============================================================================
   ;;4/ Introducing a wedge of half a pixel in BOTH x & y-axes to have the PSF with
   ;;   origin sampled properly if running a normal project. If the project is a 
   ;;   CALIBRATION one, wedge is only introduced for x-axis.
   ;;==============================================================================

   IF (np MOD 2) THEN BEGIN ;;If integer nb of px introduce a px_wf/2 offset
                            ;;to sample image center on detector with 4 px
      wedge   = FLTARR(nx, nx)
      axisCCD = (FINDGEN(np)-FIX(np)/2)*par.pxsize
                            ;;Axis for CCD matrix
      axisPSF = (FINDGEN(dim)-FIX(dim)/2)*pxsize_im
                            ;;Axis for FFT image on detector plane
   ENDIF ELSE BEGIN
      dummy = -axisMir*pxsize_im*2.42407e-6
      wedge = REBIN(dummy, nx, nx)
                            ;;Additional 1/2pxl wf wedge in [m]
      wedge = wedge + TRANSPOSE(wedge)
                            ;;wedge in both axes.
      axisCCD = (FINDGEN(np)-(np-1.)/2.)*par.pxsize
                            ;;Axis for CCD matrix
      axisPsf = (FINDGEN(dim)-dim/2)* pxsize_im + pxsize_im/2.
                            ;;Axis for FFT image on detector plane
   ENDELSE                  ;;Taking into account 1/2pxl tilt!!

   b1 = (CLOSEST(axisCCD[0],   axisPsf)-FIX(rebin_fac)/2) > 0
   b2 = (CLOSEST(axisCCD[np-1], axisPsf)+FIX(rebin_fac)/2) < (dim-1)

   ;;=======================================================================
   ;;6/ Generating matrix with r^2 needed for the aberration function due to
   ;;   DEFOCUS ABERRATION.
   ;;=======================================================================

   dummy1  = REBIN(axisMir, nx, nx) 
   dummy2  = TRANSPOSE(dummy1)
   r2_array = dummy1^2+dummy2^2

   ;;=========================================================================
   ;;7/ TEST ON WAVELENGTH: if OK also compute total Nb of photons from source
   ;;   and from sky background. 
   ;;=========================================================================

   dummy     = N_PHOT(1., BAND=dummy1, LAMBDA=dummy2, WIDTH=dummy3)
   band_tab  = dummy1
   lambda_tab = dummy2
   width_tab = dummy3
   n_band    = N_ELEMENTS(band_tab)
   f_band    = FLTARR(n_band)

   dummy   = WHERE(inp_wfp_t.n_phot, c1)
   lambda1 = par.lambda - par.width/2
   lambda2 = par.lambda + par.width/2 

   CASE 1 OF 

      (c1 EQ 1): BEGIN      ;;This case corresponds to Na LGS!!
         
         band1         = lambda_tab[dummy[0]]-width_tab[dummy[0]]/2.
         band2         = lambda_tab[dummy[0]]+width_tab[dummy[0]]/2.
         f_band[dummy] = INTERVAL2(lambda1, lambda2, band1, band2, d1, d2)
         
      END 

      (c1 GT 1): BEGIN

         dummy   = CLOSEST(par.lambda, lambda_tab)

         IF ((ABS(par.lambda - lambda_tab[dummy]) LT 1e-12)  AND        $
             (ABS(par.width  - width_tab[dummy ]) LT 1e-12)) THEN BEGIN
                            ;;Wavelength range selected coincides with a standard band.

            f_band[dummy] = 1.

         ENDIF ELSE BEGIN   ;;Wavelength range selected ooverlaps two or
                            ;; more standard bands or is a fraction of a band
            FOR i=0, n_band-1 DO BEGIN
               band1 = lambda_tab[i]-width_tab[i]/2.
               band2 = lambda_tab[i]+width_tab[i]/2.
               f_band[i] = INTERVAL2(lambda1, lambda2, band1, band2, d1, d2)
               lambda1 = d1
               lambda2 = d2
            ENDFOR 

         ENDELSE 

      END 

      (c1 LT 1): MESSAGE, 'Error: no photons in any band!!'

   ENDCASE 

   dummy = WHERE(f_band, c1)

   IF (c1 EQ 0) THEN BEGIN

      MESSAGE, 'IMG operating band is not within wavelength' + $
               ' range considered in SOURCE', CONT=NOT(!caos_debug)
      error = !caos_error.module_error
      RETURN, error
      
   ENDIF ELSE  BEGIN 

      n_phot = TOTAL(inp_wfp_t.n_phot*f_band)*inp_wfp_t.delta_t
                                                   ;Photons per base-time unit from SRC

      bg_sky = TOTAL(inp_wfp_t.background*f_band)*inp_wfp_t.delta_t *par.pxsize^2
                                                   ;Photons per base-time per IMG pxl from SKY BACKG

   ENDELSE 

   IF (n_phot LT 1e-6) THEN BEGIN 
      MESSAGE, 'IMG operating band is not within SRC emitting' + $
               ' wavelength range (i.e. LGS)', CONT=NOT(!caos_debug)
      error = !caos_error.module_error
      RETURN, error
   ENDIF 

   ;;========================================
   ;; 8/ initialization of the INIT structure
   ;;========================================

   ;Initialization of seeds for noise
   ;---------------------------------
   status = TAG_EXIST(par, 'seed_pn')
   IF status THEN BEGIN 
      seed_pn   = par.seed_pn   &  dummy_seed=RANDOMN(seed_pn  )
      seed_ron  = par.seed_ron  &  dummy_seed=RANDOMN(seed_ron )
      seed_dark = par.seed_dark &  dummy_seed=RANDOMN(seed_dark)
   ENDIF ELSE BEGIN 
      seed_pn   = SYSTIME(1)    &  dummy_seed=RANDOMN(seed_pn  )
      seed_ron  = SYSTIME(1)    &  dummy_seed=RANDOMN(seed_ron )
      seed_dark = SYSTIME(1)    &  dummy_seed=RANDOMN(seed_dark)
   ENDELSE  

   init = $
     { scale:            scale, $ ;To account for lambda dependence of wf
       increase:      increase, $ ;Matrix Increasing factor.
       rebin_fac:    rebin_fac, $ ;Rebin factor. 
       dim:                dim, $ ;Size of matrices required by IMG pixel
       axisPsf:        axisPsf, $ ;PSF axis in [arcsec]
       axisCCD:        axisCCD, $ ;IMG detector axis in [arcsec]
       wedge:            wedge, $ ;Additional wedge in [m] to have PSF 
                                $ ; well centred (odd vs even #pxls)
       r2_array:      r2_array, $ ;To add contribution of DEFOCUS ABERR.
       b1:                  b1, $ ;b1 & b2 are used to extract that
       b2:                  b2, $ ; portion of the FTT image corresponding
                                $ ; to the field sampled by IMG detector.
       n_phot: par.qeff*n_phot, $ ;Nb photons from source/base-time unit
       bg_sky: par.qeff*bg_sky, $ ;idem for sky background
       seed_pn:        seed_pn, $
       seed_ron:      seed_ron, $
       seed_dark:     seed_dark $
     }

   ;;======================================================================
   ;;9/ init. of  **FIRST**  OUT_IMG_T structure: this will store the PSF!!
   ;;======================================================================

   image = DBLARR(par.npixel, par.npixel)

   out_img_t1 = $
     {          $
       data_type  : out_type[0],      $
       data_status: !caos_data.valid, $
       image      : image,            $ ;PSF. 
       npixel     : par.npixel,       $ ;Number of linear pixels
       resolution : par.pxsize,       $ ;Pixel size [arcsec/pix]
       lambda     : par.lambda,       $ ;Mean detection wavelength [m]
       width      : par.width,        $ ;Wavelength band width [m]
       time_integ : par.time_integ,   $ ;No. of iterations to integrate
       time_delay : par.time_delay,   $ ;No. of iterations to delay
       psf        : 1B,               $ ;This flag indicates that this is a PSF.
       background : 0.,               $ ;[NOT USED]
       snr        : 0.                $ ;[NOT USED]
     }

   ;;========================================================================
   ;;10/ init. of **SECOND** OUT_IMG_T structure: this will store the IMAGE!!
   ;;========================================================================

   out_img_t2=$
     {         $
       data_type  : out_type[0],      $
       data_status: !caos_data.valid, $
       image      : image,            $ ;IMAGE with same resolution as PSF. 
       npixel     : par.npixel,       $ ;Number of linear pixels
       resolution : par.pxsize,       $ ;Pixel size [arcsec/pix]
       lambda     : par.lambda,       $ ;Mean detection wavelength [m]
       width      : par.width,        $ ;Wavelength band width [m]
       time_integ : par.time_integ,   $ ;No. of iterations to integrate
       time_delay : par.time_delay,   $ ;No. of iterations to delay
       psf        : 0B,               $ ;This flag indicates that this is an IMAGE
                                      $ ; from the convolution of the PSF with
                                      $ ; the object contained in the input.
       background : 0.,               $ ;[NOT USED]
       snr        : 0.                $ ;[NOT USED]
     }

RETURN, error
END