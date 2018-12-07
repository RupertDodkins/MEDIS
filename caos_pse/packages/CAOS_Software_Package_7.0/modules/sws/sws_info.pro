; $Id: sws_info.pro,v 7.0 2016/05/19 marcel.carbillet $
;
;+
; NAME:
;       sws_info
;
; PURPOSE:
;       sws_info is the routine that returns the basic informations about
;       the module SWS.
;
; CATEGORY:
;       Utility
;
; CALLING SEQUENCE:
;       info_struc = sws_info()
;
; OUTPUTS:
;       info_struc:  structure containing the module's basic informations.
;
; ROUTINE MODIFICATION HISTORY:
;       program written: Dec 2003,
;                        B. Femenia   (GTC) [bfemenia@ll.iac.es].
;       modifications  : december 2003,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -adapted to version 4.0+ of the whole Software System CAOS
;                        (variable "pack_name" added, and variable "mod_type"
;                        changed into "mod_name").
;                       -useless variable "calib" eliminated.
;                       -variable "info.help" added (instead of !caos_env.help).
;                      : September 2004,
;                        B. Femenia   (GTC) [bfemenia@ll.iac.es].
;                       -adapted to version 5.0 of the Software Package CAOS.
;                      : may 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;-
;
FUNCTION sws_info

   pack_name='CAOS_Software_Package_7.0'
   mod_name = 'sws'                                       ; only lowcase string allowed
   help_file='caos_help.html'
   help     = !caos_env.modules+pack_name+!caos_env.delim+'help'+!caos_env.delim+help_file

   descr    = 'Shack-Hartmann Wavefront Sensor'           ; module description
   ver      = FIX(7)                                      ; version number of the module structure

   def_file = MK_PAR_NAME(mod_name, PACK_NAME=pack_name, /DEFAULT)
                                                          ; default parameter file

   init     = 1B                                          ;INIT STRUCTURE REQUIRED
   time     = 1B                                          ;TIME INTEGRATION MAY BE REQUIRED 

   inp_type = 'wfp_t'
   inp_opt  = 0B                                          ;INPUT IS NOT OPTIONAL
   out_type = 'mim_t'

   mod_name = STRLOWCASE(STRCOMPRESS(mod_name, /REMOVE_ALL))
   inp_type = STRLOWCASE(STRCOMPRESS(inp_type, /REMOVE_ALL))
   out_type = STRLOWCASE(STRCOMPRESS(out_type, /REMOVE_ALL))

   info = {pack_name: pack_name, $
           help     : help,      $
           ver      : ver,       $

           mod_name : mod_name,  $
           descr    : descr,     $
           def_file : def_file,  $

           inp_type : inp_type,  $
           inp_opt  : inp_opt,   $
           out_type : out_type,  $

           init     : init,      $
           time     : time       }

   RETURN, info

END