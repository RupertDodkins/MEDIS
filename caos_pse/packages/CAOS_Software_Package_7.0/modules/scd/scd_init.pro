; $Id: scd_init.pro,v 7.0 2016/05/19 marcel.carbillet $
;+ 
; NAME: 
;    scd_init 
; 
; PURPOSE: 
;    scd_init executes the initialization for the Save Calibration Data
;    (SCD) module, that is:
;
;       0- check the formal validity of the input/output structure
;
;    (see scd.pro's header --or file caos_help.html-- for details
;    about the module itself).
; 
; CATEGORY: 
;    module's initialisation routine 
; 
; CALLING SEQUENCE: 
;    error = scd_init(inp_mes_t,  $ ; mes_t input structure
;                     inp_atm_t,  $ ; atm_t input structure
;                     par,        $ ; parameters structure
;                     INIT=init   $ ; initialisation data structure
;                     ) 
; 
; INPUTS/OUTPUTS/KEYWORDS/ETC.: 
;    see scd.pro's help for a detailed description. 
;
; ROUTINE MODIFICATION HISTORY: 
;    routine written: june 2002,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : january--march 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it],
;                     Christophe Verinaud (ESO) [cverinau@eso.org]:
;                    -"mod_type"->"mod_name"
;                     (for version 4.0 of the whole Software System CAOS).
;                    -INIT structure changed.
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;- 
; 
function scd_init, inp_mes_t,  $ ; mes_t input struc.
                   inp_atm_t,  $ ; atm_t input struc.
                   par,        $ ; SCD parameters structure
                   INIT=init     ; SCD initialization data structure

; CAOS global common block
common caos_block, tot_iter, this_iter

; error code initialization
error = !caos_error.ok

; retrieve the module's informations
info = scd_info()

; get the individual output structure types
if info.out_type ne '' then out_type = str_sep(info.out_type,",")

; STANDARD CHECKS
;
; compute and test the requested number of scd arguments
n_par = 1  ; the parameter structure is always present within the arguments
if info.inp_type ne '' then begin
   inp_type = str_sep(info.inp_type,",")
   n_inp    = n_elements(inp_type)
endif else n_inp = 0
if info.out_type ne '' then begin
   out_type = str_sep(info.out_type,",")
   n_out    = n_elements(out_type)
endif else n_out = 0
n_par = n_par + n_inp + n_out
if n_params() ne n_par then message, 'wrong number of arguments'

; test the parameter structure
if test_type(par, /STRUCTURE, N_ELEMENTS=n) then $
   message, 'SCD error: par must be a structure'
if n ne 1 then message, 'SCD error: par cannot be a vector of structures'
if strlowcase(tag_names(par, /STRUCTURE_NAME)) ne info.mod_name then $
   message, 'par must be a parameter structure for the module SCD'

; check the input arguments

; test if any optional input exists
if n_inp gt 0 then begin
   inp_opt = info.inp_opt
endif

dummy = test_type(inp_mes_t, TYPE=type)
if type eq 0 then begin         ; undefined variable
   inp_mes_t = $
      {        $
      data_type  : inp_type[0],         $
      data_status: !caos_data.not_valid $
      }
endif
if test_type(inp_mes_t, /STRUC, N_EL=n, TYPE=type) then $
   message, 'SCD error: wrong definition for the first input.'
if n ne 1 then message, $
   'SCD error: first input cannot be a vector of structures'

; test the data type
if inp_type[0] ne 'gen_t' then begin
   if inp_mes_t.data_type ne inp_type[0] then                $
      message, 'wrong input data type: '+inp_mes_t.data_type $
              +' ('+inp_type[0]+' expected).'
endif

if inp_mes_t.data_status eq !caos_data.not_valid and not inp_opt[0] then $
      message, 'undefined input is not allowed'


dummy = test_type(inp_atm_t, TYPE=type)
if type eq 0 then begin                ; undefined variable
   inp_atm_t = $
      {        $
      data_type  : inp_type[1],         $
      data_status: !caos_data.not_valid $
      }
endif

if test_type(inp_atm_t, /STRUC, N_EL=n, TYPE=type) then $
   message, 'SCD error: wrong definition for the second input.'

if n ne 1 then message, $
   'SCD error: second input cannot be a vector of structures'

; test the data type
if inp_atm_t.data_type ne inp_type[1] then                $
   message, 'wrong input data type: '+inp_atm_t.data_type $
           +' ('+inp_type[1]+' expected).'
if inp_atm_t.data_status eq !caos_data.not_valid and not inp_opt[1] then $
   message, 'undefined input is not allowed'
;
; END OF STANDARD CHECKS

; STRUCTURE "INIT" DEFINITION
;
nm = (size(inp_mes_t.meas))[1]
np = (size(inp_atm_t.screen))[1]
init = $
   {   $
   matint: dblarr(tot_iter, nm),    $
   mirdef: fltarr(np, np, tot_iter) $
   }

; back to calling program
return, error 
end