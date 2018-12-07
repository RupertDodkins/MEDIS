; $Id: gpr_gui.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    gpr_gui
;
; PURPOSE:
;    gpr_gui generates the Graphical User Interface (GUI) for
;    setting the parameters of the Geometrical PRopagation (GPR) module.
;    A parameter file called gpr_nnnnn.sav is created, where nnnnn
;    is the number n_module associated to the the module instance.
;    The file is stored in the project directory proj_name located
;    in the working directory.
;    (see gpr.pro's header --or file caos_help.html-- for details
;    about the module itself).
;
; CATEGORY:
;    module's Graghical User Interface routine
;
; CALLING SEQUENCE:
;    error = gpr_gui(n_module, proj_name)
;
; INPUTS:
;    n_module : integer scalar. Number associated to the intance
;               of the GPR module. n_module > 0.
;    proj_name: string. Name of the current project.
;
; OUTPUTS:
;    error: long scalar, error code (see !caos_error var in caos_init.pro).
;
; COMMON BLOCKS:
;    none.
;
; CALLED NON-IDL FUNCTIONS:
;    none.
;
; ROUTINE MODIFICATION HISTORY:
;    program written: july 1998,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : march 1999,
;                     Bruno Femenia (OAA) [bfemenia@arcetri.astro.it]:
;                    -par.angle is double precision.
;                   : december 1999--february 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -enhanced and adapted to version 2.0 (CAOS).
;                   : january/february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]
;                    -adapted to version 4.0 of the whole Software System CAOS
;                     (variable "pack_name" added, and variable "mod_type"
;                     changed into "mod_name").
;                    -(gpr_info()).help stuff added (instead of !caos_env.help).
;                    -parameter alt eliminated (was useful only to SHS).
;                   : january 2005,
;                     Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr]:
;                    -no more crash provoked when controlling the Soft.Pack.
;                     version for existing parameter files - just a warning.
;                   : february 2007,
;                     Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr]:
;                    -control of the the Soft.Pack. debugged (the warning was
;                     here *always* (partly) printed )...
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr],
;                     Andrea La Camera (DIBRIS) [andrea.lacamera@unige.it]:
;                    -New way to call CAOS_HELP (by using the "online_help" 
;                     routine, independent from the operating system used.
;
;-
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; status setting procedure ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
pro gpr_set_sensitive, state

if state.par.tel then widget_control, state.id.tel_base, SENSITIVE=1 $
else widget_control, state.id.tel_base, SENSITIVE=0

end

;;;;;;;;;;;;;;;;;;;
; GUI events loop ;
;;;;;;;;;;;;;;;;;;;
;
pro gpr_gui_event, event

common error_block, error

widget_control, event.top, GET_UVALUE=state

if tag_names(event, /STRUCTURE_NAME) eq 'WIDGET_KILL_REQUEST' then begin
    error = !caos_error.cancel
    widget_control, event.top, /DESTROY
endif

widget_control, event.id, GET_UVALUE = uvalue

case uvalue of

   'D': begin
      state.par.D = event.value
      widget_control, event.top, SET_UVALUE=state
   end

   'eps': begin
      state.par.eps = event.value
      widget_control, event.top, SET_UVALUE=state
   end

   'alt': begin
      state.par.alt = event.value
      widget_control, event.top, SET_UVALUE=state
   end

   'menu_tel': begin
      state.par.tel = event.value
      gpr_set_sensitive, state
      widget_control, event.top, SET_UVALUE=state
   end

   'dist': begin
      state.par.dist = event.value
      widget_control, event.top, SET_UVALUE=state
   end

   'angle': begin
      state.par.angle = event.value*!DPI/180.d0
      widget_control, event.top, SET_UVALUE=state
   end

   'save': begin

      ; "telescope at point [0,0]" statement
      if state.par.tel eq 0 then begin
         state.par.dist  = 0.
         state.par.angle = 0.d0
      endif

      ; check before saving the parameter file if filename already exists
      check_file = findfile(state.sav_file)
      if check_file[0] ne "" then begin
         answ = dialog_message(['a file '+state.sav_file+' already exists.', $
                               'would you like to overwrite it?'], $
                                  dialog_parent = event.top, $
                                  title = 'GPR warning', /QUEST)
         ; return without saving if the user doesn't want to overwrite the
         ; existing parameter file
         if strlowcase(answ) eq "no" then return
      endif else begin
         answ = dialog_message(['file '+state.sav_file+' will be saved.'], $
                               DIALOG_PARENT=event.top,                    $
                               TITLE='GPR information',                    $
                               /INFO                                       )
         ; inform were the parameters will be saved
      endelse

      ; save the parameter data file
      par = state.par
      save, par, FILENAME=state.sav_file

      ; kill the GUI returning a null error
      error = !caos_error.ok
      widget_control, event.top, /DESTROY

   end

   ; standard help button
   'help' : online_help, book=(gpr_info()).help, /FULL_PATH

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

      widget_control, state.id.D,     SET_VALUE=par.D
      widget_control, state.id.eps,   SET_VALUE=par.eps
      widget_control, state.id.alt,   SET_VALUE=par.alt
      widget_control, state.id.tel,   SET_VALUE=par.tel
      widget_control, state.id.dist,  SET_VALUE=par.dist
      widget_control, state.id.angle, SET_VALUE=(par.angle*1.8d2)/!DPI

      state.par = par
      gpr_set_sensitive, state
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
function gpr_gui, n_module, proj_name, GROUP_LEADER=group

; error status from the event handler procedure
common error_block, error

; retrieve the module information
info = gpr_info()

; standard checks
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

; widgets id. struc.
id = $
   { $
   par_base: 0L, $ ; parameter base id
   D       : 0L, $
   eps     : 0L, $
   alt     : 0L, $
   tel     : 0L, $
   tel_base: 0L, $
   dist    : 0L, $
   angle   : 0L  $
   }

; general status id. struc.
state = $
   {    $
   sav_file: sav_file, $
   def_file: def_file, $
   id      : id,       $
   par     : par       $
   }

; root base
modal = n_elements(group) ne 0
title = strupcase(info.mod_name)+' parameter setting GUI'
root_base_id = widget_base(TITLE=title, MODAL=modal, /COL, GROUP_LEADER=group)

; set the status structure
widget_control, root_base_id, SET_UVALUE=state

; parameters base

state.id.par_base = widget_base(root_base_id, FRAME=10, ROW=2)

tel_base = widget_base(state.id.par_base,ROW=2,/FRAME)
dummy = widget_label(tel_base, VALUE='telescope parameters',/FRAME)
tel_base = widget_base(tel_base,/COL)

   tel_base_id = widget_base(tel_base, COL=3)

      state.id.D = cw_field(tel_base_id,          $
                            TITLE='diameter [m]', $
                            /COLUMN,              $
                            VALUE=state.par.D,    $
                            UVALUE='D',           $
                            /FLOATING,            $
                            /ALL_EVENTS           )

      state.id.eps = cw_fslider(tel_base_id,               $
                                TITLE='obscuration ratio', $
                                MAXIMUM=1,                 $
                                SCROLL=.05,                $
                                UVALUE='eps',              $
                                VALUE=state.par.eps,       $
                                /EDIT,                     $
                                /DRAG                      )

   tel_base_id = widget_base(tel_base, COL=2)

      state.id.tel = cw_bgroup(tel_base_id,                 $
                               ['telescope at point [0,0]', $
                                'elsewhere'],               $
                               SET_VALUE=state.par.tel,     $
                               UVALUE='menu_tel',           $
                               COLUMN=2,                    $
                               /EXCLUSIVE                   )

      state.id.tel_base = widget_base(tel_base_id, ROW=2)

         state.id.dist  = cw_field(state.id.tel_base,                     $
                                   TITLE='distance from point [0,0] [m]', $
                                   /COLUMN,                               $
                                   VALUE=state.par.dist,                  $
                                   UVALUE='dist',                         $
                                   /FLOATING,                             $
                                   /ALL_EVENTS                            )

         state.id.angle = cw_field(state.id.tel_base,                     $
                                   TITLE='position angle [deg]         ', $
                                   /COLUMN,                               $
                                   UVALUE='angle',                        $
                                   VALUE=state.par.angle*1.8d2/!DPI,      $
                                   /FLOATING,                             $
                                   /ALL_EVENTS                            )
  
   ; button base for control buttons (standard buttons)
   btn_base_id = widget_base(root_base_id, FRAME=10, /ROW)
      dummy = widget_button(btn_base_id, VALUE="HELP", UVALUE="help")
      cancel_id = widget_button(btn_base_id, VALUE="CANCEL", UVALUE="cancel")
      if modal then widget_control, cancel_id, /CANCEL_BUTTON
      dummy = $
         widget_button(btn_base_id,VALUE="RESTORE PARAMETERS",UVALUE="restore")
      save_id = widget_button(btn_base_id,VALUE="SAVE PARAMETERS",UVALUE="save")
      if modal then widget_control, save_id, /DEFAULT_BUTTON

; final stuff
gpr_set_sensitive, state
widget_control, root_base_id, SET_UVALUE=state
widget_control, root_base_id, /REALIZE

xmanager, 'gpr_gui', root_base_id, GROUP_LEADER=group

return, error
end