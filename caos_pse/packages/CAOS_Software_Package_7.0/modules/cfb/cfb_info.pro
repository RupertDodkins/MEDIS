; $Id: cfb_info.pro,v 7.0 2016/04/27 marcel.carbillet $
;+
; NAME:
;    cfb_info
;
; PURPOSE:
;    cfb_info is the routine that returns the basic informations for the
;    module CFB (see cfb.pro's header --or file caos_help.html-- for details
;    about the module itself).
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;    info_structure = cfb_info()
; 
; OUTPUTS:
;    info_structure: structure containing the module's basic informations.
;
; ROUTINE MODIFICATION HISTORY:
;    program written: November 1999,
;                     Bruno Femenia (OAA) [bfemenia@arcetri.astro.it]
;
;    modifications  : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 4.0 of the whole Software System CAOS
;                     (variable "pack_name" added, and variable "mod_type"
;                     changed into "mod_name").
;                    -variable "calib" eliminated.
;                    -variable "info.help" added (instead of !caos_env.help).
;                   : february 2004,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 5.0 of the Software Package CAOS.
;                   : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
FUNCTION cfb_info

pack_name='CAOS_Software_Package_7.0'
help_file= 'caos_help.html'
help     = !caos_env.modules+pack_name+!caos_env.delim+'help'+!caos_env.delim+help_file
ver     = fix(7)

mod_name= 'cfb'                            ; 3-char. module short name
descr   = 'Calibration FiBer'              ; SHORT module description
def_file= mk_par_name(mod_name, PACK_NAME=pack_name, /DEFAULT)  ; default parameter filename

inp_type = ''                              ; No input for CFB
out_type = 'wfp_t'                         ; Output is of type wfp_t

init    = 0B                           ; initialisation structure is **NOT** required
time    = 0B                           ; time integration/delay management is **NOT** required

; convert in low case format and eliminate all the blanks
mod_name = STRLOWCASE(strcompress(mod_name, /REMOVE_ALL))
inp_type = STRLOWCASE(strcompress(inp_type, /REMOVE_ALL))
out_type = STRLOWCASE(strcompress(out_type, /REMOVE_ALL))

; control the module name length
IF (STRLEN(mod_name) NE !caos_env.module_len) THEN $
   MESSAGE, 'the module name must have '+STRTRIM(!caos_env.module_len)+' chars'

; resulting info structure
info =                   $
  {                      $
    pack_name: pack_name,$
    help     : help,     $
    ver      : ver,      $

    mod_name : mod_name, $
    descr    : descr,    $
    def_file : def_file, $

    inp_type : inp_type, $
    out_type : out_type, $

    init     : init,     $
    time     : time      $
  }

; back to calling program
RETURN, info
END