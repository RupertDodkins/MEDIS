; $Id: cfb_gui.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    cfb_gui
;
; PURPOSE:
;    cfb_gui generates the Graphical User Interface (GUI) for
;    setting the parameters of the Calibration FiBer (CFB) module.
;    a parameter file called cfb_nnnnn.sav is created, where nnnnn
;    is the number n_module associated to the module instance.
;    the file is stored in the project directory proj_name located
;    in the working directory.
;    (see cfb.pro's header --or file caos_help.html-- for details
;    about the module itself).
;
; CATEGORY:
;    Module's Graphical User Interface routine
;
; CALLING SEQUENCE:
;    error = cfb_gui(n_module, $
;                    proj_name )
; 
; INPUTS:
;    n_module : number associated to the intance of the CFB module
;               [integer scalar -- n_module > 0].
;    proj_name: name of the current project [string].
;
; OUTPUTS:
;    error: error code [long scalar].
;
; COMMON BLOCKS:
;    none.
;
; CALLED NON-IDL FUNCTIONS:
;    none.
;
; ROUTINE MODIFICATION HISTORY:
;    program written: Nov 1999,
;                     B. Femenia   (OAA) [bfemenia@arcetri.astro.it]
;    modifications  : september 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -obscuration ratio parameter added.
;                   : january/february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]
;                    -adapted to version 4.0 of the whole Software System CAOS
;                     (variable "pack_name" added, and variable "mod_type"
;                     changed into "mod_name").
;                    -(cfb_info()).help stuff added (instead of !caos_env.help).
;                    -fixed problem with common "wavelenghts" wrt compatibility
;                     with one of module IMG.
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
; cfb_gui_event loop ;
;;;;;;;;;;;;;;;;;;;;;;
;
PRO cfb_gui_event, event

   COMMON error_block, error
   COMMON wavelengths, band_tab, lambda_tab, width_tab, flag_band, f_band

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

      'fwhm':BEGIN
         WIDGET_CONTROL, event.id,  GET_VALUE =dummy
         state.par.fwhm = dummy[0]
      END

      'n_phot': BEGIN
         WIDGET_CONTROL, event.id,  GET_VALUE =dummy
         state.par.n_phot = dummy[0]
      END
         
      'diameter': BEGIN
         WIDGET_CONTROL, event.id,  GET_VALUE =dummy
         state.par.diameter = dummy[0]
      END 

      'eps': BEGIN
         WIDGET_CONTROL, event.id,  GET_VALUE =dummy
         state.par.eps = dummy[0]
      END 

      'wf_nb_pxl': BEGIN
         WIDGET_CONTROL, event.id,  GET_VALUE =dummy
         state.par.wf_nb_pxl = dummy[0]
      END


      'save': BEGIN
         ;Checking that number of pixels across pupil is even.
         IF (state.par.wf_nb_pxl MOD 2) THEN BEGIN
            dummy =                                                          $
              DIALOG_MESSAGE(["Number of pixels along telescope's diameter", $
                              "must be even."], DIALOG_PARENT=event.top,     $
                             TITLE='CFB error',/ERROR)
            RETURN
         ENDIF 
         ;After parameter checking, go on with saving or inform where the
         ;parameters will be saved.
         check_file = FINDFILE(state.sav_file)
         IF check_file[0] NE "" THEN BEGIN
            dummy=                                                           $
              DIALOG_MESSAGE(['file ' + state.sav_file + ' already exists.', $
                              'would you like to overwrite it?'], /QUEST   , $
                             DIALOG_PARENT=event.top,TITLE='CFB warning')
            IF STRLOWCASE(dummy) EQ "no" THEN RETURN
         ENDIF  ELSE BEGIN 
            answ = dialog_message(['file '+state.sav_file+' will be '+ $
                                   'saved.'],DIALOG_PARENT=event.top,   $
                                  TITLE='CFB information',/INFO)
         ENDELSE 

         ; save the parameter data file
         par = state.par
         SAVE, par, FILENAME=state.sav_file
         ; kill the GUI returning a null error
         error = !caos_error.ok
         WIDGET_CONTROL, event.top, /DESTROY
         RETURN
      END 
      
      
      'restore': BEGIN 
         ; restore the desired parameter file
         par = 0
         title = "parameter file to restore"
         RESTORE, filename_gui(state.def_file, /ALL ,  $
                               title, /NOEDIT, /MUST,  $
                               GROUP_LEADER=event.top, $
                               FILTER='cfb*sav')
         ; update the current module number
         par.module.n_module = state.par.module.n_module
         ; update the widget fields with new parameter values
         WIDGET_CONTROL, state.id.fwhm     , SET_VALUE= par.fwhm     
         WIDGET_CONTROL, state.id.n_phot   , SET_VALUE= par.n_phot
         WIDGET_CONTROL, state.id.diameter , SET_VALUE= par.diameter 
         WIDGET_CONTROL, state.id.eps      , SET_VALUE= par.eps 
         WIDGET_CONTROL, state.id.wf_nb_pxl, SET_VALUE= par.wf_nb_pxl

         ; update the state structure
         state.par = par

       END 

      'cancel'  : BEGIN
         error = !caos_error.cancel
         WIDGET_CONTROL, event.top, /DESTROY
         RETURN
      END 

      'help' : online_help, book=(cfb_info()).help, /FULL_PATH

   ENDCASE 

   WIDGET_CONTROL, event.top, SET_UVALUE=state

   return 

END
      

;;;;;;;;;;;;;;;;;;;;;;;
; GUI generation code ;
;;;;;;;;;;;;;;;;;;;;;;;
;
FUNCTION cfb_gui, n_module, proj_name, GROUP_LEADER=group

COMMON error_block, error
COMMON wavelengths, band_tab, lambda_tab, width_tab, flag_band, f_band

; retrieve the module information
info = cfb_info()

; check if a saved parameter file already exists for this module.
; if it exists it is restored, otherwise the default parameter file is restored.
sav_file = MK_PAR_NAME(info.mod_name, n_module, PROJ_NAME=proj_name)
def_file = MK_PAR_NAME(info.mod_name, PACK_NAME=info.pack_name, /DEFAULT)

par=0
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

dummy= N_PHOT(1.,BAND=dummy1,LAMBDA=dummy2,WIDTH=dummy3)
band_tab  = dummy1
lambda_tab= dummy2
width_tab = dummy3

id =                 $
  {                  $
    fwhm      : 0L,  $
    n_phot    : 0L,  $
    diameter  : 0L,  $
    eps       : 0L,  $
    wf_nb_pxl : 0L   $
  }

state =                  $
  {                      $
   sav_file  : sav_file, $
   def_file  : def_file, $
   id        : id      , $
   par       : par       $
   }


; ROOT BASE
;===========

modal = N_ELEMENTS(group) NE 0
title = STRUPCASE(par.module.mod_name)+' parameter setting GUI'
root  = WIDGET_BASE(TITLE=title,MODAL=modal,/COL,GROUP_LEADER=group)


WIDGET_CONTROL, root, SET_UVALUE=state  ;Set the status structure

;===========================================
par_base = WIDGET_BASE(root, FRAME=10, /COL) 
;===========================================

dummy = WIDGET_BASE(par_base,COLUMN=2)
;-------------------------------------

state.id.fwhm =                                                       $
  CW_FIELD(dummy,TITLE='Fiber image FWHM ["]            ',/COLUMN,    $
           VALUE=state.par.fwhm,UVALUE='fwhm',/ALL_EVENTS,/FLOAT)

state.id.n_phot =                                                     $
  CW_FIELD(dummy,TITLE='Number photons/m^2/s from fiber ', /COLUMN,   $
           VALUE=state.par.n_phot,UVALUE='n_phot',/FLOAT,             $
           /ALL_EVENTS)


dummy  = WIDGET_BASE(par_base,COLUM=2)
;-------------------------------------

state.id.diameter =                                                   $
  CW_FIELD(dummy,TITLE='Telescope Diameter [m]          ', /COLUMN,   $
           VALUE=state.par.diameter,UVALUE='diameter',/FLOAT, /ALL)


state.id.wf_nb_pxl =                                                  $
  CW_FIELD(dummy,TITLE='Pixels across telescope diameter',/INT,/COL,  $
           VALUE=state.par.wf_nb_pxl,UVALUE='wf_nb_pxl',/ALL_EVENTS)



dummy  = WIDGET_BASE(par_base,COLUM=1)
;-------------------------------------

state.id.eps =                                                 $
  CW_FIELD(dummy, TITLE='Telescope Obscuration Ratio: ', /ROW, $
           VALUE=state.par.eps, UVALUE='eps', /FLOAT, /ALL     )


;NOTES:
;=====
note= WIDGET_LABEL(par_base, $
VALUE='NOTES: 1/Calibration fiber produces a Gaussian image on detector.')
note= WIDGET_LABEL(par_base, $
VALUE='         FWHM refers to its size according to geometrical optics.')
note= WIDGET_LABEL(par_base, $
VALUE='       2/Use same Telescope Diameter as in NORMAL RUNNING PROJECT')
note= WIDGET_LABEL(par_base, $
VALUE='       3/Use same number of pixels across pupil as in NORMAL RUN-')
note= WIDGET_LABEL(par_base, $
VALUE='         NING PROJECT')

;Filling Control Buttons Section (standard buttons)
;===========================================
btn_base = WIDGET_BASE(root, FRAME=10, /ROW) 
;===========================================

dummy = WIDGET_BUTTON(btn_base, UVALUE="help"   ,VALUE="HELP")
cancel= WIDGET_BUTTON(btn_base, UVALUE="cancel" ,VALUE="CANCEL")
dummy = WIDGET_BUTTON(btn_base, UVALUE="restore",VALUE="RESTORE PARAMETERS")
save  = WIDGET_BUTTON(btn_base, UVALUE="save"   ,VALUE="SAVE PARAMETERS")

IF modal THEN WIDGET_CONTROL, cancel, /CANCEL_BUTTON
IF modal THEN WIDGET_CONTROL, save  , /DEFAULT_BUTTON


;Final stuff
;============
WIDGET_CONTROL, root, SET_UVALUE=state
WIDGET_CONTROL, root, /REALIZE

XMANAGER, 'cfb_gui', root, GROUP_LEADER=group

; back to the main calling program
RETURN, error
END