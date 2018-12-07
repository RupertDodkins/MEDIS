; $Id: atm_info.pro,v 7.0 2016/04/21 marcel.carbillet $
;+
; NAME:
;    atm_info
;
; PURPOSE:
;    atm_info is the routine that returns the basic informations about
;    the module ATM.
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;    info_structure = atm_info()
;
; OUTPUTS:
;    info_structure: structure containing the module's basic informations.
;
; ROUTINE MODIFICATION HISTORY:
;    program written: february 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]
;    modifications  : november 1999,
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
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]
;                    -adapted to version 5.0 of the Software Package CAOS.
;                   : arpil 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]
;                    -adapted to version 7.0 of the Software Package CAOS.
;
;-
;
function atm_info

mod_name ='atm'
pack_name='CAOS_Software_Package_7.0'
help_file='caos_help.html'
help     = !caos_env.modules+pack_name+!caos_env.delim+'help'+!caos_env.delim+help_file

info = $
   {   $
   pack_name: pack_name,                                            $
   help     : help,                                                 $
   ver      : fix(7),                                               $

   mod_name : mod_name,                                             $
   descr    : 'ATMosphere building',                                $
   def_file : mk_par_name(mod_name, PACK_NAME=pack_name, /DEFAULT), $

   inp_type : '',                                                   $
   inp_opt  : 0B,                                                   $
   out_type : 'atm_t',                                              $

   init     : 1B,                                                   $
   time     : 0B                                                    $
   }

return, info
end