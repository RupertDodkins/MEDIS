; $Id: ibc_gui.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    ibc_gui
;
; PURPOSE:
;    ibc_gui generates the Graphical User Interface (GUI) for
;    setting the parameters of the Interferometric Beam Combiner (IBC)
;    module.
;    A parameter file called ibc_nnnnn.sav is created, where nnnnn
;    is the number n_module associated to the module instance.
;    The file is stored in the project directory proj_name located
;    in the working directory.
;
; CATEGORY:
;    module's Graghical User Interface routine
;
; CALLING SEQUENCE:
;    error = ibc_gui(n_module, proj_name)
; 
; INPUTS:
;    n_module : integer scalar. Number associated to the intance
;               of the IBC module. n_module > 0.
;    proj_name: string. Name of the current project.
;
; OUTPUTS:
;    error: error code [long scalar] (see !caos_error in caos_init.pro).
;
; COMMON BLOCKS:
;    none.
;
; CALLED NON-IDL FUNCTIONS:
;    none.
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: april-october 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : december 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 2.0 (CAOS).
;                   : february 2001,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -partial diff. piston correction now taken into account.
;                   : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]
;                    -adapted to version 4.0 of the whole Software System CAOS
;                     (variable "pack_name" added, and variable "mod_type"
;                     changed into "mod_name").
;                    -(ibc_info()).help stuff added (instead of !caos_env.help).
;                   : december 2004,
;                     Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr]:
;                    -no more crash provoked when controlling the Soft.Pack.
;                     version for existing parameter files - just a warning.
;                   : march 2005,
;                     Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr],
;                     Olivier Lardiere (LISE) [lardiere@obs-hp.fr]:
;                    -densification factor parameter added (for modelling the
;                     "densified pupil" case.
;                   : march 2006,
;                     Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr]:
;                    -densification factor upgrade debugged (in GUI).
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
;;;;;;;;;;;;;;;;;;;
; GUI events loop ;
;;;;;;;;;;;;;;;;;;;
; 
pro ibc_gui_event, event

common error_block, error   

widget_control, event.top, GET_UVALUE=state

if tag_names(event, /STRUCTURE_NAME) eq 'WIDGET_KILL_REQUEST' then begin
   error = !caos_error.cancel
   widget_control, event.top, /DESTROY
endif

widget_control, event.id, GET_UVALUE=uvalue

case uvalue of

    'residual': begin
        state.par.residual = event.value
        widget_control, event.top, SET_UVALUE=state
    end

   'densification': begin
        state.par.densification=event.value
        widget_control, event.top, SET_UVALUE=state
    end

   'save': begin

      check_file = findfile(state.sav_file)
      if check_file[0] ne "" then begin
         answ = dialog_message(['file '+state.sav_file+' already exists.', $
                                'do you want to overwrite it ?'],          $
                               DIALOG_PARENT=event.top,                    $
                               TITLE='IBC warning',                        $
                               /QUEST)
         ; return without saving if the user doesn't want to overwrite the
         ; existing parameter file
         if strlowcase(answ) eq "no" then return
      endif else begin
         answ = dialog_message(['file '+state.sav_file+' will be saved.'], $
                               DIALOG_PARENT=event.top,                    $
                               TITLE='IBC information',                    $
                               /INFO                                       )
         ; inform were the parameters will be saved
      endelse

      par = state.par
      save, par, FILENAME = state.sav_file
      error = !caos_error.ok
      widget_control, event.top, /DESTROY
   end

   'help' : online_help, book=(ibc_info()).help, /FULL_PATH

   'restore': begin
      par = 0
      title = "parameter file to restore"
      restore, filename_gui(state.def_file,                          $
                            title,                                   $
                            GROUP_LEADER=event.top,                  $
                            FILTER=state.par.module.mod_name+'*sav', $
                            /NOEDIT,                                 $
                            /MUST_EXIST,                             $
                            /ALL_EVENTS                              )
      par.module.n_module = state.par.module.n_module
      widget_control, state.id.residual, SET_VALUE=par.residual
      widget_control, state.id.densification, SET_VALUE=par.densification
      state.par = par
      widget_control, event.top, SET_UVALUE=state
   end

   'cancel': begin
      error = !caos_error.cancel
      widget_control, event.top, /DESTROY
   end

endcase

end

;;;;;;;;;;;;;;;;;;;;;;;
; GUI generation code ;
;;;;;;;;;;;;;;;;;;;;;;;

function ibc_gui, n_module, proj_name, GROUP_LEADER=group

; error status from the event handler procedure
common error_block, error

; retrieve the module information
info = ibc_info()

; check if a saved parameter file already exists for this module.
; if it exists it is restored, otherwise the default parameter file is restored.
sav_file = MK_PAR_NAME(info.mod_name, n_module, PROJ_NAME=proj_name)
def_file = MK_PAR_NAME(info.mod_name, PACK_NAME=info.pack_name, /DEFAULT)
par = 0
check_file = FINDFILE(sav_file)
IF check_file[0] EQ '' THEN BEGIN
    RESTORE, def_file
    par.module.n_module = n_module
   if (par.module.mod_name ne info.mod_name) then      $
      message, 'the default parameter file ('+def_file $
              +') is from another module: please take the right one'
   if (par.module.ver ne info.ver) then                $
      message, 'the default parameter file ('+def_file $
              +') is not compatible: please generate it again'
ENDIF ELSE BEGIN
   restore, sav_file
   if (par.module.mod_name ne info.mod_name) then $
      message, 'the parameter file '+sav_file     $
              +' is from another module: please generate a new one'
   if (par.module.ver ne info.ver) then begin
      print, '************************************************************'
      print, 'WARNING: the parameter file '+sav_file
      print, 'is probably from an older version than '+info.pack_name+' !!'
      print, 'You should possibly need to generate it again...'
      print, '************************************************************'
   endif
ENDELSE

id = $
   { $                     ; widget id structure
   par_base        : 0L, $ ; parameter base id
      densification: 0L, $ ; densification slider id
      residual     : 0L  $ ; residual slider id
   }

state = $
   {    $                ; widget state structure
   sav_file: sav_file, $ ; name of the file where save params
   def_file: def_file, $ ; name of the file where save params
   id      : id,       $ ; widget id structure
   par     : par       $ ; parameter structure
   }

modal = n_elements(group) ne 0
dummy = strupcase(info.mod_name)+' parameters setting GUI'
root_base_id=widget_base(TITLE=dummy, MODAL=modal, /COL, GROUP_LEADER=group)

   widget_control, root_base_id, SET_UVALUE=state

   state.id.par_base = widget_base(root_base_id, FRAME=10, ROW=2)
   dummy = widget_label(state.id.par_base, VALUE='parameters')
   state.id.par_base = widget_base(state.id.par_base, /FRAME, /COL)

      state.id.densification = cw_field(state.id.par_base,         $
                                        TITLE='pupil densification factor: ', $
                                        /ROW,                        $
                                        VALUE=state.par.densification,  $
                                        UVALUE='densification',         $
                                        /FLOAT,                         $
                                        /ALL_EVENTS                     )

      state.id.residual = cw_fslider(state.id.par_base,                             $
                          TITLE="(residual diff. piston: ratio wrt input diff. piston)",$
                                     VALUE=state.par.residual,                      $
                                     MAXIMUM=1, SCROLL=.05,                         $
                                     UVALUE='residual',                             $
                                     /EDIT,                                         $
                                     /DRAG                                          )

   ; button base for control buttons (standard buttons)
   btn_base_id = widget_base(root_base_id, FRAME=10, /ROW)
      dummy = widget_button(btn_base_id, VALUE="HELP", UVALUE="help")
      cancel_id = widget_button(btn_base_id, VALUE="CANCEL", UVALUE="cancel")
      if modal then widget_control, cancel_id, /CANCEL_BUTTON
      dummy = widget_button(btn_base_id, VALUE="RESTORE PARAMETERS", $
                            UVALUE="restore")
      save_id = widget_button(btn_base_id, VALUE="SAVE PARAMETERS", $
                              UVALUE="save")
      if modal then widget_control, save_id, /DEFAULT_BUTTON

; save the state structure of the GUI in the top base uvalue
widget_control, root_base_id, SET_UVALUE=state

; draw the GUI
widget_control, root_base_id, /REALIZE

xmanager, 'ibc_gui', root_base_id, GROUP_LEADER=group

return, error
end