; $Id: ttm_init.pro,v 7.0 2016/05/19 marcel.carbillet $
;+ 
; NAME: 
;       ttm_init 
; 
; PURPOSE: 
;       ttm_init executes the initialization for the Tip-Tilt Mirror (TTM)
;       module, that is:
;
;       0- check the formal validity of the input/output structure.
;       1- initialize the output structure out_wfp_t. 
; 
;    (see ttm.pro's header --or file caos_help.html-- for details
;     about the module itself). 
; 
; CATEGORY: 
;       Initialisation program.
; 
; CALLING SEQUENCE: 
;       error = ttm_init(inp_wfp_t , $ ; wfp_t input structure
;                        inp_com_t , $ ; com_t input structure 
;                        out_wfp_t1, $ ; wfp_t output structure: incident wavefront-correction
;                        out_wfp_t2, $ ; wfp_t output structure: correction
;                        par       , $ ; parameters structure
;                        INIT=init   $ ; init structure
;                       )
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.: 
;       see ttm.pro's help for a detailed description. 
; 
; MODIFICATION HISTORY: 
;       program written: Feb 1999, 
;                        Bruno Femenia (OAA) [bfemenia@arcetri.astro.it]
;
;       modifications  : Nov 1999,
;                       -adapted to new version CAOS (v 2.0). Now all input,
;                        output and par variables test are performed only once and
;                        within tts_init.pro.
;                      : Dec 1999,
;                        B. Femenia   (OAA) [bfemenia@arcetri.astro.it]
;                       -a second output containing the CORRECTION is added
;                        in order to allow the use of COMBINER feature.
;                      : january 2003,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -"mod_type"->"mod_name"
;                        (for version 4.0 of the whole Software System CAOS).
;                      : may 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;-
; 
FUNCTION ttm_init, inp_wfp_t, inp_com_t, out_wfp_t1, out_wfp_t2, par, INIT=init

; STANDARD CHECKS
;================

error = !caos_error.ok                                 ; initialization of the error code: no error as default
info  = ttm_info()                                     ; retrieve the input and output information

; test the number of passed parameters corresponds to what there is in info
;--------------------------------------------------------------------------
n_par = 1                                              ; Parameter structure (GUI) always in args. list

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

n_par= n_par + n_inp + n_out

IF N_PARAMS() NE n_par THEN MESSAGE, 'wrong number of parameters'


; test the parameter structure
;-----------------------------
IF TEST_TYPE(par, /STRUCTURE, N_ELEMENTS=n) THEN $
   MESSAGE, 'TTM: par must be a structure'             

IF n NE 1 THEN MESSAGE, 'TTM: par cannot be a vector of structures'

IF STRLOWCASE(TAG_NAMES(par, /STRUCTURE_NAME)) NE info.mod_name THEN $
   MESSAGE, 'par must be a parameter structure for the module ttm'


; test if any optional input exists
;-----------------------------------
IF (n_inp GT 0) THEN BEGIN
    inp_opt = info.inp_opt
ENDIF


; TESTING THE FIRST INPUT ARGUMENT: inp_wfp_t
;=================================
dummy = test_type(inp_wfp_t, TYPE=type)
IF (type EQ 0) THEN BEGIN         ; undefined variable
   ;; Patch until the worksheet will initialize the
   ;; linked-to-nothing input to a structure as the
   ;; following:
    inp_wfp_t=                           $
      {                                  $
        data_type  : inp_type[0],        $             ;In future releases the allowed 
        data_status: !caos_data.not_valid $            ;input will be only structures
      }
ENDIF

IF test_type(inp_wfp_t, /STRUC, N_EL=n, TYPE=type) then $
   MESSAGE, 'inp_wfp_t: wrong input definition.'

IF (n NE 1) THEN MESSAGE, 'inp_wfp_t cannot be a vector of structures'

; test the data type
;-------------------
IF inp_wfp_t.data_type NE inp_type[0] THEN MESSAGE, $
  'Wrong input data type: '+inp_wfp_t.data_type +' ('+inp_type[0]+' expected)'

IF (inp_wfp_t.data_status EQ !caos_data.not_valid) AND (NOT inp_opt[0]) THEN $
  MESSAGE, 'Undefined input is not allowed'


; TESTING THE SECOND INPUT ARGUMENT: inp_wfp_t
;=================================
dummy = test_type(inp_com_t, TYPE=type)
IF (type EQ 0) THEN BEGIN                              ; undefined variable
   ;; Patch until the worksheet will initialize the
   ;; linked-to-nothing input to a structure as the
   ;; following:
   inp_com_t=                            $
     {                                   $
       data_type  : inp_type[1],         $             ;In future releases the allowed 
       data_status: !caos_data.not_valid $             ;input will be only structures
     }
ENDIF

IF test_type(inp_com_t, /STRUC, N_EL=n, TYPE=type) then $
  MESSAGE, 'inp_com_t: wrong input definition.'

IF (n NE 1) THEN MESSAGE, 'inp_com_t cannot be a vector of structures'

; test the data type
;-------------------
IF inp_com_t.data_type NE inp_type[1] THEN MESSAGE, $
  'Wrong input data type: '+inp_com_t.data_type +' ('+inp_type[0]+' expected)'

IF (inp_wfp_t.data_status EQ !caos_data.not_valid) AND (NOT inp_opt[1]) THEN $
  MESSAGE, 'Undefined input is not allowed'



; initialization of the init structure
;-------------------------------------
dim  = N_ELEMENTS(inp_wfp_t.pupil[*,0])
axis = (FINDGEN(dim)- (dim-1.)/2.)*inp_wfp_t.scale_atm


init =                      $
       {                    $
        tiptilt : [0., 0.], $                               ;Previous substrated tip-tilt
        $                                                   ;  tiptilt[0]= along x-axis
        $                                                   ;  tiptilt[1]= along y-axis
        axis    : axis      $                               ;x- & y-axis of tip-tilt in [m]
          }

; initialization of the out_wfp_t structure
;------------------------------------------
out_wfp_t1            = inp_wfp_t
out_wfp_t1.correction = 1B                             ; this is a correcting wf

out_wfp_t2            = inp_wfp_t
out_wfp_t2.correction = 0B                             ; this is **NOT** a correcting wf

RETURN,error
END