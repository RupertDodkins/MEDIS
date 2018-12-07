; $Id: ata_info.pro,v 7.0 2016/04/15 marcel.carbillet $
;+
; NAME:
;       ata_info
;
; PURPOSE:
;       ata_info is the routine that returns the basic informations about
;       the module ATA (see ata.pro's header --or file caos_help.html-- for details
;       about the module itself).
;
; CATEGORY:
;       module's utility routine
;
; CALLING SEQUENCE: 
;       info_structure = ata_info()
; 
; OUTPUTS:
;       info_structure: structure containing the module's basic informations.
;
; MODIFICATION HISTORY:
;       program written: April 2001,
;                        Bruno Femenia (OAA) [bfemenia@arcetri.astro.it].
;       modifications  : january 2003,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -adapted to version 4.0 of the whole Software System CAOS
;                        (variable "pack_name" added, and variable "mod_type"
;                        changed into "mod_name").
;                       -useless variable "calib" eliminated.
;                       -variable "info.help" added (instead of !caos_env.help).
;                      : february 2004,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -adapted to version 5.0 of the Software Package CAOS.
;                      : april 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;-
;
FUNCTION ata_info

pack_name= 'CAOS_Software_Package_7.0'
help_file= 'caos_help.html'
help     = !caos_env.modules+pack_name+!caos_env.delim+'help'+!caos_env.delim+help_file
ver      = FIX(7)

mod_name = 'ata'
descr    = 'ATmosphere Adding'
def_file = mk_par_name(mod_name, PACK_NAME=pack_name, /DEFAULT)

inp_type = 'atm_t,atm_t'                ; Inputs are of type atm_t
out_type = 'atm_t'                      ; Output is  of type atm_t
inp_opt  = [1B,1B]                      ; Any input may be optional but not simultaneously.

init     = 1B                           ; an initialisation structure is required
time     = 0B                           ; time integration/delay management is not required

; convert in low case format and eliminate all the blanks
mod_name = STRLOWCASE(STRCOMPRESS(mod_name, /REMOVE_ALL))
inp_type = STRLOWCASE(STRCOMPRESS(inp_type, /REMOVE_ALL))
out_type = STRLOWCASE(STRCOMPRESS(out_type, /REMOVE_ALL))

; control the module name length
IF (STRLEN(mod_name) NE !caos_env.module_len) THEN $
   MESSAGE, 'the module name must have '+STRTRIM(!caos_env.module_len)+' chars'

info = {                     $
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