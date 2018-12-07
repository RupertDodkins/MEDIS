; $Id: dmi_init.pro,v 7.0 2016/04/29 marcel.carbillet $
;+
; NAME:
;    dmi_init
;
; PURPOSE:
;    dmi_init executes the initialization for the Deformable MIrror (DMI)
;    module, that is:
;
;       0- check the formal validity of the input/output structure
;       1- initialize the output structures out_wfp_t and out_wfp_c
;
;    (see dmi.pro's header --or file caos_help.html-- for details).
;
; CATEGORY:
;    module's initialisation routine
;
; CALLING SEQUENCE:
;    err = dmi_init(inp_wfp_t, $
;                   inp_com_t, $
;                   out_wfp_c, $
;                   out_wfp_t, $
;                   par,       $
;                   INIT=init  )
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.:
;    see dmi.pro's help for a detailed description.
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: october 1998,
;                     Francoise Delplancke (ESO) [fdelplan@eso.org].
;    modifications  : october 1999,
;                     Francoise Delplancke (ESO) [fdelplan@eso.org]:
;                    -bug when restoring initialization corrected
;                    -add saving influence functions under a file to save
;                     memory use => the influence functions are not anymore
;                     passed as an output to REC but only the file name is 
;                     passed to this module, it will then be restored
;                   : october 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -definition of the tag "pupil" of "out_mir_t" redefined
;                     using "inp_wfp_t" instead of "annex".
;                   : december 1999--january 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -re-organized in order to be adapted to version 2.0 (CAOS).
;                   : january/february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -"mod_type"->"mod_name"
;                     (for version 4.0 of the whole Software System CAOS).
;                    -use of common block caos_block eliminated (useless).
;                    -INIT file management eliminated.
;                    -influence functions generation moved to module MDS
;                     => module DMI now generalized to all kind of mirror
;                     deformations.
;                   : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
FUNCTION dmi_init, inp_wfp_t, $
                   inp_com_t, $
                   out_wfp_c, $
                   out_wfp_t, $
                   par,       $
                   INIT=init

; initialization of the error code
error = !caos_error.ok 

; retrieve the output information
info = dmi_info()

; get the individual output structure types
if info.out_type ne '' then out_type = str_sep(info.out_type,",")

; STANDARD CHECKS
;
; compute and test the requested number of dmi arguments
n_par = 1  ; the parameter structure is always present within the arguments
if info.inp_type ne '' then begin
   inp_type = str_sep(info.inp_type,",")
   n_inp    = n_elements(inp_type)
endif else n_inp = 0
if info.out_type ne '' then begin
   out_type = str_sep(info.out_type,",")
   n_out    = n_elements(out_type)
endif else n_out = 0
n_par = n_par + n_inp + n_out
if n_params() ne n_par then message, 'wrong number of arguments'

; test the parameter structure
if test_type(par, /STRUCTURE, N_ELEMENTS=n) then $
   message, 'DMI error: par must be a structure'
if n ne 1 then message, 'DMI error: par cannot be a vector of structures'
if strlowcase(tag_names(par, /STRUCTURE_NAME)) ne info.mod_name then $
   message, 'par must be a parameter structure for the module DMI'

; check the input arguments
; test if any optional input exists
if n_inp gt 0 then begin
   inp_opt = info.inp_opt
endif

dummy = test_type(inp_wfp_t, TYPE=type)
if type eq 0 then begin         ; undefined variable
   inp_wfp_t = $
      {        $
      data_type  : inp_type[0],         $
      data_status: !caos_data.not_valid $
      }
endif
if test_type(inp_wfp_t, /STRUC, N_EL=n, TYPE=type) then $
   message, 'DMI error: wrong definition for the first input.'
if n ne 1 then message, $
   'DMI error: first input cannot be a vector of structures'

; test the data type
if inp_type[0] ne 'gen_t' then begin
   if inp_wfp_t.data_type ne inp_type[0] then                $
      message, 'wrong input data type: '+inp_wfp_t.data_type $
              +' ('+inp_type[0]+' expected).'
endif

if inp_wfp_t.data_status eq !caos_data.not_valid and not inp_opt[0] then $
      message, 'undefined input is not allowed'

dummy = test_type(inp_com_t, TYPE=type)
if type eq 0 then begin                ; undefined variable
   inp_com_t = $
      {        $
      data_type  : inp_type[1],         $
      data_status: !caos_data.not_valid $
      }
endif

if test_type(inp_com_t, /STRUC, N_EL=n, TYPE=type) then $
   message, 'DMI error: wrong definition for the second input.'

if n ne 1 then message, $
   'DMI error: second input cannot be a vector of structures'

; test the data type
if inp_com_t.data_type ne inp_type[1] then                $
   message, 'wrong input data type: '+inp_com_t.data_type $
           +' ('+inp_type[1]+' expected).'
if inp_com_t.data_status eq !caos_data.not_valid and not inp_opt[1] then $
   message, 'undefined input is not allowed'

;
; END OF STANDARD CHECKS

; STRUCTURE "INIT" DEFINITION
;
if par.mirdef_file ne " " then restore, FILENAME=par.mirdef_file, /VERBOSE $
else DEF=0.
; the mirror deformations "DEF"

np = (size(DEF))[1]
nm = (size(DEF))[3]
nx = (size(inp_wfp_t.screen))[1]
ny = (size(inp_wfp_t.screen))[2]
if nx ne ny then message,   $
   "DMI error:"+string(10B) $
   +"dimensions of mirror deformations are different along x and y."
if nx eq np then mirdef = DEF else   $
   message, "DMI error:"+string(10B) $
           +"dimensions of mirror deformations does not match"+string(10B) $
           +"with dimensions of input wavefront."

init = $
   {   $
   mirdef: mirdef, $ ; mirror deformations
   nm    : nm      $
   }

; INITIALIZE THE OUTPUT STRUCTURE
;
; initialize corrected wavefront output
out_wfp_t = inp_wfp_t

; initialize correcting mirror shape output
out_wfp_c = inp_wfp_t
out_wfp_c.n_phot     = 0.
out_wfp_c.background = 0.
out_wfp_c.map        = 0
out_wfp_c.map_scale  = 0.
out_wfp_c.off_axis   = 0.
out_wfp_c.angle      = 0.
out_wfp_c.coord      = 0
out_wfp_c.scale_z    = 0
out_wfp_c.correction = 1B   ; this is the correcting wavefront !!

; back to calling program
return, error
end