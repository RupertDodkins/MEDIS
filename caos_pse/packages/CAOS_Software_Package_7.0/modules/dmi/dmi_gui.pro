; $Id: dmi_gui.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    dmi_gui
;
; PURPOSE:
;    dmi_gui generates the Graphical User Interface (GUI) for
;    setting the parameters of the Deformable Mirror (DMI) module.
;    A parameter file called dmi_yyyyy.sav is created, where yyyyy
;    is the number n_module associated to the the module instance.
;    The file is stored in the project directory proj_name located
;    in the working directory.
;    (see dmi.pro's header --or file caos_help.html-- for details).
;
; CATEGORY:
;    module's GUI routine
;
; CALLING SEQUENCE:
;    error = dmi_gui(n_module, proj_name)
;
; INPUTS:
;    n_module : integer scalar. Number associated to the intance
;               of the DMI module. n_module > 0.
;    proj_name: string. Name of the current project.
;
; OUTPUTS:
;    error: error code [long scalar].
;
; COMMON BLOCKS:
;    ...
;
; CALLED NON-IDL FUNCTIONS:
;    ...
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: september 1998,
;                     Marcel    Carbillet  (OAA) [marcel@arcetri.astro.it],
;                     Francoise Delplancke (ESO) [fdelplan@eso.org].
;    modifications  : october 1998,
;                     Francoise Delplancke (ESO) [fdelplan@eso.org]:
;                    -adding the help.
;                   : december 1999-january 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -enhanced and adapted to version 2.0 (CAOS).
;                   : january/february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]
;                    -adapted to version 4.0 of the whole Software System CAOS
;                     (variable "pack_name" added, and variable "mod_type"
;                     changed into "mod_name").
;                    -(dmi_info()).help stuff added (instead of !caos_env.help).
;                    -actuators & influence functions generation paratemeters
;                     eliminated (whole stuff moved to module MDS).
;                    -old "advanced parameters" sub-GUI eliminated.
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
PRO dmi_gui_set, state

widget_control, /HOURGLASS

END

;;;;;;;;;;;;;;;;;;;;;;
; dmi_gui event loop ;
;;;;;;;;;;;;;;;;;;;;;;
;
pro dmi_gui_event, event

common error_block, error

widget_control, event.top, GET_UVALUE=state

if tag_names(event, /STRUCTURE_NAME) eq 'WIDGET_KILL_REQUEST' then begin
   error = !caos_error.cancel
   widget_control, event.top, /DESTROY
endif

widget_control, event.id, GET_UVALUE=uvalue
case uvalue of

   'mirdef_file': begin
      state.par.mirdef_file = event.value
      widget_control, event.top, SET_UVALUE=state
   end

   'stroke': begin
      state.par.stroke = event.value
      widget_control, event.top, SET_UVALUE=state
   end

   'time_delay': begin
      state.par.time_delay = event.value
      widget_control, event.top, SET_UVALUE=state
   end

   'save': begin

      check_file = findfile(state.sav_file)
      if check_file[0] ne "" then begin
         answ = dialog_message(['file '+state.sav_file+' already exists.', $
                                'do you want to overwrite it?'], $
                               DIALOG_PARENT = event.top, $
                               TITLE = 'DMI warning', /QUEST)
         ; return without saving if the user does't want to overwrite the
         ; existing parameter file
         if strlowcase(answ) eq "no" then return
      endif else begin
         answ = dialog_message(['file '+state.sav_file+' will be saved.'], $
                               DIALOG_PARENT=event.top,                    $
                               TITLE='DMI information',                    $
                               /INFO                                       )
         ; inform were the parameters will be saved
      endelse

      par = state.par
      save, par, FILENAME=state.sav_file

      error = !caos_error.ok
      widget_control, event.top, /DESTROY

   end

   'help' : online_help, book=(dmi_info()).help, /FULL_PATH

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

      widget_control, state.id.mirdef_file,  SET_VALUE=par.mirdef_file
      widget_control, state.id.stroke,       SET_VALUE=par.stroke
      widget_control, state.id.time_delay,   SET_VALUE=par.time_delay

      state.par = par
      dmi_gui_set, state
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
;
function dmi_gui, n_module, proj_name, GROUP_LEADER=group

common error_block,        error

; retrieve the module information
info = dmi_info()
mod_name = info.mod_name

sav_file = mk_par_name(mod_name, n_module, PROJ_NAME=proj_name)
def_file = mk_par_name(mod_name, PACK_NAME=info.pack_name, /DEFAULT)

par = 0
check_file = findfile(sav_file)
if check_file[0] eq '' then begin
    restore, def_file
    par.module.n_module = n_module
   if (par.module.mod_name ne mod_name) then      $
      message, 'the default parameter file ('+def_file $
              +') is from another module: please take the right one'
   if (par.module.ver ne info.ver) then                $
      message, 'the default parameter file ('+def_file $
              +') is not compatible: please generate it again'
endif else begin
    restore, sav_file
   if (par.module.mod_name ne mod_name) then $
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
   par_base        : 0L, $ ; parameter base id
      mirdef_file  : 0L, $ ; initialisation tag id
      stroke       : 0L, $
      time_delay   : 0L  $ ; time delay field id
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
title = strupcase(mod_name)+' parameters setting GUI'
root_base_id = widget_base(TITLE=title, MODAL=modal, /COL, GROUP_LEADER=group)
widget_control, root_base_id, SET_UVALUE=state

; parameter base
   state.id.par_base = widget_base(root_base_id, FRAME=10, ROW=2)
   dummy = widget_label(state.id.par_base, VALUE='parameters', /FRAME)
   par_base_id = widget_base(state.id.par_base, /COL)

      def_base_id = widget_base(par_base_id, ROW=2, /FRAME)
      dummy = widget_label(def_base_id, VALUE='mirror deformations', /FRAME)
      def_base_id = widget_base(def_base_id, /COL)

         state.id.mirdef_file =                                              $
            cw_filename(def_base_id,                                         $
                        TITLE="mirror deformations file address:          ", $
                        VALUE=state.par.mirdef_file,                         $
                        UVALUE="mirdef_file",                                $
                        FILTER='*mir*.sav',                                  $
                        /ALL_EVENTS                                          )

         state.id.stroke = cw_field(def_base_id,                               $
                                    TITLE="maximum mirror stroke [microns]:  " $
                             +string(10B)+"(actually a simple wavefront cut) ",$
                                    VALUE=state.par.stroke,                    $
                                    UVALUE="stroke",                           $
                                    /FLOATING,                                 $
                                    /ROW,                                      $
                                    /ALL_EVENTS                                )

      time_base_id = widget_base(par_base_id, ROW=2, /FRAME)
      dummy = widget_label(time_base_id, VALUE='time delay', /FRAME)
      time_base_id = widget_base(time_base_id, /ROW)

        state.id.time_delay = cw_field(time_base_id,                               $
                                        TITLE='time delay before applying the    '  $
                                             + string(10B)                          $
                                             +'commands [base-time unit]:        ', $
                                        VALUE=state.par.time_delay,                 $
                                        UVALUE="time_delay",                        $
                                        /INTEGER,                                   $
                                        /ALL_EVENTS                                 )

   ; base for footnote
   note_base_id = widget_base(root_base_id, /COL, FRAME=10)
   note = WIDGET_LABEL(note_base_id, $
                       VALUE='NOTE: Within the Application Builder the BOTTOM box (output#1)'+string(10B) $
                            +'      contains the MIRROR SHAPE while the UPPER box (output#2)'+string(10B) $
                            +'      stores the corrected wavefront (wf - mirror shape).     ')

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
dmi_gui_set, state
widget_control, root_base_id, SET_UVALUE=state
widget_control, root_base_id, /REALIZE
xmanager, 'dmi_gui', root_base_id, GROUP_LEADER=group

return, error
end