; $Id: dmi_info.pro,v 7.0 2016/04/29 marcel.carbillet $
;+
; NAME:
;    dmi_info
;
; PURPOSE:
;    dmi_info is the routine that returns the basic informations for the
;    module DMI (see dmi.pro's header --or file caos_help.html-- for details
;    about the module itself).
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;    info_structure = dmi_info()
; 
; OUTPUTS:
;    info_structure: structure containing the module's basic informations.
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: may 1998,
;                     Francoise Delplancke (ESO) [fdelplan@eso.org].
;    modifications  : december 1999-january 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 2.0 (CAOS).
;                   : january/february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 4.0 of the whole Software System CAOS.
;                     (variable "pack_name" added, and variable "mod_type"
;                     changed into "mod_name").
;                    -variable "info.help" added (instead of !caos_env.help).
;                    -variable "calib" eliminated.
;                   : february 2004,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 5.0 of the Software Package CAOS.
;                   : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
FUNCTION dmi_info

pack_name= 'CAOS_Software_Package_7.0'
help_file= 'caos_help.html'
help     = !caos_env.modules+pack_name+!caos_env.delim+'help'+!caos_env.delim+help_file
ver      = fix(7)

mod_name = 'dmi'
descr    = 'Deformable MIrror'
def_file = mk_par_name(mod_name, PACK_NAME=pack_name, /DEFAULT)

inp_type = 'wfp_t,com_t'
inp_opt  = [0B,1B]
out_type = 'wfp_t,wfp_t'

init     = 1B
time     = 1B

mod_name = strlowcase(strcompress(mod_name, /REMOVE_ALL))
inp_type = strlowcase(strcompress(inp_type, /REMOVE_ALL))
out_type = strlowcase(strcompress(out_type, /REMOVE_ALL))

info = $
   {   $
   pack_name:pack_name, $
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