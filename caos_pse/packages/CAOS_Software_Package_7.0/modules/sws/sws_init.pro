; $Id: sws_init.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;       sws_init
;
; PURPOSE:
;       sws_init executes the initialization for the Shack-Hartmann
;       Wavefront Sensing (SWS) module, that is:
;
;       0- check the formal validity of the input/output structure.
;       1- initialize the output structure out_sws_t. 
; 
;       (see sws.pro's header --or file caos_help.html-- for details
;       about the module itself). 
; 
; CATEGORY:
;       Initialisation program.
;
; CALLING SEQUENCE:
;       error = sws_init(inp_wfp_t, $ ; wfp_t input structure
;                        out_mim_t, $ ; mim_t output structure 
;                        par      , $ ; parameters structure
;                        INIT=init  ) ; initialisation data structure
;
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.: 
;       see sws.pro's help for a detailed description. 
;
; ROUTINE MODIFICATION HISTORY:
;       program written: Dec 2003,
;                        B. Femenia (GTC) [bfemenia@ll.iac.es].
;       modifications  : december 2003,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -"mod_type"->"mod_name"
;                        (from version 4.0 of the whole Software System CAOS).
;                      : September 2004,
;                        B. Femenia (GTC) [bfemenia@ll.iac.es]
;                       -Routine now does not require an integer nb of wf pixels
;                        within subaperture=> bilinear interpolation.
;                      : September 2004,
;                        B. Femenia (GTC) [bfemenia@ll.iac.es]
;                       -Does not rely on MAKEPUPIL, but instead uses inp_wfp_t.pupil
;                        This is required to make SWS be able to work on whatever
;                        pupil shape (aka. GTC pupil)
;                      : October 2004,
;                        B. Femenia (GTC) [bfemenia@ll.iac.es]
;                       -Debugging computation of number of photons from sky background.
;                      : may 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;-
;
FUNCTION sws_init, inp_wfp_t, out_mim_t, par, INIT=init

   ;; CAOS global common block
   ;;=========================
   COMMON caos_block, tot_iter, this_iter


   ;; STANDARD CHECKS
   ;;================
   error = !caos_error.ok                                   ;Init error code: no error as default
   info  = sws_info()                                       ;Retrieve the Input & Output info.

   ;;Test the number of passed parameters 
   ;;corresponds to what there is in info
   ;;-------------------------------------
   n_par = 1                                                ; Parameter structure (GUI) always in args. list

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


   ;;Test the parameter structure
   ;;----------------------------
   IF TEST_TYPE(par, /STRUCTURE, N_ELEMENTS=n) THEN $
     MESSAGE, 'SWS: par must be a structure'             
   
   IF n NE 1 THEN MESSAGE, 'SWS: par cannot be a vector of structures'

   IF STRLOWCASE(TAG_NAMES(par, /STRUCTURE_NAME)) NE info.mod_name THEN $
     MESSAGE, 'par must be a parameter structure for the module SWS'


   ;;Test if any optional input exists
   ;;---------------------------------
   IF n_inp GT 0 THEN BEGIN
      inp_opt = info.inp_opt
   ENDIF


   ;;Test the input argument
   ;;------------------------
   dummy = test_type(inp_wfp_t, TYPE=type)
   IF (type EQ 0) THEN BEGIN                                ;Undefined variable => patch until the
      inp_wfp_t = {data_type:   inp_type[0],         $      ;   worksheet will init the linked-to-
                   data_status: !caos_data.not_valid}       ;   nothing structure as in these lines
   ENDIF

   IF test_type(inp_wfp_t, /STRUC, N_EL=n, TYPE=type) THEN $
     MESSAGE, 'inp_wfp_t: wrong input definition.'

   IF (n NE 1) THEN MESSAGE, 'inp_wfp_t cannot be a vector of structures'


   ;;Test the data type
   ;;-------------------
   IF inp_wfp_t.data_type NE inp_type[0] THEN MESSAGE, $
     'Wrong input data type: '+inp_wfp_t.data_type +' ('+inp_type[0]+' expected)'

   IF (inp_wfp_t.data_status EQ !caos_data.not_valid) AND (NOT inp_opt[0]) THEN $
     MESSAGE, 'Undefined input is not allowed'

   
   ;;Reporting WARNING message is inp_wfp_t.correction is detected
   ;;=> user may have not realized he/she is using a wf containing 
   ;;   only correcting mirror shape
   ;;-------------------------------------------------------------
   IF inp_wfp_t.correction THEN BEGIN 
      st1 = ['SWS has detected the WFP_T input is marked with flag CORRECTION  ', $
             '1B meaning that you will visualize a correcting mirror shape.    ', $
             '', $
             'If you agree with this just click on YES to continue the', $
             'program. Otherwise click on NO to abort the program.    ']
      dummy = DIALOG_MESSAGE(st1, /QUEST, TITLE='SWS warning')
      IF (dummy EQ 'No') THEN BEGIN 
         PRINT, 'SWS: Simulation aborted as requested by user.'
         error = !caos_error.module_error
         RETURN, error
      ENDIF 
   ENDIF 


   ;;========================
   ;;1/ Defining useful vars.
   ;;========================
   npix     = N_ELEMENTS(inp_wfp_t.pupil[*, 0])
   AxisWF_0 = INDGEN(npix)                                  ;Original WF axis in units of original sampling points.
   nx0      = FLOAT(npix)/par.nsubap                        ;Original Nb WF pixels on a subaperture side.

   IF (nx0 GT FIX(nx0)) THEN  BEGIN                         ;Need to interpolate incoming wavefront.
      interpol = 1B                                         ;=======================================
      PRINT, ''
      PRINT, 'WARNING:'
      PRINT, '========'
      PRINT, ['   Sampling of WF is such that each ' + $
             'subaperture takes a non-integer number', $
             '   of WF pixels. The program will proc'+ $
             'eed by interpolating the original WF.']

      nx = CEIL(nx0)                                        ;Nb of NEW WF pixels on subaperture.
      IF nx MOD 2 THEN nx = nx+1

      AxisWF_1 = (FINDGEN(nx*par.nsubap)+0.5)* $            ;Interpolating position: units of original sampling points
                 FLOAT(npix)/(nx*par.nsubap)-0.5
      
      dummy = INTERPOLATE(inp_wfp_t.pupil, AxisWF_1, AxisWF_1, /GRID)
      r1    = WHERE(dummy GT 0.)
      InterPupil     = BYTARR(nx*par.nsubap, nx*par.nsubap)
      InterPupil[r1] = 1B
                                 
   ENDIF ELSE BEGIN 
      nx         = nx0
      interpol   = 0B
      AxisWF_1   = AxisWF_0
      InterPupil = 0B
   ENDELSE


   np   = par.nsubap*nx                                     ;Linear number of NEW WF pixels along pupil diameter.
   d    = inp_wfp_t.scale_atm*nx0                           ;Subaperture side size in [m].
   Diam = par.nsubap*d                                      ;Pupil   diameter size in [m].

   arc2rad = !DPI/(180.*60*60.)                             ;Arcsecond to radian conversion factor.
   src_nbD = (SIZE(inp_wfp_t.map))[0]                       ;Number of Dimensions of source map.
   CASE src_nbD OF 
      0:
      2: 
      3: BEGIN 
         MESSAGE, '3D sources handle not yet operative', /INFO
         error = !caos_error.not_yet_implemented
         RETURN, error
      END
      ELSE: MESSAGE, 'What kind of source are you using?'
   ENDCASE


   scale_atm = inp_wfp_t.scale_atm*(FLOAT(nx0)/FLOAT(nx))        ;Scale of working  screen pixels.
   psSWS     = par.pxsize                                        ;Original SWS pixel size.
   scale     = (air_ref_idx(par.lambda)/air_ref_idx(500e-9))     ;Accounts for wf lambda dependence,
   scale     = FLOAT(scale*2.d0*!DPI/par.lambda)*COMPLEX(0, 1)   ;Forcing it to be floating-point.
   rebin_fac = 1.                                                ;Rebin factor. Computed later.
   increase  = 1.                                                ;Matrix Increasing factor. Comp'd later.


   ;;=================================================================================
   ;;2/ Expand PUPIL properly so that image through (FFT)^2 happens to be sampled with
   ;;   a pix size which is that of SWS detector (if SWS requires a smaller pixel size
   ;;   that lambda/D) or an intg. fraction of lambda/D (in case lambda/D > SWS pixel)
   ;;=================================================================================
   increase = (par.lambda/d)/(par.pxsize*arc2rad)

   IF (ABS(increase-1.) LT 1e-3) THEN BEGIN                      ;Handles very special case where
      increase  = 1.                                             ;pixel size = lambda/d
      rebin_fac = 1.
   ENDIF ELSE BEGIN 
      IF (increase LT 1.) THEN BEGIN                             ;Finding factor to increase resolution
         dummy = CEIL(1./increase)                               ;so to have an image sampled such      
         REPEAT BEGIN                                            ;that the CCD pxl is an integer number
            factor = (dummy*increase)                            ;of times the pixel image (to do REBIN) 
            dummy = dummy+ 1.
         ENDREP UNTIL NOT(dummy MOD 2) AND $                     ;The rebin factor is forced to be an
           (ABS(factor-ROUND(factor))/ factor LT 0.9)            ;odd number. 10% accuracy required.
         
         rebin_fac = ROUND(dummy-1.)
         increase  = factor
      ENDIF ELSE BEGIN 
         rebin_fac = 3
         increase  = 3*increase
      ENDELSE
   ENDELSE

   dim       = ROUND(nx*increase)                                ;Size of new square with WF sampled by Subapertures.
   IF (dim MOD 2) THEN dim = dim+1                               ;Forcing dim to be even.
   increase = FLOAT(dim)/FLOAT(nx)                               ;FINAL increasing factor.

   IF (dim GE 4096) THEN BEGIN
      MESSAGE, 'Resolution parameters yield  '+      $
               'matrix larger than 4096x4096', /INFO
      error = !caos_error.module_error
      RETURN, error
   ENDIF

   ps        = (par.lambda/d/increase)*rebin_fac/arc2rad         ;New SWS pxl(slightly modified) in [arcsec]
   pxsize_im = ps/rebin_fac                                      ;Pxl size of image from FFT in [arcsec].
   IF (ABS(ps-par.pxsize)/par.pxsize GT  0.1) THEN            $  ;Inform the user if new pxsize
     PRINT, FORMAT='(a,2x,f6.4,a)', 'SWS pixel has changed.'+ $  ; differs in more than 10% wrt
            'to  ', ps/par.pxsize, ' times original pixel'       ; pxsize given by user in GUI.

   dummy = ROUND(par.pxsize/pxsize_im)
   par.pxsize = ps                                               ;UPGRADING SWS PXSIZE IN PAR !!! In [arcsec].
                                                            

   ;;==================================================================
   ;;3/ Checking whether sampling of wavefront on pupil produces a FOV 
   ;;   < that the subapertures FOV. If so, stop the program and report
   ;;   values concerning CCD pixel size and #CCD pixels to use instead
   ;;==================================================================
   fov_atm = par.lambda/(d/nx)/arc2rad                           ;FoV from ATM sampling
   fov_sws = par.npixel*par.pxsize                               ;Largest FoV usable within SWS

   IF (fov_atm LT fov_sws) THEN BEGIN 
      
      CASE 1 OF 
         (par.npixel LT 10  ): st1 = STRING(par.npixel, FORMAT='(i2)')
         (par.npixel LT 100 ): st1 = STRING(par.npixel, FORMAT='(i3)')
         (par.npixel LT 1000): st1 = STRING(par.npixel, FORMAT='(i4)')
         ELSE                : st1 = STRING(par.npixel)
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
      
      st3 = ['Subaperture FoV selected in SWS GUI not compa' + $ 
             'tible with FOV in ATM module. Going like this',  $
             'would mean the presence of a FIELD STOP which' + $
             ' is INEXISTENT in the system. By clicking on ',  $
             'YES the number of SWS pixels will be changed ',  $
             '',                                               $
             'from:'+st1,                                      $
             '',                                               $
             'to  :'+st2,                                      $
             '',                                               $
             'Otherwise click on NO and the program will '  +  $
             'be aborted!!!',                                  $
             '',                                               $
             '',                                               $
             'SHALL I CHANGE THE NUMBER OF PIXELS IN SWS '  +  $
             'DETECTOR?']

      dummy = DIALOG_MESSAGE(st3, /QUEST, TITLE='SWS FOV warning')
      
      IF (dummy EQ 'No') THEN BEGIN 
         MESSAGE, 'Incompatible Fields of View defined in ATM '+ $
                  'and SWS modules. Define apropriate values!!', $
                  CONT=NOT(!caos_debug)
         error = !caos_error.module_error
         RETURN, error
      ENDIF ELSE BEGIN
         MESSAGE, 'Changing the number of SWS pixels to make its '+ $
                  'FOV compatible with that defined in ATM module'+ $
                  '. Number of SWS pixels per subaperture was int'+ $
                  'ially'+st1+' and has been changed to'+st2, /INFO
         par.npixel = np
         
      ENDELSE
      
   ENDIF 


   ;;========================================================================
   ;;4/ Introducing a wedge of WF pixel/2 in BOTH x & y-axes to have the FFTs 
   ;;   with origin sampled properly if running a normal project. If the pro-  
   ;;   ject is a CALIBRATION one, wedge is only introduced for x-axis.
   ;;========================================================================
   np    = par.npixel*par.nsubap                                 ;Number of SWS CCD pixels along pupil diameter.
   IF (np MOD 2) THEN                              $
     axisCCD = (FINDGEN(np)-FIX(np)/2)*par.pxsize  $             ;Axis for full CCD (covering ALL subapertures).
   ELSE                                            $
     axisCCD = (FINDGEN(np)-(np-1.)/2.)*par.pxsize               ;Axis for full CCD (covering ALL subapertures).

   dummy = FIX(par.npixel)
   IF (par.npixel MOD 2) THEN BEGIN                              ;If subap. sampled with odd nb. pixels, assuming
      wedge   = 0.                                               ;  optical axis is sampled by a single CCD pixel.
      axisSUB = (FINDGEN(dummy)-dummy/2)*par.pxsize              ;Axis for CCD portion within a subaperture
      axisPSF = (FINDGEN(dim)-FIX(dim)/2)*pxsize_im              ;Axis for SUBAPERTURE FFT image on detector plane
   ENDIF ELSE BEGIN
      AxisWF  = (FINDGEN(nx)-(nx-1.)/2)*inp_wfp_t.scale_atm* $
                nx0/nx                                           ;Mirror axis in [m] along a subaperture.
      axisSUB = (FINDGEN(dummy)-dummy/2+0.5)*par.pxsize          ;Axis for CCD matrix covering 1 subaperture.
      dummy   = -AxisWF*(pxsize_im*arc2rad/2.)                   ;Additional 1/2pxl wf wedge in [m]
      wedge   = REBIN(dummy, nx, nx)                             ;Wedge in both axes.
      dummy   = 2*!PI/par.lambda/ABS(scale)                      ;Tilt must be always 1/2 pxl => remove n(lmbd) effect
      wedge   = (wedge + TRANSPOSE(wedge))*dummy                 ;Wedge in both axes.
      axisPsf = (FINDGEN(dim)-dim/2)* pxsize_im + pxsize_im/2.   ;Axis for SUBAPERTURE FFT image on detector plane
   ENDELSE

   b1 = (CLOSEST(axisSUB[0],            axisPsf)-FIX(rebin_fac)/2) > 0
   b2 = (CLOSEST(axisSUB[par.npixel-1], axisPsf)+FIX(rebin_fac)/2) < (dim-1)


   ;;=========================================================================
   ;;5/ TEST ON WAVELENGTH: if OK also compute total Nb of photons from source
   ;;   and from sky background per time-base unit on  full telescope pupil. 
   ;;=========================================================================
   dummy      = N_PHOT(1., BAND=dummy1, LAMBDA=dummy2, WIDTH=dummy3)
   band_tab   = dummy1
   lambda_tab = dummy2
   width_tab  = dummy3
   n_band     = N_ELEMENTS(band_tab)
   f_band     = FLTARR(n_band)

   dummy      = WHERE(inp_wfp_t.n_phot, c1)
   lambda1    = par.lambda - par.width/2
   lambda2    = par.lambda + par.width/2 

   CASE 1 OF 

      (c1 EQ 1): BEGIN                                           ;This case corresponds to Na LGS!!
         band1 = lambda_tab[dummy[0]]-width_tab[dummy[0]]/2.
         band2 = lambda_tab[dummy[0]]+width_tab[dummy[0]]/2.
         f_band[dummy] = INTERVAL2(lambda1, lambda2, band1, band2, d1, d2)
      END 

      (c1 GT 1): BEGIN
         dummy   = CLOSEST(par.lambda, lambda_tab)
         IF ((ABS(par.lambda-lambda_tab[dummy]) LT 1e-12)  AND  $ ;Wavelength range selected coincides with  
             (ABS(par.width -width_tab[dummy ]) LT 1e-12)) THEN $ ; a standard band.
           f_band[dummy] = 1.                                   $
         ELSE BEGIN                                              ;Wavelength range selected overlaps two or
            FOR i = 0, n_band-1 DO BEGIN                         ; more standard bands or is a fraction of a band
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
      MESSAGE, 'SWS operating band is not within wavelength' + $
               ' range considered in SOURCE', CONT=NOT(!caos_debug)
      error = !caos_error.module_error
      RETURN, error
   ENDIF ELSE  BEGIN 
      n_phot = TOTAL(inp_wfp_t.n_phot*f_band)*     $        ;Photons per base-time from SRC on full pupil. 
               inp_wfp_t.delta_t*par.qeff                   ;  Taking into account detector Qeff.
      bg_sky = TOTAL(inp_wfp_t.background*f_band)* $        ;Photons per base-time per SWS pxl from SKY BACKG on pupil
               inp_wfp_t.delta_t*par.pxsize^2*par.qeff      ;  Taking into account detector Qeff
   ENDELSE 


   IF (n_phot LT 1e-6) THEN BEGIN 
      MESSAGE, 'SWS operating band is not within SRC emitting' + $
               ' wavelength range (i.e. LGS)', CONT=NOT(!caos_debug)
      error = !caos_error.module_error
      RETURN, error
   ENDIF 
   


   ;;=========================================================================
   ;;6/ Bringing source map to same resolution as the PSF. Only for 2D sources
   ;;=========================================================================

    IF (src_nbD EQ 2) THEN BEGIN

       i = 0
         
       ;;i/ Finding indexes where map will be interp at PSF resolution
       ;;--------------------------------------------------------------
       dummy  = inp_wfp_t.coord
       offset = DBLARR(2)                                        ;These lines are required to "center" each
       IF (src_nbD EQ 3) THEN BEGIN                              ;  layer of 3D. With these lines, weighted  
          offset[0] = ATAN(dummy[3, i]-pointing[0], dummy[2, i]) ;  center of 3D spot is at center of FOV
          offset[1] = ATAN(dummy[4, i]-pointing[1], dummy[2, i]) ;  of detector so that any displacement
       ENDIF                                                     ;  of image is only due to atm turbulence!!

       nmap     = N_ELEMENTS(inp_wfp_t.map[0, *, 0])
       dummy    = (FINDGEN(nmap)-(nmap-1.)/2.)
       axisMapx = (dummy*inp_wfp_t.map_scale+offset[0])/arc2rad  ;x-axis for MAP matrix in [arcsec]
       axisMapy = (dummy*inp_wfp_t.map_scale+offset[1])/arc2rad  ;y-axis for MAP matrix in [arcsec]

       index_x = (axisPsf-axisMapx[0])/(axisMapx[1]-axisMapx[0]) ;"Indexes" of axisPsf within axisMapX array.
       index_y = (axisPsf-axisMapy[0])/(axisMapy[1]-axisMapy[0]) ;"Indexes" of axisPsf within axisMapY array.
       
       r1 = WHERE(index_x GT 0 AND index_x LE nmap-1, c1)        ;Finding idx of pts along x &  
       r2 = WHERE(index_y GT 0 AND index_y LE nmap-1, c2)        ;y where map will be interpolated.
       
       IF (c1 EQ 0) OR (c2 EQ 0) THEN BEGIN
          MESSAGE, 'Extend source out of field of view?? '+ $    ;For debugging purposes
                   'CHECK!', CONT=NOT(!caos_debug)
          error = !caos_error.module_error
          RETURN, error
       ENDIF

       ;;ii/ Bilinear interpolation and axis of resulting box
       ;;----------------------------------------------------
       dummy1 = INTERPOLATE(inp_wfp_t.map[*, *, i], index_x[r1], $      ;;Bilinear interp. of src map to  
                            index_y[r2], /GRID)                         ;;  points where PSF is sampled.
       axis_xInterp = (axisMapx[1]-axisMapx[0])*index_x[r1]+axisMapx[0] ;x-axis of box resulting from interpolation.
       axis_yInterp = (axisMapx[1]-axisMapx[0])*index_y[r2]+axisMapy[0] ;y-axis of box resulting from interpolation.
       
       ;;iii/ Inserting interpolation into appropriate 2D array
       ;;------------------------------------------------------
       col1 = CLOSEST(axis_xInterp[0], axisPSF)                                                                 
       col2 = col1 + N_ELEMENTS(dummy1[*, 0])-1                  ;col2= col index lower left corner of box within MAP  
       
       row1 = CLOSEST(FLOAT(axis_yInterp[0]), axisPSF)
       row2 = row1+N_ELEMENTS(dummy1[0, *])-1                    ;row2= row index lower left corner of box within MAP  

       map  = FLTARR(dim, dim)
       map[col1:col2, row1:row2] = dummy1

    ENDIF ELSE map = 0B


   ;;========================================
   ;; 7/ Initialization of the INIT structure
   ;;========================================

   ;;Initialization of seeds for noise
   ;;---------------------------------
   seed_pn   = par.seed_pn    &  dummy = RANDOMN(seed_pn  )
   seed_ron  = par.seed_ron   &  dummy = RANDOMN(seed_ron )
   seed_dark = par.seed_dark  &  dummy = RANDOMN(seed_dark)


   ;;Generating matrix with r^2 modelling DEFOCUS ABERRATION 
   ;;(needed e.g. when using LGS modelled as 3D sources or defocus drifts)
   ;;---------------------------------------------------------------------
   IF interpol THEN                          $
     NbPx = N_ELEMENTS(InterPupil[*, 0])     $              ;Nb WF pixels along INTERPOLATED pupil diameter.
   ELSE                                      $
     NbPx = N_ELEMENTS(inp_wfp_t.pupil[*, 0])               ;Nb WF pixels along ORIGINAL     pupil diameter.

   dummy    = (FINDGEN(NbPx)-(NbPx-1.)/2)*(Diam/NbPx)       ;inp_wfp_t.scale_atm
   dummy    = REBIN(dummy, NbPx, NbPx)
   r2_array = FLOAT(dummy^2+TRANSPOSE(dummy^2))


   ;;Identifying Valid Subapertures
   ;;------------------------------
   illumin = FLTARR(par.nsubap, par.nsubap)                 ;Array of relative illuminations of each subaperture
   idxB    = INTARR(par.nsubap, par.nsubap)                 ;Pixel idx for BOTTOM corners of each subaperture
   idxU    = INTARR(par.nsubap, par.nsubap)                 ;Pixel idx for UPPER  corners of each subaperture
   idxL    = INTARR(par.nsubap, par.nsubap)                 ;Pixel idx for LEFT   corners of each subaperture
   idxR    = INTARR(par.nsubap, par.nsubap)                 ;Pixel idx for RIGHT  corners of each subaperture
   nel_sub = 64l > nx                                       ;Nb pixels on subaperture for fract. illumination calculus
   NbPx    = nel_sub*par.nsubap                             ;Nb pixels to sample WF x&y-axes

   IF nel_sub GT 64l THEN $
     Pupil = InterPupil   $
   ELSE BEGIN 
      dummy = N_ELEMENTS(AxisWF_0)
      axis  = (FINDGEN(NbPx)+.5)*dummy/FLOAT(NbPx)-0.5      ;Grid positions in units of original sampling points where 
      dummy = FLOAT(inp_wfp_t.pupil)                        ;  to interpolate I/P to compute fractional illuminations.
      dummy = INTERPOLATE(dummy, Axis, Axis, /GRID)
      r1    = WHERE(dummy GT 0.)
      Pupil = BYTARR(NbPx, NbPx)                            ;Pupil function at resol. to compute fract. illumination.
      Pupil[r1] = 1B
   ENDELSE


   FOR i_y = 0, par.nsubap-1 DO BEGIN

      idx_b = (i_y-par.nsubap/2)*nel_sub+NbPx/2 > 0
      idx_u = idx_b+nel_sub-1

      FOR i_x = 0, par.nsubap-1 DO BEGIN 
         idx_l = (i_x-par.nsubap/2)*nel_sub+NbPx/2
         idx_r = idx_l+nel_sub-1
         
         r1 = WHERE(pupil[idx_l:idx_r, idx_b:idx_u] GT 0, c1)
         illumin[i_x, i_y] = FLOAT(c1)/FLOAT(nel_sub^2)

         idxB[i_x,i_y] = idx_b
         idxU[i_x,i_y] = idx_u
         idxL[i_x,i_y] = idx_l
         idxR[i_x,i_y] = idx_r
      ENDFOR 

   ENDFOR 

   sub_ap = WHERE(illumin GE par.fvalid, n_sub_ap)  ;;Indexes of valid subapertures

   
   ;;Generating mask to identify pixels behind valid subapertures
   ;;------------------------------------------------------------
   dummy = par.nsubap*par.npixel
   subap_mask = BYTARR(dummy, dummy)

   FOR i = 0, n_sub_ap-1 DO BEGIN
      iy = sub_ap[i]  /  par.nsubap
      ix = sub_ap[i] MOD par.nsubap
      subap_mask[ix*par.npixel:(ix+1)*par.npixel-1, $
                 iy*par.npixel:(iy+1)*par.npixel-1] = 1B
   ENDFOR


   ;;Generating binary mask simulating field stop
   ;;--------------------------------------------
   diam    = ROUND(par.subapFoV/pxsize_im)                  ;Subaperture FoV in units of high-resolution pixels.
   dummy   = (dim-1.)/2
   FoV_PSF = MAKEPUPIL(dim, diam, 0, XC=dummy, YC=dummy)    ;Assuming circular FoV.
   FoV_CCD = REBIN(FLOAT(FoV_PSF[b1:b2, b1:b2]), $
                   par.npixel, par.npixel)


   ;;Nb photons per time-base unit on a fully illum subapert.
   ;;--------------------------------------------------------
   dummy      = WHERE(inp_wfp_t.pupil, c1)
   pupil_surf = inp_wfp_t.scale_atm^2*c1                    ;Entrance pupil collecting surface in [m^2]
   subap_surf = d^2                                         ;Fully illuminated subaperture surface in [m^2]
   fluxsubap  = n_phot*d^2/pupil_surf                       ;Photon flux from src in fully illuminated square subapert
   bg_sky     = bg_sky*d^2/pupil_surf                       ;Photon flux from sky in fully illuminated square subapert
   
   nsub_ap = N_ELEMENTS(sub_ap)

   init = {interpol:      interpol, $  ;;If 1B then I/P wavefront pupil has to be interpolated.
           pupil:       InterPupil, $  ;;If interpol=1B => interpolated pupil; otherwise 0B.
           AxisWF_0:      AxisWF_0, $  ;;If interpol=1B => original WF axis in units of original sampling points.
           AxisWF_1:      AxisWF_1, $  ;;If interpol=1B => interpol WF axis in units of original sampling points.
           scale:            scale, $  ;;To account for lambda dependence of wf
           increase:      increase, $  ;;Matrix Increasing factor.
           rebin_fac:    rebin_fac, $  ;;Rebin factor. 
           dim:                dim, $  ;;Size of matrices required by SWS pixel.
           axisCCD:        axisCCD, $  ;;Shack-Hartmann CCD  axis in [arcsec]
           axisPSF: FLOAT(axisPSF), $  ;;PSF axis in [arcsec].
           axisSUB:        axisSUB, $  ;;Axis within a subaperture in [arcsec] at CCD resolution. 
           wedge:            wedge, $  ;;Aditional wedge in [m] to have PSF well centred (odd vs even #pxls).
           r2_array:      r2_array, $  ;;To add contribution of DEFOCUS ABERR.
           b1:                  b1, $  ;;b1 & b2 are used to extract that portion of the FTT image
           b2:                  b2, $  ;;  corresponding to the field sampled by each subaperture.
           map:                map, $  ;;Source map at same resolution as PSF (Only applies to 2D sources).
           seed_pn:        seed_pn, $  ;;Seed for generation of PHOTON noise.
           seed_ron:      seed_ron, $  ;;Seed for generation of READ-OUT noise.
           seed_dark:    seed_dark, $  ;;Seed for generation of DARK-CURRENT noise.
           sub_ap:          sub_ap, $  ;;Indexes of active subapertures.
           nsub_ap:        nsub_ap, $  ;;Number of  active subapertures.
           subap_mask:  subap_mask, $  ;;Mask to identify pixels behind valid subapertures.
           FoV_PSF:        FoV_PSF, $  ;;Mask to simulate Field Stop at resolution PSF is computed.
           FoV_CCD:        FoV_CCD, $  ;;MAsk to simulate Field Stop at CCD pixel resolution.
           illumin:        illumin, $  ;;Subapertures relative illumination (wrt fully illuminated subap.)
           fluxsubap:    fluxsubap, $  ;;Nb photons from SRC per time-base unit on a fully illuminated subaperture.
           bg_sky:          bg_sky}    ;;Nb photons on each CCD pixel from sky background/base-time unit.

   ;;===========================================
   ;;8/ Initialization of output MIM_T structure => same O/P structure as SHS module: keeping unused tags.
   ;;===========================================   

   ;;Keeping same definition for xspos_CCD & yspos_CCD as in SHS module
   ;;------------------------------------------------------------------
   dummy     = FINDGEN(par.nsubap)*par.npixel+ (par.npixel-1.)/2.
   dummy     = REBIN(dummy, par.nsubap, par.nsubap)
   xspos_CCD = dummy[sub_ap]
   dummy     = TRANSPOSE(dummy)
   yspos_CCD = dummy[sub_ap]
   convert   = d*2.*!PI/par.lambda*par.pxsize*arc2rad

   out_mim_t = {data_type:          out_type[0], $
                data_status:   !caos_data.valid, $
                image:           FLTARR(np, np), $    
                npixpersub:          par.npixel, $  ;Linear nb of px per sub-aperture.
                pxsize:              par.pxsize, $  ;Detector pixel size ["/px]
                nxsub:               par.nsubap, $  ;Linear nb of sub-apertures along pupil diameter.
                nsp:                   n_sub_ap, $  ;Total nb of active sub-apertures.
                sub_ap:                  sub_ap, $  ;Indexes of active sub-apertures.
                xspos_CCD: TRANSPOSE(xspos_CCD), $  ;Subaperture center x-positions on the CCD.
                yspos_CCD: TRANSPOSE(yspos_CCD), $  ;Subaperture center y-positions on the CCD.
                convert:                convert, $  ;Conversion factor from centroid displacement [px>rad].
                step:                        0., $
                type:                         0, $  ;Indicates geometry of detector: UNUSED TAG.
                lambda:              par.lambda, $  ;WFS observation band central wavelegth.
                width:                par.width}    ;WFS observation band width.

   RETURN, error

END