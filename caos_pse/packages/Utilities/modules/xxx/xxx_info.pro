;**
;*******************************************************************************
;** HOW TO USE THIS TEMPLATE:                                                  *
;**                                                                            *
;** 0-PLEASE READ THE WHOLE TEMPLATE FIRST (AND AT LEAST ONCE) !!              *
;** 1-CHANGE EVERYWHERE THE STRINGS "XXX" INTO THE CHOSEN 3-CHAR MODULE NAME   *
;** 2-CHANGE EVERYWHERE THE STRINGS "XYZ" INTO THE SOFTWARE PACKAGE NAME       *
;** 3-ADAPT THE TEMPLATE ONTO THE NEW MODULE CASE FOLLOWING THE EXAMPLES,      *
;**   RECOMENDATIONS, AND ADVICES  THROUGH THE TEMPLATE                        *
;** 4-DELETE ALL THE LINES OF CODE BEGINNING WITH ";**"                        *
;**                                                                            *
;*******************************************************************************
;**
;**
;** here is the routine identification
;**
; $Id: xxx_info.pro,v 5.0 2005/01/08 marcel.carbillet $
;**
;** put right version, date, and main author name of last update in the line
;** here above following the formats:
;** -n.m for the version (n=software release version, m=module update version).
;** -YYYY/MM/DD for the date (YYYY=year, MM=month, DD=day).
;** -first_name.last_name for the (last update) main author name.
;**
;
;**
;** here begins the header of the routine
;**
;+
; NAME:
;    xxx_info
;
; PURPOSE:
;    xxx_info is the routine that returns the basic informations for the
;    module XXX of the Software Package XYZ (see xxx.pro's header --or
;    file xyz_help.html-- for details about the module itself).
;
; CATEGORY:
;    module's utility routine
;
; CALLING SEQUENCE:
;    info_structure = xxx_info()
; 
; OUTPUTS:
;    info_structure: structure containing the module's basic informations.
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: date,
;                     author (institute) [email].
;    modifications  : date,
;                     author (institute) [email]:
;                    -description of the modifications.
;                   : date,
;                     author (institute) [email]:
;                    -description of the modifications.
;
;**
;** ROUTINE'S TEMPLATE MODIFICATION HISTORY:
;**     routine written: may 1998,
;**                      Armando Riccardi (OAA) [riccardi@arcetri.astro.it].
;**     modifications  : november 1998,
;**                      Armando Riccardi (OAA) [riccardi@arcetri.astro.it]:
;**                     -the tags calib, time and inp_opt are added in the
;**                      structure returned by xxx_info (see the comments
;**                      for a description).
;**     modifications  : april 1999,
;**                      Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;**                     -the tag inp_feedb is added in the structure
;**                      returned by xxx_info (in order to close the adaptive
;**                      loop, if any).
;**                    : november 1999,
;**                      Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;**                     -enhanced and adapted to version 2.0 (CAOS).
;**                    : june 2001,
;**                      Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;**                     -the template module XXX can now be visualized by the
;**                      CAOS Application Builder, with the two inputs and
;**                      two outputs defined of type "gen_t".
;**                   : january 2003,
;**                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;**                    -simplified templates for the version 4.0 of the
;**                     whole CAOS system (no more use of the COMMON variable
;**                     "calibration" and no more use of the possible
;**                     initialisation file and, obviously, of the calibration
;**                     file as well).
;**                    -variable "pack_name" added.
;**                    -variable "mod_type" changed into "mod_name".
;**                    -variable "calib" eliminated.
;**                    -variable "info.help" added (instead of !caos_env.help).
;**
;-
;
;**
;** here actually begins the routine code
;**
function xxx_info

pack_name= 'Template_Package_5.0'   ; package name
help_file= 'template_help.html' ; help file name
help     = !caos_env.modules+pack_name+!caos_env.delim+'help'+!caos_env.delim+help_file
                                ; help file address for Software Package "template"
ver      = fix(5)               ; version number of the Software Package used

mod_name = 'xxx'                ; 3-char. module short name
descr    = 'template module'    ; SHORT module description
def_file = mk_par_name(mod_name, PACK_NAME=pack_name, /DEFAULT)
                                ; default parameter filename

                                ;** comma separated list of input data types
                                ;** here two inputs are defined. this is a
                                ;** maximum. you could define just one input
                                ;** of type yyy_t: inp_type = 'yyy_t', or even
                                ;** zero input: inp_type = ''.
                                ;**
inp_type = 'gen_t,gen_t'        ; first and second input are both of type gen_t
                                ; (for demonstrative purpose)

                                ;** DELETE the line below where inp_opt is
                                ;** defined if the module has no input.
                                ;** define inp_opt as 0B (or 1B) if there
                                ;** is only one input.
                                ;**
inp_opt  = [0B, 1B]             ; first input may not be optional
                                ; second input may be optional
                                ;** the ordering must match inp_type. 1B
                                ;** means that the module can manage an
                                ;** undefined input.

                                ;** comma separated list of output data types
                                ;** (same remark as above).
                                ;**
out_type = 'gen_t,gen_t'        ; first and second output are both of type gen_t
                                ; (for demonstrative purpose)

                                ;** need initialisation STRUCTURE ?
                                ;** (yes=1B, no=0B)
                                ;**
init     = 1B                   ; an initialisation STRUCTURE is required

                                ;** need time delay/integration management ?
                                ;** (yes=1B, no=0B)
                                ;**
time     = 1B                   ; time integration/delay management is required

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
   inp_opt  : inp_opt,  $  ;** DELETE this line if the module has no input
   out_type : out_type, $

   init     : init,     $
   time     : time      $
   }

; back to calling program
return, info
end
