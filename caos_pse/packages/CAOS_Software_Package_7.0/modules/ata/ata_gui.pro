; $Id: ata_gui.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;   ata_gui
;
; PURPOSE:
;   ata_gui generates the Graphical User Interface (GUI) for setting the
;   parameters of the ATmosphere Adding(ATA) module.  A parameter file
;   called ata_yyyyy.sav is created, where yyyyy is the number n_module
;   associated to the the module instance.  The file is stored in the
;   project directory proj_name located in the working directory.
;   (see ata.pro's header --or file caos_help.html-- for details
;   about the module itself).
;
; CATEGORY:
;   Module's Graphical User Interface (GUI) routine 
;
; CALLING SEQUENCE:
;   error = ata_gui(n_module, proj_name)
;
; INPUTS:
;   n_module  : integer scalar. Number associated to the intance
;               of the ATA module. n_module > 0.
;   proj_name : string. Name of the current project.
;
; OUTPUTS:
;   error     : long scalar.Error code (see caos_init procedure)
;
; COMMON BLOCKS:
;   common error_block, error
;   error    :  long scalar. Error code (see caos_init procedure).
;
;   common weights, tab1, tab2
;   tab1 & tab2: array of predefined weights.
;
; CALLED NON-IDL FUNCTIONS:
;   None.
;
; MODIFICATION HISTORY:
;    program written: march 2001,
;                     Bruno Femenia (OAA) [bfemenia@arcetri.astro.it].
;    modifications  : june 2002,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -comment on correction atmosphere eliminated since not true
;                     when using RCC.
;                   : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]
;                    -adapted to version 4.0 of the whole Software System CAOS
;                     (variable "pack_name" added, and variable "mod_type"
;                     changed into "mod_name").
;                    -(ata_info()).help stuff added (instead of !caos_env.help).
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
;-
;
PRO ata_set, state

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

   WIDGET_CONTROL, state.id.atm1_corr, GET_VALUE= atm1_corr
   WIDGET_CONTROL, state.id.atm2_corr, GET_VALUE= atm2_corr
   IF (atm1_corr NE 0B) OR (atm2_corr NE 0B) THEN   $
     WIDGET_CONTROL,state.id.base_corr, SENSITIVE=1 $
   ELSE                                             $
     WIDGET_CONTROL,state.id.base_corr, SENSITIVE=0 

   np       = state.par.nlay_corr
   alt_corr = state.par.alt_corr[0:np-1]

   IF (N_ELEMENTS(alt_corr) EQ 1) THEN                 $
     alt_corr = [alt_corr]                             $
   ELSE                                                $
     alt_corr = TRANSPOSE(alt_corr)

   WIDGET_CONTROL, state.id.alt_corr, /DELETE_ROWS
   WIDGET_CONTROL, state.id.alt_corr, INSERT_ROWS= state.par.nlay_corr
   WIDGET_CONTROL, state.id.alt_corr, ROW_LABELS = "layer #"+STRTRIM(INDGEN(np),2)
   WIDGET_CONTROL, state.id.alt_corr, SET_VALUE  = alt_corr

END 


PRO ata_gui_event, event

   COMMON error_block, error
   COMMON weights, tab1, tab2
   
   IF TAG_NAMES(event, /STRUCTURE_NAME) EQ 'WIDGET_KILL_REQUEST' THEN BEGIN
      WIDGET_CONTROL, event.top, GET_UVALUE=state
      error = !caos_error.cancel
      WIDGET_CONTROL, event.top, /DESTROY
   ENDIF
   
   
   WIDGET_CONTROL, event.id , GET_UVALUE= uvalue
   WIDGET_CONTROL, event.top, GET_UVALUE= state

   CASE uvalue OF
      
      'atm1_corr': BEGIN 
         state.par.atm1_corr = event.value
         WIDGET_CONTROL, event.top, SET_UVALUE=state
         ata_set,state
      END 

      'atm2_corr': BEGIN 
         state.par.atm2_corr = event.value
         WIDGET_CONTROL, event.top, SET_UVALUE=state
         ata_set,state
      END 

      'nlay_corr': BEGIN 
         state.par.nlay_corr = event.value
         WIDGET_CONTROL, event.top, SET_UVALUE=state
         ata_set, state
      END 

      'table': IF (event.type EQ 0) THEN BEGIN
         WIDGET_CONTROL, event.id,  GET_VALUE =dummy
         np = state.par.nlay_corr
         state.par.alt_corr[0:np-1] = dummy[0:np-1]
         WIDGET_CONTROL, event.top,  SET_UVALUE=state
         ata_set,state
      ENDIF 

      'threshold': BEGIN 
         state.par.threshold = event.value
         WIDGET_CONTROL, event.top, SET_UVALUE=state
         ata_set, state
      END 

      'wb_button':BEGIN
         IF (event.value LE N_ELEMENTS(tab2)-1) THEN state.par.wb = tab2[event.value]
         ata_set, state
         WIDGET_CONTROL, event.top, SET_UVALUE=state
      END
      
      'wb':BEGIN
         WIDGET_CONTROL, event.id,  GET_VALUE=dummy
         state.par.wb = dummy
         WIDGET_CONTROL, event.top, SET_UVALUE=state
      END
      
      'wt_button':BEGIN
         IF (event.value LE N_ELEMENTS(tab2)-1) THEN state.par.wt = tab2[event.value]
         ata_set, state
         WIDGET_CONTROL, event.top, SET_UVALUE=state
      END
      
      'wt':BEGIN
         WIDGET_CONTROL, event.id,  GET_VALUE=dummy
         state.par.wt = dummy
         ata_set,state
         WIDGET_CONTROL, event.top, SET_UVALUE=state
      END           
      
      'help' : online_help, book=(ata_info()).help, /FULL_PATH
      
      'restore': BEGIN 
         ;; restore the desired parameter file
         par = 0
         title = "parameter file to restore"
         RESTORE, FILENAME_GUI(state.def_file, /ALL ,  $
                               title, /NOEDIT, /MUST,  $
                               GROUP_LEADER=event.top, $
                               FILTER='ata*sav')
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
         
         WIDGET_CONTROL,state.id.atm1_corr, SET_VALUE= par.atm1_corr
         WIDGET_CONTROL,state.id.atm2_corr, SET_VALUE= par.atm2_corr
         WIDGET_CONTROL,state.id.nlay_corr, SET_VALUE= par.nlay_corr
         WIDGET_CONTROL,state.id.alt_corr , SET_VALUE= par.alt_corr
         WIDGET_CONTROL,state.id.threshold, SET_VALUE= par.threshold


         ata_set,state
         
         WIDGET_CONTROL,event.top  , SET_UVALUE=state
      END 
      
      'save': BEGIN
         ;; checks to be done before saving parameter file
         IF (state.par.atm1_corr NE 0B) AND (state.par.atm2_corr NE 0B) THEN BEGIN 
            dummy = DIALOG_MESSAGE(["There must be at least one atm_t"+  $
                                    " input which is NOT correction!!"], $
                                   DIALOG_PARENT=event.top,/ ERROR,      $
                                   TITLE='ATA error')
           RETURN 
        ENDIF
           
         ;; check before saving the parameter file if filename already exists
         ;; or inform where the parameters will be saved.
         check_file = FINDFILE(state.sav_file)
         IF check_file[0] NE "" THEN BEGIN
            dummy=DIALOG_MESSAGE(['file '+state.sav_file+             $
                                  ' already exists.',                 $
                                  'would you like to overwrite it?'], $
                                 DIALOG_PARENT=event.top,             $
                                 TITLE='ATA warning', /QUEST)
            IF STRLOWCASE(dummy) EQ "no" THEN RETURN
         ENDIF  ELSE BEGIN 
            answ = DIALOG_MESSAGE(['File '+state.sav_file+' will be '+ $
                                   'saved.'],DIALOG_PARENT=event.top,  $
                                  TITLE='ATA information',/INFO)
         ENDELSE 


         ;; save the parameter data file
         par = state.par
         par.alt_corr[par.nlay_corr:*] = 0.
         SAVE, par, FILENAME=state.sav_file
         ;; kill the GUI returning a null error
         error = !caos_error.ok
         WIDGET_CONTROL, event.top, /DESTROY
         return
      END 
      
      'cancel'  : BEGIN
         error = !caos_error.cancel
         WIDGET_CONTROL, event.top, /DESTROY
         RETURN
      END
      
   ENDCASE
   
   RETURN
   
END
 


FUNCTION ata_gui, n_module, proj_name, GROUP_LEADER=group

COMMON error_block, error
COMMON weights, tab1, tab2

tab1 = ['-1.0','-0.5','+0.5','+1.0','Other']
tab2 = [-1.,-0.5,0.5,1.]

; retrieve the module information
info = ata_info()

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
    wt_button  : 0L,     $
    atm1_corr  : 0L,     $
    atm2_corr  : 0L,     $
    base_corr  : 0L,     $
    nlay_corr  : 0L,     $
    threshold  : 0L,     $
    alt_corr   : 0L      $
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


base1= WIDGET_BASE( base,/FRAME,/COL,/BASE_ALIGN_CENTER)

;;;
;;; Building part associated to BOTTOM input: atm1_t
;;;
dummy  = WIDGET_LABEL(base1,VALUE="Weight assigned to bottom atmosphere in AppBuilder (atm1_t)",/FRAME)
base1_1= WIDGET_BASE(base1,/ROW)

dummy = (WHERE(tab2 EQ state.par.wb))[0]
IF (dummy EQ -1) THEN dummy= N_ELEMENTS(tab2)

state.id.atm1_corr =                                           $
  CW_BGROUP(base1_1,['No','Yes'],UVALUE='atm1_corr',/EXCLUS,   $
            /COL, LABEL_TOP='Correction atm_t?' ,              $
            SET_VALUE=par.atm1_corr)

void_text = WIDGET_LABEL(base1_1,VALUE='')

state.id.wb_button =                                           $
  CW_BGROUP(base1_1,tab1,UVALUE='wb_button',/EXCLUSIVE, ROW=2, $
            SET_VALUE=dummy)

state.id.wb =                                                  $
  CW_FIELD(base1_1,/COL,VALUE=state.par.wb,UVALUE='wb',        $
           /FLOATING,/ALL_EVENTS,TITLE='Weight for bottom ATM')


;;;
;;; Building part associated to TOP input: atm2_t
;;;
dummy  = WIDGET_LABEL(base1,VALUE="Weight assigned to top    atmosphere in AppBuilder (atm2_t)",/FRAME)
base1_2= WIDGET_BASE(base1,/ROW)

dummy = (WHERE(tab2 EQ state.par.wt))[0]
IF (dummy EQ -1) THEN dummy= N_ELEMENTS(tab2)

state.id.atm2_corr =                                           $
  CW_BGROUP(base1_2,['No','Yes'],UVALUE='atm2_corr',/EXCLUS,   $
            /COL, LABEL_TOP='Correction atm_t?',              $
            SET_VALUE=par.atm2_corr)

void_text = WIDGET_LABEL(base1_1,VALUE='')

state.id.wt_button =                                           $
  CW_BGROUP(base1_2,tab1,UVALUE='wt_button',/EXCLUSIVE, ROW=2, $
            SET_VALUE=dummy)
state.id.wt =                                                  $
  CW_FIELD(base1_2,/COL,VALUE=state.par.wb,UVALUE='wt',        $
           /FLOATING,/ALL_EVENTS, TITLE='Weight for top ATM')

;;dummy = WIDGET_LABEL(base1, VALUE='NOTE: When using ATA to duplicate a correction the weights assigned')
;;dummy = WIDGET_LABEL(base1, VALUE='      to bottom and top atmospheres ***MUST*** be set to +1.       ')


;;;
;;; Building part associated to threshold to consider two layers at different altitudes
;;;

base2 = WIDGET_BASE(base,/FRAME,/COL,/BASE_ALIGN_CENTER)

state.id.threshold=                                                 $
  CW_FIELD(base2,/COL,VALUE=state.par.threshold,UVALUE='threshold', $
           /FLOATING,/ALL_EVENTS, TITLE='Layer altitude threshold')

dummy = WIDGET_LABEL(base2, VALUE='NOTE: This threshold refers to the mininimun difference in altitude')
dummy = WIDGET_LABEL(base2, VALUE='      of two phase screens to be assumed different turbulent layers')

;;;
;;; Building part associated to layers at which apply correction
;;;

alt_corr = par.alt_corr[0:par.nlay_corr-1]
IF (N_ELEMENTS(alt_corr) EQ 1) THEN $
  alt_corr = [alt_corr]             $
ELSE                                $
  alt_corr = TRANSPOSE(alt_corr)

state.id.base_corr = WIDGET_BASE(base,/FRAME,/COL,/BASE_ALIGN_CENTER )

dummy = WIDGET_LABEL(state.id.base_corr,VALUE='  Altitudes at which correction operates  ',FRAME=4,/ALIGN_CENTER)

dummy = WIDGET_BASE(state.id.base_corr, COL=2)

; dummy = WIDGET_LABEL(state.id.base_corr,VALUE='Number of correction layers (HIT RETURN !)',/FRAME ,/ALIGN_CENTER)

state.id.nlay_corr = CW_FIELD(dummy,TITLE='Nb layers (HIT RETURN !!)', /COL, $
                              VALUE=state.par.nlay_corr, UVALUE='nlay_corr',/INTEGER, /RETURN_EVENTS)

state.id.alt_corr = WIDGET_TABLE(dummy,ROW_LABELS='layer #'+STRTRIM(INDGEN(state.par.nlay_corr),2), $ 
                                 COLUMN_LABELS=["h [m]"],VALUE=alt_corr, UVALUE='table', /EDITABLE, YSIZE=4,     $
                                 /ALIGN_CENTER,/SCROLL)


;;;
;;; Building part associated to Standard buttons
;;;
base3     = WIDGET_BASE(base,/FRAME,/ROW)
help_id   = WIDGET_BUTTON(base3, VALUE='HELP'              ,UVALUE='help')
cancel_id = WIDGET_BUTTON(base3, VALUE='CANCEL'            ,UVALUE='cancel')
restore_id= WIDGET_BUTTON(base3, VALUE='RESTORE PARAMETERS',UVALUE='restore')
save_id   = WIDGET_BUTTON(base3, VALUE='SAVE PARAMETERS'   ,UVALUE='save')

IF modal THEN WIDGET_CONTROL, cancel_id, /CANCEL_BUTTON
IF modal THEN WIDGET_CONTROL, save_id, /DEFAULT_BUTTON
 
;Final stuff
;============

ata_set,state

WIDGET_CONTROL, base, SET_UVALUE=state
WIDGET_CONTROL, base, /REALIZE

XMANAGER, 'ata_gui', base, GROUP_LEADER=group

RETURN, error
END