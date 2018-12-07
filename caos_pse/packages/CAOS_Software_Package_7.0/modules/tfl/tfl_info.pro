; $Id: tfl_info.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    tfl_info
;
; PURPOSE:
;    tfl_info is the routine that returns the basic informations about
;    the module TFL (see tfl.pro's header --or file caos_help.html-- for
;    details about the module itself).
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;    info_structure = tfl_info()
; 
; OUTPUTS:
;    info_structure: structure containing the module's basic informations.
;
; MODIFICATION HISTORY:
;    program written: May 1998,
;                     A. Riccardi (OAA), <riccardi@arcetri.astro.it>.
;
;    modifications  : november 1998, Armando Riccardi:
;                    -the tags calib, time and inp_opt are added in the
;                     structure returned by tfl_info (see the comments
;                     for a description).
;                   : Nov 1999,
;                     B. Femenia   (OAA) [bfemenia@arcetri.astro.it]
;                    -adapted to new version CAOS (v 2.0).
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
function tfl_info

pack_name= 'CAOS_Software_Package_7.0'           ; Package name.
help_file= 'caos_help.html'
help     = !caos_env.modules+pack_name+!caos_env.delim+'help'+!caos_env.delim+help_file
ver      = fix(7)               ; Version number of the module structure

mod_name = 'tfl'                ; Module name. Only LOWCASE string allowed
descr    = 'Time FiLtering'     ; Short module description
def_file = mk_par_name(mod_name, PACK_NAME=pack_name,/DEFAULT) ; default parameter file

inp_type = 'com_t'              ; Input  is of type com_t.
out_type = 'com_t'              ; Output is of type com_t.
inp_opt  = [0B]                 ; Input is **NOT** optional

init     = 1B                   ; Initialisation structure is required.
time     = 0B                   ; Module not allowed to delay or integrate.

; convert in low case format and eliminate all the blanks
mod_name = strlowcase(strcompress(mod_name, /REMOVE_ALL))
inp_type = strlowcase(strcompress(inp_type, /REMOVE_ALL))
out_type = strlowcase(strcompress(out_type, /REMOVE_ALL))

; control the module name length
IF (STRLEN(mod_name) NE !caos_env.module_len) THEN $
   MESSAGE, 'the module name must have '+STRTRIM(!caos_env.module_len)+' chars'

info = {                     $
       pack_name: pack_name, $
       help     : help,      $
       ver      : ver,       $

       mod_name : mod_name,  $
       descr    : descr,     $
       def_file : def_file,  $

       inp_type : inp_type,  $
       out_type : out_type,  $
       inp_opt  : inp_opt,   $

       init     : init,      $
       time     : time       $
       }

return, info
end