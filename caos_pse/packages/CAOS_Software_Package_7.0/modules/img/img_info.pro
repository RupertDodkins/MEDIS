; $Id: img_info.pro,v 7.0 2016/04/21 marcel.carbillet $
;+
; NAME:
;       img_info
;
; PURPOSE:
;       img_info is the routine that returns the basic informations about
;       the module IMG.
;
; CATEGORY:
;       Utility
;
; CALLING SEQUENCE:
;       info_structure = img_info()
;
; OUTPUTS:
;       info_structure: structure containing the module's basic informations.
;
; MODIFICATION HISTORY:
;       program written: Dec 1999,
;                        B. Femenia (OAA) [bfemenia@arcetri.astro.it]
;       modifications  : january 2003,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]
;                       -adapted to version 4.0 of the whole Software System CAOS
;                        (variable "pack_name" added, and variable "mod_type"
;                        changed into "mod_name").
;                       -useless variable "calib" eliminated.
;                       -variable "info.help" added (instead of !caos_env.help).
;                      : March 2003,
;                        B. Femenia (GTC) [bfemenia@ll.iac.es]
;                       -merging versions at OAA and GTC.
;                      : february 2004,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -adapted to version 5.0 of the Software Package CAOS.
;                      : april 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;-
;
FUNCTION img_info

pack_name= 'CAOS_Software_Package_7.0'
help_file= 'caos_help.html'
help     = !caos_env.modules+pack_name+!caos_env.delim+'help'+!caos_env.delim+help_file
ver      = FIX(7)

mod_name = 'img'
descr    = 'IMaGer module'
def_file = MK_PAR_NAME(mod_name, PACK_NAME=pack_name, /DEFAULT)

inp_type = 'wfp_t'
out_type = 'img_t,img_t'
inp_opt  = 0B              ;INPUT IS NOT OPTIONAL

init     = 1B              ;INIT STRUCTURE REQUIRED
time     = 1B              ;TIME INTEGRATION MAY BE REQUIRED

; convert in low case format and eliminate all the blanks
mod_name = STRLOWCASE(STRCOMPRESS(mod_name, /REMOVE_ALL))
inp_type = STRLOWCASE(STRCOMPRESS(inp_type, /REMOVE_ALL))
out_type = STRLOWCASE(STRCOMPRESS(out_type, /REMOVE_ALL))

info =                   $
  {                      $
    pack_name: pack_name,$
    help     : help,     $
    ver      : ver     , $

    mod_name : mod_name, $
    descr    : descr   , $
    def_file : def_file, $

    inp_type : inp_type, $
    out_type : out_type, $
    inp_opt  : inp_opt , $

    init     : init    , $
    time     : time      $
  }

RETURN, info
END