; $Id: stf_gui.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    stf_gui
;
; PURPOSE:
;    STructure Function Graphical User Interface
;
; CATEGORY:
;    module's GUI
;
; CALLING SEQUENCE:
;    error = stf_gui(n_module, proj_name)
;
; INPUTS:
;    n_module : integer scalar. Number associated to the instance
;               of the STF module. n_module > 0.
;    proj_name: string. Name of the current project.
;
; OUTPUTS:
;    error: error code (long scalar).
;
; COMMON BLOCKS:
;    none.
;
; CALLED NON-IDL FUNCTIONS:
;    none.
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: july 1998,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : march 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted for version 1.0.
;                   : december 1999,
;                     Marcel Carbillet [marcel@arcetri.astro.it]:
;                    -adapted to version 2.0 (CAOS).
;                   : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]
;                    -adapted to version 4.0 of the whole Software System CAOS
;                     (variable "pack_name" added, and variable "mod_type"
;                     changed into "mod_name").
;                    -(stf_info()).help stuff added (instead of !caos_env.help).
;                   : december 2004,
;                     Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr]:
;                    -no more crash provoked when controlling the Soft.Pack.
;                     version for existing parameter files - just a warning.
;                   : february 2007,
;                     Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr]:
;                    -control of the the Soft.Pack. debugged (the warning was
;                     here *always* (partly) printed )...
;                   : may 2010,
;                     Marcel Carbillet (Fizeau) [marcel.carbillet@unice.fr]:
;                    -"Kolmogorov" option debugged (GUI prodiced an error when
;                     selecting it).
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr],
;                     Andrea La Camera (DIBRIS) [andrea.lacamera@unige.it]:
;                    -New way to call CAOS_HELP (by using the "online_help" 
;                     routine, independent from the operating system used.
;-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; status setting procedure ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
pro stf_gui_set, state

widget_control, /HOURGLASS

if (state.par.model eq 0) then widget_control, state.id.L0, SENSITIVE=0 $
                          else widget_control, state.id.L0, /SENSITIVE

end

;;;;;;;;;;;;;;;;;;;;;;
; stf_gui event loop ;
;;;;;;;;;;;;;;;;;;;;;;
;
pro stf_gui_event, event

common error_block, error

; read the GUI state structure
widget_control, event.top, GET_UVALUE=state

if tag_names(event, /STRUCTURE_NAME) eq 'WIDGET_KILL_REQUEST' then begin
    error = !caos_error.cancel
    widget_control, event.top, /DESTROY
endif

widget_control, event.id, GET_UVALUE = uvalue
case uvalue of

   'r0' : begin
      state.par.r0 = event.value
      widget_control, event.top, SET_UVALUE=state
   end

   'L0' : begin
      state.par.L0 = event.value
      widget_control, event.top, SET_UVALUE=state
   end

   'menu_mod': begin
   	state.par.model = event.value
      stf_gui_set, state
      widget_control, event.top, SET_UVALUE=state
   end

   'save': begin

      ; check before saving the parameter file if filename already exists
      check_file = findfile(state.sav_file)
      if check_file[0] ne "" then begin
         dummy = dialog_message(['file '+state.sav_file+' already exists.', $
                                 'do you ant to overwrite it ?'],           $
                                DIALOG_PARENT=event.top,                    $
                                TITLE='STF warning', /QUEST                 )
         if strlowcase(dummy) eq "no" then return
      endif else begin
         answ = dialog_message(['file '+state.sav_file+' will be saved.'], $
                               DIALOG_PARENT=event.top,                    $
                               TITLE='STF information', /INFO              )
      endelse

      par = state.par
      save, par, FILENAME=state.sav_file

      error = !caos_error.ok
      widget_control, event.top, /DESTROY

   end

   'help' : online_help, book=(stf_info()).help, /FULL_PATH

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

      widget_control, state.id.r0,    SET_VALUE=par.r0
      widget_control, state.id.L0,    SET_VALUE=par.L0
      widget_control, state.id.model, SET_VALUE=par.model

      state.par = par

      stf_gui_set, state

      widget_control, event.top, SET_UVALUE=state

   end

   'cancel'  : begin
      error = !caos_error.cancel
      widget_control, event.top, /DESTROY
   end

endcase

end

;;;;;;;;;;;;;;;;;;;;;;;
; GUI generation code ;
;;;;;;;;;;;;;;;;;;;;;;;
;
function stf_gui, n_module, proj_name, GROUP_LEADER=group

common error_block, error

info = stf_info()
mod_name = info.mod_name

sav_file = mk_par_name(mod_name, n_module, PROJ_NAME=proj_name)
def_file = mk_par_name(mod_name, PACK_NAME=info.pack_name, /DEFAULT)

par = 0
check_file = findfile(sav_file)
if check_file[0] eq '' then begin
    restore, def_file
    par.module.n_module = n_module
    if par.module.mod_name ne mod_name then            $
      message, 'the default parameter file ('+def_file $
              +') is from another module: please take the right one'
   if (par.module.ver ne info.ver) then                $
      message, 'the default parameter file ('+def_file $
              +') is not compatible: please generate it again'
endif else begin
    restore, sav_file
    if (par.module.mod_name ne mod_name) then $
      message, 'the parameter file '+sav_file $
              +' is from another module: please generate a new one'
   if (par.module.ver ne info.ver) then begin
      print, '************************************************************'
      print, 'WARNING: the parameter file '+sav_file
      print, 'is probably from an older version than '+info.pack_name+' !!'
      print, 'You should possibly need to generate it again...'
      print, '************************************************************'
   endif
endelse

id = $
   { $
   par_base: 0L, $
      r0   : 0L, $
      L0   : 0L, $
      model: 0L  $
   }

state = $
   {    $
   sav_file: sav_file, $
   def_file: def_file, $
   id      : id,       $
   par     : par       $
   }

modal = n_elements(group) ne 0
title = strupcase(mod_name)+" parameter setting GUI"
root_base_id = widget_base(TITLE=title, MODAL=modal, /COL, GROUP_LEADER=group)
widget_control, root_base_id, SET_UVALUE=state

   par_base_id = widget_base(root_base_id, FRAME=10, /COL)
      dummy = widget_label(par_base_id, VALUE='atmosphere parameters', /FRAME)

      par_base_id1 = widget_base(par_base_id, COLUMN=2)

      state.id.model = cw_bgroup(par_base_id1, LABEL_TOP="atmospheric model:",$
         ['Kolmogorov', 'von Karman'], $ ;BUTTON_UVALUE=[0,1], $
         SET_VALUE=state.par.model, UVALUE='menu_mod', /EXCLUSIVE)

      par_base_id2 = widget_base(par_base_id1, ROW=2)

      state.id.r0 = cw_field(par_base_id2, $
         TITLE="Fried parameter r0 [m] (@500nm):", $
         /COLUMN, VALUE=state.par.r0, UVALUE='r0', /FLOATING, /ALL_EVENTS)

      state.id.L0 = cw_field(par_base_id2, $
         TITLE="wave-front outer scale L0 [m]:", /COLUMN, $
         VALUE=state.par.L0, UVALUE='L0', /FLOATING, /ALL_EVENTS)

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

; final stuff
stf_gui_set, state
widget_control, root_base_id, SET_UVALUE=state
widget_control, root_base_id, /REALIZE
xmanager, 'stf_gui', root_base_id, GROUP_LEADER=group

return, error
end