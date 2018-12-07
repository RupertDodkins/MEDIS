; $Id: wfa_gui.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    wfa_gui
;
; PURPOSE:
;    wfa_gui generates the Graphical User Interface (GUI) for setting the
;    parameters of the WaveFront Adding(WFA) module.  A parameter file
;    called wfa_yyyyy.sav is created, where yyyyy is the number n_module
;    associated to the the module instance.  The file is stored in the
;    project directory proj_name located in the working directory.
;    (see wfa.pro's header --or file caos_help.html-- for details
;    about the module itself).
;
; CATEGORY:
;    Module's Graphical User Interface (GUI) routine 
;
; CALLING SEQUENCE:
;    error = wfa_gui(n_module, proj_name)
;
; INPUTS:
;    n_module  : integer scalar. Number associated to the intance
;                of the WFA module. n_module > 0.
;    proj_name : string. Name of the current project.
;
; OUTPUTS:
;    error     : long scalar.Error code (see caos_init procedure)
;
; COMMON BLOCKS:
;    common error_block, error
;    error    :  long scalar. Error code (see caos_init procedure).
;
;    common weights, tab1, tab2
;    tab1 & tab2: array of predefined weights.
;
; CALLED NON-IDL FUNCTIONS:
;    None.
;
; MODIFICATION HISTORY:
;    program written: April 1999, 
;                     B. Femenia (OAA) [bfemenia@arcetri.astro.it]
;
;    modifications  : Dec 1999,
;                     Bruno Femenia (OAA)  [bfemenia@arcetri.astro.it]
;                    -adapted to version 2.0 (CAOS code)
;                   : may 2000,
;                     Marcel carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -call to help file debugged.
;                   : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]
;                    -adapted to version 4.0 of the whole Software System CAOS
;                     (variable "pack_name" added, and variable "mod_type"
;                     changed into "mod_name").
;                    -(wfa_info()).help stuff added (instead of !caos_env.help).
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
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr],
;                     Andrea La Camera (DIBRIS) [andrea.lacamera@unige.it]:
;                    -New way to call CAOS_HELP (by using the "online_help" 
;                     routine, independent from the operating system used.
;-
;
PRO wfa_set, state

   COMMON weights, tab1, tab2

   WIDGET_CONTROL, state.id.wb_button, GET_VALUE= dummy
   IF (dummy EQ N_ELEMENTS(tab2)) THEN BEGIN
       WIDGET_CONTROL,state.id.wb, SENSITIVE=1
   ENDIF ELSE BEGIN
       WIDGET_CONTROL,state.id.wb, SENSITIVE=0 
   ENDELSE

   WIDGET_CONTROL, state.id.wt_button, GET_VALUE= dummy
   IF (dummy EQ N_ELEMENTS(tab2)) THEN BEGIN
       WIDGET_CONTROL,state.id.wt, SENSITIVE=1
   ENDIF ELSE BEGIN
       WIDGET_CONTROL,state.id.wt, SENSITIVE=0 
   ENDELSE

END 


PRO wfa_gui_event, event

   COMMON error_block, error
   COMMON weights, tab1, tab2
   
   IF TAG_NAMES(event, /STRUCTURE_NAME) EQ 'WIDGET_KILL_REQUEST' THEN BEGIN
      WIDGET_CONTROL, event.top, GET_UVALUE=state
      error = !caos_error.cancel
      WIDGET_CONTROL, event.top, /DESTROY
   ENDIF
   
   
   WIDGET_CONTROL, event.id, GET_UVALUE = uvalue
   
   CASE uvalue OF
      
      'wb_button':BEGIN
         WIDGET_CONTROL, event.top, GET_UVALUE=state
         IF (event.value LE N_ELEMENTS(tab2)-1) THEN state.par.wb = tab2[event.value]
         wfa_set, state
         WIDGET_CONTROL, event.top, SET_UVALUE=state
      END
      
      'wb':BEGIN
         WIDGET_CONTROL, event.top, GET_UVALUE=state
         WIDGET_CONTROL, event.id,  GET_VALUE=dummy
         state.par.wb = dummy
         WIDGET_CONTROL, event.top, SET_UVALUE=state
      END
      
      'wt_button':BEGIN
         WIDGET_CONTROL, event.top, GET_UVALUE=state
         IF (event.value LE N_ELEMENTS(tab2)-1) THEN state.par.wt = tab2[event.value]
         wfa_set, state
         WIDGET_CONTROL, event.top, SET_UVALUE=state
      END
      
      'wt':BEGIN
         WIDGET_CONTROL, event.top, GET_UVALUE=state
         WIDGET_CONTROL, event.id,  GET_VALUE=dummy
         state.par.wt = dummy
         wfa_set,state
         WIDGET_CONTROL, event.top, SET_UVALUE=state
      END           

      'help' : online_help, book=(wfa_info()).help, /FULL_PATH
      
      'restore': BEGIN 
         WIDGET_CONTROL, event.top, GET_UVALUE=state
         ;; restore the desired parameter file
         par = 0
         title = "parameter file to restore"
         RESTORE, filename_gui(state.def_file, /ALL ,  $
                               title, /NOEDIT, /MUST,  $
                               GROUP_LEADER=event.top, $
                               FILTER='wfa*sav')
         ;; update the current module number
         par.module.n_module = state.par.module.n_module
         ;; update the widget fields with new parameter values
         state.par = par

         dummy = (WHERE(tab2 EQ state.par.wb))[0]
         IF (dummy EQ -1) THEN dummy= N_ELEMENTS(tab2)
         WIDGET_CONTROL,state.id.wb_button, SET_VALUE= dummy
         WIDGET_CONTROL,state.id.wb       , SET_VALUE= state.par.wb
         
         dummy = (WHERE(tab2 EQ state.par.wt))[0]
         IF (dummy EQ -1) THEN dummy= N_ELEMENTS(tab2)
         WIDGET_CONTROL,state.id.wt_button, SET_VALUE= dummy
         WIDGET_CONTROL,state.id.wt       , SET_VALUE= state.par.wt
         
         wfa_set,state
         
         WIDGET_CONTROL,event.top  , SET_UVALUE=state
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
                                 TITLE='WFA warning', /QUEST)
            IF STRLOWCASE(dummy) EQ "no" THEN RETURN
         ENDIF  ELSE BEGIN 
            answ = dialog_message(['File '+state.sav_file+' will be '+ $
                                   'saved.'],DIALOG_PARENT=event.top,  $
                                  TITLE='WFA information',/INFO)
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
 


FUNCTION wfa_gui, n_module, proj_name, GROUP_LEADER=group

COMMON error_block, error
COMMON weights, tab1, tab2

tab1 = ['-1.0','-0.5','+0.5','+1.0','Other']
tab2 = [-1.,-0.5,0.5,1.]

; retrieve the module information
info = wfa_info()

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


id =                     $
  {                      $
    wb         : 0L,     $
    wb_button  : 0L,     $
    wt         : 0L,     $
    wt_button  : 0L      $
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

base1= WIDGET_BASE( base,FRAME=10,/COL)

dummy  = WIDGET_LABEL(base1,VALUE="Weight assigned to bottom wavefront",/FRAME)
base1_1= WIDGET_BASE(base1,/ROW)

dummy = (WHERE(tab2 EQ state.par.wb))[0]
IF (dummy EQ -1) THEN dummy= N_ELEMENTS(tab2)
state.id.wb_button =                                          $
  CW_BGROUP(base1_1,tab1,UVALUE='wb_button',/EXCLUSIVE, /ROW, $
            SET_VALUE=dummy)
state.id.wb =                                                 $
  CW_FIELD(base1_1,/COL,VALUE=state.par.wb,UVALUE='wb',       $
           /FLOATING,/ALL_EVENTS,TITLE='Weight for bottom WF')
  

dummy  = WIDGET_LABEL(base1,VALUE="Weight assigned to top wavefront",/FRAME)
base1_2= WIDGET_BASE(base1,/ROW)

dummy = (WHERE(tab2 EQ state.par.wt))[0]
IF (dummy EQ -1) THEN dummy= N_ELEMENTS(tab2)
state.id.wt_button =                                          $
  CW_BGROUP(base1_2,tab1,UVALUE='wt_button',/EXCLUSIVE, /ROW, $
            SET_VALUE=dummy)
state.id.wt =                                                 $
  CW_FIELD(base1_2,/COL,VALUE=state.par.wb,UVALUE='wt',       $
           /FLOATING,/ALL_EVENTS, TITLE='Weight for top WF')

dummy = WIDGET_LABEL(base1, VALUE='NOTE: When using WFA to duplicate a correction the weights assigned')
dummy = WIDGET_LABEL(base1, VALUE='      bottom and top wavefronts **MUST** be set to +1.             ')

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

wfa_set,state

WIDGET_CONTROL, base, SET_UVALUE=state
WIDGET_CONTROL, base, /REALIZE

XMANAGER, 'wfa_gui', base, GROUP_LEADER=group

RETURN, error
END