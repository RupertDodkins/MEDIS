;**
;*******************************************************************************
;** HOW TO USE THIS TEMPLATE:                                                  *
;**                                                                            *
;** 0-READ THE WHOLE TEMPLATE ONCE !!                                          *
;** 1-CHANGE EVERYWHERE THE STRINGS "XXX" IN THE CHOSEN 3-CHAR MODULE NAME     *
;**   (CHANGE AS WELL THE POSSIBLE "YYY", "ZZZ", "AAA", AND "BBB" STRINGS INTO *
;**    THE, RESPECTIVELY, FIRST INPUT STRUCTURE TYPE NAME, SECOND INPUT        *
;**    STRUCTURE TYPE NAME, FIRST OUTPUT STRUCTURE TYPE NAME, AND SECOND       *
;**    OUTPUT STRUCTURE TYPE NAME)                                             *
;** 2-ADAPT THE TEMPLATE ONTO THE NEW MODULE CASE FOLLOWING THE EXAMPLES,      *
;**   RECOMMENDATIONS, AND ADVICES FOUND THROUGH THE TEMPLATE                  *
;** 3-DELETE ALL THE LINES OF CODE BEGINNING WITH ";**"                        *
;**                                                                            *
;*******************************************************************************
;**
;**
;** here is the routine identification
;**
; $Id: xxx_init.pro,v 5.1 2005/07/04 marcel.carbillet
;**
;** put right version, date, and main author name of last update in the line
;** here above following the formats:
;** -n.m for the version (n=software release version, m=module update version).
;** -YYYY/MM/DD for the date (YYYY=year, MM=month, DD=day).
;** -first_name.last_name for the (last update) main author name.
;**
;+ 
; NAME: 
;    xxx_init 
; 
; PURPOSE: 
;    xxx_init executes the initialization for the [PUT HERE THE NAME] 
;    (XXX) module, that is:
;
;       0- check the formal validity of the input/output structure
;       1- initialize the output structure(s) out_yyy_t and out_zzz_t
;**
;** DESCRIBE HERE WHAT KIND OF OTHER INITIALISATION OPERATIONS XXX_INIT PERFORMS
;**
;
;    (see xxx.pro's header --or file xyz_help.html-- for details
;    about the module itself).
; 
; CATEGORY: 
;    module's initialisation routine 
; 
; CALLING SEQUENCE: 
;    error = xxx_init(inp_yyy_t,  $ ; yyy_t input structure
;                     inp_zzz_t,  $ ; zzz_t input structure
;                     out_aaa_t,  $ ; aaa_t output structure
;                     out_bbb_t,  $ ; bbb_t output structure 
;                     par,        $ ; parameters structure
;                     INIT=init   $ ; initialisation data structure
;                     ) 
; 
; INPUTS/OUTPUTS/KEYWORDS/ETC.: 
;    see xxx.pro's help for a detailed description. 
;
; ROUTINE MODIFICATION HISTORY: 
;    routine written: date,
;                     author (institute) [e-mail].
;    modifications  : date,
;                     author (institute) [e-mail]:
;                    -descrition of mofications made.
;                   : date,
;                     author (institute) [email]:
;                    -description of modifications made.
;** 
;** ROUTINE'S TEMPLATE MODIFICATION HISTORY: 
;**    routine written: november 1998,
;**                     Armando Riccardi (OAA) [riccardi@arcetri.astro.it].
;**    modifications  : february 1999,
;**                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;**                    -output structures initialisation.
;**                   : february 1999,
;**                     Francoise Delplancke (ESO) [fdelplan@eso.org]:
;**                    -annex structure added.
;**                   : february 1999,
;**                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;**                    -a few minor errors fixed.
;**                   : march 1999,
;**                     Bruno Femenia (OAA) [bfemenia@arcetri.astro.it]:
;**                    -control on tag 'INIT_FILE' done with count.
;**                   : september 1999,
;**                     Francoise Delplancke (ESO) [fdelplan@eso.org]:
;**                    -add of "WARNING: you restored the struc...".
;**                   : november 1999,
;**                     Marcel Carbillet (OAA) [marcel@arcetro.astro.it]:
;**                    -enhanced and adapted to version 2.0 (CAOS).
;**                   : june 2001,
;**                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;**                    -enhanced for version 3.0 of CAOS (package-oriented).
;**                   : january 2003,
;**                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;**                    -simplified templates for the version 4.0 of the
;**                     whole CAOS system (no more use of the COMMON variable
;**                     "calibration" and no more use of the possible
;**                     initialisation file and, obviously, of the calibration
;**                     file as well).
;**                    -"mod_type"->"mod_name"
;**
;- 
; 
;**
;** here begins the module's initialisation routine code
;**
function xxx_init, inp_yyy_t,  $ ; 1st input struc.  ;** DELETE if no input
                   inp_zzz_t,  $ ; 2nd input struc.  ;** DELETE if no 2nd input
                   out_aaa_t,  $ ; 1st output struc. ;** DELETE if no output
                   out_bbb_t,  $ ; 2nd output struc. ;** DELETE if no 2nd output
                   par,        $ ; XXX parameters structure
                   INIT=init     ; XXX initialization data structure

;**
;** DELETE the following common call if neither save/load calibration
;** data file management nor the number of iterations are required here
;**
; CAOS global common block
common caos_block, tot_iter, this_iter

; error code initialization
error = !caos_error.ok

; retrieve the module's informations
info = xxx_info()

; get the individual output structure types
if info.out_type ne '' then out_type = str_sep(info.out_type,",")

; STANDARD CHECKS
;
;**
;** here begins some standard checks among the parameters structure
;** and the input(s) and output(s) structures.
;** just change the strings "xxx" or "XXX" into the module's ones
;** (as well as the strings "yyy" and "zzz" into the first and second input
;** ones), and DELETE the parts where non-existing inputs are controled.
;**
; compute and test the requested number of xxx arguments
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
   message, 'XXX error: par must be a structure'
if n ne 1 then message, 'XXX error: par cannot be a vector of structures'
if strlowcase(tag_names(par, /STRUCTURE_NAME)) ne info.mod_name then $
   message, 'par must be a parameter structure for the module XXX'

; check the input arguments
;**
;** DELETE down to "END INPUT CHECKS" if the module does not have any input
;**

; test if any optional input exists
if n_inp gt 0 then begin
   inp_opt = info.inp_opt
   ;**
   ;** some parameters configuration can force the input to be defined
   ;** even if inp_opt eq 1B for it (in the info structure 1B means that
   ;** at least one configuration allowing undefined input exists).
   ;** check here the parameter setting and override the value of inp_opt
   ;** to 0B if the considered case occurred.
   ;**
   ;** BUT: changing 0B into 1B is NOT permitted !!
   ;**
endif

dummy = test_type(inp_yyy_t, TYPE=type)
if type eq 0 then begin         ; undefined variable
   ;**
   ;** patch until the worksheet will initialize the linked-to-nothing input
   ;** to a structure as the following:
   ;**
   inp_yyy_t = $
      {        $
      data_type  : inp_type[0],         $
      data_status: !caos_data.not_valid $
      }
endif
if test_type(inp_yyy_t, /STRUC, N_EL=n, TYPE=type) then $
   message, 'XXX error: wrong definition for the first input.'
if n ne 1 then message, $
   'XXX error: first input cannot be a vector of structures'

; test the data type
if inp_type[0] ne 'gen_t' then begin
   if inp_yyy_t.data_type ne inp_type[0] then                $
      message, 'wrong input data type: '+inp_yyy_t.data_type $
              +' ('+inp_type[0]+' expected).'
endif

if inp_yyy_t.data_status eq !caos_data.not_valid and not inp_opt[0] then $
      message, 'undefined input is not allowed'

;**
;** DELETE down to "END INPUT CHECKS" if the module does not have a 2nd input
;**

dummy = test_type(inp_zzz_t, TYPE=type)
if type eq 0 then begin                ; undefined variable
   ;**
   ;** patch until the worksheet will initialize the linked-to-nothing input
   ;** to a structure as the following:
   ;**
   inp_zzz_t = $
      {        $
      data_type  : inp_type[1],         $
      data_status: !caos_data.not_valid $
      }
endif

if test_type(inp_zzz_t, /STRUC, N_EL=n, TYPE=type) then $
   message, 'XXX error: wrong definition for the second input.'

if n ne 1 then message, $
   'XXX error: second input cannot be a vector of structures'

; test the data type
if inp_zzz_t.data_type ne inp_type[1] then                $
   message, 'wrong input data type: '+inp_zzz_t.data_type $
           +' ('+inp_type[1]+' expected).'
if inp_zzz_t.data_status eq !caos_data.not_valid and not inp_opt[1] then $
   message, 'undefined input is not allowed'

;**
;** END INPUT CHECKS
;**

;
; END OF STANDARD CHECKS

; STRUCTURE "INIT" DEFINITION
;
;**
;** here is the part of the code where the INIT structure is defined
;**

; structure INIT definition
;**
;** put here the code in order to define the structure INIT 
;**
init = $
   {   $
   some_parameter: par.some_number,                                     $
   some_vector   : intarr(init.some_number),                            $
   some_array    : fltarr(inp_yyy_t.some_number, inp_zzz_t.some_number) $
   }


; INITIALIZE THE OUTPUT STRUCTURE(S)
;
;**
;** here are defined and initialized the output structures that will be
;** updated within xxx_prog.pro (each data elements has to be initialized
;** here):
;**

; initialize (1st) output
out_aaa_t = $
   {        $
   data_type  : out_type[0],                   $
   data_status: !caos_data.valid,              $
   ;**
   ;** all the other data elements initialized, for instance:
   ;**
   bla  : par.bla,                             $
   vec  : intarr(init.param),                  $
   array: fltarr(inp_yyy_t.dim, inp_zzz_t.dim) $
   }

; initialize 2nd output
out_bbb_t = $
   {        $
   data_type  : out_type[1],                   $
   data_status: !caos_data.valid,              $
   ;**
   ;** all the other data elements initialized, for instance:
   ;**
   bla  : par.bla,                             $
   vec  : intarr(init.param),                  $
   array: fltarr(inp_yyy_t.dim, inp_zzz_t.dim) $
   }

; back to calling program
return, error 
end
