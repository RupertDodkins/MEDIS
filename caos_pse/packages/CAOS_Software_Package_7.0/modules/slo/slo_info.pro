; $Id: slo_info.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    slo_info
;
; PURPOSE:
;    slo_info is the routine that returns the basic informations for the
;    module slo (see slo.pro's header --or file caos_help.html-- for details
;    about the module itself).
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;    info_struc = slo_info()
; 
; OUTPUTS:
;    info_struc: structure containing the module's basic informations.
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: june 2001,
;                     Christophe Verinaud (OAA) [verinaud@arcetri.astro.it].
;    modifications  : january 2003,
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
function slo_info

pack_name= 'CAOS_Software_Package_7.0'
help_file= 'caos_help.html'
help     = !caos_env.modules+pack_name+!caos_env.delim+'help'+!caos_env.delim+help_file
ver      = fix(7)

mod_name = 'slo'
descr    = 'SLOpe calculus from PYR signals'

def_file = mk_par_name(mod_name, PACK_NAME=pack_name, /DEFAULT)
                                  ; default parameter file
inp_type = 'mim_t'
out_type = 'mes_t'
inp_opt  = 0B                     ; input may not be optional

init     = 1B                     ; initialization structure needed
time     = 0B                     ; timing not needed

mod_name = strlowcase(strcompress(mod_name, /REMOVE_ALL))
inp_type = strlowcase(strcompress(inp_type, /REMOVE_ALL))
out_type = strlowcase(strcompress(out_type, /REMOVE_ALL))

info = $
     { $
     pack_name: pack_name,$
     help     : help,     $
     ver      : ver,      $

     mod_name : mod_name, $
     descr    : descr,    $
     def_file : def_file, $

     inp_type : inp_type, $
     inp_opt  : inp_opt,  $
     out_type : out_type, $

     init    : init,     $
     time    : time      $
     }

return, info
end