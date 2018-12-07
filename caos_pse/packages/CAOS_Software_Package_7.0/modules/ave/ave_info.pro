; $Id: ave_info.pro,v 7.0 2016/04/27 marcel.carbillet$
;+
; NAME:
;       ave_info
;
; PURPOSE:
;       ave_info is the routine that returns the basic informations about
;       the module AVE (see ave.pro's header --or file caos_help.html-- for details
;       about the module itself).
;
; CATEGORY:
;       module's utility routine
;
; CALLING SEQUENCE: 
;       info_structure = ave_info()
; 
; OUTPUTS:
;       info_structure: structure containing the module's basic informations.
;
; MODIFICATION HISTORY:
;       program written: april 2008,
;                        Marcel Carbillet (Fizeau) [marcel.carbillet@unice.fr].
;       modifications  : april 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
FUNCTION ave_info

pack_name= 'CAOS_Software_Package_7.0'
help_file= 'caos_help.html'
help     = !caos_env.modules+pack_name+!caos_env.delim+'help'+!caos_env.delim+help_file
ver      = fix(7)

mod_name = 'ave'
descr    = 'signals AVEraging'
def_file = mk_par_name(mod_name, PACK_NAME=pack_name, /DEFAULT)

inp_type = 'mes_t'                           ; Input is of type mes_t
out_type = 'mes_t'                           ; Output is  of type mes_t
inp_opt  = 0B                                ; input is NOT optional

init     = 0B                ;initialisation file management is **NOT** required
time     = 0B                ;time integration/delay management is **NOT** required

; convert in low case format and eliminate all the blanks
mod_name = STRLOWCASE(STRCOMPRESS(mod_name, /REMOVE_ALL))
inp_type = STRLOWCASE(STRCOMPRESS(inp_type, /REMOVE_ALL))
out_type = STRLOWCASE(STRCOMPRESS(out_type, /REMOVE_ALL))

; control the module name length
IF (STRLEN(mod_name) NE !caos_env.module_len) THEN $
   MESSAGE, 'the module name must have '+STRTRIM(!caos_env.module_len)+' chars'

info = {                       $
         pack_name: pack_name, $
         help     : help,      $
         ver      : ver     ,  $

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