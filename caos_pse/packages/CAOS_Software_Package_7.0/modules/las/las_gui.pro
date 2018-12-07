; $Id: las_gui.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    las_gui
;
; PURPOSE:
;    las_gui generates the Graphical User Interface (GUI) for
;    setting the parameters of the LASer (LAS) module.
;    a parameter file called las_nnnnn.sav is created, where nnnnn
;    is the number n_module associated to the module instance.
;    the file is stored in the project directory proj_name located
;    in the working directory.
;    (see las.pro's header --or file caos_help.html-- for details
;    about the module itself).
;
; CATEGORY:
;    module's Graghical User Interface routine
;
; CALLING SEQUENCE:
;    error = las_gui(n_module, proj_name)
;
; INPUTS:
;    n_module : integer scalar. number associated to the instance
;               of the LAS module. n_module > 0.
;    proj_name: string. name of the current project.
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
;    routine written: july 1998,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : february 1999,
;                     Elise Viard (ESO) [eviard@eso.org]:
;                    -a few modifications for version 1.0.
;                   : march 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -took out the wavelength parameter.
;                   : march 1999,
;                     Bruno Femenia (OAA) [bfemenia@arcetri.astro.it]:
;                    -par.angle & par.off_axis are now double precission.
;                   : december 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -enhanced and adpated to version 2.0 (CAOS).
;                   : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]
;                    -adapted to version 4.0 of the whole Software System CAOS
;                     (variable "pack_name" added, and variable "mod_type"
;                     changed into "mod_name").
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
;;;;;;;;;;;;;;;;;;;
; GUI events loop ;
;;;;;;;;;;;;;;;;;;;
;
pro las_gui_event, event
 
; las_gui error management block
common error_block, error
 
; read the GUI state structure
widget_control, event.top, GET_UVALUE=state

; handle a kill request (considered as a cancel event).
if tag_names(event, /STRUCTURE_NAME) eq 'WIDGET_KILL_REQUEST' then begin
    error = !caos_error.cancel
    widget_control, event.top, /DESTROY
endif

; handle all the other events
widget_control, event.id, GET_UVALUE = uvalue
case uvalue of

   'power': begin
      state.par.power = event.value
      widget_control, event.top, SET_UVALUE=state
   end

   'off_axis': begin
      state.par.off_axis = event.value*!DPI/6.48d5
      widget_control, event.top, SET_UVALUE=state
   end

   'pos_ang': begin
      state.par.pos_ang = event.value*!DPI/1.8d2
      widget_control, event.top, SET_UVALUE=state
   end

   'waist': begin
      state.par.waist = event.value
      widget_control, event.top, SET_UVALUE=state
   end

   'dist_foc': begin
      state.par.dist_foc = event.value*1e3
      widget_control, event.top, SET_UVALUE=state
   end

   'constant': begin
      state.par.constant = event.value
      widget_control, event.top, SET_UVALUE=state
    end

   'save' : begin

     check_file = findfile(state.sav_file)
      if check_file[0] ne "" then begin
         answ = dialog_message(['file '+state.sav_file+' already exists:', $
                                'would you like to overwrite it ?'],       $
                               DIALOG_PARENT=event.top,                    $
                               TITLE='LAS warning',                        $
                               /QUEST                                      )
         ; return without saving if the user doesn't want to overwrite the
         ; existing parameter file
         if strlowcase(answ) eq "no" then return
      endif else begin
         answ = dialog_message(['file '+state.sav_file+' will be saved.'], $
                               DIALOG_PARENT=event.top,                    $
                               TITLE='LAS information',                    $
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
   'help' : online_help, book=(las_info()).help, /FULL_PATH

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
      widget_control, state.id.dist_foc, SET_VALUE=par.dist_foc/1e3
      widget_control, state.id.off_axis, SET_VALUE=par.off_axis*6.48d5/!DPI
      widget_control, state.id.pos_ang,  SET_VALUE=par.pos_ang*1.8d2/!DPI
      widget_control, state.id.power,    SET_VALUE=par.power
      widget_control, state.id.waist,    SET_VALUE=par.waist
      widget_control, state.id.constant, SET_VALUE=par.constant

      ; update the state structure
      state.par = par

      ; write the GUI state structure
      widget_control, event.top, SET_UVALUE=state

   end

   'cancel'  : begin
      error = !caos_error.cancel
      widget_control, event.top, /DESTROY
   end

endcase

end

;;;;;;;;;;;;;;;;;;;;;;;;;
; GUI generation code
;;;;;;;;;;;;;;;;;;;;;;;;;
;
function las_gui, n_module, proj_name, GROUP_LEADER=group

; error status from the event handler procedure
common error_block, error

; get info structure
info = las_info()

; check if a saved parameter file exists. If it exists it is restored,
; otherwise the default parameter file is restored.
sav_file = mk_par_name(info.mod_name, n_module, PROJ_NAME=proj_name)
def_file = mk_par_name(info.mod_name, PACK_NAME=info.pack_name, /DEFAULT)
par=0
check_file = findfile(sav_file)
if check_file[0] eq '' then begin
    restore, def_file            ; restore the par structure
    par.module.n_module = n_module
   if (par.module.mod_name ne info.mod_name) then      $
      message, 'the default parameter file ('+def_file $
              +') is from another module: please take the right one'
   if (par.module.ver ne info.ver) then                $
      message, 'the default parameter file ('+def_file $
              +') is not compatible: please generate it again'
endif else begin
    restore, sav_file            ; restore the par structure
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

; widget identification structure init.
id = $
   { $
   par_base   : 0L, $ ; parameter base id
      power   : 0L, $
      off_axis: 0L, $
      pos_ang : 0L, $
      waist   : 0L, $
      dist_foc: 0L, $
      constant: 0L  $
   }

; general state identification structure init.
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
state.id.par_base = widget_base(root_base_id, FRAME=10, /COL)

   las_base_id = widget_base(state.id.par_base, ROW=3, /FRAME)
      dummy = widget_label(las_base_id, VALUE='laser parameters', /FRAME)

      las_base_id1 = widget_base(las_base_id, COLUMN=2)

         state.id.power = cw_field(las_base_id1,             $
                                   TITLE='laser power [W]:', $
                                   VALUE=state.par.power,    $
                                   UVALUE='power',           $
                                   /FLOATING,                $
                                   /ALL_EVENTS               )

         state.id.waist = cw_field(las_base_id,                            $
            TITLE='gaussian profile waist [units of proj. tel. radius]: ', $
                                   /COLUMN,                                $
                                   VALUE=state.par.waist,                  $
                                   UVALUE='waist',                         $
                                   /FLOATING,                              $
                                   /ALL_EVENTS                             )

   spo_base_id = widget_base(state.id.par_base, ROW=3, /FRAME)
      dummy = widget_label(spo_base_id,                     $
                           VALUE=' Final spot coordinates', $
                           /FRAME                           )

      state.id.dist_foc = cw_field(spo_base_id,                               $
                                   TITLE='proj. tel. focusing distance [km]', $
                                   VALUE=state.par.dist_foc/1e3,              $
                                   UVALUE='dist_foc',                         $
                                   /FLOATING,                                 $
                                   /ALL_EVENTS                                )

      spo_base_id1 = widget_base(spo_base_id, ROW=2)
       
         dummy = widget_label(spo_base_id1,                                   $
       VALUE= 'with respect to z-axis of system centered at launch telescope:')
       
         spo_base_id2 = widget_base(spo_base_id1, COLUMN=2)

            state.id.off_axis = cw_field(spo_base_id2,                        $
                                         TITLE='Zenith angle [arcsec]',       $
                                         /COLUMN,                             $
                                         VALUE=                               $
                                            state.par.off_axis*(6.48d5/!DPI), $
                                         UVALUE='off_axis',                   $
                                         /FLOATING,                           $
                                         /ALL_EVENTS                          )

            state.id.pos_ang = cw_field(spo_base_id2,                         $
                                        TITLE='Azimut [deg]',                 $
                                        /COLUMN,                              $
                                        VALUE=state.par.pos_ang*(1.8d2/!DPI), $
                                        UVALUE='pos_ang',                     $
                                        /FLOATING,                            $
                                        /ALL_EVENTS                           )

   constant_base_id = widget_base(state.id.par_base, /FRAME, ROW=2)
 
      state.id.constant = cw_bgroup(constant_base_id,                          $
                                    label_top=                                 $
                                    'Do you want to compute the laser spot:',  $
                                     ['at each step','Only at the first step'],$
                                     COLUMN=2,                                 $
                                     SET_VALUE=state.par.constant,             $
                                     /EXCLUSIVE,                               $
                                     UVALUE='constant'                         )

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
widget_control, root_base_id, SET_UVALUE=state
widget_control, root_base_id, /REALIZE

xmanager, 'las_gui', root_base_id, GROUP_LEADER=group

return, error
end