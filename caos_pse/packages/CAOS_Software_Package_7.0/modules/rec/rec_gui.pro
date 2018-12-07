; $Id: rec_gui.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    rec_gui
;
; PURPOSE:
;    rec_gui generates the Graphical User Interface (GUI) for
;    setting the parameters of the wavefront REConstruction (REC)
;    module.
;    A parameter file called rec_nnnnn.sav is created, where nnnnn
;    is the number n_module associated to the module instance.
;    The file is stored in the project directory proj_name located
;    in the working directory.
;
; CATEGORY:
;    module's GUI routine
;
; CALLING SEQUENCE:
;    error = rec_gui(n_module, proj_name)
;
; INPUTS:
;    n_module : integer scalar. Number associated to the intance
;               of the REC module. n_module > 0.
;    proj_name:  string. Name of the current project.
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
;
; ROUTINE MODIFICATION HISTORY:
;    program written: june 2002,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : october,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -parameter n_modes added.
;                   : january/february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]
;                    -adapted to version 4.0 of the whole Software System CAOS
;                     (variable "pack_name" added, and variable "mod_type"
;                     changed into "mod_name").
;                    -(rec_info()).help stuff added (instead of !caos_env.help).
;                    -"calib_file" now splitted into "mirdef_file" AND "matint_file".
;                    -all parameters related to the atmosphere-type output eliminated
;                     (since only the command-type output exists from now on).
;                    -added option for saving/restoring of w,u,v after SVD
;                     (and consequently rec_gui_set procedure).
;                    -no more use of common variable "calibration".
;                    -module's name from RCC to REC (eliminating old module REC).
;                   : december 2004,
;                     Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr]:
;                    -no more crash provoked when controlling the Soft.Pack.
;                     version for existing parameter files - just a warning.
;                    -use of the LAPACK la_svd routine option in alternative to the
;                     standard svdc IDL routine (needs IDL5.6+).
;                   : february 2007,
;                     Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr]:
;                    -control of the the Soft.Pack. debugged (the warning was
;                     here *always* (partly) printed )...
;                   : january 2011,
;                     Marcel Carbillet (Fizeau) [marcel.carbillet@unice.fr]:
;                    -warning added for par.modes use in case of zonal rec'n.
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
;
pro rec_gui_set, state, event

widget_control, /HOURGLASS

case state.par.save_wuv of
   0: begin
      widget_control, state.id.save_wuv_file, /SENSITIVE
      widget_control, state.id.calib_base,    /SENSITIVE
      widget_control, state.id.svd_type,    /SENSITIVE
   end
   1: begin
      widget_control, state.id.save_wuv_file, /SENSITIVE
      widget_control, state.id.calib_base,    SENSITIVE=0
      widget_control, state.id.svd_type,    SENSITIVE=0
   end
   2: begin
      widget_control, state.id.save_wuv_file, SENSITIVE=0
      widget_control, state.id.calib_base,    /SENSITIVE
      widget_control, state.id.svd_type,    /SENSITIVE
   end
endcase

end

;;;;;;;;;;;;;;;;;;;
; GUI events loop ;
;;;;;;;;;;;;;;;;;;;
;
pro rec_gui_event, event

; rec_gui error management block
common error_block, error

; read the GUI state structure
widget_control, event.top, GET_UVALUE=state

; handle a kill request (considered as a cancel event).
if tag_names(event, /STRUCTURE_NAME) eq 'WIDGET_KILL_REQUEST' then begin
   error = !caos_error.cancel
   widget_control, event.top, /DESTROY
endif

; handle all the other events
widget_control, event.id, GET_UVALUE=uvalue
case uvalue of

   'mirdef_file'  : state.par.mirdef_file   = event.value
   'matint_file'  : state.par.matint_file   = event.value
   'n_modes'      : state.par.n_modes       = event.value
   'svd_type'     : state.par.svd_type      = event.value
   'save_wuv'     : state.par.save_wuv      = event.value
   'save_wuv_file': state.par.save_wuv_file = event.value

   ; handle event from standard save button
   'save': begin

      ; check if the mirror deformations file is not empty
      if (state.par.mirdef_file eq '') then begin
         dummy = dialog_message(                                        $
                   ["you MUST provide a mirror deformations filename"], $
                   DIALOG_PARENT=event.top,                             $
                   TITLE='REC error',                                   $
                   /ERROR)
         return
      endif 

      ; check if the interaction matrix file is not empty
      if (state.par.matint_file eq '') then begin
         dummy = dialog_message(                                        $
                   ["you MUST provide an interaction matrix filename"], $
                   DIALOG_PARENT=event.top,                             $
                   TITLE='REC error',                                   $
                   /ERROR)
         return
      endif 

      ; check before saving the parameter file if filename already exists
      check_file = findfile(state.sav_file)
      if check_file[0] ne "" then begin
         answ = dialog_message(['file '+state.sav_file+' already exists.', $
                                'do you want to overwrite it ?'],          $
                               DIALOG_PARENT=event.top,                    $
                               TITLE='REC warning',                        $
                               /QUEST)
         ; return without saving if the user doesn't want to overwrite the
         ; existing parameter file
         if strlowcase(answ) eq "no" then return
      endif else begin
         answ = dialog_message(['file '+state.sav_file+' will be saved.'], $
                               DIALOG_PARENT=event.top,                    $
                               TITLE='REC information',                    $
                               /INFO                                       )
         ; inform where the parameters will be saved
      endelse

      ; save the parameter data file
      par = state.par
      save, par, FILENAME = state.sav_file

      ; kill the GUI returning a null error
      error = !caos_error.ok
      widget_control, event.top, /DESTROY
      return

   end
    
   ; handle event from standard help button
   'help' : online_help, book=(rec_info()).help, /FULL_PATH

   ; handle event from standard restore button
   'restore': begin

      ; restore the desired parameter file
      par = 0
      title = "parameter file to restore"
      restore, filename_gui(state.def_file,                          $
                            title,                                   $
                            GROUP_LEADER=event.top,                  $
                            FILTER=state.par.module.mod_name+'*sav', $
                            /NOEDIT,                                 $
                            /MUST_EXIST,                             $
                            /ALL_EVENTS                              )

      ; update the current module number
      par.module.n_module = state.par.module.n_module

      ; set the default values for all the widgets
      widget_control, state.id.mirdef_file,   SET_VALUE=par.mirdef_file
      widget_control, state.id.matint_file,   SET_VALUE=par.matint_file
      widget_control, state.id.n_modes,       SET_VALUE=par.n_modes
      widget_control, state.id.svd_type,      SET_VALUE=par.svd_type
      widget_control, state.id.save_wuv,      SET_VALUE=par.save_wuv
      widget_control, state.id.save_wuv_file, SET_VALUE=par.save_wuv_file

      ; update the state structure
      state.par = par

   end

   ; handle event of standard cancel button (exit without saving)
   'cancel': begin
      error = !caos_error.cancel
      widget_control, event.top, /DESTROY
      return
   end

endcase

; reset the setting parameters status
rec_gui_set, state

; write the GUI state structure
widget_control, event.top, SET_UVALUE=state

return

end

;;;;;;;;;;;;;;;;;;;;;;;
; GUI generation code ;
;;;;;;;;;;;;;;;;;;;;;;;
;
function rec_gui, n_module,  $
                  proj_name, $
                  GROUP_LEADER=group

; CAOS global common block
common caos_block, tot_iter, this_iter

; error status from the event handler procedure
common error_block, error

; retrieve the module information
info = rec_info()

; check if a saved parameter file already exists for this module.
; if it exists it is restored, otherwise the default parameter file is restored.
sav_file = mk_par_name(info.mod_name, n_module, PROJ_NAME=proj_name)
def_file = mk_par_name(info.mod_name, PACK_NAME=info.pack_name, /DEFAULT)
par=0
check_file = findfile(sav_file)
if check_file[0] eq '' then begin
   restore, def_file
   par.module.n_module = n_module
   if (par.module.mod_name ne info.mod_name) then      $
      message, 'the default parameter file ('+def_file $
              +') is from another module: please take the right one'
   if (par.module.ver ne info.ver) then                $
      message, 'the default parameter file ('+def_file $
              +') is not compatible: please generate it again'   
endif else begin
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
endelse

; build the widget id structure where all the needed (in rec_gui_event)
; widget's id will be stored
id = $
   { $                     ; widget id structure
   par_base        : 0L, $ ; parameter base id
      calib_base   : 0L, $
      mirdef_file  : 0L, $
      matint_file  : 0L, $
      n_modes      : 0L, $
      svd_type     : 0L, $
      save_wuv     : 0L, $
      save_wuv_file: 0L  $
   }

; build the state structure were par, id, sav_file and def_file will be stored
; (and passed to rec_gui_event).
state = $
   {    $                ; widget state structure
   sav_file: sav_file, $ ; actual name of the file where save params
   def_file: def_file, $ ; default name of the file where save params
   id      : id,       $ ; widget id structure
   par     : par       $ ; parameter structure
   }

; root base definition
modal = n_elements(group) ne 0
dummy = strupcase(info.mod_name)+' parameters setting GUI'
root_base_id = widget_base(TITLE=dummy, MODAL=modal, /COL, GROUP_LEADER=group)

; set the status structure
widget_control, root_base_id, SET_UVALUE=state

   ; parameters base
   state.id.par_base = widget_base(root_base_id, FRAME=10, ROW=3)
   dummy = widget_label(state.id.par_base, VALUE='parameters', /FRAME)
   par_base_id = widget_base(state.id.par_base, /COL)

      ; reconstruction informations
      rec_base_id = widget_base(par_base_id, /ROW, /FRAME)

         ; n_modes
         state.id.n_modes = cw_field(rec_base_id,                              $
                      TITLE="restrict nb of cons'd mirror deformations (maybe NOT if inf.fct!) to:", $
                                    /COL,                                      $
                                    VALUE=state.par.n_modes,                   $
                                    /LONG,                                     $
                                    UVALUE="n_modes",                          $
                                    /ALL_EVENTS                                )

   ; w,u,v SVD base:
   wuv_base_id = widget_base(par_base_id, /FRAME, ROW=2)
   dummy = widget_label(wuv_base_id, VALUE="SVD operation", /FRAME)
   wuv_base_id = widget_base(wuv_base_id, /COL)

         state.id.save_wuv = cw_bgroup(wuv_base_id,                       $
                                       LABEL_TOP='What to do with w,u,v ?', $
                                       ['save w,u,v after SVD',           $
                                        'restore already computed w,u,v', $
                                        'do not save nor restore w,u,v'], $
                                       ROW=3,                             $
                                       SET_VALUE=state.par.save_wuv,      $
                                       /EXCLUSIVE, /FRAME,                $
                                       UVALUE="save_wuv"                  )

         state.id.save_wuv_file = cw_filename(wuv_base_id,                       $
                                              TITLE=                             $
                                "w,u,v file address                           ", $
                                              VALUE=state.par.save_wuv_file,     $
                                              UVALUE="save_wuv_file",            $
                                              FILTER='*sav',                     $
                                              /ALL_EVENTS                        )

         state.id.svd_type = cw_bgroup(wuv_base_id,                       $
                                       LABEL_TOP='type of SVD routine ?', $
                                       ['use standard svdc IDL routine',           $
                                        'use la_svd LAPACK/IDL routine (needs IDL5.6+)'], $
                                       ROW=2,                             $
                                       SET_VALUE=state.par.svd_type,      $
                                       /EXCLUSIVE, /FRAME,                $
                                       UVALUE="svd_type"                  )

   ; calibration files base:
   state.id.calib_base = widget_base(par_base_id, /FRAME, ROW=2)
   dummy = widget_label(state.id.calib_base, $
                        VALUE="calibration data files", /FRAME)
   calib_base_id = widget_base(state.id.calib_base, /COL)

         state.id.mirdef_file = cw_filename(calib_base_id,                       $
                                            TITLE=                               $
                                "mirror deformations file address             ", $
                                            VALUE=state.par.mirdef_file,         $
                                            UVALUE="mirdef_file",                $
                                            FILTER='*mir*',                      $
                                            /MUST_EXIST,                         $
                                            /ALL_EVENTS                          )

         state.id.matint_file = cw_filename(calib_base_id,                       $
                                            TITLE=                               $
                                "interaction matrix file address              ", $
                                            VALUE=state.par.matint_file,         $
                                            UVALUE="matint_file",                $
                                            FILTER='*mat*',                      $
                                            /MUST_EXIST,                         $
                                            /ALL_EVENTS                          )

   ; button base for control buttons (standard buttons)
   btn_base_id = widget_base(root_base_id, FRAME=10, /ROW)
      dummy = widget_button(btn_base_id, VALUE="HELP", UVALUE="help")
      cancel_id = widget_button(btn_base_id, VALUE="CANCEL", UVALUE="cancel")
      if modal then widget_control, cancel_id, /CANCEL_BUTTON
      dummy = widget_button(btn_base_id, VALUE="RESTORE PARAMETERS", $
                            UVALUE="restore"                         )
      save_id = widget_button(btn_base_id, VALUE="SAVE PARAMETERS",  $
                              UVALUE="save"                          )
      if modal then widget_control, save_id, /DEFAULT_BUTTON

; initialize all the sensitive states
rec_gui_set, state

; save the state structure of the GUI in the top base uvalue
widget_control, root_base_id, SET_UVALUE=state

; draw the GUI
widget_control, root_base_id, /REALIZE

; launch xmanager
xmanager, 'rec_gui', root_base_id, GROUP_LEADER=group

; back to the main calling program
return, error
end