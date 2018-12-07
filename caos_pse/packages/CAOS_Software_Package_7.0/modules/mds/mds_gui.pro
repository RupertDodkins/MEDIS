; $Id: mds_gui.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    mds_gui
;
; PURPOSE:
;    mds_gui generates the Graphical User Interface (GUI) for
;    setting the parameters of the Mirror Deformation Sequencer (MDS) module.
;    A parameter file called atm_nnnnn.sav is created, where nnnnn
;    is the number n_module associated to the module instance.
;    The file is stored in the project directory proj_name located
;    in the working directory.
;    (see atm.pro's header --or file caos_help.html-- for details
;    about the module itself).
;
; CATEGORY:
;    module's Graphical User Interface routine
;
; CALLING SEQUENCE:
;    error = mds_gui(n_module, proj_name)
; 
; INPUTS:
;    n_module:  integer scalar. number associated to the intance
;               of the MDS module. n_module > 0.
;    proj_name: string. name of the current project.
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
;    program written: june 2002,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it],
;                     Christophe Verinaud (OAA) [verinaud@arcetri.astro.it].
;    modifications  : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]
;                    -adapted to version 4.0 of the whole Software System CAOS
;                     (variable "pack_name" added, and variable "mod_type"
;                     changed into "mod_name").
;                    -(mds_info()).help stuff added (instead of !caos_env.help).
;                    -PZT influence functions generation parameters added.
;                   : december 2004,
;                     Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr]:
;                    -no more crash provoked when controlling the Soft.Pack.
;                     version for existing parameter files - just a warning.
;                   : december 2010,
;                     Marcel Carbillet (Fizeau) [marcel.carbillet@unice.fr]:
;                    -"already-computed" option clarified.
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; status setting procedure ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
pro mds_gui_set, state, event

widget_control, /HOURGLASS

case state.par.mirdef_choice of
   0: begin
      widget_control, state.id.mirdef_file,     /SENSITIVE
      widget_control, state.id.zern_rad_degree,  SENSITIVE=0
      widget_control, state.id.dim,              SENSITIVE=0
      widget_control, state.id.nb_act,           SENSITIVE=0
      widget_control, state.id.eps,              SENSITIVE=0
      widget_control, state.id.note,            /SENSITIVE
   end
   1: begin
      widget_control, state.id.mirdef_file,      SENSITIVE=0
      widget_control, state.id.zern_rad_degree, /SENSITIVE
      widget_control, state.id.dim,             /SENSITIVE
      widget_control, state.id.nb_act,           SENSITIVE=0
      widget_control, state.id.eps,              SENSITIVE=0
      widget_control, state.id.note,             SENSITIVE=0
   end
   2: begin
      widget_control, state.id.mirdef_file,      SENSITIVE=0
      widget_control, state.id.zern_rad_degree,  SENSITIVE=0
      widget_control, state.id.dim,             /SENSITIVE
      widget_control, state.id.nb_act,          /SENSITIVE
      widget_control, state.id.eps,             /SENSITIVE
      widget_control, state.id.note,             SENSITIVE=0
   end
   3: begin
      widget_control, state.id.mirdef_file,      SENSITIVE=0
      widget_control, state.id.zern_rad_degree,  SENSITIVE=0
      widget_control, state.id.dim,              SENSITIVE=0
      widget_control, state.id.nb_act,           SENSITIVE=0
      widget_control, state.id.eps,              SENSITIVE=0
      widget_control, state.id.note,             SENSITIVE=0
      
      dummy = dialog_message('bimorph case not yet implemented (... wanna do it ?)', $
                             DIALOG_PARENT=event.top,TITLE='MDS information', /INFO)
   end
endcase

end

;;;;;;;;;;;;;;;;;;;
; GUI events loop ;
;;;;;;;;;;;;;;;;;;;
;
pro mds_gui_event, event

common error_block, error

; read the GUI state structure
widget_control, event.top, GET_UVALUE=state

; handle a kill request (considered as a cancel event).
if tag_names(event, /STRUCTURE_NAME) eq 'WIDGET_KILL_REQUEST' then begin
   error = !caos_error.cancel
   widget_control, event.top, /DESTROY
endif

; handle all the other events.
widget_control, event.id, GET_UVALUE=uvalue
case uvalue of

   'mirdef_choice': begin
      state.par.mirdef_choice = event.value
      mds_gui_set, state, event
      widget_control, event.top, SET_UVALUE=state
   end

   'length': begin
      state.par.length = event.value
      widget_control, event.top, SET_UVALUE=state
   end

   'alt': begin
      state.par.alt = event.value
      widget_control, event.top, SET_UVALUE=state
   end

   'mirdef_choice': begin
      state.par.mirdef_choice = event.value
      widget_control, event.top, SET_UVALUE=state
   end

   'mirdef_file': begin
      state.par.mirdef_file = event.value
      widget_control, event.top, SET_UVALUE=state
   end

   'dim': begin
      state.par.dim = event.value
      widget_control, event.top, SET_UVALUE=state
   end

   'zern_rad_degree': BEGIN 
      state.par.zern_rad_degree = event.value
      WIDGET_CONTROL, event.top, SET_UVALUE=state
   END 

   'nb_act': begin
      state.par.nb_act = event.value
      widget_control, event.top, SET_UVALUE=state
   end

   'eps': begin
      state.par.eps = event.value
      widget_control, event.top, SET_UVALUE=state
   end

   'mirdef_amplitude': BEGIN 
      state.par.mirdef_amplitude = event.value
      WIDGET_CONTROL, event.top, SET_UVALUE=state
   END 

   'save': begin

      ; first (dummy) checks...
      if (state.par.length le 0.) then begin
         dummy = dialog_message("screens' length MUST BE greater than zero", $
                                DIALOG_PARENT=event.top,                     $
                                TITLE='MDS error',                           $
                                /ERROR                                       )
         return
      endif
      if (state.par.dim le 0) then begin
         dummy = dialog_message("screens' dimension MUST BE greater than zero",$
                                DIALOG_PARENT=event.top,                       $
                                TITLE='MDS error',                             $
                                /ERROR                                         )
         return
      endif

      ; check if the phase screens lin. nb of px is even

      if (state.par.dim/2 ne state.par.dim/float(2)) then begin
         dummy = dialog_message(                            $
            'phase screens linear nb of pix. MUST BE even', $
            DIALOG_PARENT=event.top, TITLE='MDS error', /ERROR)
         return
      endif

      ; check before saving the parameter file if filename already exists
      check_file = findfile(state.sav_file)
      if check_file[0] ne "" then begin
         dummy = dialog_message(['file '+state.sav_file+' already exists.', $
            'would you like to overwrite it ?'],                            $
            DIALOG_PARENT=event.top, TITLE='MDS warning', /QUEST)
         if strlowcase(dummy) eq "no" then return
      endif else begin
         dummy = dialog_message(['file '+state.sav_file+' will be saved.'], $
                                DIALOG_PARENT=event.top,                    $
                                TITLE='MDS information',                    $
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

   'help' : online_help, book=(mds_info()).help, /FULL_PATH

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
      widget_control, state.id.length,          SET_VALUE=par.length
      widget_control, state.id.dim,             SET_VALUE=par.dim
      widget_control, state.id.alt,             SET_VALUE=par.alt
      widget_control, state.id.mirdef_choice,   SET_VALUE=par.mirdef_choice
      widget_control, state.id.mirdef_file,     SET_VALUE=par.mirdef_file
      widget_control, state.id.mirdef_amplitude,SET_VALUE=par.mirdef_amplitude
      widget_control, state.id.nb_act,          SET_VALUE=par.nb_act
      widget_control, state.id.eps,             SET_VALUE=par.eps
      widget_control, state.id.zern_rad_degree, SET_VALUE=par.zern_rad_degree

      ; update the state structure
      state.par = par

      ; reset the setting parameters status
      mds_gui_set, state, event

      ; write the GUI state structure
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
function mds_gui, n_module, proj_name, GROUP_LEADER=group

; error status from the event handler procedure
common error_block, error

; retrieve the module information
info = mds_info()

; check if a saved parameter file exists. If it exists it is restored,
; otherwise the default parameter file is restored.
sav_file = mk_par_name(info.mod_name, n_module, PROJ_NAME=proj_name)
def_file = mk_par_name(info.mod_name, PACK_NAME=info.pack_name, /DEFAULT)
par = 0
check_file = findfile(sav_file)
if check_file[0] eq '' then begin
   restore, def_file
   par.module.n_module = n_module
   if par.module.mod_name ne info.mod_name then        $
      message, 'the default parameter file ('+def_file $
              +') is from another module: please take the right one'
   if (par.module.ver ne info.ver) then       $
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
   par_base       : 0L, $
   length         : 0L, $
   dim            : 0L, $
   alt            : 0L, $
   mirdef_choice  : 0L, $
   note           : 0L, $
   mirdef_file    : 0L, $
   mirdef_amplitude: 0L,$
   nb_act         : 0L, $
   eps            : 0L, $
   zern_rad_degree: 0L  $
   }

state = $
   {    $
   sav_file: sav_file, $
   def_file: def_file, $
   id      : id,       $
   par     : par       $
   }

modal = n_elements(group) ne 0
title = strupcase(info.mod_name)+" parameters setting GUI"
root_base_id = widget_base(TITLE=title, MODAL=modal, /COL, GROUP_LEADER=group)
widget_control, root_base_id, SET_UVALUE=state
   
   ; parameters base
   state.id.par_base = widget_base(root_base_id, FRAME=10, ROW=2)
   dummy = widget_label(state.id.par_base, VALUE='parameters', /FRAME)
   par_base_id = widget_base(state.id.par_base, /COL)

      dummy = widget_base(par_base_id, /ROW)

         state.id.length = cw_field(dummy,                               $
                                    TITLE="pupil's physical length [m]", $
                                    /COLUMN,                             $
                                    VALUE=state.par.length,              $
                                    UVALUE='length',                     $
                                    /FLOATING,                           $
                                    /ALL_EVENTS                          )

         state.id.alt = cw_field(dummy,                                   $
                                 TITLE='mirror conjugation altitude [m]', $
                                 /COLUMN,                                 $
                                 VALUE=state.par.alt,                     $
                                 UVALUE='alt',                            $
                                 /FLOATING,                               $
                                 /ALL_EVENTS                              )

      dummy = widget_base(par_base_id, /COL, /FRAME)
         dummu = widget_label(dummy, VALUE='type of mirror deformations sequence:')
         state.id.mirdef_choice = cw_bgroup(dummy,                                                            $
                                            ["already-comp'd mirror deformations (file must be named 'DEF')", $
                                             'Zernike polynomials',                                           $
                                             '(modelized) piezoelectric (PZT) influence functions',           $
                                             '(modelized) bimorph influence functions'],                      $
                                            SET_VALUE=state.par.mirdef_choice,   $
                                            UVALUE='mirdef_choice',              $
                                            ROW=4,                               $
                                            /EXCLUSIVE                           )
        state.id.note = WIDGET_LABEL(dummy,                                               $
        VALUE=' NOTE: In the case of user-defined mirror deformations, the  '+string(10B) $
             +'       deformations array must have been named DEF and saved '+string(10B) $
             +'       using the IDL "save" routine.                         ', /FRAME)
 
      state.id.mirdef_file = cw_filename(par_base_id,                                       $
                                         TITLE=                                             $
                                         'mirror deformations filename                    ',$
                                         VALUE=state.par.mirdef_file,                       $
                                         UVALUE='mirdef_file',                              $
                                         /ALL_EVENTS                                        )

      dummy = widget_base(par_base_id, /ROW)
         state.id.dim = cw_field(dummy,                               $
                                 TITLE='linear number of pixels    ', $
                                 /COLUMN,                             $
                                 VALUE=state.par.dim,                 $
                                 UVALUE='dim',                        $
                                 /INTEGER,                            $
                                 /ALL_EVENTS                          )
         state.id.zern_rad_degree = cw_field(dummy,                                    $
                                             TITLE='maximum Zernike radial degree   ', $
                                             VALUE=state.par.zern_rad_degree,          $
                                             /INTEGER,                                 $
                                             UVALUE='zern_rad_degree',                 $
                                             /ALL_EVENTS,                              $
                                             /COLUMN                                   )

      dummy = widget_base(par_base_id, /ROW)
         state.id.nb_act = cw_field(dummy,                               $
                                    TITLE='linear number of actuators ', $
                                    VALUE=state.par.nb_act,              $
                                    UVALUE="nb_act",                     $
                                    /ALL_EVENTS,                         $
                                    /COLUMN,                             $
                                    /INTEGER                            )

         state.id.eps = cw_field(dummy,                                    $
                                 TITLE='mirror central obscuration      ', $
                                 VALUE=state.par.eps,                      $
                                 UVALUE="eps",                             $
                                 /ALL_EVENTS,                              $
                                 /COLUMN,                                  $
                                 /INTEGER                                  )

      state.id.mirdef_amplitude = cw_field(par_base_id,                                 $
                                        TITLE='maximum mirror deformations amplitude:', $
                                        VALUE=state.par.mirdef_amplitude,               $
                                        /FLOATING,                                      $
                                        UVALUE='mirdef_amplitude',                      $
                                        /ALL_EVENTS,                                    $
                                        /ROW                                            )

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

; initialize all the sensitive states
mds_gui_set, state, event

; save the state structure of the GUI in the top base uvalue
widget_control, root_base_id, SET_UVALUE=state

; draw the GUI
widget_control, root_base_id, /REALIZE

xmanager, 'mds_gui', root_base_id, GROUP_LEADER=group

return, error
end