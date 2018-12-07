; $Id: wft_info.pro,v 7.0 last revision 2016/04/29 Andrea La Camera $
;+
; NAME:
;    wft_info
;
; PURPOSE:
;    wft_info is the routine that returns the basic informations about
;    the module WFT.
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;    info_structure = wft_info()
; 
; OUTPUTS:
;    info_structure: structure containing the module's basic informations.
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: october 2000,
;                     Serge Correia (OAA) [correia@arcetri.astro.it].
;    modifications  : february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]
;                    -adapted to version 4.0 of the whole system CAOS
;                     (variable "pack_name" added, and variable "mod_type"
;                     changed into "mod_name").
;                    -useless variable "calib" eliminated.
;                    -variable info.help added (instead of !caos_env.help).
;                   : for version 5.0,
;                     Andrea La Camera (DISI) [lacamera@disi.unige.it]:
;                    -INIT eliminated (obsolete).
;                   : from CAOS_PSE v 7.0 (2016) 
;                    -this module has been moved from AIRY 6.1 to the new 
;                     package "Utilities". Version number has been
;                     set to 7.0. 
;-
;
function wft_info

pack_name= 'Utilities'
                                    ; Software Package name
help_file= 'utilities_help.html'
help     = !caos_env.modules+pack_name+!caos_env.delim+'help'+!caos_env.delim+help_file
                                    ; help-file address for Soft.Pack. AIRY
ver      = fix(7)                   ; version number of the Software Package used

mod_name = 'wft'                    ; module name
descr    = 'Write FiTs file format' ; short module description
def_file = mk_par_name(mod_name, PACK_NAME=pack_name, /DEFAULT)
                                    ; default parameter file

init     = 0B                       ; initialization struc. needed
time     = 0B                       ; time struc. not needed

inp_type = 'img_t'                  ; input is of image type (img_t)
inp_opt  = 0B                       ; the input cannot be optional
out_type = ''                       ; no output

; convert in low case format and eliminate all the blanks
mod_name = strlowcase(strcompress(mod_name, /REMOVE_ALL))
inp_type = strlowcase(strcompress(inp_type, /REMOVE_ALL))
out_type = strlowcase(strcompress(out_type, /REMOVE_ALL))

info = {                   $
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
