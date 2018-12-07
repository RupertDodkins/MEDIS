; $Id: rec_info.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    rec_info
;
; PURPOSE:
;    rec_info is the routine that returns the basic informations for the
;    module REC (see rec.pro's header --or file caos_help.html-- for details
;    about the module itself).
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;    info_struc = rec_info()
;
; OUTPUTS:
;    info_struc: structure containing the module's basic informations.
;
; ROUTINE MODIFICATION HISTORY:
;    program written: june 2002,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]
;                    -adapted to version 4.0 of the whole Software System CAOS
;                     (variable "pack_name" added, and variable "mod_type"
;                     changed into "mod_name").
;                    -useless variable "calib" eliminated.
;                    -variable "info.help" added (instead of !caos_env.help).
;                    -atmosphere-type output eliminated (useless wrt command-type
;                     output + use of new module DMC).
;                    -module's name from RCC to REC (eliminating old module REC).
;                   : february 2004,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 5.0 of the Software Package CAOS.
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;-
;
function rec_info

pack_name= 'CAOS_Software_Package_7.0'           ; package name
help_file= 'caos_help.html'
help     = !caos_env.modules+pack_name+!caos_env.delim+'help'+!caos_env.delim+help_file
ver      = fix(7)               ; version number of the whole software

mod_name = 'rec'                ; 3-char. module short name
descr    = 'wave-front REConstruction'; SHORT module description
def_file = mk_par_name(mod_name, PACK_NAME=pack_name, /DEFAULT)
                                ; default parameter filename

inp_type = 'mes_t'              ; input is of type mes_t
inp_opt  = 0B                   ; inputs may not be optional
out_type = 'com_t'              ; output is of type com_t

init     = 1B                   ; an initialisation STRUCTURE is required
time     = 0B                   ; time integration/delay management is required

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