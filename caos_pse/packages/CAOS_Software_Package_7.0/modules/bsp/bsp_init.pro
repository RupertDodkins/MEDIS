; $Id: bsp_init.pro,v 7.0 2016/04/27 marcel.carbillet $
;+ 
; NAME: 
;       bsp_init 
; 
; PURPOSE: 
;       bsp_init executes the initialization for the Beam SPlitter (BSP)
;       module, that is:
;
;       0- check the formal validity of the input/output structures.
;       1- initialize the output structures out_wfp_t. 
; 
;     (see bsp.pro's header --or file caos_help.html-- for details
;      about the module itself).  
; 
; CATEGORY: 
;       Initialisation program.
; 
; CALLING SEQUENCE: 
;       error = bsp_init(inp_wfp_t ,$ ; wfp_t input structure
;                        out_wfp_t1,$ ; wfp_t output structure
;                        out_wfp_t2,$ ; wfp_t output structure 
;                        par          ; parameters structure
;                       )
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.: 
;       see module help for a detailed description. 
; 
; MODIFICATION HISTORY: 
;       program written: March 1999, 
;                        Bruno Femenia (OAA) [bfemenia@arcetri.astro.it]
;
;       modifications  : Nov 1999, 
;                        B. Femenia   (OAA) [bfemenia@arcetri.astro.it]
;                       -adapted to new version CAOS (v 2.0).
;                      : january 2003,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -"mod_type"->"mod_name"
;                        (for version 4.0 of the whole Software System CAOS).
;                      : april 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;
;-
; 
FUNCTION bsp_init, inp_wfp_t, out_wfp_t1, out_wfp_t2, par
 
; STANDARD CHECKS
;================

error = !caos_error.ok                                 ; initialization of the error code: no error as default
info  = bsp_info()                                     ; retrieve the input and output information

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
   MESSAGE, 'BSP: par must be a structure'             

IF n NE 1 THEN MESSAGE, 'BSP: par cannot be a vector of structures'

IF STRLOWCASE(TAG_NAMES(par, /STRUCTURE_NAME)) NE info.mod_name THEN $
   MESSAGE, 'par must be a parameter structure for the module bsp'


; test if any optional input exists
;-----------------------------------
IF (n_inp GT 0) THEN BEGIN
    inp_opt = info.inp_opt
ENDIF


; TESTING THE  INPUT ARGUMENT: inp_wfp_t
;=============================
dummy = test_type(inp_wfp_t, TYPE=type)
IF (type EQ 0) THEN BEGIN         ; undefined variable
   ;; Patch until the worksheet will initialize the
   ;; linked-to-nothing input to a structure as the
   ;; following:
    inp_wfp_t=                            $
      {                                   $
        data_type  : inp_type[0],         $ ;In future releases the allowed 
        data_status: !caos_data.not_valid $ ;input will be only structures
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


; initialization of the OUTPUT wfp_t structures
;----------------------------------------------
out_wfp_t1           = inp_wfp_t
out_wfp_t1.n_phot    = inp_wfp_t.n_phot*par.frac
out_wfp_t1.background= inp_wfp_t.background*par.frac

out_wfp_t2           = inp_wfp_t
out_wfp_t2.n_phot    = inp_wfp_t.n_phot*(1-par.frac)
out_wfp_t2.background= inp_wfp_t.background*(1-par.frac)

RETURN,error
END