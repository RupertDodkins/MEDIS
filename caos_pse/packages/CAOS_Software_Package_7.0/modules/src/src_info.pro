; $Id: src_info.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;       src_info
;
; PURPOSE:
;       src_info is the routine that returns the basic informations about
;       the module SRC.
;
; CATEGORY:
;       module's utility routine
;
; CALLING SEQUENCE:
;       info_structure = src_info()
; 
; OUTPUTS:
;       info_structure: structure containing the module's basic informations.
;
; MODIFICATION HISTORY:
;       program written: june 1998, Marcel Carbillet (OAA),
;                        <marcel@arcetri.astro.it>.
;       modifications  : february 1999, Marcel Carbillet:
;                       -a few modifications for version 1.0.
;                      : Dec 1999,
;                        Bruno Femenia (OAA) [bfemenia@arcetri.astro.it]
;                       -adapted to new version CAOS (v 2.0).
;                      : january 2003,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]
;                       -adapted to version 4.0 of the whole Software System CAOS
;                        (variable "pack_name" added, and variable "mod_type"
;                        changed into "mod_name").
;                       -useless variable "calib" eliminated.
;                       -variable "info.help" added (instead of !caos_env.help).
;                      : february 2004,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -adapted to version 5.0 of the Software Package CAOS.
;                      : april 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;-
;
function src_info

pack_name= 'CAOS_Software_Package_7.0'           ; Software Package name.
help_file= 'caos_help.html'
help     = !caos_env.modules+pack_name+!caos_env.delim+'help'+!caos_env.delim+help_file
ver      = fix(7)

mod_name = 'src'                ; Module name. Only LOWCASE string allowed
descr    = 'SouRCe definition'
def_file = mk_par_name(mod_name, PACK_NAME=pack_name, /DEFAULT) ; default parameter file

inp_type = ''                              ; Comma separated list of input data types.
out_type = 'src_t'                         ; Comma separated list of output data types.

init    = 1B                          ; initialisation file management is required
time    = 0B                          ; time integration/delay management is **NOT** required

; convert in low case format and eliminate all the blanks
mod_name = strlowcase(strcompress(mod_name, /REMOVE_ALL))
inp_type = strlowcase(strcompress(inp_type, /REMOVE_ALL))
out_type = strlowcase(strcompress(out_type, /REMOVE_ALL))

; control the module name length
IF (STRLEN(mod_name) NE !caos_env.module_len) THEN $
   MESSAGE, 'the module name must have '+STRTRIM(!caos_env.module_len)+' chars'

; resulting info structure
info = { $
         pack_name: pack_name,$
         help     : help,     $
         ver      : ver,      $

         mod_name : mod_name, $
         descr    : descr,    $
         def_file : def_file, $

         inp_type : inp_type, $
         out_type : out_type, $

         init     : init,     $
         time     : time      $
       }

return, info
end