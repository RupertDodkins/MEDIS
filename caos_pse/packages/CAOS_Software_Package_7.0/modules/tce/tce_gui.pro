; $Id: tce_gui.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;       tce_gui
;
; PURPOSE:
;       tce_gui generates the Graphical User Interface (GUI) for setting the
;       parameters of the Tip-tilt CEntroiding (TCE) module.  A parameter file
;       called tce_yyyyy.sav is created, where yyyyy is the number n_module
;       associated to the the module instance.  The file is stored in the
;       project directory proj_name located in the working directory. In this
;       version the par structure associated to TCE (and stored within
;       tce_yyyyy.sav) only contains tags associated to the management of
;       program, but no parameter relevant to scientific program.
;
; CATEGORY:
;       Graghical User Interface (GUI) program
;
; CALLING SEQUENCE:
;       error = tce_gui(n_module, proj_name)
;
; INPUTS:
;       n_module :  integer scalar. Number associated to the intance
;                   of the TCE module. n_module > 0.
;       proj_name:  string. Name of the current project.
;
; OUTPUTS:
;       error    :  long scalar. Error code (see caos_init procedure).
;
; COMMON BLOCKS:
;       common error_block, error
;
;       error    :  long scalar. Error code (see caos_init procedure).
;
; CALLED NON-IDL FUNCTIONS:
;       None.
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
;                   : Jun 1999,
;                     B. Femenia (OAA) [bfemenia@arcetri.astro.it]
;                    -possibility to introduce a THRESHOLD value.
;                   : Nov 1999,
;                     Bruno Femenia (OAA),[bfemenia@arcetri.astro.it]
;                    -adapted to version 2.0 (CAOS code)
;                   : Apr 2001,
;                     B. Femenia (OAA) [bfemenia@arcetri.astro.it]
;                    -possibility to introduce directly constant of calibration
;                     from TCE_GUI.
;                   : january/february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]
;                    -adapted to version 4.0 of the whole Software System CAOS
;                     (variable "pack_name" added, and variable "mod_type"
;                     changed into "mod_name").
;                    -(tce_info()).help stuff added (instead of !caos_env.help).
;                    -common variable calibration changed into parameter variable.
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; status setting procedure ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PRO tce_set, state

;CAOS global common block
COMMON caos_block, tot_iter, this_iter
COMMON tce_messages, text1, text2, text3, text4

IF (state.par.detector EQ 1) THEN BEGIN 

   WIDGET_CONTROL, state.id.newbase, SENSITIVE=0
   WIDGET_CONTROL, state.id.base2,   SENSITIVE=0
   text = text1

ENDIF ELSE BEGIN

   WIDGET_CONTROL, state.id.base2,   /SENSITIVE

   IF (state.par.calibration EQ 0B) THEN text = text2 ELSE text = text3

   CASE state.par.method OF 

      0: BEGIN 
         WIDGET_CONTROL, state.id.calib_file, SENSITIVE=1
         WIDGET_CONTROL, state.id.newbase,    SENSITIVE=1
         WIDGET_CONTROL, state.id.range,      SENSITIVE=1
         WIDGET_CONTROL, state.id.cal_cte,    SENSITIVE=0
      END 

      1: BEGIN 
         WIDGET_CONTROL, state.id.calib_file, SENSITIVE=1
         WIDGET_CONTROL, state.id.newbase,    SENSITIVE=1
         WIDGET_CONTROL, state.id.range,      SENSITIVE=0
         WIDGET_CONTROL, state.id.cal_cte,    SENSITIVE=0
      END 

      2: BEGIN 
         WIDGET_CONTROL, state.id.calib_file, SENSITIVE=0
         WIDGET_CONTROL, state.id.newbase,    SENSITIVE=0
         WIDGET_CONTROL, state.id.range,      SENSITIVE=0
         WIDGET_CONTROL, state.id.cal_cte,    SENSITIVE=1
         text = text4
      END 

   ENDCASE 

ENDELSE 

WIDGET_CONTROL, state.id.message, SET_VALUE= text
WIDGET_CONTROL, state.id.message, YSIZE= N_ELEMENTS(text)

END 


;;;;;;;;;;;;;;;;;;;;;; 
; tce_gui event loop ;
;;;;;;;;;;;;;;;;;;;;;;
;
PRO tce_gui_event, event
   
   COMMON error_block, error
   
   ; handle a kill request (considered as a cancel event).
   IF TAG_NAMES(event, /STRUCTURE_NAME) EQ 'WIDGET_KILL_REQUEST' THEN BEGIN
      WIDGET_CONTROL, event.top, GET_UVALUE=state
      error = !caos_error.cancel
      WIDGET_CONTROL, event.top, /DESTROY
   ENDIF
   
   ; read the GUI state structure
   WIDGET_CONTROL, event.top, GET_UVALUE=state

   ; handle all the other events
   WIDGET_CONTROL, event.id, GET_UVALUE = uvalue

   
   CASE uvalue OF
      
      'detector': state.par.detector = event.value
      
      'threshold': BEGIN
         WIDGET_CONTROL, event.id,  GET_VALUE =dummy
         state.par.threshold = dummy[0]
      END
      
      'method': state.par.method = event.value

      'calibration': state.par.calibration = event.value

      'cal_cte': BEGIN 
         WIDGET_CONTROL, event.id,  GET_VALUE =dummy
         state.par.cal_cte = dummy[0]
      END

      'calib_file': state.par.calib_file =  event.value
      
      'range': BEGIN
         state.par.range = ABS(FLOAT(ROUND(event.value*100.))/100.)
         WIDGET_CONTROL, state.id.negative, SET_VALUE= -state.par.range
         WIDGET_CONTROL, state.id.positive, SET_VALUE=  state.par.range
      END  

      'range_minus':BEGIN
         WIDGET_CONTROL, event.id,  GET_VALUE =dummy
         state.par.range = ABS(dummy)
         WIDGET_CONTROL, state.id.negative, SET_VALUE= -state.par.range
         WIDGET_CONTROL, state.id.positive, SET_VALUE=  state.par.range
         WIDGET_CONTROL, state.id.slider  , SET_VALUE=  state.par.range
      END

      'range_plus':BEGIN
         WIDGET_CONTROL, event.id,  GET_VALUE =dummy
         state.par.range = ABS(dummy)
         WIDGET_CONTROL, state.id.negative, SET_VALUE= -state.par.range
         WIDGET_CONTROL, state.id.positive, SET_VALUE=  state.par.range
         WIDGET_CONTROL, state.id.slider  , SET_VALUE=  state.par.range
      END

      'help' : online_help, book=(tce_info()).help, /FULL_PATH
      
      'restore': BEGIN 
         ; restore the desired parameter file
         par = 0
         title = "parameter file to restore"
         RESTORE, filename_gui(state.def_file, /ALL ,  $
                               title, /NOEDIT, /MUST,  $
                               GROUP_LEADER=event.top, $
                               FILTER='tce*sav')
         ; update the current module number
         par.module.n_module = state.par.module.n_module
         ; update the widget fields with new parameter values
         WIDGET_CONTROL, state.id.detector  , SET_VALUE= par.detector
         WIDGET_CONTROL, state.id.threshold , SET_VALUE= par.threshold
         WIDGET_CONTROL, state.id.method    , SET_VALUE= par.method
         WIDGET_CONTROL, state.id.cal_cte   , SET_VALUE= par.cal_cte
         WIDGET_CONTROL, state.id.calibration,SET_VALUE= par.calibration
         WIDGET_CONTROL, state.id.calib_file, SET_VALUE= par.calib_file
         WIDGET_CONTROL, state.id.negative  , SET_VALUE=-par.range
         WIDGET_CONTROL, state.id.positive  , SET_VALUE= par.range
         WIDGET_CONTROL, state.id.slider    , SET_VALUE= par.range
         state.par = par
       END 
      
      'save': BEGIN
         ;Cheking if TCE needs calibration to act properly
         IF (state.par.calib_file EQ '') AND (state.par.detector EQ 0) AND (state.par.method NE 2) THEN BEGIN
            dummy =                                                            $
              DIALOG_MESSAGE(["you MUST provide a calibration data filename"], $
                             DIALOG_PARENT=event.top,TITLE='TCE error',/ERROR)
            RETURN
         ENDIF 
         ;saving of parameters.
         check_file = FINDFILE(state.sav_file)
         IF check_file[0] NE "" THEN BEGIN
            dummy=                                                           $
              DIALOG_MESSAGE(['file ' + state.sav_file + ' already exists.', $
                              'would you like to overwrite it?'], /QUEST   , $
                                 DIALOG_PARENT=event.top,TITLE='TCE warning')
            IF STRLOWCASE(dummy) EQ "no" THEN RETURN
         ENDIF ELSE BEGIN
            dummy =                                                           $          
              DIALOG_MESSAGE(['file ' + state.sav_file + ' will be written.'],$
                             DIALOG_PARENT=event.top,TITLE='TCE information' ,$
                            /INFO)
         ENDELSE 
         ; save the parameter data file
         par = state.par
         SAVE, par, FILENAME=state.sav_file
         ; kill the GUI returning a null error
         error = !caos_error.ok
         WIDGET_CONTROL, event.top, /DESTROY
         RETURN
      END 
      
      'cancel'  : BEGIN
         error = !caos_error.cancel
         WIDGET_CONTROL, event.top, /DESTROY
         RETURN
      END
      
   ENDCASE

   WIDGET_CONTROL, event.top, SET_UVALUE=state
   tce_set, state
   
   RETURN
   
END 


FUNCTION tce_gui, n_module, proj_name, GROUP_LEADER=group

; CAOS global common block
COMMON caos_block, tot_iter, this_iter
COMMON tce_messages, text1, text2, text3, text4
   
COMMON error_block, error
   
; retrieve the module information
info = tce_info()

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

id =                       $
  {                        $
    detector   : 0L,       $
    threshold  : 0L,       $
    method     : 0L,       $
    cal_cte    : 0L,       $
    message    : 0L,       $
    calibration: 0L,       $
    newbase    : 0L,       $
    calib_file : 0L,       $
    base2      : 0L,       $
    negative   : 0L,       $
    range      : 0L,       $
    slider     : 0L,       $
    positive   : 0L        $
  }

state =                    $
  {                        $
    sav_file : sav_file,   $
    def_file : def_file,   $
    id       : id      ,   $
    par      : par         $
  }

modal= N_ELEMENTS(group) NE 0
title= STRUPCASE(state.par.module.mod_name)+' parameter setting GUI'
base = WIDGET_BASE(TITLE=title,MODAL=modal,/COL,GROUP_LEADER=group,/BASE_ALIGN_CENTER)



base1= WIDGET_BASE(base,/COL,/FRAME,/BASE_ALIGN_CENTER)
;=================
dummy= WIDGET_LABEL(base1, $
                    VALUE="Specify algorithm to estimate tip-tilt")

state.id.detector= $
  CW_BGROUP(base1,['QUAD-CELL algorithm','BARYCENTER algorithm'],/ROW,      $
            SET_VALUE=state.par.detector,UVALUE='detector',/EXCLUSIVE)

;===============================================================================
state.id.newbase=widget_base(base1,/COL,FRAME=10,/BASE_ALIGN_CENTER)
dummy= widget_label(state.id.newbase,VALUE="Specify type of simulation",/FRAME)
state.id.calibration = cw_bgroup(state.id.newbase,YSIZE=60,XSIZE=300,          $
                                 ['normal simulation','tip-tilt calibration'], $
                                 /ROW,                                         $
                                 SET_VALUE=state.par.calibration,              $
                                 UVALUE='calibration',                         $
                                 /EXCLUSIVE                                    )
;===============================================================================

dummy= WIDGET_LABEL(base1,VALUE="Discard pixels with a number of photons < threshold ")

state.id.threshold= $
    CW_FIELD(base1,TITLE='Threshold:',VALUE=state.par.threshold, $
           /INT,UVALUE='threshold',/ALL_EVENTS)



state.id.base2= WIDGET_BASE(base,/COL,FRAME=3,/BASE_ALIGN_CENTER)
;===========================
dummy= WIDGET_LABEL(state.id.base2,VALUE='Q-CELL CALIBRATION SECTION',FRAME=5)

dummy= WIDGET_LABEL(state.id.base2,VALUE="Method to interpolate the calibration curve")

state.id.method =                                                                    $
  CW_BGROUP(state.id.base2,['Linear interpol.','Spline interpol.','Calib cte'],/ROW, $
            SET_VALUE=state.par.method,UVALUE='method',/EXCLUSIVE)

state.id.cal_cte=                                                  $
    CW_FIELD(state.id.base2,TITLE='Calibration Constant',/FLOAT,   $
             VALUE=state.par.cal_cte,UVALUE='cal_cte',/ALL_EVENTS)


state.id.range = WIDGET_BASE(state.id.base2, COL=1,/BASE_ALIGN_CENTER)
;===========================
dummy = WIDGET_LABEL(state.id.range,VALUE='Select tilt range in [arcsec] to calibrate')
dummy = WIDGET_LABEL(state.id.range,VALUE='     when selecting linear fit option     ')


dummy = WIDGET_BASE( state.id.range,/ROW)

state.id.negative =                                                        $
  CW_FIELD(dummy,TITLE="FROM:", /COLUMN, VALUE=-ABS(state.par.range),      $
           /FLOAT, /ALL_EVENTS, UVALUE='range_minus', XSIZE=8)

state.id.slider   =                                                        $
  CW_FSLIDER(dummy,TITLE=' Tilt range ["]',MAXIMUM=5,                      $
             UVALUE='range', /SUPPRESS_VALUE, VALUE=ABS(state.par.range),  $
             /EDIT, SCROLL=.05,/DRAG)  ;state.id.range

state.id.positive  =                                                       $
  CW_FIELD(dummy,TITLE="TO:", /COLUMN, VALUE= ABS(state.par.range),        $
           /FLOAT, /ALL_EVENTS, UVALUE='range_plus', XSIZE=8)

calib_base_id = WIDGET_BASE(state.id.base2, FRAME=10, /COL)
;==========================
dummy = WIDGET_LABEL(calib_base_id,VALUE="Calibration File",/FRAME)

text1 = [' Barycenter DOES NOT need calibration.      ', $
         '                                            ', $
         '                                            ', $
         '                                            ', $
         '                                            ', $
         '                                            ', $
         '                                            ', $
         '                                            ']
text2 = [' This module needs calibration data. Please ', $
         ' provide in the field below the name of the ', $
         " calibration data file.If you still haven't ", $
         ' built and ran a calibration project then   ', $
         ' you **MUST** do it before running TCE.     ', $
         ' Then come back to this project and fill in ', $
         ' the name of the file where you have previ- ', $
         ' ously saved the calibration data.          ']
text3 = ['Provide filename where calibration data will', $
         'be stored as a result of this calibration   ', $
         'project.                                    ', $
         '                                            ', $
         '                                            ', $
         '                                            ', $
         '                                            ', $
         '                                            ']
text4 = ['Q-cell in this mode DOES NOT need calib file', $
         '                                            ', $
         '                                            ', $
         '                                            ', $
         '                                            ', $
         '                                            ', $
         '                                            ', $
         '                                            ']

state.id.message = WIDGET_TEXT(calib_base_id,VALUE= text2,FRAME=0, YSIZE=N_ELEMENTS(text2))
                 ; For some misterious reason, if WIDGET_TEXT does
                 ; not start with largest text, it makes confusion

state.id.calib_file = CW_FILENAME(calib_base_id,TITLE= "Calibration data"+         $
                                  " filename        ", VALUE=state.par.calib_file, $
                                  UVALUE= "calib_file",/ALL_EVENTS, XSIZE=30)

                                ;Standard buttons
                                ;----------------
base3     = WIDGET_BASE(base,/ROW,/FRAME) ;Standard buttons

help_id   = WIDGET_BUTTON(base3, VALUE='HELP'              ,UVALUE='help')
cancel_id = WIDGET_BUTTON(base3, VALUE='CANCEL'            ,UVALUE='cancel')
restore_id= WIDGET_BUTTON(base3, VALUE='RESTORE PARAMETERS',UVALUE='restore')
save_id   = WIDGET_BUTTON(base3, VALUE='SAVE PARAMETERS'   ,UVALUE='save')

IF modal THEN WIDGET_CONTROL, cancel_id, /CANCEL_BUTTON
IF modal THEN WIDGET_CONTROL, save_id, /DEFAULT_BUTTON

                                ;Final stuff
                                ;============
tce_set, state

WIDGET_CONTROL, base, SET_UVALUE=state
WIDGET_CONTROL, base, /REALIZE
XMANAGER, 'tce_gui', base, GROUP_LEADER=group

RETURN, error
END