; $Id: ave_gui.pro,v 7.0 2016/05/19 marcel.carbillet $
;
;+
; NAME:
;    ave_gui
;
; PURPOSE:
;    ave_gui generates the Graphical User Interface (GUI) for
;    setting the parameters of the signals AVEraging (AVE) module.
;    a parameter file called ave_nnnnn.sav is created, where nnnnn
;    is the number n_module associated to the module instance.
;    the file is stored in the project directory proj_name located
;    in the working directory.
;    (see ave.pro's header --or file caos_help.html-- for details
;    about the module itself).
;
; CATEGORY:
;    module's Graghical User Interface routine
;
; CALLING SEQUENCE:
;    error = ave_gui(n_module, $
;                    proj_name )
; 
; INPUTS:
;    n_module : number associated to the intance of the AVE module
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
; none.
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: september 2008,
;                     Marcel Carbillet (Fizeau) [marcel.carbillet@unice.fr].
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
;;;;;;;;;;;;;;;;;;;
; GUI events loop ;
;;;;;;;;;;;;;;;;;;;
;
pro ave_gui_event, event

; ave_gui error management block
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

   'nstars': state.par.nstars = event.value

   ; handle event from standard save button
   'save': begin

      ; cross-check controls among the parameters

      if state.par.nstars eq 0 then begin
         dummy = dialog_message(["nb of stars cannot be 0"], $
                                DIALOG_PARENT=event.top,            $
                                TITLE='AVE error',                  $
                                /ERROR                              )
         return
      endif
        
      ; check before saving the parameter file if filename already exists
      check_file = findfile(state.sav_file)
      if check_file[0] ne "" then begin
         answ = dialog_message(['file '+state.sav_file+' already exists.', $
                                'do you want to overwrite it ?'],          $
                               DIALOG_PARENT=event.top,                    $
                               TITLE='AVE warning',                        $
                               /QUEST)
         ; return without saving if the user doesn't want to overwrite the
         ; existing parameter file
         if strlowcase(answ) eq "no" then return
      endif else begin
         answ = dialog_message(['file '+state.sav_file+' will be saved.'], $
                               DIALOG_PARENT=event.top,                    $
                               TITLE='AVE information',                    $
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
    
   ; handle event from standard help button
   'help' : online_help, book=(ave_info()).help, /FULL_PATH

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
      widget_control, state.id.nstars, SET_VALUE=par.nstars

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

; write the GUI state structure
widget_control, event.top, SET_UVALUE=state

return

end


;;;;;;;;;;;;;;;;;;;;;;;
; GUI generation code ;
;;;;;;;;;;;;;;;;;;;;;;;
;
function ave_gui, n_module,  $
                  proj_name, $
                  GROUP_LEADER=group

; error status from the event handler procedure
common error_block, error

; retrieve the module information
info = ave_info()

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

; build the widget id structure where all the needed (in ave_gui_event)
; widget's id will be stored
id = $
   { $              ; widget id structure
   par_base : 0L, $ ; parameter base id
      nstars: 0L  $ ; ...
   }

; build the state structure were par, id, sav_file and def_file will be stored
; (and passed to ave_gui_event).
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
   state.id.par_base = widget_base(root_base_id, FRAME=10, ROW=2)
   dummy = widget_label(state.id.par_base, VALUE='parameters', /FRAME)
   par_base_id = widget_base(state.id.par_base, /ROW)

         ; example of an exclusive bgroup
         state.id.nstars = cw_field(par_base_id,                    $
                                    TITLE='nb of stars from which signals are to be averaged', $
                                    /COLUMN,                        $
                                    VALUE=state.par.nstars,         $
                                    /LONG,                          $
                                    UVALUE="nstars",                $
                                    /ALL_EVENTS                     )

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

; save the state structure of the GUI in the top base uvalue
widget_control, root_base_id, SET_UVALUE=state

; draw the GUI
widget_control, root_base_id, /REALIZE

; launch xmanager
xmanager, 'ave_gui', root_base_id, GROUP_LEADER=group

; back to the main calling program
return, error
end