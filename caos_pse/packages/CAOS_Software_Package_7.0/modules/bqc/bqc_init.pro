; $Id: bqc_init.pro,v 7.0 2016/04/27 marcel.carbillet $
; 
;+ 
; NAME: 
;       bqc_init 
; 
; PURPOSE: 
;       bqc_init executes the initialization for the Barycenter/Quad-cell
;       Centroiding (BQC) module, that is:
;
;       0- check the formal validity of the input/output structure.
;       1- initialize the output structure out_com_t. 
;       2- manage the load/save calibration data file feature.
; 
;    (see bqc.pro's header --or file caos_help.html-- for details
;     about the module itself).
;
; CATEGORY: 
;       Initialisation program.
; 
; CALLING SEQUENCE: 
;       error = bqc_init(inp_mim_t, $ ; mim_t input structure
;                        out_mes_t, $ ; mes_t output structure 
;                        par      , $ ; parameters structure
;                        INIT= init)  ; initialisation structure
; 
; INPUTS/OUTPUTS/KEYWORDS/ETC.: 
;       see module help for a detailed description. 
; 
; MODIFICATION HISTORY: 
;       program written: Dec 2003,
;                        Bruno Femenia (GTC) [bfemenia@ll.iac.es]
;
;       modifications  : december 2003,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -"mod_type"->"mod_name"
;                        (for version 4.0+ of the whole Software System CAOS).
;
;                        September 2004
;                        Bruno Femenia (GTC) [bfemenia@ll.iac.es]
;                       -implementing pixel weightings when computing centroids
;                        and possibility to have different calibration constants
;                        for different active subapertures.
;                      : april 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
FUNCTION bqc_init, inp_mim_t, out_meas_t, par, INIT=init
   
   ;; CAOS global common block
   ;;=========================
   COMMON caos_block, tot_iter, this_iter


   ;; Testing that if Q-Cell is chosen, the CCD has an even number of pixels
   ;;-----------------------------------------------------------------------
   IF (par.detector EQ 0) AND (inp_mim_t.npixpersub MOD 2) THEN BEGIN
      MESSAGE, 'Quad-cell requires an even linear number of detector'+     $
               ' pixels behind each subaperture', CONTINUE=NOT(!caos_debug)
      error = !caos_error.bqc.qcell_odd_pixel
      RETURN, error
   ENDIF 


   ;; STANDARD CHECKS
   ;;================
   error = !caos_error.ok                                   ;Init error code: no error as default
   info  = bqc_info()                                       ;Retrieve the Input & Output info.

   ;;Test the number of passed parameters 
   ;;corresponds to what there is in info
   ;;-------------------------------------
   n_par = 1                                                ; Parameter structure (GUI) always in args. list

   IF (info.inp_type NE '') THEN BEGIN
      inp_type = STR_SEP(info.inp_type, ",")
      n_inp    = N_ELEMENTS(inp_type)
   ENDIF ELSE BEGIN
      n_inp    = 0
   ENDELSE

   IF (info.out_type NE '') THEN BEGIN
      out_type = STR_SEP(info.out_type, ",")
      n_out    = N_ELEMENTS(out_type)
   ENDIF ELSE BEGIN
      n_out    = 0
   ENDELSE

   n_par = n_par + n_inp + n_out
   IF (N_PARAMS() NE n_par) THEN MESSAGE, 'wrong number of parameters'


   ;;Test the parameter structure
   ;;----------------------------
   IF TEST_TYPE(par, /STRUCTURE, N_ELEMENTS=n) THEN $
     MESSAGE, 'BQC: par must be a structure'             

   IF (n NE 1) THEN MESSAGE, 'BQC: par cannot be a vector of structures'

   IF STRLOWCASE(TAG_NAMES(par, /STRUCTURE_NAME)) NE info.mod_name THEN $
     MESSAGE, 'par must be a parameter structure for the module BQC'


   ;;Test if any optional input exists
   ;;---------------------------------
   IF n_inp GT 0 THEN BEGIN
      inp_opt = info.inp_opt
   ENDIF


   ;;Test the input argument
   ;;------------------------
   dummy = test_type(inp_mim_t, TYPE=type)
   IF (type EQ 0) THEN BEGIN                                ;Undefined variable => patch until the
      inp_mim_t = {data_type:   inp_type[0],         $      ;   worksheet will init the linked-to-
                   data_status: !caos_data.not_valid}       ;   nothing structure as in these lines
   ENDIF

   IF test_type(inp_mim_t, /STRUC, N_EL=n, TYPE=type) THEN $
     MESSAGE, 'inp_mim_t: wrong definition for the input.'

   IF (n NE 1) THEN MESSAGE, 'inp_mim_t cannot be a vector of structures'


   ;;Test the data type
   ;;-------------------
   IF inp_mim_t.data_type NE inp_type[0] THEN MESSAGE, $
     'Wrong input data type: '+inp_mim_t.data_type +' ('+inp_type[0]+' expected)'

   IF (inp_mim_t.data_status EQ !caos_data.not_valid) AND (NOT inp_opt[0]) THEN $
     MESSAGE, 'Undefined input is not allowed'



   ;;Checking for file with Qcel Calibrations.
   ;;=========================================
   IF par.detector EQ 0B THEN BEGIN                         
      
      IF par.same_cal THEN BEGIN 

         CalCte = par.cal_cte
 
      ENDIF ELSE BEGIN 

         dummy = FILE_INFO(par.cal_file)
         
         IF dummy.EXISTS THEN BEGIN 
            RESTORE, par.cal_file
            
            dummy = SIZE(CalCte)
            IF TOTAL(dummy EQ 0) THEN $
              MESSAGE, 'CalCte variable is not within Calibration Constants File!!'
            IF dummy[1] NE N_ELEMENTS(inp_mim_t.SUB_AP) THEN $
              MESSAGE, 'CalCte number of elements does not coincide ' + $
                       'with the number of valid subapertures!!'

         ENDIF ELSE MESSAGE, 'File with calibration constants does not exist!!'

      ENDELSE

   ENDIF ELSE CalCte = 0.



   ;;Checking for file with Pixel Weightings.
   ;;=========================================
   nx = inp_mim_t.npixpersub

   IF par.weights THEN BEGIN 

      dummy = FILE_INFO(par.filename)

      IF dummy.EXISTS THEN BEGIN 
         RESTORE, par.filename

         dummy = SIZE(weight_X)
         IF TOTAL(dummy EQ 0)    THEN $
           MESSAGE, 'weight_x is not within the Pixel Weighting File!!'
         IF dummy[0] NE 2        THEN $
           MESSAGE, 'weight_x must be a square 2D array!'
         IF dummy[1] NE dummy[2] THEN $
           MESSAGE, 'weight_x must be a square 2D array!'
         IF dummy[1] NE nx       THEN $
           MESSAGE, 'weight_x must have same number of elements as CCD pixels per subaperture!'

         dummy = SIZE(weight_y)
         IF TOTAL(dummy EQ 0)    THEN $
           MESSAGE, 'weight_y is not within the Pixel Weighting File!!'
         IF dummy[0] NE 2        THEN $
           MESSAGE, 'weight_y must be a square 2D array!'
         IF dummy[1] NE dummy[2] THEN $
           MESSAGE, 'weight_y must be a square 2D array!'
         IF dummy[1] NE nx       THEN $
           MESSAGE, 'weight_y must have same number of elements as CCD pixels per subaperture!'

      ENDIF ELSE MESSAGE, 'File with pixel weights does not exist!!'

   ENDIF ELSE BEGIN 
      weight_X = MAKE_ARRAY(nx, nx, VALUE=1.) 
      weight_Y = MAKE_ARRAY(nx, nx, VALUE=1.)
   ENDELSE


   ;;CREATE init STRUCTURE
   ;;=====================
   init = {CalCte:     CalCte, $
           weight_X: weight_X, $
           weight_Y: weight_Y}


   ;;CREATE out_meas_t STRUCTURE
   ;;===========================
   meas = FLTARR(2*inp_mim_t.nxsub)

   out_meas_t = {data_type:      info.out_type[0], $
                 data_status:    !caos_data.valid, $
                 npixpersub: inp_mim_t.npixpersub, $ ;Number of CCD pixels on a side of subaperture.
                 pxsize:         inp_mim_t.pxsize, $ ;Detector pixel size [arcsec/pixel]
                 nxsub:           inp_mim_t.nxsub, $ ;Linear number of sub-apertures along pupil diameter.
                 nsp:               inp_mim_t.nsp, $ ;Total number of active sub-apertures.
                 xspos_CCD:   inp_mim_t.xspos_CCD, $ ;Subaperture center x-positions on the CCD [m].
                 yspos_CCD:   inp_mim_t.yspos_CCD, $ ;Subaperture center y-positions on the CCD [m].
                 convert:       inp_mim_t.convert, $ ;Conversion factor from centroid deviation in pixels to radians.
                 geom:             inp_mim_t.type, $ ;Indicates geometry of detector: UNUSED TAG.
                 type:                          0, $ ;Shack-Hartmann wfs type
                 lambda:         inp_mim_t.lambda, $ ;WFS observation band central wavelegth [m].
                 width:           inp_mim_t.width, $ ;WFS observation band width [m].
                 meas:    FLTARR(2*inp_mim_t.nsp)}   ; initialisation ref. measurements

   RETURN, error

END