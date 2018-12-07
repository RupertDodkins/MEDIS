; $Id: slo_gui.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    slo_gui
;
; PURPOSE:
;    slo_gui generates the Graphical User Interface (GUI) for
;    setting the parameters of the slotroiding (slo) module.
;    A parameter file called slo_yyyyy.sav is created, where yyyyy
;    is the number n_module associated to the the module instance.
;    The file is stored in the project directory proj_name located
;    in the working directory.
;    (see slo.pro's header --or file caos_help.html-- for details
;    about the module itself).
;
; CATEGORY:
;    module's Graghical User Interface routine
;
; CALLING SEQUENCE:
;       error = slo_gui(n_module, proj_name)
;
; INPUTS:
;    n_module : number associated to the intance of the XXX module
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
;    routine written: june 2001,
;                     Christophe Verinaud (OAA) [verinaud@arcetri.astro.it].
;    modifications  : october 2002,
;                     Christophe Verinaud (OAA) [verinaud@arcetri.astro.it]:
;                    -parameter "algo_type" added for normalization alternative.
;                   : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]
;                    -adapted to version 4.0 of the whole Software System CAOS
;                     (variable "pack_name" added, and variable "mod_type"
;                     changed into "mod_name").
;                    -(slo_info()).help stuff added (instead of !caos_env.help).
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
;
pro slo_gui_set, state
 
widget_control, /HOURGLASS

end

;;;;;;;;;;;;;;;;;;;
; GUI events loop ;
;;;;;;;;;;;;;;;;;;;
;
pro slo_gui_event, event

common error_block, error

widget_control, event.top, GET_UVALUE=state

if tag_names(event, /STRUCTURE_NAME) eq 'WIDGET_KILL_REQUEST' then begin
   error = !caos_error.cancel
   widget_control, event.top, /DESTROY
endif

widget_control, event.id, GET_UVALUE=uvalue
case uvalue of

 'algo_type'   : state.par.algo_type   = event.value

   ; handle event from standard save button
   'save': begin

      check_file = findfile(state.sav_file)
      if check_file[0] ne "" then begin
         answ = dialog_message(['file '+state.sav_file+' already exists.', $
                                'do you want to overwrite it ?'],          $
                               DIALOG_PARENT = event.top,                  $
                               TITLE = 'slo warning',                      $
                               /QUEST)
         if strlowcase(answ) eq "no" then return
      endif else begin
         answ = dialog_message(['file '+state.sav_file+' will be saved.'], $
                               DIALOG_PARENT=event.top,                    $
                               TITLE='slo information',                    $
                               /INFO                                       )
         ; inform were the parameters will be saved
      endelse
        

      par = state.par
      save, par, FILENAME = state.sav_file
      error = !caos_error.ok
      widget_control, event.top, /DESTROY
      return

   end
    
   ; standard help button
   'help' : online_help, book=(slo_info()).help, /FULL_PATH

   ; standard restore button:
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
      widget_control, state.id.algo_type, SET_VALUE=par.algo_type
      state.par = par

   end

   ; standard cancel button (exit without saving)
   'cancel': begin
      error = !caos_error.cancel
      widget_control, event.top, /DESTROY
      return
   end

endcase

; reset the setting parameters status
slo_gui_set, state

; write the GUI state structure
widget_control, event.top, SET_UVALUE=state
return

end

;;;;;;;;;;;;;;;;;;;;;;;
; GUI generation code ;
;;;;;;;;;;;;;;;;;;;;;;;
;
function slo_gui, n_module, proj_name, GROUP_LEADER=group

common error_block, error

info = slo_info()
mod_name = info.mod_name

sav_file = mk_par_name(mod_name, n_module, PROJ_NAME=proj_name)
def_file = mk_par_name(mod_name, PACK_NAME=info.pack_name, /DEFAULT)
par = 0
check_file = findfile(sav_file)
if check_file[0] eq '' then begin
    restore, def_file
    par.module.n_module = n_module
    if par.module.mod_name ne mod_name then $
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

id = $
   { $
   par_base    : 0L,   $ ; parameter base id
   algo_type   : 0L    $
   }

state = $
   {    $
   sav_file: sav_file, $
   def_file: def_file, $
   id      : id,       $
   par     : par       $
   }

; root base
modal = n_elements(group) ne 0
title = strupcase(mod_name)+' parameter setting GUI'
root_base_id = widget_base(TITLE=title, MODAL=modal, /COL, GROUP_LEADER=group)
widget_control, root_base_id, SET_UVALUE=state

   ; parameters base
   state.id.par_base = widget_base(root_base_id, FRAME=10, ROW=2)
   dummy = widget_label(state.id.par_base, VALUE='parameters', /FRAME)
   par_base_id = widget_base(state.id.par_base, /COL)

 state.id.algo_type = widget_base(par_base_id, ROW=2, /FRAME)
 dummy = WIDGET_LABEL(state.id.algo_type, VALUE='algo_type', /FRAME)
 algo_type_base_id = WIDGET_BASE(state.id.algo_type, /ROW)

     dummy = cw_bgroup(algo_type_base_id,                                                      $
                     LABEL_LEFT= 'Algorithm for slope computation ?',                          $
                       ['Divide by constant', 'Divide by intensity in sub_ap'],                $
                       COLUMN=2,                                                               $
                       SET_VALUE=state.par.algo_type,                                          $
                       /EXCLUSIVE,                                                             $
                       UVALUE="algo_type")

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
slo_gui_set, state
widget_control, root_base_id, SET_UVALUE=state
widget_control, root_base_id, /realize
xmanager, 'slo_gui', root_base_id, GROUP_LEADER=group

return, error
end