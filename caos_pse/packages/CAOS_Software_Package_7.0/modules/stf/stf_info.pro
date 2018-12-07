; $Id: stf_info.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    stf_info
;
; PURPOSE:
;    stf_info is the routine that returns the basic informations about
;    the module STF.
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;    info_struc = stf_info()
;
; OUTPUTS:
;    info_struc:  structure
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: july 1998,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : march 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 1.0.
;                   : december 1999,
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
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;-
;
function stf_info

pack_name= 'CAOS_Software_Package_7.0'
help_file= 'caos_help.html'
help     = !caos_env.modules+pack_name+!caos_env.delim+'help'+!caos_env.delim+help_file
ver      = fix(7)

mod_name = 'stf'
descr    = 'STructure Function calculus'
def_file = mk_par_name(mod_name, PACK_NAME=pack_name, /DEFAULT)

inp_type = 'wfp_t'              ; wavefront input type
out_type = 'stf_t'              ; structure function output type
inp_opt  = 0B

init     = 1B
time     = 0B

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