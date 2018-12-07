; $Id: tce_info.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;       tce_info
;
; PURPOSE:
;       tce_info is the routine that returns the basic informations about
;       the module TCE.
;
; CATEGORY:
;       Utility
;
; CALLING SEQUENCE:
;       info_structure = tce_info()
;
; OUTPUTS:
;       info_structure: structure containing the module's basic informations.
;
; MODIFICATION HISTORY:
;       program written: Oct 1998, 
;                        B. Femenia (OAA) [bfemenia@arcetri.astro.it] 
;
;       modifications  : Feb 1999,
;                        Bruno Femenia (OAA) [bfemenia@arcetri.astro.it]
;                       -rewritten to match general style and requirements on
;                        how to manage initialization process, calibration
;                        procedure and time management according to  released
;                      : Nov 1999,
;                        Bruno Femenia (OAA)  [bfemenia@arcetri.astro.it]
;                       -adapted to version 2.0 (CAOS code)
;                        templates on Feb 1999.
;                      : Jan 2000,
;                        B. Femenia   (OAA) [bfemenia@arcetri.astro.it]
;                       -TCE now accepts inputs coming from IMG module whose
;                        output structure is now of type img_t.
;                      : january 2003,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]
;                       -adapted to version 4.0 of the whole Software System CAOS
;                        (variable "pack_name" added, and variable "mod_type"
;                        changed into "mod_name").
;                       -variable "info.help" added (instead of !caos_env.help).
;                       -variable "calib" eliminated.
;                      : february 2004,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -adapted to version 5.0 of the Software Package CAOS.
;                      : may 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;-
;
FUNCTION tce_info

pack_name= 'CAOS_Software_Package_7.0'
help_file= 'caos_help.html'
help     = !caos_env.modules+pack_name+!caos_env.delim+'help'+!caos_env.delim+help_file
ver      = FIX(7)

mod_name = 'tce'
descr    = 'Tip-tilt CEntroiding'
def_file = MK_PAR_NAME(mod_name, PACK_NAME=pack_name, /DEFAULT)

inp_type = 'img_t'
out_type = 'com_t'
inp_opt  = 0B              ;INPUT is not optional.

init     = 1B              ;INIT STRUCTURE REQUIRED
time     = 0B              ;MODULE NOT ALLOWED TO DELAY OR INTEGRATE

; convert in low case format and eliminate all the blanks
mod_name = STRLOWCASE(STRCOMPRESS(mod_name, /REMOVE_ALL))
inp_type = STRLOWCASE(STRCOMPRESS(inp_type, /REMOVE_ALL))
out_type = STRLOWCASE(STRCOMPRESS(out_type, /REMOVE_ALL))

info =                    $
  {                       $
    pack_name: pack_name, $
    help     : help,      $
    ver      : ver,       $

    mod_name : mod_name,  $
    descr    : descr   ,  $
    def_file : def_file,  $

    inp_type : inp_type,  $
    out_type : out_type,  $
    inp_opt  : inp_opt ,  $

    init     : init    ,  $
    time     : time       $
   }

RETURN, info

END