; $Id: iws_gui.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    iws_gui
;
; PURPOSE:
;    iws_gui generates the Graphical User Interface (GUI) for setting the
;    parameters of the Ideal Wavefront Sensing (and reconstruction) (IWS)
;    module.  A parameter file called iws_yyyyy.sav is created, where
;    yyyyy is the number n_module associated to the the module instance.
;    The file is stored in the project directory proj_name located in the
;    working directory.
;    (see iws.pro's header --or file caos_help.html-- for details
;    about the module itself).
;
; CATEGORY:
;    Module's Graphical User Interface (GUI) routine 
;
; CALLING SEQUENCE:
;    error = iws_gui(n_module, proj_name)
;
; INPUTS:
;    n_module  : integer scalar. Number associated to the intance
;                of the IWS module. n_module > 0.
;    proj_name : string. Name of the current project.
;
; OUTPUTS:
;    error     : long scalar.Error code (see caos_init procedure)
;
; COMMON BLOCKS:
;    common error_block, error
;    error    :  long scalar. Error code (see caos_init procedure).
;
; CALLED NON-IDL FUNCTIONS:
;    None.
;
; MODIFICATION HISTORY:
;    program written: april 2015,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr].
;
;    modifications  : april 2016,
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
PRO iws_gui_event, event

   COMMON error_block, error
   
   IF TAG_NAMES(event, /STRUCTURE_NAME) EQ 'WIDGET_KILL_REQUEST' THEN BEGIN
      WIDGET_CONTROL, event.top, GET_UVALUE=state
      error = !caos_error.cancel
      WIDGET_CONTROL, event.top, /DESTROY
   ENDIF
   
   
   WIDGET_CONTROL, event.id, GET_UVALUE = uvalue
   
   CASE uvalue OF
      
      'radial_order':BEGIN
         WIDGET_CONTROL, event.top, GET_UVALUE=state
         WIDGET_CONTROL, event.id,  GET_VALUE=dummy
         state.par.radial_order = dummy
         WIDGET_CONTROL, event.top, SET_UVALUE=state
      END
      
      'part_corr':BEGIN
         WIDGET_CONTROL, event.top, GET_UVALUE=state
         WIDGET_CONTROL, event.id,  GET_VALUE=dummy
         state.par.part_corr = dummy
         WIDGET_CONTROL, event.top, SET_UVALUE=state
      END           
      
      'help' : online_help, book=(iws_info()).help, /FULL_PATH
      
      'restore': BEGIN 
         ;; restore the desired parameter file
         par = 0
         title = "parameter file to restore"
         RESTORE, filename_gui(state.def_file, /ALL ,  $
                               title, /NOEDIT, /MUST,  $
                               GROUP_LEADER=event.top, $
                               FILTER='iws*sav')
         ;; update the current module number
         par.module.n_module = state.par.module.n_module

         widget_control, state.id.radial_order, SET_VALUE=par.radial_order
         widget_control, state.id.part_corr, SET_VALUE=par.part_corr

         state.par = par
         widget_control, event.top, SET_UVALUE=state

      END 
      
      'save': BEGIN
         WIDGET_CONTROL, event.top, GET_UVALUE=state
         
         ;; check before saving the parameter file if filename already exists
         ;; or inform where the parameters will be saved.
         check_file = FINDFILE(state.sav_file)
         IF check_file[0] NE "" THEN BEGIN
            dummy=DIALOG_MESSAGE(['file '+state.sav_file+             $
                                  ' already exists.',                 $
                                  'would you like to overwrite it?'], $
                                 DIALOG_PARENT=event.top,             $
                                 TITLE='IWS warning', /QUEST)
            IF STRLOWCASE(dummy) EQ "no" THEN RETURN
         ENDIF  ELSE BEGIN 
            answ = dialog_message(['File '+state.sav_file+' will be '+ $
                                   'saved.'],DIALOG_PARENT=event.top,  $
                                  TITLE='IWS information',/INFO)
         ENDELSE 

         ; save the parameter data file
         par = state.par
         SAVE, par, FILENAME=state.sav_file
         ; kill the GUI returning a null error
         error = !caos_error.ok
         WIDGET_CONTROL, event.top, /DESTROY
      END 
      
      'cancel'  : BEGIN
         error = !caos_error.cancel
         WIDGET_CONTROL, event.top, /DESTROY
         RETURN
      END
      
   ENDCASE
   
   RETURN
   
END
 
 
;;;;;;;;;;;;;;;;;;;;;;;
; GUI generation code ;
;;;;;;;;;;;;;;;;;;;;;;;
;
FUNCTION iws_gui, n_module, proj_name, GROUP_LEADER=group

COMMON error_block, error

; retrieve the module information
info = iws_info()

; check if a saved parameter file already exists for this module.
; if it exists it is restored, otherwise the default parameter file is restored.
sav_file = MK_PAR_NAME(info.mod_name, n_module, PROJ_NAME=proj_name)
def_file = MK_PAR_NAME(info.mod_name, PACK_NAME=info.pack_name, /DEFAULT)

par = 0
check_file = FINDFILE(sav_file)
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


id =                  $
  {                   $
    radial_order: 0L, $
    part_corr   : 0L  $
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

base1= WIDGET_BASE(base,FRAME=10,/COL)

state.id.radial_order =                                                      $
  CW_FIELD(base1, /COL, VALUE=state.par.radial_order, UVALUE='radial_order', $
           /FLOATING, /ALL_EVENTS, TITLE='maximum Zernike radial degree'     )

state.id.part_corr =                                                             $
  CW_FSLIDER(base1, MAXIMUM=1, VALUE=state.par.part_corr, UVALUE='part_corr',    $
             SCROLL=.05, /EDIT, /DRAG, TITLE="partial correction on cons'd modes")

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

XMANAGER, 'iws_gui', base, GROUP_LEADER=group

RETURN, error

END