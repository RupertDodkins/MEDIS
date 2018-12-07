; $Id: sav_info.pro,v 7.0 2016/05/03 marcel.carbillet $
;+
; NAME:
;    sav_info
;
; PURPOSE:
;    sav_info is the routine that returns the basic informations about
;    the module SAV.
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;    info_structure = sav_info()
; 
; OUTPUTS:
;    info_structure: structure containing the module's basic informations.
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: march 1999,
;                     Simone Esposito (OAA) [esposito@arcetri.astro.it].
;    modifications  : december,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 2.0 (CAOS).
;                   : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]
;                    -adapted to version 4.0 of the whole Software System CAOS
;                     (variable "pack_name" added, and variable "mod_type"
;                     changed into "mod_name").
;                    -useless variable "calib" eliminated.
;                    -variable "info.help" added (instead of !caos_env.help).
;                   : february 2004,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 5.0 of the Software Package CAOS.
;                   : may 2016,
;                     Ulysse Perruchon-Monge & Adama Sy (Dépt.Physique UNS),
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -moved from Soft.Pack.CAOS 5.2 to new package "Utilities"
;                     of new version (7.0) of the CAOS PSE,
;                    -simple IDL "save" format and FITS format added.
;-
;
function sav_info

pack_name= 'Utilities'          ; package name
help_file= 'utilitites.html'
help     = !caos_env.modules+pack_name+!caos_env.delim+'help'+!caos_env.delim+help_file
ver      = fix(7)               ; version number

mod_name = 'sav'                ; module name
descr    = 'data SAVing'        ; short module description
def_file = mk_par_name(mod_name, PACK_NAME=pack_name, /DEFAULT)
                                ; default parameter file

inp_type = 'gen_t'              ; input is of generic type (gen_t)
out_type = ''                   ; no output
inp_opt  = 0B                   ; the input cannot be optional

init     = 1B                   ; initialization struc. needed
time     = 0B                   ; time struc. not needed

; convert in low case format and eliminate all the blanks
mod_name = strlowcase(strcompress(mod_name, /REMOVE_ALL))
inp_type = strlowcase(strcompress(inp_type, /REMOVE_ALL))
out_type = strlowcase(strcompress(out_type, /REMOVE_ALL))

info = {                    $
       pack_name: pack_name,$
       help     : help,     $
       ver      : ver,      $

       mod_name : mod_name, $
       descr    : descr,    $
       def_file : def_file, $

       inp_type : inp_type, $
       out_type : out_type, $
       inp_opt  : inp_opt,  $

       init     : init,     $
       time     : time      $
       }

return, info
end