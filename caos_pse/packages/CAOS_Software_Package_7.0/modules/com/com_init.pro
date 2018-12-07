; $Id: com_init.pro,v 7.0 2016/04/27 marcel.carbillet $
;+ 
; NAME: 
;    com_init 
; 
; PURPOSE: 
;    com_init executes the initialization for the COMbine measurements 
;    (COM) module, that is:
;
;       0- check the formal validity of the input/output structure
;       1- initialize the output structure out_mes_t
;
;    (see com.pro's header --or file caos_help.html-- for details
;    about the module itself).
; 
; CATEGORY: 
;    module's initialisation routine 
; 
; CALLING SEQUENCE: 
;    error = com_init(inp_mes_t1,  $ ; mes_t input structure
;                     inp_mes_t2,  $ ; mes_t input structure
;                     out_mes_t,   $ ; mes_t output structure
;                     par            ; parameters structure
;                     ) 
; 
; INPUTS/OUTPUTS/KEYWORDS/ETC.: 
;    see com.pro's help for a detailed description. 
;
; ROUTINE MODIFICATION HISTORY: 
;    routine written: february 2001,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to new CAOS system (4.0) and building of
;                     Software Package MAOS 1.0.
;                   : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
;- 
; 
function com_init, inp_mes_t1, $ ; 1st input struc.
                   inp_mes_t2, $ ; 2nd input struc.
                   out_mes_t,  $ ; output struc.
                   par           ; COM parameters structure

; CAOS global common block
common caos_block, tot_iter, this_iter

; error code initialization
error = !caos_error.ok

; retrieve the module's informations
info = com_info()

; get the individual output structure types
if info.out_type ne '' then out_type = str_sep(info.out_type,",")

; STANDARD CHECKS
;
; compute and test the requested number of com arguments
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
   message, 'COM error: par must be a structure'
if n ne 1 then message, 'COM error: par cannot be a vector of structures'
if strlowcase(tag_names(par, /STRUCTURE_NAME)) ne info.mod_name then $
   message, 'par must be a parameter structure for the module COM'

; check the input arguments

; test if any optional input exists
if n_inp gt 0 then begin
   inp_opt = info.inp_opt
endif

dummy = test_type(inp_mes_t1, TYPE=type)
if type eq 0 then begin         ; undefined variable
   inp_mes_t1 = $
      {         $
      data_type  : inp_type[0],         $
      data_status: !caos_data.not_valid $
      }
endif
if test_type(inp_mes_t1, /STRUC, N_EL=n, TYPE=type) then $
   message, 'COM error: wrong definition for the first input.'
if n ne 1 then message, $
   'COM error: first input cannot be a vector of structures'

; test the data type
if inp_type[0] ne 'gen_t' then begin
   if inp_mes_t1.data_type ne inp_type[0] then                $
      message, 'wrong input data type: '+inp_mes_t1.data_type $
              +' ('+inp_type[0]+' expected).'
endif

if inp_mes_t1.data_status eq !caos_data.not_valid and not inp_opt[0] then $
      message, 'undefined input is not allowed'


dummy = test_type(inp_mes_t2, TYPE=type)
if type eq 0 then begin                ; undefined variable
   inp_mes_t2 = $
      {         $
      data_type  : inp_type[1],         $
      data_status: !caos_data.not_valid $
      }
endif

if test_type(inp_mes_t2, /STRUC, N_EL=n, TYPE=type) then $
   message, 'COM error: wrong definition for the second input.'

if n ne 1 then message, $
   'COM error: second input cannot be a vector of structures'

; test the data type
if inp_mes_t2.data_type ne inp_type[1] then                $
   message, 'wrong input data type: '+inp_mes_t2.data_type $
           +' ('+inp_type[1]+' expected).'
if inp_mes_t2.data_status eq !caos_data.not_valid and not inp_opt[1] then $
   message, 'undefined input is not allowed'
;
; END OF STANDARD CHECKS


; INITIALIZE THE OUTPUT STRUCTURE
;
; initialize output
out_mes_t = $
   {        $
   data_type  : out_type[0],                        $
   data_status: !caos_data.valid,                   $
   meas       : [inp_mes_t1.meas, inp_mes_t2.meas], $
   npixpersub : inp_mes_t1.npixpersub,              $
   pxsize     : inp_mes_t1.pxsize,                  $
   nxsub      : inp_mes_t1.nxsub,                   $
   nsp        : inp_mes_t1.nsp,                     $
   xspos_CCD  : inp_mes_t1.xspos_CCD,               $
   yspos_CCD  : inp_mes_t1.yspos_CCD,               $
   convert    : inp_mes_t1.convert,                 $
   type       : inp_mes_t1.type,                    $
   geom       : inp_mes_t1.geom,                    $
   lambda     : inp_mes_t1.lambda,                  $
   width      : inp_mes_t1.width                    $
   }

; back to calling program
return, error 
end