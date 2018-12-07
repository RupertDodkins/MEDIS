; $Id: nls_gui.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    nls_gui
;
; PURPOSE:
;    nls_gui generates the Graphical User Interface (GUI) for
;    setting the parameters of the Na-Layer Spot (NLS) module.
;    A parameter file called las_nnnnn.sav is created, where nnnnn
;    is the number n_module associated to the the module instance.
;    The file is stored in the project directory proj_name located
;    in the working directory.
;    (see nls.pro's header --or file caos_help.html-- for details
;    about the module itself).
;
; CATEGORY:
;    module's Graghical User Interface routine
;
; CALLING SEQUENCE:
;    error = nls_gui(n_module, proj_name)
;
; INPUTS:
;    n_module : integer scalar. Number associated to the instance
;               of the NLS module. n_module > 0.
;    proj_name: string. Name of the current project.
;
; OUTPUTS:
;    error: error code [long scalar].
;
; CALLED NON-IDL FUNCTIONS:
;    nls_coord
;    nls_defocus
;    nls_density
;    nls_map
;
; MODIFICATION HISTORY:
;    program written: october 1998,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : january 1999,
;                     Elise Viard (ESO) [eviard@eso.org]:
;                    -modifications for version 1.0.
;                   : march 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -reordening, debugging and version 1.0 standardization.
;                    -background stuff added.
;                   : december 1999--february 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -enhanced and adapted to version 2.0 (CAOS).
;                   : may 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -the effective Na backscatter cross section (ecs)
;                     parameter and the atmosphere transmission (trans)
;                     parameter have no more a value fixed within nls_init.pro
;                     but are part of the free parameters set.
;                    -call to help file debugged.
;                   : january-march 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]
;                    -adapted to version 4.0 of the whole Software System CAOS
;                     (variable "pack_name" added, and variable "mod_type"
;                     changed into "mod_name").
;                    -(nls_info()).help stuff added (instead of !caos_env.help).
;                    -sky magnitude stuff debugged.
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
pro nls_gui_set, state

if (state.par.own EQ 0) THEN BEGIN
   widget_control, state.id.alt,   /SENSITIVE
   widget_control, state.id.width, /SENSITIVE
   widget_control, state.id.n_sub, /SENSITIVE
   widget_control, state.id.Na,    SENSITIVE=0
endif else begin
   widget_control, state.id.alt,   SENSITIVE=0
   widget_control, state.id.width, SENSITIVE=0
   widget_control, state.id.n_sub, SENSITIVE=0
   widget_control, state.id.Na,    /SENSITIVE
endelse

end

pro nls_gui_event, event

common error_block, error

widget_control, event.top, GET_UVALUE=state

if tag_names(event, /STRUCTURE_NAME) eq 'WIDGET_KILL_REQUEST' then begin
    error = !caos_error.cancel
    widget_control, event.top, /DESTROY
endif

widget_control, event.id, GET_UVALUE=uvalue
case uvalue of

   ; handle parameters events
   'alt'     : state.par.alt = event.value*1e3
   'width'   : state.par.width = event.value*1e3
   'n_sub'   : state.par.n_sub = event.value
   'skymag'  : if (event.type eq 0) then begin
                  widget_control, event.id, GET_VALUE=dummy
                  state.par.skymag = dummy
               endif
   'menu_nal': begin
      state.par.own = event.value
      nls_gui_set, state
   end
   'Na'      : state.par.Na = event.value
   'ecs'     : state.par.ecs = event.value
   'trans'   : state.par.trans = event.value

   ; handle event from standard save button
   'save'    : begin

      check_file = findfile(state.sav_file)
      if check_file[0] ne "" then begin
         answ = dialog_message(['file '+state.sav_file+' already exists:', $
                                'would you like to overwrite it ?'],       $
                               DIALOG_PARENT=event.top,                    $
                               TITLE='NLS warning',                        $
                               /QUEST                                      )
         if strlowcase(answ) eq "no" then return
      endif else begin
         answ = dialog_message(['file '+state.sav_file+' will be saved.'], $
                               DIALOG_PARENT=event.top,                    $
                               TITLE='NLS information',                    $
                               /INFO                                       )
      endelse

      par = state.par
      save, par, FILENAME=state.sav_file

      error = !caos_error.ok
      widget_control, event.top, /DESTROY
      return

   end

   ; standard help button
   'help' : online_help, book=(nls_info()).help, /FULL_PATH

   ; standard restore button:
   'restore' : begin

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

      widget_control, state.id.alt,    SET_VALUE=par.alt/1e3
      widget_control, state.id.width,  SET_VALUE=par.width/1e3
      widget_control, state.id.n_sub,  SET_VALUE=par.n_sub
      widget_control, state.id.skymag, SET_VALUE=par.skymag
      widget_control, state.id.own,    SET_VALUE=par.own
      widget_control, state.id.Na,     SET_VALUE=par.Na
      widget_control, state.id.ecs,    SET_VALUE=par.ecs
      widget_control, state.id.trans,  SET_VALUE=par.trans

      state.par = par

   end

   'cancel'  : begin
      error = !caos_error.cancel
      widget_control, event.top, /DESTROY
      return
   end

endcase

nls_gui_set, state
widget_control, event.top, SET_UVALUE=state

return

end

;;;;;;;;;;;;;;;;;;;;;;;;;
; GUI generation code
;;;;;;;;;;;;;;;;;;;;;;;;;
;
function nls_gui, n_module, proj_name, GROUP_LEADER=group

common error_block, error

info = nls_info()

; check if a saved parameter file exists. If it exists it is restored,
; otherwise the default parameter file is restored.
sav_file = mk_par_name(info.mod_name, n_module, PROJ_NAME=proj_name)
def_file = mk_par_name(info.mod_name, PACK_NAME=info.pack_name, /DEFAULT)
par=0
check_file = findfile(sav_file)
if check_file[0] eq '' then begin
    restore, def_file           ; restore the par structure
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

id = $
   { $
   par_base    : 0L, $ ; parameter base id
      alt      : 0L, $
      width    : 0L, $
      n_sub    : 0L, $
      skymag   : 0L, $
      own      : 0L, $
      Na       : 0L, $
      ecs      : 0L, $
      trans    : 0L  $
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
title = strupcase(info.mod_name)+' parameter setting GUI'
root_base_id = widget_base(TITLE=title, MODAL=modal, /COL, GROUP_LEADER=group)
widget_control, root_base_id, SET_UVALUE=state

   ; parameters base
   state.id.par_base = widget_base(root_base_id, FRAME=10, ROW=2)
   dummy = widget_label(state.id.par_base, VALUE='parameters', /FRAME)
   state.id.par_base = widget_base(state.id.par_base, /COL)

      nal_base_id = widget_base(state.id.par_base, ROW=4, /FRAME)

         dummy = widget_label(nal_base_id,                      $
                              VALUE='Na layer characteristics', $
                              /FRAME                            )

         dummy = widget_base(nal_base_id, COL=2)

            state.id.own = cw_bgroup(dummy,                                  $
                                     ['gaussian Na profile',                 $
                                      'user-defined Na profile'],            $
                                     COLUMN=2, BUTTON_UVALUE=[0, 1],         $
                                     SET_VALUE=state.par.own,                $
                                     UVALUE='menu_nal',                      $
                                     /EXCLUSIVE                              )

            state.id.Na = cw_filename(dummy,                               $
                                   TITLE=                                  $
                                   'user-defined Na profile file address', $
                                   VALUE=state.par.Na,                     $
                                   UVALUE='Na',                            $
                                   /RETURN_EVENTS                          )


         dummy = widget_base(nal_base_id, COL=3)

            state.id.alt = cw_field(dummy,                                 $
                                    TITLE='mean altitude [km]'+string(10B) $
                                         +'(wrt telescope altitude): ',    $
                                    VALUE=state.par.alt/1e3,               $
                                    UVALUE='alt',                          $
                                    /FLOATING,                             $
                                    /ALL_EVENTS                            )

            state.id.width = cw_field(dummy,                          $
                                      TITLE='width [km]: ',           $
                                      VALUE=state.par.width/1e3,      $
                                      UVALUE='width',                 $
                                      /FLOATING,                      $
                                      /ALL_EVENTS                     )

            state.id.n_sub = cw_field(dummy,                          $
                                      TITLE='number of sub-layers: ', $
                                      VALUE=state.par.n_sub,          $
                                      UVALUE='n_sub',                 $
                                      /FLOATING,                      $
                                      /ALL_EVENTS                     )

         dummy = widget_base(nal_base_id, COL=2)

            state.id.ecs = cw_field(dummy,                                     $
                           TITLE='effective backscatter cross section [m^2]: ',$
                                    VALUE=state.par.ecs,                       $
                                    UVALUE='ecs',                              $
                                    /FLOATING,                                 $
                                    /ALL_EVENTS                                )

            state.id.trans = cw_field(dummy,                           $
                                    TITLE='atmosphere transmission: ', $
                                    VALUE=state.par.trans,             $
                                    UVALUE='trans',                    $
                                    /FLOATING,                         $
                                    /ALL_EVENTS                        )

      back_base_id = widget_base(state.id.par_base, ROW=2, /FRAME)
         dummy = widget_label(back_base_id,                               $
                    VALUE="sky background magnitudes vs. spectral bands", $
                    /FRAME)
         dummy = n_phot(0., BAND=band)         
         state.id.skymag = widget_table(back_base_id,           $
                                        ROW_LABELS=['mag.'],    $
                                        COLUMN_LABELS=band,     $
                                        VALUE=state.par.skymag, $
                                        UVALUE='skymag',        $
                                        /EDITABLE,              $
                                        YSIZE=1                 )

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
nls_gui_set, state
widget_control, root_base_id, SET_UVALUE=state
widget_control, root_base_id, /REALIZE
xmanager, 'nls_gui', root_base_id, GROUP_LEADER=group

return, error
end