; $Id: bqc_gui.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;       bqc_gui
;
; PURPOSE:
;       bqc_gui generates the Graphical User Interface (GUI) for setting the
;       parameters of the Barycenter/Q-cell Centroiding (BQC) module. A
;       parameter file called bqc_yyyyy.sav is created, where yyyyy is the
;       number n_module associated to the the module instance. The file is
;       stored in the project directory proj_name located in the working
;       directory. 
;
; CATEGORY:
;       Graghical User Interface (GUI) program
;
; CALLING SEQUENCE:
;       error = bqc_gui(n_module, proj_name)
;
; INPUTS:
;       n_module :  integer scalar. Number associated to the intance
;                   of the BQC module. n_module > 0.
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
;    program written: Dec 2003, 
;                     B. Femenia (GTC) [bfemenia@ll.iac.es]
;    modifications  : december 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]
;                    -adapted to version 4.0+ of the whole Software System CAOS
;                     (variable "pack_name" added, and variable "mod_type"
;                     changed into "mod_name").
;                    -(bqc_info()).help stuff added (instead of !caos_env.help).
;                   : december 2003,
;                     B. Femenia (GTC) [bfemenia@ll.iac.es].
;                    -Removing seldomly used tags and letting BQC a much simpler module to
;                     use when considering a Q-cell detector.
;                   : september,2004
;                     B. Femenia (GTC) [bfemenia@ll.iac.es].
;                    -Within BQC GUI it is possible to choose or not the application of a pixel
;                     weighting when computing centroids.
;                   : september,2004
;                     B. Femenia (GTC) [bfemenia@ll.iac.es].
;                    -Within BQC GUI and with Q-cell it is possible to apply
;                     different calibration constants for different subapertures.
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
;;;;;;;;;;;;;;;;;;;;;; 
; bqc_gui event loop ;
;;;;;;;;;;;;;;;;;;;;;;
;
PRO bqc_gui_set, state

   IF state.par.detector THEN BEGIN 
     WIDGET_CONTROL, state.id.baseQ, SENSITIVE=0B
   ENDIF ELSE BEGIN 
      WIDGET_CONTROL, state.id.baseQ,    SENSITIVE=1B
      IF state.par.same_cal THEN BEGIN 
         WIDGET_CONTROL, state.id.cal_cte,  SENSITIVE=1B
         WIDGET_CONTROL, state.id.cal_file, SENSITIVE=0B
         WIDGET_CONTROL, state.id.baseQN,   SENSITIVE=0B
      ENDIF ELSE BEGIN 
         WIDGET_CONTROL, state.id.cal_cte,  SENSITIVE=0B
         WIDGET_CONTROL, state.id.cal_file, SENSITIVE=1B
         WIDGET_CONTROL, state.id.baseQN,   SENSITIVE=1B
      ENDELSE
   ENDELSE

   WIDGET_CONTROL, state.id.filename, SENSITIVE=state.par.weights
   WIDGET_CONTROL, state.id.baseWN,   SENSITIVE=state.par.weights
END



PRO bqc_gui_event, event
   
   COMMON error_block, error
   
   ;;Handle a kill request (considered as a cancel event).
   IF TAG_NAMES(event, /STRUCTURE_NAME) EQ 'WIDGET_KILL_REQUEST' THEN BEGIN
      WIDGET_CONTROL, event.top, GET_UVALUE=state
      error = !caos_error.cancel
      WIDGET_CONTROL, event.top, /DESTROY
   ENDIF
   
   ;;Read the GUI state structure
   WIDGET_CONTROL, event.top, GET_UVALUE=state

   ;;Handle all the other events
   WIDGET_CONTROL, event.id, GET_UVALUE=uvalue,  GET_VALUE=dummy

   
   CASE uvalue OF
      
      'detector': state.par.detector = event.value

      'same_cal': state.par.same_cal = event.value

      'cal_cte':  state.par.cal_cte  = dummy[0]

      'cal_file': state.par.cal_file = event.value

      'weights':  state.par.weights  = dummy[0]

      'filename': state.par.filename = event.value


      ;;Standard buttons actions
      ;;========================
      'help' : online_help, book=(bqc_info()).help, /FULL_PATH


      'restore': BEGIN 
         par   = 0
         title = "parameter file to restore"
         RESTORE, filename_gui(!caos_env.work+'Projects',      $ ;Restore the desired parameter file
                               title, GROUP_LEADER=event.top,  $
                               FILTER='bqc*sav', /MUST_EXIST,  $
                               /ALL_EVENTS, /NOEDIT)
                                                            
         par.module.n_module = state.par.module.n_module    ;Update the current module number

         ;; update the widget fields with new parameter values
         WIDGET_CONTROL, state.id.detector, SET_VALUE=par.detector
         WIDGET_CONTROL, state.id.cal_cte, SET_VALUE=par.cal_cte
         state.par = par
      END 
      
      'save': BEGIN                                         ;Saving of parameters.
         check_file = FINDFILE(state.sav_file)
         IF check_file[0] NE "" THEN BEGIN
            dummy =                                                            $
              DIALOG_MESSAGE(['File ' + state.sav_file + ' already exists.',   $
                              'would you like to overwrite it?'], /QUEST,      $
                             DIALOG_PARENT=event.top, TITLE='BQC warning')
            IF STRLOWCASE(dummy) EQ "no" THEN RETURN
         ENDIF ELSE BEGIN
            dummy =                                                            $          
              DIALOG_MESSAGE(['File ' + state.sav_file + ' will be written.'], $
                             DIALOG_PARENT=event.top, TITLE='BQC information', $
                             /INFO)
         ENDELSE 
                                                            
         par = state.par
         SAVE, par, FILENAME=state.sav_file                 ;Save the parameter data file
                                                            
         error = !caos_error.ok
         WIDGET_CONTROL, event.top, /DESTROY                ;Kill the GUI returning a null error
         RETURN
      END 
      
      'cancel'  : BEGIN
         error = !caos_error.cancel
         WIDGET_CONTROL, event.top, /DESTROY
         RETURN
      END
      
   ENDCASE

   WIDGET_CONTROL, event.top, SET_UVALUE=state
   bqc_gui_set, state

   RETURN
   
END 


FUNCTION bqc_gui, n_module, proj_name, GROUP_LEADER = group

   COMMON error_block, error
   
   ;; retrieve the module information
   info = bqc_info()

   ;; check if a saved parameter file already exists for this module.
   ;; if it exists it is restored, otherwise the default parameter file is restored.
   sav_file = MK_PAR_NAME(info.mod_name, n_module, PROJ_NAME=proj_name)
   def_file = MK_PAR_NAME(info.mod_name, PACK_NAME=info.pack_name, /DEFAULT)

   par = 0
   check_file = FINDFILE(sav_file)
   IF check_file[0] EQ '' THEN BEGIN
      RESTORE, def_file
      par.module.n_module = n_module
      IF (par.module.mod_name NE info.mod_name) THEN                    $
        MESSAGE, 'the default parameter file ('+ def_file               $
                 +') is from another module: please take the right one'
      IF (par.module.ver ne info.ver) THEN                              $
        MESSAGE, 'the default parameter file ('+ def_file               $
                 +') is not compatible: please generate it again'   
   ENDIF ELSE BEGIN
      RESTORE, sav_file
      IF (par.module.mod_name NE info.mod_name) THEN                    $
        MESSAGE, 'the parameter file '+sav_file                         $
                 +' is from another module: please generate a new one'
      IF (par.module.ver NE info.ver) THEN begin
         print, '************************************************************'
         print, 'WARNING: the parameter file '+sav_file
         print, 'is probably from an older version than '+info.pack_name+' !!'
         print, 'You should possibly need to generate it again...'
         print, '************************************************************'
      endif
   ENDELSE

   id    = {baseQ:          0L, $
            baseQN:         0L, $
            baseWN:         0L, $
            detector:       0L, $
            cal_cte:        0L, $
            same_cal:       0L, $
            cal_file:       0L, $
            weights:        0L, $
            filename:       0L  }

   state = {sav_file: sav_file, $
            def_file: def_file, $
            id:             id, $
            par:           par  }


   modal = N_ELEMENTS(group) NE 0
   title = STRUPCASE(state.par.module.mod_name)+' parameter setting GUI'
   base = WIDGET_BASE(TITLE=title, MODAL=modal, /COL, GROUP_LEADER=group, /BASE_ALIGN_CENTER)


   ;;Parameters for BQC
   ;;==================
   base1 = WIDGET_BASE(base, /COL, /FRAME, /BASE_ALIGN_CENTER)
   dummy = WIDGET_LABEL(base1, $
                        VALUE="Specify algorithm to estimate tip-tilt", /FRAME)

   state.id.detector =                                                        $
     CW_BGROUP(base1, ['QUAD-CELL algorithm', 'BARYCENTER algorithm'], /ROW,  $
               SET_VALUE=state.par.detector, UVALUE='detector', /EXCLUSIVE)

   ;;-----
   state.id.baseQ = WIDGET_BASE(base1, /COL, /FRAME, /BASE_ALIGN_CENTER)

   dummy = WIDGET_LABEL(state.id.baseQ, /FRAME, VALUE='Quad Cell Calibration Options')

   state.id.same_cal =                                                                 $
     CW_BGROUP(state.id.baseQ, ['    Different Calibration Constants               ',  $
                                '    Same Calibration Constant for all subapertures'], $
               SET_VALUE=state.par.same_cal, UVALUE='same_cal', /COL, /EXCLUSIVE)

   state.id.cal_cte  =                                                                 $
     CW_FIELD(state.id.baseQ, TITLE='Calibration Constant [arcsec]', /FLOAT,           $
              VALUE=state.par.cal_cte, UVALUE='cal_cte', /ALL_EVENTS)

   state.id.cal_file =                                                                 $
     CW_FILENAME(state.id.baseQ, TITLE="Calibration constants file address:", /ALL,    $
                 VALUE=state.par.cal_file, UVALUE='cal_file', FILTER='*.sav')

   state.id.baseQN = WIDGET_BASE(state.id.baseQ, /COL, /FRAME, /BASE_ALIGN_CENTER)
   dummy = WIDGET_LABEL(state.id.baseQN, VALUE='NOTE: It is up to the user to ensure the calibration')
   dummy = WIDGET_LABEL(state.id.baseQN, VALUE='====: constants are ordered in the same way as BQC  ')
   dummy = WIDGET_LABEL(state.id.baseQN, VALUE='      works (e.g. SUB_AP field in input variable).  ')
   dummy = WIDGET_LABEL(state.id.baseQN, VALUE='      These constants must be stored in a variable  ')
   dummy = WIDGET_LABEL(state.id.baseQN, VALUE='      named "CalCte" (Without ""!!).                ')

   ;;-----

   state.id.weights =                                                        $
     CW_BGROUP(base1, ['Do not apply Weighting to centroid calculus',        $
                       'Apply Pixel  Weighting to centroid calculus'], /COL, $ 
               SET_VALUE=state.par.weights, UVALUE='weights', /EXCLUSIVE)

   state.id.filename =                                                         $
     CW_FILENAME(base1, TITLE="Pixel weighting file address:", FILTER='*.sav', $
                 VALUE=state.par.filename, UVALUE='filename', /ALL_EVENTS)

   state.id.baseWN = WIDGET_BASE(base1, /COL, /FRAME, /BASE_ALIGN_CENTER)
   dummy = WIDGET_LABEL(state.id.baseWN, VALUE='NOTE: It is up to the user to ensure the 2D arrays')
   dummy = WIDGET_LABEL(state.id.baseWN, VALUE='====: storing the pixel weightings are saved under')
   dummy = WIDGET_LABEL(state.id.baseWN, VALUE='      the variables weight_x and weight_y.        ')


   ;;Standard buttons
   ;;================
   base3      = WIDGET_BASE(base, /ROW, /FRAME)
   
   help_id    = WIDGET_BUTTON(base3, VALUE='HELP', UVALUE='help')
   cancel_id  = WIDGET_BUTTON(base3, VALUE='CANCEL', UVALUE='cancel')
   restore_id = WIDGET_BUTTON(base3, VALUE='RESTORE PARAMETERS', UVALUE='restore')
   save_id    = WIDGET_BUTTON(base3, VALUE='SAVE PARAMETERS', UVALUE='save')

   IF modal THEN WIDGET_CONTROL, cancel_id, /CANCEL_BUTTON
   IF modal THEN WIDGET_CONTROL, save_id, /DEFAULT_BUTTON


   ;;Final stuff
   ;;============
   bqc_gui_set, state
   WIDGET_CONTROL, base, SET_UVALUE=state
   WIDGET_CONTROL, base, /REALIZE
   XMANAGER, 'bqc_gui', base, GROUP_LEADER=group

   RETURN, error

END