; $Id: bsp_gui.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    bsp_gui
;
; PURPOSE:
;    bsp_gui generates the Graphical User Interface (GUI) for setting the
;    parameters of the Beam SPlitter (BSP) module.  A parameter file
;    called bsp_yyyyy.sav is created, where yyyyy is the number n_module
;    associated to the the module instance.  The file is stored in the
;    project directory proj_name located in the working directory.
;    (see bsp.pro's header --or file caos_help.html-- for details
;    about the module itself).
;
; CATEGORY:
;    Module's Graphical User Interface (GUI) routine 
;
; CALLING SEQUENCE:
;    error = bsp_gui(n_module, proj_name)
;
; INPUTS:
;    n_module  : integer scalar. Number associated to the intance
;                of the BSP module. n_module > 0.
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
;    program written: March 1999, 
;                     B. Femenia (OAA) [bfemenia@arcetri.astro.it]
;    modifications  : Nov 1999,
;                     Bruno Femenia (OAA)  [bfemenia@arcetri.astro.it]
;                    -adapted to version 2.0 (CAOS code)
;                   : may 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -call to help file debugged.
;                   : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]
;                    -adapted to version 4.0 of the whole Software System CAOS
;                     (variable "pack_name" added, and variable "mod_type"
;                     changed into "mod_name").
;                    -(xxx_info()).help stuff added (instead of !caos_env.help).
;                   : december 2004,
;                     Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr]:
;                    -no more crash provoked when controlling the Soft.Pack.
;                     version for existing parameter files - just a warning.
;                   : february 2007,
;                     Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr]:
;                    -control of the the Soft.Pack. debugged (the warning was
;                     here *always* (partly) printed )...
;                   : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr],
;                     Andrea La Camera (DIBRIS) [andrea.lacamera@unige.it]:
;                    -New way to call CAOS_HELP (by using the "online_help" 
;                     routine, independent from the operating system used.
;
;-
;
PRO bsp_gui_event, event
   
   COMMON error_block, error
   
   IF TAG_NAMES(event, /STRUCTURE_NAME) EQ 'WIDGET_KILL_REQUEST' THEN BEGIN
      WIDGET_CONTROL, event.top, GET_UVALUE=state
      error = !caos_error.cancel
      WIDGET_CONTROL, event.top, /DESTROY
   ENDIF
   
   WIDGET_CONTROL, event.id, GET_UVALUE = uvalue
   
   
   CASE uvalue OF
      
      'frac':BEGIN
         WIDGET_CONTROL, event.top, GET_UVALUE=state
         state.par.frac= FLOAT(ROUND(event.value*100.))/100.
         WIDGET_CONTROL, state.id.bottom, SET_VALUE=state.par.frac
         WIDGET_CONTROL, state.id.top   , SET_VALUE=1.-state.par.frac
         WIDGET_CONTROL, event.top, SET_UVALUE=state
      END
      
      'up':BEGIN
         WIDGET_CONTROL, event.top, GET_UVALUE=state
         WIDGET_CONTROL, event.id,  GET_VALUE=dummy
         IF (dummy LT 0) THEN dummy=0.
         IF (dummy GT 1) THEN dummy=1.
         state.par.frac= 1.-dummy
         WIDGET_CONTROL,state.id.bottom, SET_VALUE= state.par.frac
         WIDGET_CONTROL,state.id.frac  , SET_VALUE= state.par.frac
         WIDGET_CONTROL,event.top      , SET_UVALUE=state
      END 
      
      'bottom':BEGIN
         WIDGET_CONTROL, event.top, GET_UVALUE=state
         WIDGET_CONTROL, event.id,  GET_VALUE=dummy
         IF (dummy LT 0) THEN dummy=0.
         IF (dummy GT 1) THEN dummy=1.
         state.par.frac= dummy
         WIDGET_CONTROL,state.id.top , SET_VALUE= 1.-state.par.frac
         WIDGET_CONTROL,state.id.frac, SET_VALUE= state.par.frac
         WIDGET_CONTROL,event.top    , SET_UVALUE=state
      END
      
      'save': BEGIN
         WIDGET_CONTROL, event.top, GET_UVALUE=state
         
         ; check before saving the parameter file if filename already exists
         ; or inform where the parameters will be saved.
         check_file = FINDFILE(state.sav_file)
         IF check_file[0] NE "" THEN BEGIN
            dummy=DIALOG_MESSAGE(['file '+state.sav_file+             $
                                  ' already exists.',                 $
                                  'would you like to overwrite it?'], $
                                 DIALOG_PARENT=event.top,             $
                                 TITLE='BSP warning', /QUEST)
            IF STRLOWCASE(dummy) EQ "no" THEN RETURN
         ENDIF  ELSE BEGIN 
            answ = dialog_message(['file '+state.sav_file+' will be '+ $
                                   'saved.'],DIALOG_PARENT=event.top,   $
                                  TITLE='BSP information',/INFO)
         ENDELSE 

         ;; save the parameter data file
         par = state.par
         SAVE, par, FILENAME=state.sav_file
         ;; kill the GUI returning a null error
         error = !caos_error.ok
         WIDGET_CONTROL, event.top, /DESTROY
      END 
      
      'restore': BEGIN 
         WIDGET_CONTROL, event.top, GET_UVALUE=state
         ;; restore the desired parameter file
         par = 0
         title = "parameter file to restore"
         RESTORE, filename_gui(state.def_file, /ALL ,  $
                               title, /NOEDIT, /MUST,  $
                               GROUP_LEADER=event.top, $
                               FILTER='bsp*sav')
         ;; update the current module number
         par.module.n_module = state.par.module.n_module
         ;; update the widget fields with new parameter values
         state.par = par
         WIDGET_CONTROL,state.id.bottom, SET_VALUE= state.par.frac
         WIDGET_CONTROL,state.id.frac  , SET_VALUE= state.par.frac
         WIDGET_CONTROL,state.id.top   , SET_VALUE= 1.-state.par.frac
         WIDGET_CONTROL,event.top      , SET_UVALUE=state
      END 
      
      'cancel'  : BEGIN
         error = !caos_error.cancel
         WIDGET_CONTROL, event.top, /DESTROY
         RETURN
      END
      
      'help' : online_help, book=(bsp_info()).help, /FULL_PATH
      
   ENDCASE
   
   RETURN
   
END 
 

FUNCTION bsp_gui, n_module, proj_name, GROUP_LEADER=group

COMMON error_block, error

; retrieve the module information
info = bsp_info()

; check if a saved parameter file already exists for this module.
; if it exists it is restored, otherwise the default parameter file is restored.
sav_file = MK_PAR_NAME(info.mod_name, n_module, PROJ_NAME=proj_name)
def_file = MK_PAR_NAME(info.mod_name, PACK_NAME=info.pack_name, /DEFAULT)

par = 0
check_file = FINDFILE(sav_file)
IF (check_file[0] eq '') THEN BEGIN
   restore, def_file
   par.module.n_module = n_module
   IF (par.module.mod_name NE info.mod_name) THEN        $
      MESSAGE, 'the default parameter file ('+def_file $
              +') is from another module: please take the right one'
   IF (par.module.ver NE info.ver) THEN       $
      MESSAGE, 'the default parameter file ('+def_file $
              +') is not compatible: please generate it again'   
ENDIF ELSE BEGIN
   RESTORE, sav_file
   IF (par.module.mod_name NE info.mod_name) THEN $
      MESSAGE, 'the parameter file '+sav_file     $
              +' is from another module: please generate a new one'
   IF (par.module.ver NE info.ver) THEN begin
      print, '************************************************************'
      print, 'WARNING: the parameter file '+sav_file
      print, 'is probably from an older version than '+info.pack_name+' !!'
      print, 'You should possibly need to generate it again...'
      print, '************************************************************'
   endif
ENDELSE

id =                     $
  {                      $
    frac     : 0L,       $
    bottom   : 0L,       $
    top      : 0L        $
  }

state =                  $
  {                      $
    sav_file : sav_file, $
    def_file : def_file, $
    id       : id      , $
    par      : par       $
   }

modal= N_ELEMENTS(group) NE 0
title= STRUPCASE(par.module.mod_name)+' parameter setting GUI'
base = WIDGET_BASE(TITLE=title,MODAL=modal,/COL,GROUP_LEADER=group)

;Slider to select fraction and texts
;-----------------------------------
IF (par.frac LT 0.) THEN state.par.frac=0.
IF (par.frac GT 1.) THEN state.par.frac=1.

base1= WIDGET_BASE( base,FRAME=10,/ROW)

state.id.bottom =                                           $
  CW_FIELD(base1,TITLE="Fraction sent downwards",/COLUMN,   $
           VALUE=state.par.frac,/FLOAT,UVALUE='bottom',     $
           /ALL_EVENTS)

state.id.frac   =                                           $
  CW_FSLIDER(base1,TITLE='Slide to select fractions',/MAX , $
             SCROLL=.05, UVALUE='frac', /EDIT, /DRAG,       $
             /SUPPRESS_VALUE, VALUE=state.par.frac)

state.id.top=                                               $
  CW_FIELD(base1,TITLE="Fraction sent upwards  ",/COLUMN,   $
           VALUE=1.-state.par.frac,/FLOAT,UVALUE='up',      $
           /ALL_EVENTS)


;Standard buttons
;----------------
base2     = WIDGET_BASE(base,FRAME=10,/ROW)
help_id   = WIDGET_BUTTON(base2, VALUE='HELP'              ,UVALUE='help')
cancel_id = WIDGET_BUTTON(base2, VALUE='CANCEL'            ,UVALUE='cancel')
restore_id= WIDGET_BUTTON(base2, VALUE='RESTORE PARAMETERS',UVALUE='restore')
save_id   = WIDGET_BUTTON(base2, VALUE='SAVE PARAMETERS'   ,UVALUE='save')

IF modal THEN WIDGET_CONTROL, cancel_id, /CANCEL_BUTTON
IF modal THEN WIDGET_CONTROL, save_id, /DEFAULT_BUTTON
 
;Final stuff
;============


WIDGET_CONTROL, base, SET_UVALUE=state
WIDGET_CONTROL, base, /REALIZE
XMANAGER, 'bsp_gui', base, GROUP_LEADER=group

RETURN, error
END