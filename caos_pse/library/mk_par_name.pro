; $Id: mk_par_name.pro,v 1.1.1.1 2003/03/07 10:46:19 marcel Exp $
;
;+
; NAME:
;    mk_par_name
;
; PURPOSE:
;    mk_par_name returns the name of the parameter file of the
;    instance n_module of the module module_name.
;    the relative path of the project is added if the name
;    of the project is passed in the keyword PROJ_NAME.
;    if the keyword DEFAULT is set, the default parameter
;    file name is returned. in this case only the module_name
;    is needed.
;
; CATEGORY:
;    utility routine
;
; CALLING SEQUENCE:
;    filename = mk_par_name(module_name, n_module)
; 
; INPUTS:
;    module_name: 3-char string. Name of the module.
;    n_module   : Integer scalar. Number associated to the intance
;                 of the module. n_module > 0.
;
; OPTIONAL INPUTS:
;    none.
;      
; KEYWORD PARAMETERS:
;    PROJ_NAME: string. Name of the current project. If defined
;               add the directory name of the project to the path.
;    DEFAULT  : if set the default parameter file name is
;               returned. In this case n_modules and PROJ_NAME
;               are not considered.
;
; OUTPUTS:
;    filename: string. Name of the parameter file of the module.
;
; OPTIONAL OUTPUTS:
;    none.
;
; COMMON BLOCKS:
;    none.
;
; SIDE EFFECTS:
;    none.
;
; RESTRICTIONS:
;    none.
;
; PROCEDURE:
;    none.
;
; EXAMPLE:
;    filename = mk_par_name("atm", 17)
;    +-> returns "atm00017.sav"
;
;    filename = mk_par_name("atm", 17, PROJ_NAME="my_project")
;    +-> returns "Projects/my_project/atm00017.sav"
;
;    filename = mk_par_name("atm", PACK_NAME="CAOS_4.0", /DEFAULT)
;    +-> returns "..../caos/packages/CAOS_4.0/modules/atm/atm_default.sav"
;
; MODIFICATION HISTORY:
;    program written: may 1998,
;                     Armando Riccardi (OAA) [riccardi@arcetri.astro.it].
;    modifications  : november 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 2.0 (CAOS).
;                   : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to CAOS system version 4.0 (keyword PACK_NAME
;                     added).
;
;-
;
function mk_par_name, module_name,         $
                      n_module,            $
                      PACK_NAME=pack_name, $
                      PROJ_NAME=proj_name, $
                      DEFAULT=default

; number of parameter test
np = n_params()
if keyword_set(default) then begin
   if np lt 1 then message, "wrong number of parameters"
endif else begin
   if np lt 2 then message, "wrong number of parameters"
endelse

; parameter type and dimension test
if test_type(module_name, /STRING, N_ELEMENTS=n) then $
   message, "module_name must be a string"
if n ne 1 then message, "module_name must be a scalar"
if strlen(module_name) ne !caos_env.module_len then $
   message, "module_name must be a "+strtrim(!caos_env.module_len,2) $
           +"-char string"

; if DEFAULT keyword is set, returns the default file path
if keyword_set(default) then begin
   filename = !caos_env.modules + !caos_env.delim + pack_name $
            + !caos_env.delim + "modules" + !caos_env.delim   $
            + module_name + !caos_env.delim + module_name     $
            + "_default.sav"
   return, filename
endif
    
; parameter type and dimension test
if test_type(n_module, /INT, /LONG, N_ELEMENTS=n) then $
   message, "n_module must be integer"
if n ne 1 then message, "n_module must be a scalar"
if n_module le 0 or n_module gt '7FFF'X then $
   message, "n_module must be 0<n_module<=32767"

; test of the keywords
n_proj_name = n_elements(proj_name)

; test if proj_name is defined
if n_proj_name ne 0 then begin
   ; test the type and dimension
   if test_type(proj_name, /STRING, N_ELEMENTS=n) then $
      message, "proj_name must be a string"
   if n ne 1 then message, "proj_name must be one string"
endif

filename = module_name+"_"+string(fix(n_module), format="(I5.5)")+".sav"
if n_proj_name ne 0 then filename = proj_name + !caos_env.delim + filename

; back to calling procedure
return, filename
end
