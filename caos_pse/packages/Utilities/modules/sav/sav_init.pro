; $Id: sav_init.pro,v 7.0 2016/05/03 marcel.carbillet $
;+ 
; NAME: 
;    sav_init 
; 
; PURPOSE: 
;    sav_init executes the initialization for the [PUT HERE THE NAME] 
;    (SAV) module.
; 
; CATEGORY: 
;    module's initialisation routine 
; 
; CALLING SEQUENCE: 
;    error = sav_init(inp_yyy_t, $ ; yyy_t input structure
;                     par,       $ ; parameters structure
;                     INIT=init  ) ; initialisation structure
; 
; INPUTS/OUTPUTS/KEYWORDS/ETC.: 
;    see module help for a detailed description. 
; 
; ROUTINE MODIFICATION HISTORY: 
;    routine written: march 1999,
;                     Simone Esposito (OAA) [esposito@arcetri.astro.it].
;    modifications  : march 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -file names are now generic names (the extensions
;                     ".sav" and ".xdr" are so added.
;                    -a ".sav" file (the structure prototype) is created for
;                     the calibration data also.
;                   : june 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -there is now two counters: counter_run (for the running
;                     steps), and counter_calib (for the calibration steps).
;                   : december 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 2.0 (CAOS) => simplified
;                   : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -"mod_type"->"mod_name"
;                     (for version 4.0 of the whole Software System CAOS).
;                   : may 2016,
;                     Ulysse Perruchon-Monge & Adama Sy (Dépt.Physique UNS),
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -moved from Soft.Pack.CAOS 5.2 to new package "Utilities"
;                     of new version (7.0) of the CAOS PSE,
;                    -simple IDL "save" format and FITS format added.
;                    -useless init.counter eliminated (this_iter used instead).
;- 
; 
function sav_init, inp_yyy_t, $
                   par,       $
                   INIT=init 

; initialization of the error code: no error as default
error = !caos_error.ok 

; retrieve the module's informations
info = sav_info()

; get the individual output structure types
if info.out_type ne '' then out_type = str_sep(info.out_type,",")

; STANDARD CHECKS
;
; compute and test the requested number of sav arguments
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
   message, 'SAV error: par must be a structure'
if n ne 1 then message, 'SAV error: par cannot be a vector of structures'
if strlowcase(tag_names(par, /STRUCTURE_NAME)) ne info.mod_name then $
   message, 'par must be a parameter structure for the module SAV'

; check the input arguments

; test if any optional input exists
if n_inp gt 0 then begin
   inp_opt = info.inp_opt
endif

dummy = test_type(inp_yyy_t, TYPE=type)
if type eq 0 then begin         ; undefined variable
   inp_yyy_t = $
      {        $
      data_type  : inp_type[0],         $
      data_status: !caos_data.not_valid $
      }
endif
if test_type(inp_yyy_t, /STRUC, N_EL=n, TYPE=type) then $
   message, 'SAV error: wrong definition for the first input.'
if n ne 1 then message, $
   'SAV error: first input cannot be a vector of structures'

; test the data type
if inp_type[0] ne 'gen_t' then begin
   if inp_yyy_t.data_type ne inp_type[0] then                $
      message, 'wrong input data type: '+inp_yyy_t.data_type $
              +' ('+inp_type[0]+' expected).'
endif

if inp_yyy_t.data_status eq !caos_data.not_valid and not inp_opt[0] then $
      message, 'undefined input is not allowed'

; STRUCTURE "INIT" DEFINITION
;
unit_data = 0L
if par.format eq 0 then begin
   get_lun, unit_data
   file = par.data_file
   save, inp_yyy_t, filename = file+".sav"
endif

init = $
   {   $
   unit_data: unit_data $
   }

; back to calling program
return, error 
end