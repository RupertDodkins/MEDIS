; $Id: ave_init.pro,v 7.0 2016/04/27 marcel.carbillet$
;+ 
; NAME: 
;       ave_init
; 
; PURPOSE: 
;       ave_init executes the initialization for the signals Averaging 
;       (AVE) module, that is:
;
;       0- check the formal validity of the input/output structures.
;       1- initialize the output structure out_mes_t.
; 
;     (see ave.pro's header --or file caos_help.html-- for details
;      about the module itself).
; 
; CATEGORY: 
;       Initialisation program.
; 
; CALLING SEQUENCE: 
;       error = ave_init(inp_mes_t,$ ; mes_t input structure
;                        out_mes_t,$ ; mes_t output structure 
;                        par       $ ; parameters structure
;                       )
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.: 
;    see module help for a detailed description. 
; 
; MODIFICATION HISTORY: 
;    program written: april 2008,
;                     Marcel Carbillet (Fizeau) [marcel.carbillet@unice.fr].
;
;    modifications  : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
;-
; 
FUNCTION ave_init, inp_mes_t, out_mes_t, par

; STANDARD CHECKS
;================
error = !caos_error.ok  ; initialization of the error code: no error as default
info  = ave_info()      ; Retrieve the Input & Output info.

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
   MESSAGE, 'AVE: par must be a structure'             

IF n NE 1 THEN MESSAGE, 'AVE: par cannot be a vector of structures'

IF STRLOWCASE(TAG_NAMES(par, /STRUCTURE_NAME)) NE info.mod_name THEN $
   MESSAGE, 'par must be a parameter structure for the module AVE'


; test if any optional input exists
;-----------------------------------
IF (n_inp GT 0) THEN BEGIN
    inp_opt = info.inp_opt
ENDIF


; TESTING THE INPUT ARGUMENT: inp_mes_t
;============================
dummy = test_type(inp_mes_t, TYPE=type)
IF (type EQ 0) THEN BEGIN         ; undefined variable
   ;; Patch until the worksheet will initialize the
   ;; linked-to-nothing input to a structure as the
   ;; following:
    inp_mes_t=                           $
      {                                  $
        data_type  : inp_type[0],        $ ;In future releases the allowed 
        data_status: !caos_data.not_valid $ ;input will be only structures
      }
ENDIF

IF test_type(inp_mes_t, /STRUC, N_EL=n, TYPE=type) then $
   MESSAGE, 'inp_mes_t: wrong input definition.'

IF (n NE 1) THEN MESSAGE, 'inp_mes_t cannot be a vector of structures'

; test the data type
;-------------------
IF inp_mes_t.data_type NE inp_type[0] THEN MESSAGE, $
  'Wrong input data type: '+inp_mes_t.data_type +' ('+inp_type[0]+' expected)'

IF (inp_mes_t.data_status EQ !caos_data.not_valid) AND (NOT inp_opt[0]) THEN $
  MESSAGE, 'Undefined input is not allowed'


; initialization of the OUTPUT mes_t structure
;=============================================
;
dim=n_elements(inp_mes_t.meas)
nmod=long(dim/par.nstars)

out_mes_t = $
   {        $
   data_type  : out_type[0],                       $
   data_status: !caos_data.valid,                  $
   meas       : fltarr(nmod),                      $
   npixpersub : inp_mes_t.npixpersub,              $
   pxsize     : inp_mes_t.pxsize,                  $
   nxsub      : inp_mes_t.nxsub,                   $
   nsp        : inp_mes_t.nsp,                     $
   xspos_CCD  : inp_mes_t.xspos_CCD,               $
   yspos_CCD  : inp_mes_t.yspos_CCD,               $
   convert    : inp_mes_t.convert,                 $
   type       : inp_mes_t.type,                    $
   geom       : inp_mes_t.geom,                    $
   lambda     : inp_mes_t.lambda,                  $
   width      : inp_mes_t.width                    $
   }

RETURN,error
END
