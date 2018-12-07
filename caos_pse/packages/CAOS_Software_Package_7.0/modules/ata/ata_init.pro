; $Id: ata_init.pro,v 7.0 2016/05/19 marcel.carbillet $
;+ 
; NAME: 
;       ata_init 
; 
; PURPOSE: 
;       ata_init executes the initialization for the WaveFront Adding 
;       (ATA) module, that is:
;
;       0- check the formal validity of the input/output structures.
;       1- initialize the output structures out_atm_t. 
; 
;     (see ata.pro's header --or file caos_help.html-- for details
;      about the module itself).
; 
; CATEGORY: 
;       Initialisation program.
; 
; CALLING SEQUENCE: 
;       error = ata_init(inp_atm_t1,$ ; atm_t input structure
;                        inp_atm_t2,$ ; atm_t input structure
;                        out_atm_t ,$ ; atm_t output structure 
;                        par       ,$ ; parameters structure
;                        INIT=init ,  ; init structure
;                       )
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.: 
;       see module help for a detailed description. 
; 
; MODIFICATION HISTORY: 
;       program written: March 2001,
;                        Bruno Femenia (OAA) [bfemenia@arcetri.astro.it]
;       modifications  : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -"mod_type"->"mod_name"
;                     (for version 4.0 of the whole Software System CAOS).
;                      : april 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;-
; 
FUNCTION ata_init, inp_atm_t1, inp_atm_t2, out_atm_t, par, INIT=init
 

; STANDARD CHECKS
;================

error = !caos_error.ok                                 ; initialization of the error code: no error as default
info  = ata_info()                                     ; Retrieve the Input & Output info.

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
   MESSAGE, 'ATA: par must be a structure'             

IF n NE 1 THEN MESSAGE, 'ATA: par cannot be a vector of structures'

IF STRLOWCASE(TAG_NAMES(par, /STRUCTURE_NAME)) NE info.mod_name THEN $
   MESSAGE, 'par must be a parameter structure for the module ata'


; test if any optional input exists
;-----------------------------------
IF (n_inp GT 0) THEN BEGIN
    inp_opt = info.inp_opt
ENDIF


; TESTING THE INPUT ARGUMENT: inp_atm_t1
;============================
dummy = test_type(inp_atm_t1, TYPE=type)
IF (type EQ 0) THEN BEGIN         ; undefined variable
   ;; Patch until the worksheet will initialize the
   ;; linked-to-nothing input to a structure as the
   ;; following:
    inp_atm_t1=                          $
      {                                  $
        data_type  : inp_type[0],        $ ;In future releases the allowed 
        data_status: !caos_data.not_valid $ ;input will be only structures
      }
ENDIF

IF test_type(inp_atm_t1, /STRUC, N_EL=n, TYPE=type) then $
   MESSAGE, 'inp_atm_t1: wrong input definition.'

IF (n NE 1) THEN MESSAGE, 'inp_atm_t1 cannot be a vector of structures'

; test the data type
;-------------------
IF inp_atm_t1.data_type NE inp_type[0] THEN MESSAGE, $
  'Wrong input data type: '+inp_atm_t1.data_type +' ('+inp_type[0]+' expected)'

ds1 = inp_atm_t1.data_status
IF (ds1 EQ !caos_data.not_valid) AND (NOT inp_opt[0]) THEN $
  MESSAGE, 'Undefined input is not allowed'


; TESTING THE INPUT ARGUMENT: inp_atm_t2
;============================
dummy = test_type(inp_atm_t2, TYPE=type)
IF (type EQ 0) THEN BEGIN         ; undefined variable
   ;; Patch until the worksheet will initialize the
   ;; linked-to-nothing input to a structure as the
   ;; following:
    inp_atm_t2=                           $
      {                                   $
        data_type  : inp_type[1],         $ ;In future releases the allowed 
        data_status: !caos_data.not_valid $ ;input will be only structures
      }
ENDIF

IF test_type(inp_atm_t2, /STRUC, N_EL=n, TYPE=type) then $
   MESSAGE, 'inp_atm_t2: wrong input definition.'

IF (n NE 1) THEN MESSAGE, 'inp_atm_t2 cannot be a vector of structures'

; test the data type
;-------------------
IF inp_atm_t2.data_type NE inp_type[0] THEN MESSAGE, $
  'Wrong input data type: '+inp_atm_t2.data_type +' ('+inp_type[0]+' expected)'

ds2 = inp_atm_t2.data_status
IF (ds2 EQ !caos_data.not_valid) AND (NOT inp_opt[1]) THEN $
  MESSAGE, 'Undefined input is not allowed'


;Any input may be optional (e.g. a correction in Closed-Loop) but not both at same time
;======================================================================================
IF (ds1 EQ !caos_data.not_valid) AND (ds2 EQ !caos_data.not_valid) THEN $
  MESSAGE,'Any input may be optional but not both at the same time'


; initialization of the OUTPUT atm_t structure
;=============================================
CASE 1 OF 

   (par.atm1_corr EQ 0) AND (par.atm2_corr EQ 0): BEGIN 

      link_atms, inp_atm_t1, inp_atm_t2, par, atm1_to_atm, atm2_to_atm, alt_layers, dir_layers, nlayers

      nel_x = N_ELEMENTS(inp_atm_t1.screen[*,0,0])
      nel_y = N_ELEMENTS(inp_atm_t1.screen[0,*,0])
      
      out_atm_t =                                   $       ; output structure init.
        {                                           $
          data_type  : out_type[0]                , $       ; data type
          data_status: !caos_data.valid           , $       ; data status
          screen     : FLTARR(nel_x,nel_y,nlayers), $       ; layers' screens
          scale      : inp_atm_t1.scale           , $       ; scale [m/px]
          delta_t    : inp_atm_t1.delta_t         , $       ; time-base [s]
          alt        : alt_layers                 , $       ; layers' altitudes [m]
          dir        : dir_layers                 , $       ; winds' directions [rd]
          correction : 0B                           $       ; this is NOT a correction atmosphere
        }
 
   END 


   (par.atm1_corr EQ 0) AND (par.atm2_corr NE 0): BEGIN

      nel_x   = N_ELEMENTS(inp_atm_t1.screen[*,0,0])
      nel_y   = N_ELEMENTS(inp_atm_t1.screen[0,*,0])
      nlayers = par.nlay_corr

      dummy_atm_t =                                 $
        {                                           $
          data_type  : inp_type[1]                , $       ; data type
          data_status: !caos_data.valid           , $       ; data status
          screen     : FLTARR(nel_x,nel_y,nlayers), $       ; layers' screens
          scale      : inp_atm_t1.scale           , $       ; scale [m/px]
          delta_t    : inp_atm_t1.delta_t         , $       ; time-base [s]
          alt        : par.alt_corr               , $       ; layers' altitudes [m]
          dir        : FLTARR(nlayers)            , $       ; winds' directions [rd]
          correction : 0B                           $       ; this is NOT a correction atmosphere
        }
 
      link_atms, inp_atm_t1, dummy_atm_t, par, atm1_to_atm, atm2_to_atm, alt_layers, dir_layers, nlayers

      out_atm_t =                                   $       ; output structure init.
        {                                           $
          data_type  : out_type[0]                , $       ; data type
          data_status: !caos_data.valid           , $       ; data status
          screen     : FLTARR(nel_x,nel_y,nlayers), $       ; layers' screens
          scale      : inp_atm_t1.scale           , $       ; scale [m/px]
          delta_t    : inp_atm_t1.delta_t         , $       ; time-base [s]
          alt        : alt_layers                 , $       ; layers' altitudes [m]
          dir        : dir_layers                 , $       ; winds' directions [rd]
          correction : 0B                           $       ; this is NOT a correction atmosphere
        }

   END 


   (par.atm1_corr NE 0) AND (par.atm2_corr EQ 0): BEGIN

      nel_x   = N_ELEMENTS(inp_atm_t2.screen[*,0,0])
      nel_y   = N_ELEMENTS(inp_atm_t2.screen[0,*,0])
      nlayers = par.nlay_corr

      dummy_atm_t =                                 $
        {                                           $
          data_type  : inp_type[1]                , $       ; data type
          data_status: !caos_data.valid           , $       ; data status
          screen     : FLTARR(nel_x,nel_y,nlayers), $       ; layers' screens
          scale      : inp_atm_t2.scale           , $       ; scale [m/px]
          delta_t    : inp_atm_t2.delta_t         , $       ; time-base [s]
          alt        : par.alt_corr               , $       ; layers' altitudes [m]
          dir        : FLTARR(nlayers)            , $       ; winds' directions [rd]
          correction : 0B                           $       ; this is NOT a correction atmosphere
        }
 
      link_atms, inp_atm_t2, dummy_atm_t, par, atm2_to_atm, atm1_to_atm, alt_layers, dir_layers, nlayers

      out_atm_t =                                   $       ; output structure init.
        {                                           $
          data_type  : out_type[0]                , $       ; data type
          data_status: !caos_data.valid           , $       ; data status
          screen     : FLTARR(nel_x,nel_y,nlayers), $       ; layers' screens
          scale      : inp_atm_t2.scale           , $       ; scale [m/px]
          delta_t    : inp_atm_t2.delta_t         , $       ; time-base [s]
          alt        : alt_layers                 , $       ; layers' altitudes [m]
          dir        : dir_layers                 , $       ; winds' directions [rd]
          correction : 0B                           $       ; this is NOT a correction atmosphere
        }

   END 

   ELSE: MESSAGE,'Any input may be a correction atmosphere but not both at the same time'

ENDCASE 


; initialization of the INIT structure
;=====================================

init =                        $
  {                           $
    atm1_to_atm: atm1_to_atm, $  ; Map between screens in atm1 and screens in output atm_t
    atm2_to_atm: atm2_to_atm, $  ; Map between screens in atm1 and screens in output atm_t
    alt_layers : alt_layers , $  ; Heights of layers in output atm_t
    nlayers    : nlayers      $  ; Number  of layers in output atm_t
  }



RETURN,error
END