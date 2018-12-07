; $Id: dmc_info.pro,v 7.0 2016/04/29 marcel.carbillet $
;+
; NAME:
;    dmc_info
;
; PURPOSE:
;    dmc_info is the routine that returns the basic informations for the
;    module DMC (see dmc.pro's header --or file caos_help.html-- for details
;    about the module itself).
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;    info_structure = dmc_info()
; 
; OUTPUTS:
;    info_structure: structure containing the module's basic informations.
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: february-march 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
FUNCTION dmc_info

pack_name= 'CAOS_Software_Package_7.0'
help_file= 'caos_help.html'
help     = !caos_env.modules+pack_name+!caos_env.delim+'help'+!caos_env.delim+help_file
ver      = fix(7)

mod_name = 'dmc'
descr    = 'Deformable Mirror Conjugated'
def_file = mk_par_name(mod_name, PACK_NAME=pack_name, /DEFAULT)

inp_type = 'atm_t,com_t'
inp_opt  = [0B,1B]
out_type = 'atm_t,atm_t'

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