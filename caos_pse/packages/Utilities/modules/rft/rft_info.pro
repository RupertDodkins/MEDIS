; $Id: rft_info.pro,v 7.0 last revision 2016/04/29 Andrea La Camera $
;+
; NAME:
;    rft_info
;
; PURPOSE:
;    rft_info is the routine that returns the basic information for the
;    module RFT (see rft.pro's header --or file utilities_help.html-- for details
;    about the module itself).
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;    info_structure = rft_info()
;
; OUTPUTS:
;    info_structure: structure containing the module's basic information.
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: october 2000,
;                     Serge Correia (OAA) [marcel@arcetri.astro.it].
;    modifications  : february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]
;                    -adapted to version 4.0 of the whole system CAOS
;                     (variable "pack_name" added, and variable "mod_type"
;                     changed into "mod_name").
;                    -useless variable "calib" eliminated.
;                    -variable info.help added (instead of !caos_env.help).
;                   : from CAOS_PSE v 7.0 (2016) 
;                    -this module has been moved from AIRY 6.1 to the new 
;                     package "Utilities". Version number has been
;                     set to 7.0. 
;-
;
function rft_info

pack_name= 'Utilities'             ; Software Package name
help_file= 'utilities_help.html'
help     = !caos_env.modules+pack_name+!caos_env.delim+'help'+!caos_env.delim+help_file
                                 ; help-file address for Soft.Pack
ver      = fix(7)                ; version number of the Soft.Pack used

mod_name = 'rft'
descr    = 'Read FiTs file format'
def_file = mk_par_name(mod_name, PACK_NAME=pack_name, /DEFAULT)
                                 ; default parameter filename

inp_type = ''
out_type = 'img_t'

init     = 0B                    ; an initialisation STRUCTURE is required
time     = 0B                    ; time integration/delay management is required

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
   out_type : out_type, $

   init     : init,     $
   time     : time      $
   }

; back to calling program
return, info
end
