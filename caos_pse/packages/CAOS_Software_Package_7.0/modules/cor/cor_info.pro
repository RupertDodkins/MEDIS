; $Id: cor_info.pro,v 7.0 2016/04/27 marcel.carbillet$
;
;+
; NAME:
;    cor_info
;
; PURPOSE:
;    cor_info is the routine that returns the basic informations for the
;    module COR of the Software Package CAOS (see cor.pro's header --or
;    file caos_help.html-- for details about the module itself).
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;    info_structure = cor_info()
; 
; OUTPUTS:
;    info_structure: structure containing the module's basic informations.
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: september 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it],
;                     Olivier Lardiere (OAA) [lardiere@arcetri.astro.it],
;    modifications  : february 2004,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 5.0 of the Software Package CAOS.
;                   : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
function cor_info

pack_name= 'CAOS_Software_Package_7.0'   ; package name
help_file= 'caos_help.html' ; help file name
help     = !caos_env.modules+pack_name+!caos_env.delim+'help'+!caos_env.delim+help_file
                                ; help file address for Software Package CAOS 5.0
ver      = fix(7)               ; version number of the Software Package used

mod_name = 'cor'                ; 3-char. module short name
descr    = 'CORonagraphy module'    ; SHORT module description
def_file = mk_par_name(mod_name, PACK_NAME=pack_name, /DEFAULT)
                                ; default parameter filename

inp_type = 'wfp_t'              ; input is of type wfp_t

inp_opt  = 0B                   ; input may not be optional

out_type = 'img_t'              ; output is of type img_t

init     = 1B                   ; an initialisation STRUCTURE is required

time     = 0B                   ; time integration/delay management is NOT required

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