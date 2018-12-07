; $Id: ttm_gui.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    ttm_gui
;
; PURPOSE:
;    ttm_gui generates the Graphical User Interface (GUI) for setting the
;    parameters of the Tip-Tilt Mirror (TTM) module.  A parameter file
;    called ttm_yyyyy.sav is created, where yyyyy is the number n_module
;    associated to the the module instance.  The file is stored in the
;    project directory proj_name located in the working directory. In this
;    version the par structure associated to TTM (and stored within
;    ttm_yyyyy.sav) only contains tags associated to the management of
;    program, but no parameter relevant to scientific program.
;
; CATEGORY:
;    Graghical User Interface (GUI) program 
;
; CALLING SEQUENCE:
;    error = ttm_gui(n_module, proj_name)
;
; INPUTS:
;    n_module  : integer scalar. Number associated to the intance
;                of the TTM module. n_module > 0.
;    proj_name : string. Name of the current project.
;
; OUTPUTS:
;    error     : long scalar.Error code (see caos_init procedure)
;
; COMMON BLOCKS:
;    common error_block, error
;
;    error    :  long scalar. Error code (see caos_init procedure).
;
; CALLED NON-IDL FUNCTIONS:
;    None.
;
; MODIFICATION HISTORY:
;    program written: Oct 1998, 
;                     B. Femenia (OAA) [bfemenia@arcetri.astro.it]
;
;    modifications  : Feb 1999, 
;                     B. Femenia (OAA) [bfemenia@arcetri.astro.it]
;                    -written to match general style and requirements on
;                     how to manage initialization process, calibration
;                     procedure and time management according to  released
;                     templates on Feb 1999.
;                   : Nov 1999,
;                     B. Femenia   (OAA) [bfemenia@arcetri.astro.it]
;                    -adapted to new version CAOS (v 2.0).
;                   : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]
;                    -adapted to version 4.0 of the whole Software System CAOS
;                     (variable "pack_name" added, and variable "mod_type"
;                     changed into "mod_name").
;                   : december 2004,
;                     Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr]:
;                    -no more crash provoked when controlling the Soft.Pack.
;                     version for existing parameter files - just a warning.
;                   : february 2007,
;                     Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr]:
;                    -control of the the Soft.Pack. debugged (the warning was
;                     here *always* (partly) printed )...
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;-
;
FUNCTION ttm_gui, n_module, proj_name, GROUP_LEADER=group

COMMON error_block, error

error = !caos_error.ok                       ; initialization of the error code.


; retrieve the module information
info = ttm_info()

; check if a saved parameter file already exists for this module.
; if it exists it is restored, otherwise the default parameter file is restored.
sav_file = MK_PAR_NAME(info.mod_name, n_module, PROJ_NAME=proj_name)
def_file = MK_PAR_NAME(info.mod_name, PACK_NAME=info.pack_name, /DEFAULT)

par = 0
check_file = FINDFILE(sav_file)
IF check_file[0] EQ '' THEN BEGIN
   RESTORE, def_file
   par.module.n_module = n_module
   IF (par.module.mod_name NE info.mod_name) THEN          $
     MESSAGE, 'the default parameter file ('+ def_file     $
     +') is from another module: please take the right one'
   IF (par.module.ver ne info.ver) THEN                    $
     MESSAGE, 'the default parameter file ('+ def_file     $
     +') is not compatible: please generate it again'   
ENDIF ELSE BEGIN
   RESTORE, sav_file
   IF (par.module.mod_name NE info.mod_name) THEN          $
     MESSAGE, 'the parameter file '+sav_file               $
     +' is from another module: please generate a new one'
   IF (par.module.ver NE info.ver) THEN begin
      print, '************************************************************'
      print, 'WARNING: the parameter file '+sav_file
      print, 'is probably from an older version than '+info.pack_name+' !!'
      print, 'You should possibly need to generate it again...'
      print, '************************************************************'
   endif
ENDELSE

SAVE, par, FILE=sav_file

RETURN, error

END