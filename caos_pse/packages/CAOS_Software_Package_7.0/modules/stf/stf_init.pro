; $Id: stf_init.pro,v 7.0 2016/05/19 marcel.carbillet $
;+ 
; NAME: 
;    stf_init 
; 
; PURPOSE: 
;    stf_init executes the initialization for the STructure Function 
;    (STF) module.
; 
; CATEGORY: 
;    module's initialisation routine 
; 
; CALLING SEQUENCE: 
;    error = stf_init(          $
;                    inp_wfp_t, $ ; wfp_t input structure
;                    out_stf_t, $ ; stf_t output structure
;                    par,       $ ; parameters structure
;                    INIT=init  $ ; initialisation structure
;                    ) 
; 
; INPUTS/OUTPUTS/KEYWORDS/ETC.: 
;    see module help for a detailed description. 
; 
; ROUTINE MODIFICATION HISTORY: 
;    routine written: march 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : may 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -modified the nb of pixels where the structure function
;                     computed (see also the sub-routine stf_simu.pro).
;                   : december 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 2.0 (CAOS).
;                   : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -"mod_type"->"mod_name"
;                     (for version 4.0 of the whole Software System CAOS).
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;- 
; 
function stf_init, inp_wfp_t, $
                   out_stf_t, $
                   par,       $
                   INIT=init 

; initial stuff
error = !caos_error.ok 
info = stf_info()
if info.out_type ne '' then out_type = str_sep(info.out_type,",")

; STANDARD CHECKS
;
; compute and test the requested number of stf arguments
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
   message, 'STF error: par must be a structure'
if n ne 1 then message, 'STF error: par cannot be a vector of structures'
if strlowcase(tag_names(par, /STRUCTURE_NAME)) ne info.mod_name then $
   message, 'par must be a parameter structure for the module XXX'

; check the input arguments

; test if any optional input exists
if n_inp gt 0 then inp_opt = info.inp_opt

dummy = test_type(inp_wfp_t, TYPE=type)
if type eq 0 then begin         ; undefined variable
   inp_wfp_t = $
      {        $
      data_type  : inp_type[0],         $
      data_status: !caos_data.not_valid $
      }
endif
if test_type(inp_wfp_t, /STRUC, N_EL=n, TYPE=type) then $
   message, 'STF error: wrong definition for the first input.'
if n ne 1 then message, $
   'STF error: first input cannot be a vector of structures'

; test the data type
if inp_type[0] ne 'gen_t' then begin
   if inp_wfp_t.data_type ne inp_type[0] then                $
      message, 'wrong input data type: '+inp_wfp_t.data_type $
              +' ('+inp_type[0]+' expected).'
endif

if inp_wfp_t.data_status eq !caos_data.not_valid and not inp_opt[0] then $
      message, 'undefined input is not allowed'

; STRUCTURE "INIT" DEFINITION
;
np = (size(inp_wfp_t.screen))[1]                     ; pupiled screen dim. [px]
npobs = floor(total(inp_wfp_t.pupil[np/2, *] eq 0.)) ; obstruction dim. [px]
np = (np-npobs)/2                                    ; struc. fct dim. [px]

stf_theo, par.model, inp_wfp_t.scale_atm, np, par.r0, par.L0, theo
theo = temporary(theo) * ((5E-7)/(2*!PI))^2

init = $
   {   $
   np   : np,         $ nb of points [px]
   theo : theo,       $ theoretical structure function [um^2]
   struc: fltarr(np), $ simulated structure function [um^2]
   iter : 0           $ iteration number
   }

; INITIALIZE THE OUTPUT STRUCTURE
; 
out_stf_t = $                               ; STF output structure
   {        $
   data_type  : out_type[0],                $
   data_status: !caos_data.valid,            $
   struc      : init.struc,                 $ ; simulated structure function
   theo       : init.theo,                  $ ; theoretical structure function
   scale      : inp_wfp_t.scale_atm,        $ ; scale on "struc"
   model      : par.model,                  $ ; theoretical model
   r0         : par.r0,                     $ ; Fried parameter
   L0         : par.L0,                     $ ; wave-front outer scale
   iter       : init.iter,                  $ ; number of screens used
   dim        : (size(inp_wfp_t.screen))[1] $ ; screens' linear dimension [px]
   }

return, error 
end