; $Id: wft_init.pro,v 7.0 last revision 2016/05/27 Andrea La Camera$
;+ 
; NAME: 
;    wft_init 
; 
; PURPOSE: 
;    wft_init executes the initialization for the Save IMage 
;    (WFT) module.
; 
; CATEGORY: 
;    module's initialization routine 
; 
; CALLING SEQUENCE: 
;    error = wft_init(inp_img_t, $ ; img_t input structure
;                     par )        ; parameters structure
;                       
; INPUTS/OUTPUTS/KEYWORDS/ETC.: 
;    see module help for a detailed description. 
; 
; ROUTINE MODIFICATION HISTORY: 
;    routine written: october 2000,
;                     Serge Correia (OAA) [correia@arcetri.astro.it].
;    modifications  : february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -"mod_type"->"mod_name"
;                     (for version 4.0 of the whole system CAOS).
;                   : for version 5.0,
;                     Andrea La Camera (DISI) [lacamera@disi.unige.it]:
;                    -INIT eliminated (obsolete).
;                   : from CAOS_PSE v 7.0 (2016) 
;                    -this module has been moved from AIRY 6.1 to the new 
;                     package "Utilities". Version number has been
;                     reset to 1.0. 
;                   : may 2016,
;                     Andrea La Camera (DIBRIS) [andrea.lacamera@unige.it]:
;                    -header definition from previous modules is
;                     saved, together with the usual WFT keywords. 
;                    -TIME_IN change in EXPTIME (worldwide used)
;
;- 
; 
function wft_init, inp_img_t, par 

; initialization of the error code: no error as default
error = !caos_error.ok 

; retrieve the module's informations
info = wft_info()

; get the individual output structure types
if info.out_type ne '' then out_type = str_sep(info.out_type,",")

; STANDARD CHECKS
;
; compute and test the requested number of wft arguments
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
   message, 'WFT error: par must be a structure'
if n ne 1 then message, 'WFT error: par cannot be a vector of structures'
if strlowcase(tag_names(par, /STRUCTURE_NAME)) ne info.mod_name then $
   message, 'par must be a parameter structure for the module WFT'

; check the input arguments

; test if any optional input exists
if n_inp gt 0 then begin
   inp_opt = info.inp_opt
endif

dummy = test_type(inp_img_t, TYPE=type)
if type eq 0 then begin         ; undefined variable
   inp_img_t = $
      {        $
      data_type  : inp_type[0],         $
      data_status: !caos_data.not_valid $
      }
endif
if test_type(inp_img_t, /STRUC, N_EL=n, TYPE=type) then $
   message, 'WFT error: wrong definition for the first input.'
if n ne 1 then message, $
   'WFT error: first input cannot be a vector of structures'

; test the data type
if inp_type[0] ne 'gen_t' then begin
   if inp_img_t.data_type ne inp_type[0] then                $
      message, 'wrong input data type: '+inp_img_t.data_type $
              +' ('+inp_type[0]+' expected).'
endif

if inp_img_t.data_status eq !caos_data.not_valid and not inp_opt[0] then $
      message, 'undefined input is not allowed'


; back to calling program
return, error 
end
