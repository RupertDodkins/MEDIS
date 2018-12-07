; $Id: ima_init.pro,v 7.0 2016/04/29 marcel.carbillet$
;+ 
; NAME: 
;       ima_init
; 
; PURPOSE: 
;       ima_init executes the initialization for the IMage Adding 
;       (IMA) module, that is:
;
;       0- check the formal validity of the input/output structures.
;       1- initialize the output structure out_img_t.
; 
;     (see ima.pro's header --or file caos_help.html-- for details
;      about the module itself).
; 
; CATEGORY: 
;       Initialisation program.
; 
; CALLING SEQUENCE: 
;       error = ima_init(inp_img_t1,$ ; img_t input structure
;                        inp_img_t2,$ ; img_t input structure
;                        out_img_t ,$ ; img_t output structure 
;                        par        $ ; parameters structure
;                       )
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.: 
;    see module help for a detailed description. 
; 
; MODIFICATION HISTORY: 
;    program written: september 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;
;    modifications  : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;-
; 
FUNCTION ima_init, inp_img_t1, inp_img_t2, out_img_t, par

; STANDARD CHECKS
;================
error = !caos_error.ok  ; initialization of the error code: no error as default
info  = ima_info()      ; Retrieve the Input & Output info.

; test the number of passed parameters corresponds to what there is in info
;--------------------------------------------------------------------------
n_par = 1               ; Parameter structure (GUI) always in args. list

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
   MESSAGE, 'IMA: par must be a structure'             

IF n NE 1 THEN MESSAGE, 'IMA: par cannot be a vector of structures'

IF STRLOWCASE(TAG_NAMES(par, /STRUCTURE_NAME)) NE info.mod_name THEN $
   MESSAGE, 'par must be a parameter structure for the module IMA'


; test if any optional input exists
;-----------------------------------
IF (n_inp GT 0) THEN BEGIN
    inp_opt = info.inp_opt
ENDIF


; TESTING THE INPUT ARGUMENT: inp_img_t1
;============================
dummy = test_type(inp_img_t1, TYPE=type)
IF (type EQ 0) THEN BEGIN         ; undefined variable
   ;; Patch until the worksheet will initialize the
   ;; linked-to-nothing input to a structure as the
   ;; following:
    inp_img_t1=                          $
      {                                  $
        data_type  : inp_type[0],        $ ;In future releases the allowed 
        data_status: !caos_data.not_valid $ ;input will be only structures
      }
ENDIF

IF test_type(inp_img_t1, /STRUC, N_EL=n, TYPE=type) then $
   MESSAGE, 'inp_img_t1: wrong input definition.'

IF (n NE 1) THEN MESSAGE, 'inp_img_t1 cannot be a vector of structures'

; test the data type
;-------------------
IF inp_img_t1.data_type NE inp_type[0] THEN MESSAGE, $
  'Wrong input data type: '+inp_img_t1.data_type +' ('+inp_type[0]+' expected)'

IF (inp_img_t1.data_status EQ !caos_data.not_valid) AND (NOT inp_opt[0]) THEN $
  MESSAGE, 'Undefined input is not allowed'


; TESTING THE INPUT ARGUMENT: inp_img_t2
;============================
dummy = test_type(inp_img_t2, TYPE=type)
IF (type EQ 0) THEN BEGIN         ; undefined variable
   ;; Patch until the worksheet will initialize the
   ;; linked-to-nothing input to a structure as the
   ;; following:
    inp_img_t2=                           $
      {                                   $
        data_type  : inp_type[0],         $ ;In future releases the allowed 
        data_status: !caos_data.not_valid $ ;input will be only structures
      }
ENDIF

IF test_type(inp_img_t2, /STRUC, N_EL=n, TYPE=type) then $
   MESSAGE, 'inp_img_t2: wrong input definition.'

IF (n NE 1) THEN MESSAGE, 'inp_img_t2 cannot be a vector of structures'

; test the data type
;-------------------
IF inp_img_t2.data_type NE inp_type[0] THEN MESSAGE, $
  'Wrong input data type: '+inp_img_t2.data_type +' ('+inp_type[0]+' expected)'

IF (inp_img_t2.data_status EQ !caos_data.not_valid) AND (NOT inp_opt[0]) THEN $
  MESSAGE, 'Undefined input is not allowed'

;Checking compatibility of both inputs.
;======================================
IF N_ELEMENTS(inp_img_t1.image[*,0]) NE N_ELEMENTS(inp_img_t2.image[*,0]) $
THEN MESSAGE,'Images in inputs are sampled with different number of pixels'

;;IF abs((inp_img_t1.resolution-inp_img_t2.resolution)/inp_img_t1.resolution) gt 0.01 THEN $
;;MESSAGE,'Images in inputs have different spatial sampling'

; initialization of the OUTPUT img_t structures
;==============================================
out_img_t = inp_img_t1
out_img_t.image = 0.

RETURN,error
END