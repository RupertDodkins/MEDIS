; $Id: ttm_info.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;       ttm_info
;
; PURPOSE:
;       ttm_info is the routine that returns the basic informations about
;       the module TTM.
;
; CATEGORY:
;       utility
;
; CALLING SEQUENCE: 
;       info_structure = ttm_info()
; 
; OUTPUTS:
;       info_structure: structure containing the module's basic informations.
;
; MODIFICATION HISTORY:
;       program written: Oct 1998,
;                        B. Femenia   (OAA) [bfemenia@arcetri.astro.it]
;                        M. Carbillet (OAA) [marcel@arcetri.astro.it]
;
;       modifications  : Feb 1999,
;                        B. Femenia (OAA) [bfemenia@arcetri.astro.it]
;                       -completely rewritten to match general style and
;                        requirements on how to manage initialization process,
;                        calibration procedure and time management according to
;                        released templates on Feb 1999.
;                      : Nov 1999,
;                        Bruno Femenia (OAA)  [bfemenia@arcetri.astro.it]
;                       -adapted to version 2.0 (CAOS code)
;                      : Dec 1999,
;                        B. Femenia   (OAA) [bfemenia@arcetri.astro.it]
;                       -a second output containing the CORRECTION is added
;                        in order to allow the use of COMBINER feature.
;                      : january 2003,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]
;                       -adapted to version 4.0 of the whole Software System CAOS
;                        (variable "pack_name" added, and variable "mod_type"
;                        changed into "mod_name").
;                       -useless variable "calib" eliminated.
;                       -variable "info.help" added (instead of !caos_env.help).
;                      : february 2004,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -adapted to version 5.0 of the Software Package CAOS.
;                      : may 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;-
;
FUNCTION ttm_info

pack_name= 'CAOS_Software_Package_7.0'
help_file= 'caos_help.html'
help     = !caos_env.modules+pack_name+!caos_env.delim+'help'+!caos_env.delim+help_file
ver      = FIX(7)

mod_name = 'ttm'
descr    = 'Tip-Tilt Mirror'
def_file = mk_par_name(mod_name, PACK_NAME=pack_name, /DEFAULT)

inp_type = 'wfp_t,com_t'
out_type = 'wfp_t,wfp_t'
inp_opt  = [0B, 1B]             ; Only second input may be optional

init     = 1B                   ;INITIALIZATION STRUCTURE REQUIRED
time     = 0B                   ;MODULE NOT ALLOWED TO DELAY OR INTEGRATE           

; convert in low case format and eliminate all the blanks
mod_name = STRLOWCASE(strcompress(mod_name, /REMOVE_ALL))
inp_type = STRLOWCASE(strcompress(inp_type, /REMOVE_ALL))
out_type = STRLOWCASE(strcompress(out_type, /REMOVE_ALL))

; control the module name length
IF (STRLEN(mod_name) NE !caos_env.module_len) THEN $
   MESSAGE, 'the module name must have '+STRTRIM(!caos_env.module_len)+' chars'

info = {                       $
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

RETURN, info
END