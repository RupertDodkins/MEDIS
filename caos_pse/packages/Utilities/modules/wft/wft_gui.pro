; $Id: wft_gui.pro,v 1.0 last revision 2016/04/29 Andrea La Camera$
;+
; NAME:
;    wft_gui
;
; PURPOSE:
;    wft_gui generates the Graphical User Interface (GUI) for
;    setting the parameters of the WFT module.
;    A parameter file called wft_nnnnn.sav is created, where nnnnn
;    is the number n_module associated to the module instance.
;    The file is stored in the project directory proj_name located
;    in the working directory.
;
; CATEGORY:
;    module's Graphical User Interface routine
;
; CALLING SEQUENCE:
;    error = wft_gui(n_module, proj_name)
;
; INPUTS:
;    n_module : integer scalar. Number associated to the instance
;               of the WFT module. n_module > 0.
;    proj_name: string. Name of the current project.
;
; OUTPUTS:
;    error: error code [long scalar]
;
; COMMON BLOCKS:
;    none.
;
; CALLED NON-IDL FUNCTIONS:
;    none.
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: october 2000,
;                     Serge Correia (OAA) [correia@arcetri.astro.it].
;    modifications  : february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]
;                    -adapted to version 4.0 of the whole system CAOS
;                     (variable "pack_name" added, and variable "mod_type"
;                     changed into "mod_name").
;                    -(wft_info()).help stuff added (instead of !caos_env.help).
;                   ; september 2005
;                     Barbara Anconelli (DISI) [anconelli@disi.unige.it]
;                    -added help for windows version.
;                   : may 2007, 
;                     Gabriele Desidera' (DISI) [desidera@disi.unige.it]:
;                    -simpler way to call AIRY_HELP.
;                   : February 2012,
;                     Andrea La Camera (DISI) [lacamera@disi.unige.it]:
;                    -New way to call AIRY_HELP. By using the "online_help" 
;                     routine, we resolved a known-issue of the Soft.Pack.
;                   : from CAOS_PSE v 7.0 (2016) 
;                    -this module has been moved from AIRY 6.1 to the new 
;                     package "Utilities". Version number has been
;                     reset to 1.0. 
;-
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; status setting procedure ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
pro wft_gui_set, state

case state.par.end_iter of
    0: widget_control, state.id.iteration, /SENSITIVE
    1: widget_control, state.id.iteration, SENSITIVE=0
endcase

end

;;;;;;;;;;;;;;;;;;;;;;
; wft_gui event loop ;
;;;;;;;;;;;;;;;;;;;;;;
;
pro wft_gui_event, event

common error_block, error

; read the GUI state structure
widget_control, event.top, GET_UVALUE=state

; handle a kill request (considered as a cancel event).
if tag_names(event, /STRUCTURE_NAME) eq 'WIDGET_KILL_REQUEST' then begin
   error = !caos_error.cancel
   widget_control, event.top, /DESTROY
endif

; handle other events.
widget_control, event.id, GET_UVALUE=uvalue
case uvalue of


    'save_data': state.par.data_file = event.value

    'end_iter': begin
        state.par.end_iter = event.value
        wft_gui_set, state
    end

    'iteration': state.par.iteration = event.value

   ; handle event from standard save button
   'save': begin

      if state.par.iteration eq 0 then begin
         dummy = dialog_message(["number of iterations cannot be 0"], $
                                DIALOG_PARENT=event.top,         $
                                TITLE='WFT error',               $
                                /ERROR)
         ; return without saving if the test failed
         return
      endif

      ; check if output structure filename already exists
      check_file = findfile(state.par.data_file)
      if check_file[0] ne "" then begin
         answ = dialog_message(                                            $
                ['file '+state.par.data_file+' already exists.',     $
                 'do you want to append other output structures to it ?'], $
                DIALOG_PARENT=event.top,                                   $
                TITLE='WFT warning',                                       $
                /QUEST                                                     )
         ; return without saving if the user doesn't want to append other
         ; structures to the existing output file
         if strlowcase(answ) eq "no" then return
      endif

      ; save data in the parameter file.
      ; check before if filename already exists
      check_file = findfile(state.sav_file)
      if check_file[0] ne "" then begin
         answ = dialog_message(['file '+state.sav_file+' already exists.', $
                                'do you want to overwrite it ?'],          $
                               DIALOG_PARENT=event.top,                    $
                               TITLE='WFT warning',                        $
                               /QUEST)
         ; return without saving if the user doesn't want to overwrite the
         ; existing parameter file
         if strlowcase(answ) eq "no" then return
      endif else begin
         answ = dialog_message(['file '+state.sav_file+' will be saved.'], $
                               DIALOG_PARENT=event.top,                    $
                               TITLE='WFT information',                    $
                               /INFO                                       )
         ; inform were the parameters will be saved
      endelse

      ; save the parameter data file
      par = state.par
      save, par, FILENAME = state.sav_file

      ; kill the GUI returning a null error
      error = !caos_error.ok
      widget_control, event.top, /DESTROY
      return
   end

   ; standard help button
  'help': begin
   online_help, book=(wft_info()).help, /FULL_PATH
;         widget_control, /HOURGLASS
;         
;       CASE !VERSION.OS_FAMILY OF
;         'Windows'   :     begin
;                    spawn, !caos_env.browser+" "+(wft_info()).help,/NOSHELL
;                   end
;         else    :  begin
;                     spawn, !caos_env.browser+" "+(wft_info()).help+" &"
;                   end
;       ENDCASE
end
   ; standard restore button:
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
      widget_control, state.id.data_file, SET_VALUE=par.data_file
      widget_control, state.id.end_iter,  SET_VALUE=par.end_iter
      widget_control, state.id.iteration, SET_VALUE=par.iteration

      ; write the reseted state structure
      state.par = par

      ; write the GUI state structure
      widget_control, event.top, SET_UVALUE=state
   end

   ; standard cancel button (exit without saving)
   'cancel': begin
      error = !caos_error.cancel
      widget_control, event.top, /DESTROY
      return
   end

endcase

; write the GUI state structure
widget_control, event.top, SET_UVALUE=state

return
end

;;;;;;;;;;;;;;;;;;;;;;;
; GUI generation code ;
;;;;;;;;;;;;;;;;;;;;;;;
;
function wft_gui, n_module, proj_name, GROUP_LEADER=group

; error status from the event handler procedure
common error_block, error

; get info structure
info = wft_info()

; check if a saved parameter file exists.
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
endif else begin
   restore, sav_file
   if (par.module.mod_name ne info.mod_name) then $
      message, 'the parameter file '+sav_file     $
              +' is from another module: please generate a new one'
   if (par.module.ver ne info.ver) then       $
      message, 'the parameter file '+sav_file $
              +' is not compatible: please generate it again'
endelse

; build the widget id structure
id = $
   { $                     ; widget id structure
   par_base        : 0L, $ ; data widget base
      data_file    : 0L, $ ; data file widget base
      end_iter     : 0L, $ ; "when saving ?" widget base
      iteration    : 0L  $
   }

; build the state structure
state = $
   {    $                   ; widget state structure
   sav_file: sav_file, $    ; name of the file where save params
   def_file: def_file, $    ; name of the file where save params
   id      : id,       $    ; widget id structure
   par     : par       $    ; parameter structure
   }

; root base
modal = n_elements(group) ne 0
title = strupcase(info.mod_name)+' parameters setting GUI'
root_base_id = widget_base(TITLE=title, MODAL=modal, /COL, GROUP_LEADER=group)

; set the status structure
widget_control, root_base_id, SET_UVALUE=state

   ; parameters base
   state.id.par_base = widget_base(root_base_id, FRAME=10, ROW=2)
   dummy = widget_label(state.id.par_base, VALUE='parameters', /FRAME)
   par_base_id = widget_base(state.id.par_base, /COL)

   ; filename
   state.id.data_file = cw_filename(par_base_id,                               $
                                    TITLE='image filename',                    $
                                    VALUE=state.par.data_file,                 $
                                    UVALUE='save_data',                        $
                                    /ALL_EVENTS                                )

   ; save the image at the very end of wftulation ?
   state.id.end_iter = cw_bgroup(par_base_id,                        $
                                 LABEL_LEFT='save the image at: ',   $
                                 ['each given nb of iterations',     $
                                  'the very end of the simulation'], $
                                 COLUMN=2,                           $
                                 SET_VALUE = state.par.end_iter,     $
                                 UVALUE = 'end_iter',                $
                                 /EXCLUSIVE                          )

   ; # of iterations per saving
   state.id.iteration = cw_field(par_base_id,                          $
                                 TITLE='nb of iterations per saving: ',$
                                 VALUE = state.par.iteration,          $
                                 /INTEGER,                             $
                                 UVALUE = 'iteration',                 $
                                 /ALL_EVENTS                           )

   ; standard buttons
   btn_base_id = widget_base(root_base_id, FRAME=10, /ROW)
      dummy = widget_button(btn_base_id, VALUE="HELP", UVALUE="help")
      cancel_id = widget_button(btn_base_id, VALUE="CANCEL", UVALUE="cancel")
      if modal then widget_control, cancel_id, /CANCEL_BUTTON
      dummy = widget_button(btn_base_id, VALUE="RESTORE PARAMETERS", $
                            UVALUE="restore")
      save_id = widget_button(btn_base_id, VALUE="SAVE PARAMETERS", $
                              UVALUE="save")
      if modal then widget_control, save_id, /DEFAULT_BUTTON

; initialize the sensitive state
wft_gui_set, state

; save the state structure of the GUI in the top base uvalue
widget_control, root_base_id, SET_UVALUE=state

; draw the GUI
widget_control, root_base_id, /REALIZE

xmanager, 'wft_gui', root_base_id, GROUP_LEADER=group

return, error
end
