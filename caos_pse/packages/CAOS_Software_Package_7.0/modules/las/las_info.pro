; $Id: las_info.pro,v 7.0 2016/04/29 marcel.carbillet $
;+
; NAME:
;    las_info
;
; PURPOSE:
;    las_info is the routine that returns the basic informations for the
;    module LAS (see las.pro's header --or file caos_help.html-- for details
;    about the module itself).
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;    info_structure = las_info()
;
; OUTPUTS:
;    info_structure:  structure containing the module's basic informations.
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: june 1998,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : february 1999,
;                     Elise Viard (ESO) [eviard@eso.org]:
;                    -a few modifications for version 1.0.
;                   : december 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -enhanced and adapted to version 2.0 (CAOS).
;                    -init put to 0B (structure INIT useless).
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
function las_info

pack_name= 'CAOS_Software_Package_7.0'
help_file= 'caos_help.html'
help     = !caos_env.modules+pack_name+!caos_env.delim+'help'+!caos_env.delim+help_file
ver      = fix(7)

mod_name = 'las'
descr    = 'LASer definition'
def_file = mk_par_name(mod_name, PACK_NAME=pack_name, /DEFAULT)

inp_type = ''
inp_opt  = 0B
out_type = 'src_t'

init     = 0B                   ; initialization structure not needed
time     = 0B                   ; time structure not needed

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
   inp_opt  : inp_opt,  $
   out_type : out_type, $

   init     : init,     $
   time     : time      $
   }

return, info
end