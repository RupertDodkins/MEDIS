; $Id: tce_init.pro,v 7.0 2016/05/19 marcel.carbillet $
;+ 
; NAME: 
;    tce_init 
; 
; PURPOSE: 
;    tce_init executes the initialization for the Tip-tilt CEntroiding (TCE)
;    module, that is:
;
;    0- check the formal validity of the input/output structure.
;    1- initialize the output structure out_com_t. 
; 
; (see tce.pro's header --or file caos_help.html-- for details
; about the module itself).
;
; CATEGORY: 
;    Initialisation program.
; 
; CALLING SEQUENCE: 
;    error = tce_init(inp_img_t, $ ; img_t input structure
;                     out_com_t, $ ; com_t output structure 
;                     par      , $ ; parameters structure
;                     INIT= init $ ; initialisation structure
;                     )
; 
; INPUTS/OUTPUTS/KEYWORDS/ETC.: 
;    see module help for a detailed description. 
; 
; MODIFICATION HISTORY: 
;    program written: Feb 1999,
;                     Bruno Femenia (OAA) [bfemenia@arcetri.astro.it]
;                     Jun 1999,
;
;    modifications  : Jun 1999,
;                     B. Femenia (OAA) [bfemenia@arcetri.astro.it]
;                    -possibility to introduce directly constant of
;                     calibration from TCE_GUI.
;                   : Nov 1999,
;                     Bruno Femenia (OAA),[bfemenia@arcetri.astro.it]
;                    -adapted to version 2.0 (CAOS code)
;                   : january/february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -!caos_error.dmi.* variables eliminated for
;                     compliance with the CAOS Software System, version 4.0.
;                    -"mod_type"->"mod_name"
;                    -use of parameter "calibration" instead of dedicated common variable. 
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;-
; 
FUNCTION tce_init, inp_img_t, out_com_t, par, INIT=init
 
; CAOS global common block
;-------------------------
COMMON caos_block, tot_iter, this_iter

; Testing that if Q-Cell is chosen, the CCD has an even number of pixels
;-----------------------------------------------------------------------
IF (par.detector EQ 0) AND (inp_img_t.npixel MOD 2) THEN BEGIN
   MESSAGE,'Quad-cell requires an even linear number of '+ $
     ' pixels in detector',CONTINUE=NOT(!caos_debug)
   error = !caos_error.module_error
   RETURN, error
ENDIF 

;================
; STANDARD CHECKS
;================

error = !caos_error.ok       ; initialization of the error code: no error as default
info  = tce_info()           ; Retrieve the Input & Output info.

; test the number of passed parameters corresponds to what there is in info
;--------------------------------------------------------------------------
n_par = 1                                                   ; Parameter structure (GUI) always in args. list

IF (info.inp_type NE '') THEN BEGIN
    inp_type = STR_SEP(info.inp_type,",")
    n_inp    = N_ELEMENTS(inp_type)
ENDIF ELSE BEGIN
    n_inp    = 0
ENDELSE

IF (info.out_type NE '') THEN BEGIN
    out_type = STR_SEP(info.out_type,",")
    n_out    = N_ELEMENTS(out_type)
ENDIF ELSE BEGIN
    n_out    = 0
ENDELSE

n_par= n_par + n_inp + n_out
IF (N_PARAMS() NE n_par) THEN MESSAGE, 'wrong number of parameters'

; test the parameter structure
;-----------------------------
IF TEST_TYPE(par, /STRUCTURE, N_ELEMENTS=n) THEN $
   MESSAGE, 'TCE: par must be a structure'             

IF (n NE 1) THEN MESSAGE, 'TCE: par cannot be a vector of structures'

IF STRLOWCASE(TAG_NAMES(par, /STRUCTURE_NAME)) NE info.mod_name THEN $
   MESSAGE, 'par must be a parameter structure for the module TCE'

; test if any optional input exists
;-----------------------------------
IF n_inp GT 0 THEN BEGIN
    inp_opt = info.inp_opt
ENDIF

; test the input argument
;-------------------------
dummy = test_type(inp_img_t, TYPE=type)
IF (type EQ 0) THEN BEGIN         ; undefined variable
   ;; Patch until the worksheet will initialize the
   ;; linked-to-nothing input to a structure as the
   ;; following:
    inp_img_t = { $
                  data_type  : inp_type[0],         $
                  data_status: !caos_data.not_valid $
                }
   ;; In future releases the allowed input will be only
   ;; structures.
ENDIF

; IF ((inp_img_t.type NE 5) AND (inp_img_t.type NE 6)) THEN BEGIN
;   MESSAGE,'TCE only intended to work on img_t images from TTS',$
;     CONT = NOT(!caos_debug) 
;   error = !caos_error.module_error
;   RETURN,error
; ;;PATCH until unified version for CEN and TCE is available
; ENDIF

IF test_type(inp_img_t, /STRUC, N_EL=n, TYPE=type) THEN $
   MESSAGE, 'TCE: wrong definition for the first input.'

IF (n NE 1) THEN MESSAGE, 'inp_img_t cannot be a vector of structures'

; test the data type
;-------------------
IF inp_img_t.data_type NE inp_type[0] THEN MESSAGE, $
  'Wrong input data type: '+inp_img_t.data_type +' ('+inp_type[0]+' expected)'

IF (inp_img_t.data_status EQ !caos_data.not_valid) AND (NOT inp_opt[0]) THEN $
  MESSAGE, 'Undefined input is not allowed'


; default situation: loading of a calibration data file is not allowed.
restore_calib = 0B

;Reporting WARNING message is inp_img_t.psf is detected => user may have not realized he/she is using
;------------------------------------------------------    not the IMAGE but the psf instead.
IF inp_img_t.psf THEN BEGIN 
   st1= ['TCE has detected the IMG_T input is marked with flag PSF 1B meaning', $
         'you are using the PSF for tip-tilt, this being equivalent to:'      , $
         ''                                                                   , $
         '  1/ Using a point-like source for sensing of tip-tilt.'            , $
         '  2/ The image used for sensing does not contain any kind of noise.', $
         ''                                                                   , $
         'If you agree with this just click on YES and the program will con- ', $
         'tinue. Otherwise click on NO and the program will be aborted']
   dummy = DIALOG_MESSAGE(st1,/QUEST, TITLE='TCE warning')
   IF (dummy EQ 'No') THEN BEGIN 
      PRINT,'TCE: Simulation aborted as requested by user.'
      error = !caos_error.module_error
      RETURN,error
   ENDIF 
ENDIF 


; restoring calibration file for TCE module if using Quad-cell.
;--------------------------------------------------------------
IF ((par.calibration EQ 0B) AND (par.detector EQ 0B) AND $  ; we are within a "regular" project
    (par.method NE 2)) THEN BEGIN                           ; and using CALIBRATION provided 
                                                            ; directly from GUI.
   dummy = WHERE(tag_names(par) EQ 'CALIB_FILE',count)

   IF (count GT 0) THEN BEGIN                               ; the module allows the loading 
      IF (par.calib_file NE '') THEN BEGIN                  ; of a calibration data file
         restore_calib = 1B
         file_exists  = (findfile(par.calib_file))[0] NE ''
      ENDIF

   ENDIF 

ENDIF 

                               ;;;----------------------
IF restore_calib THEN BEGIN    ;;; RESTORING CALIBRATION => for TCE this also means restoring
                               ;;;----------------------    the init structure.
   
   IF NOT(file_exists) THEN $ 
     MESSAGE, 'the file '+par.calib_file+" doesn't exist."
   
   ;;RESTORING par AND init STRUCTURES FROM calib_file
   ;;-------------------------------------------------
   the_par = par                ; backup copy of the par structure
   par     = 0
   init    = 0
   RESTORE, the_par.calib_file  
   
  
   ;;Checking if the GUI par & restored par structures 
   ;; are identical for fields relevant to calibration
   ;;-------------------------------------------------

   names1 = STRLOWCASE(TAG_NAMES(par))      &   n1 = N_ELEMENTS(names1)
   names2 = STRLOWCASE(TAG_NAMES(the_par))  &   n2 = N_ELEMENTS(names2)
   
   IF (n1 NE n2) THEN BEGIN
      
      MESSAGE, 'Restored and GUI PAR structures have a '+ $
               'different number of tags'
      RETURN, !caos_error.non_ident_par
      
   ENDIF ELSE BEGIN

      names1 = names1[SORT(names1)]
      names2 = names2[SORT(names2)]
      diffarr = names1 eq names2
      
      IF (TOTAL(diffarr) NE n1) THEN BEGIN
         MESSAGE, 'Restored and GUI PAR structures '+ $
                  'have different tags'
         RETURN, !caos_error.non_ident_par
      ENDIF
      
      except = ['n_module', 'ver', 'note', 'calibration', 'method', $    ;Tags which can admit a different
                'calib_file', 'cal_cte', 'range','threshold']            ;value without triggering errors.
      diffarr = COMPARE_STRUCT(par, the_par, /RECUR_A, EXCEPT=except)
      
      IF TOTAL(diffarr.ndiff) GT 0 THEN BEGIN
         MESSAGE, 'Restored and GUI PAR structures with same tags'+ $
                  ' but storing different values'
         RETURN, !caos_error.non_ident_par
      ENDIF

      par = the_par                                         ;Recovering original PAR.

   ENDELSE

   ;;Updating value for init.calibration depending on chosen linear range
   ;;--------------------------------------------------------------------
   IF par.method EQ 0 THEN BEGIN                            ;Only if linear interpolation
                                                            ; is requested.
      r1= WHERE((ABS(init.tilt) LE ABS(par.range)), count)

      IF (count LT 2) THEN BEGIN
         MESSAGE, 'Insufficient number of points to perform a linear fit.'
         error = !caos_error.module_error
         RETURN, error
      ENDIF ELSE BEGIN 
         x                   = init.tilt[r1]
         y                   = init.signal[r1]
         result              = LINFIT(x, y)
         init.calibration[0] = result[0]                    ;A= Offset [adimensional]
         init.calibration[1] = result[1]                    ;B= Slope  [rad^-1]
      ENDELSE 

   ENDIF 


ENDIF ELSE BEGIN 

   IF (par.detector EQ 0) AND (par.method NE 2) THEN BEGIN

       ;;Check that number of iterations is ODD
       ;;======================================

       IF ((tot_iter MOD 2) EQ 0) THEN BEGIN

           st2=STRCOMPRESS(tot_iter,/REMOVE_ALL)
           st3=STRCOMPRESS(tot_iter+1,/REMOVE_ALL)

           st1=['Number of iterations is EVEN but for TCE',$
                'calibration purposes it MUST be ODD. By ',$
                'clicking on yes it will be changed from:',$
                ''                                        ,$
                '           '+st2                         ,$
                ''                                        ,$
                'to:'                                     ,$
                ''                                        ,$
                '           '+st3                         ,$
                ''                                        ,$
                'Click on NO to abort the program       ']

           dummy = DIALOG_MESSAGE(st1,/QUEST, TITLE='TCE warning')
           IF (dummy EQ 'No') THEN BEGIN 
               PRINT,'TCE: Simulation aborted as requested by user.'
               error = !caos_error.module_error
               RETURN,error
           ENDIF ELSE BEGIN
               tot_iter=tot_iter+1
           ENDELSE 
       ENDIF 

       ;;CREATE init STRUCTURE                              ; choice of these values for tags tilt,
       ;;=====================                              ; signal and calibration guarantee that
                                                            ; during running of calibration project
                                                            ; TCE ouputs directly the Q-cell signal
       init =                                              $
              {                                            $
               tilt        : FINDGEN(tot_iter)-tot_iter/2, $ ; mirror's tilt.
               signal      : FINDGEN(tot_iter)-tot_iter/2, $ ; signal from Q-cell.
               calibration : [0., 1.],                     $ ; calibration constants if a straight
                                                           $ ; line is chosen.
               sign        : -1                            $ ; Trick if TTM is to work applying 
              }                                              ;  corrections with negative sign BUT
                                                             ;  during calibration we require + sign!!

       SAVE,par,init,FILE=par.calib_file 

   ENDIF 

ENDELSE


IF ((par.calibration EQ 0B) AND (par.detector EQ 0B) AND $
    (par.method NE 2)) THEN BEGIN 
   IF par.calibration THEN init.sign = -1 ELSE init.sign = 1
ENDIF


; initialization of the out_com_t structure
;------------------------------------------
out_com_t =                         $
  {                                 $
    data_type  : info.out_type[0] , $
    data_status: !caos_data.valid , $
    type       : 0                , $ ; commands are for high-orders
                                    $ ;  reconstruction (0 stands for
                                    $ ;  tip-tilt)
    command    : FLTARR(2)        , $ ; 'commands' during run
    flag       : 0                , $ ; run output kind 
                                    $ ;  -1 = wavefront
                                    $ ;   0 = commands
                                    $ ;   1 = modes
    mod2com    : 0.0              , $ ; mode to command matrix. (See REC)
    mode_idx   : 0                  $ ; index of the accepted modes
  }                                   ;  in the specified base. (See REC)


RETURN,error

END