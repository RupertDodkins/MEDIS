; $Id: ibc_info.pro,v 7.0 2016/04/29 marcel.carbillet $
;+
; NAME:
;    ibc_info
;
; PURPOSE:
;    ibc_info is the routine that returns the basic informations about
;    the module IBC.
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;    info_structure = ibc_info()
; 
; OUTPUTS:
;    info_structure: structure containing the module's basic informations.
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: april 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : december 1999,
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
;                   : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
function ibc_info

pack_name= 'CAOS_Software_Package_7.0'
                                ; package name
help_file= 'caos_help.html'
help     = !caos_env.modules+pack_name+!caos_env.delim+'help'+!caos_env.delim+help_file
ver      = fix(7)               ; version number

mod_name = 'ibc'                ; module name
descr    = 'Interferometric Beam Combiner'
                                ; short module description
def_file = mk_par_name(mod_name, PACK_NAME=pack_name, /DEFAULT)
                                ; default parameter file

inp_type = 'wfp_t,wfp_t'        ; input data types
inp_opt  = [0B, 0B]             ; inputs are not optional
out_type = 'wfp_t'              ; output data type

init     = 1B                   ; initialization needed
time     = 0B                   ; no time management needed

; convert in low case format and eliminate all the blanks
mod_name = strlowcase(strcompress(mod_name, /REMOVE_ALL))
inp_type = strlowcase(strcompress(inp_type, /REMOVE_ALL))
out_type = strlowcase(strcompress(out_type, /REMOVE_ALL))

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
   inp_opt  : inp_opt,  $

   init     : init,     $
   time     : time      $
   }

return, info
end