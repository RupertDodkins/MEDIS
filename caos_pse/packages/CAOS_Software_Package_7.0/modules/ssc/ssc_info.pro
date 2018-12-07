; $Id: ssc_info.pro, Soft.Pack.CAOS v 7.0 2016/05/19 marcel.carbillet $
;
;+
; NAME:
;    ssc_info
;
; PURPOSE:
;    ssc_info is the routine that returns the basic informations for the
;    module SSC of the Software Package CAOS (see ssc.pro's header --or
;    file caos_help.html-- for details about the module itself).
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;    info_structure = ssc_info()
; 
; OUTPUTS:
;    info_structure: structure containing the module's basic informations.
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: february 2012,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr].
;    modifications  : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;-
;
function ssc_info

pack_name= 'CAOS_Software_Package_7.0'
                                ; package name
help_file= 'caos_help.html'     ; help file name
help     = !caos_env.modules+pack_name+!caos_env.delim+'help'+!caos_env.delim+help_file
                                ; help file address for Software Package "template"
ver      = fix(7)               ; version number of the Software Package used

mod_name = 'ssc'                ; 3-char. module short name
descr    = 'State-Space Control'; SHORT module description
def_file = mk_par_name(mod_name, PACK_NAME=pack_name, /DEFAULT)
                                ; default parameter filename

inp_type = 'mes_t'              ; input is of type mes_t
inp_opt  = [0B]                 ; input is not optional
out_type = 'com_t'              ; output is  of type com_t

init     = 1B                   ; an initialisation STRUCTURE is required

time     = 0B                   ; module not allowed to delay or integrate.

; convert in low case format and eliminate all the blanks
mod_name = strlowcase(strcompress(mod_name, /REMOVE_ALL))
inp_type = strlowcase(strcompress(inp_type, /REMOVE_ALL))
out_type = strlowcase(strcompress(out_type, /REMOVE_ALL))

; control the module name length
if strlen(mod_name) ne !caos_env.module_len then $
   message, 'the module name must have '+strtrim(!caos_env.module_len)+' chars'

; resulting info structure
info = $
   {   $
   pack_name: pack_name,$
   help     : help,     $
   ver      : ver,      $

   mod_name : mod_name, $
   descr    : descr,    $
   def_file : def_file, $

   inp_type : inp_type, $
   inp_opt  : inp_opt,  $
   out_type : out_type, $

   init     : init,     $
   time     : time      $
   }

; back to calling program
return, info
end