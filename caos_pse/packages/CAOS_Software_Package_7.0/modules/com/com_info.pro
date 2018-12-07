; $Id: com_info.pro,v 7.0 2016/04/27 marcel.carbillet $
;+
; NAME:
;    com_info
;
; PURPOSE:
;    com_info is the routine that returns the basic informations for the
;    module COM (see com.pro's header --or file caos_help.html-- for details
;    about the module itself).
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;    info_structure = com_info()
; 
; OUTPUTS:
;    info_structure: structure containing the module's basic informations.
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: february 2001,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : march 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;                    -adapted to new CAOS system (4.0) and building of the
;                     Software Package MAOS 1.0.
;                   : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
function com_info

pack_name = 'CAOS_Software_Package_7.0'
                                ; name of the Software Package
ver       = fix(7)              ; version number of the Software Package
help_file= 'caos_help.html'     ; help file name
help     = !caos_env.modules+pack_name+!caos_env.delim+'help'+!caos_env.delim+help_file
                                ; help file address for Software Package MAOS

mod_name = 'com'                ; 3-char. module short name
descr    = 'COMbine measurements'
                                ; SHORT module description
def_file = mk_par_name(mod_name, PACK_NAME=pack_name, /DEFAULT)
                                ; default parameter filename

inp_type = 'mes_t,mes_t'        ; first input is of type mes_t, second input as well
inp_opt  = [0B, 0B]             ; first input may not be optional, second input neither
out_type = 'mes_t'              ; output is of type mes_t

init     = 0B                   ; an initialisation STRUCTURE is NOT required
time     = 0B                   ; time integ./delay management is NOT required

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
   pack_name: pack_name, $
   help     : help,      $
   ver      : ver,       $

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