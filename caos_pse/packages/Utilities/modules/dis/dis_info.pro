; $Id: dis_info.pro,v 7.0 2016/04/21 marcel.carbillet $
;+
; NAME:
;    dis_info
;
; PURPOSE:
;    dis_info is the routine that returns the basic informations for
;    module DIS of package "Utilities".
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;    info_structure = dis_info()
; 
; OUTPUTS:
;    info_structure: structure containing the module's basic informations.
;
; MODIFICATION HISTORY:
;    program written: april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr],
;                     Andrea La Camera (DIBRIS) [andrea.lacamera@unige.it]:
;                    -global merging of dsp_info of module DSP (from Soft.
;                     Pack. AIRY 6.1 ) and dis_info of module DIS (from Soft.
;                     Pack. CAOS 5.2) for new CAOS Problem-Solving Env. 7.0.
;    modifications  : date,
;                     author (institute) [email@address]:
;                    -description of modification.
;
;-
;
function dis_info

pack_name= 'Utilities'          ; package name
help_file= 'utilities_help.html'
help     = !caos_env.modules+pack_name+!caos_env.delim+'help'+!caos_env.delim+help_file
ver      = fix(7)               ; version number of the module structure

mod_name = 'dis'                ; module name
descr    = 'data DISplay'       ; short module description
def_file = mk_par_name(mod_name, PACK_NAME=pack_name, /DEFAULT) ; default parameter file
                                ; default parameters file name
inp_type = 'gen_t'              ; generic input type
inp_opt  = 1B                   ; the input may be optional
out_type = ''                   ; no output

init     = 1B                   ; initialization structure needed
time     = 0B                   ; time integration/delay not needed

; convert in low case format and eliminate all the blanks
mod_name = strlowcase(strcompress(mod_name, /REMOVE_ALL))
inp_type = strlowcase(strcompress(inp_type, /REMOVE_ALL))
out_type = strlowcase(strcompress(out_type, /REMOVE_ALL))

; control the module name length
if strlen(mod_name) ne !caos_env.module_len then $
   message, 'the module name must have '+strtrim(!caos_env.module_len)+' chars'

; resulting info structure
info = $
   {   $
   pack_name: pack_name,$
   help     : help,     $
   ver      : ver,      $

   mod_name : mod_name, $
   descr    : descr,    $
   def_file : def_file, $

   inp_type : inp_type, $
   inp_opt  : inp_opt,  $
   out_type : out_type, $

   init     : init,     $
   time     : time      $
   }

; back to calling program
return, info
end