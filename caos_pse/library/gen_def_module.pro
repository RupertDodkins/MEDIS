; $Id: gen_def_module.pro,v 1.1.1.1 2003/03/07 10:46:19 marcel Exp $
;
;+
; NAME:
;    gen_def_module
;
; PURPOSE:
;    gen_def_module function returns the default structure
;    of type MOD_DESC used as first tag for the parameter
;    structure of a module. It is defined as
;    module = $
;       {     $
;       MOD_DESC,              $
;       mod_name: module_name, $ ; string of !caos_env.module_len
;       n_module: -1,          $ ; int, -1= default par. file
;       version : ver          $
;       } 
;    The user needs to use this function only when he need to
;    define a new class of modules (see xxx_gen_default)
;
; CATEGORY:
;    File utility
;
; CALLING SEQUENCE:
;    module = gen_def_module(module_name, ver)
; 
; INPUTS:
;    module_name: string. Name of the module. (length: !caos_env.module_len)
;    ver        : Integer scalar. Version number of the parameter
;                 structure associated to the module module_name.
;                 ver >= 0.
;
; OPTIONAL INPUTS:
;    none.
;      
; KEYWORD PARAMETERS:
;    none.
;
; OUTPUTS:
;    module: structure of type MOD_DESC.
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
;    ...   
;
; MODIFICATION HISTORY:
;    program written: may 1998,
;                     Armando Riccardi (OAA) [riccardi@arcetri.astro.it].
;    modifications  : november 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                   -adapted to version 2.0 (CAOS).
;-
;
function gen_def_module, mod_name, ver

; test the number of passed parameters
if n_params() ne 2 then message, 'wrong number of parameters'

; test the mod_name parameter
if test_type(mod_name, /STRING, N_ELEMENTS=n) then $
   message, 'mod_name must be a string'
if n ne 1 then message, 'mod_name must be a single string'
if strlen(mod_name) ne !caos_env.module_len then $
   message, 'mod_name must be a '+strtrim(!caos_env.module_len,2) $
           +'-char string'

; test the ver parameter
if test_type(ver, /INT, N_ELEMENTS=n) then message, 'ver must be an integer'
if n ne 1 then message, 'ver must be a scalar'
if ver lt 0 then message, 'ver must be >=0'

; build the MOD_DESC structure
module = $
   {     $
   MOD_DESC,           $
   mod_name: mod_name, $ ; module name (!caos_env_module_len chrs)
   n_module: -1,       $ ; int>=-1, -1 no module instace associated
   ver     : ver,      $ ; int>=0, version number
   note    : ''        $ ; notes
   }

; back to calling program
return, module
end
