; $Id: aic_gui.pro,v 7.0 2016/05/19 marcel.carbillet$
;+
; NAME:
;    aic_gui
;
; PURPOSE:
;    aic_gui generates the Graphical User Interface (GUI) for
;    setting the parameters of the Achrom. Interf. Coronagraph (AIC) module.
;    A parameter file called aic_nnnnn.sav is created, where nnnnn
;    is the number n_module associated to the the module instance.
;    The file is stored in the project directory proj_name located
;    in the working directory.
;    (see aic.pro's header --or file caos_help.html-- for details
;    about the module itself).
;
; CATEGORY:
;    module's Graghical User Interface routine
;
; CALLING SEQUENCE:
;    error = aic_gui(n_module, proj_name)
;
; INPUTS:
;    n_module : integer scalar. Number associated to the intance
;               of the AIC module. n_module > 0.
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
;    program written: september 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it],
;                     Christophe Verinaud (ESO) [cverinau@eso.org]:
;    modifications  : december 2004,
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
;-
;
;;;;;;;;;;;;;;;;;;;
; GUI events loop ;
;;;;;;;;;;;;;;;;;;;
;
pro aic_gui_event, event

common error_block, error

widget_control, event.top, GET_UVALUE=state

if tag_names(event, /STRUCTURE_NAME) eq 'WIDGET_KILL_REQUEST' then begin
    error = !caos_error.cancel
    widget_control, event.top, /DESTROY
endif

widget_control, event.id, GET_UVALUE = uvalue

case uvalue of

   'Rfac'        : state.par.Rfac = event.value

   'Tfac'        : state.par.Tfac = event.value

   'psf_sampling': state.par.psf_sampling = event.value

   'band'        : state.par.band = event.value

   'pos_ang'     : state.par.pos_ang = event.value

   'off_axis'    : state.par.off_axis = event.value

   'int_ratio'   : state.par.int_ratio = event.value

   'save': begin

      ; check before saving the parameter file if filename already exists
      check_file = findfile(state.sav_file)
      if check_file[0] ne "" then begin
         answ = dialog_message(['a file '+state.sav_file+' already exists.', $
                               'would you like to overwrite it?'], $
                                  dialog_parent = event.top, $
                                  title = 'AIC warning', /QUEST)
         ; return without saving if the user doesn't want to overwrite the
         ; existing parameter file
         if strlowcase(answ) eq "no" then return
      endif else begin
         answ = dialog_message(['file '+state.sav_file+' will be saved.'], $
                               DIALOG_PARENT=event.top,                    $
                               TITLE='AIC information',                    $
                               /INFO                                       )
         ; inform were the parameters will be saved
      endelse

      ; save the parameter data file
      par = state.par
      save, par, FILENAME=state.sav_file

      ; kill the GUI returning a null error
      error = !caos_error.ok
      widget_control, event.top, /DESTROY
      return

   end

   ; standard help button
   'help' : online_help, book=(aic_info()).help, /FULL_PATH

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

      widget_control, state.id.Rfac,         SET_VALUE=par.Rfac
      widget_control, state.id.Tfac,         SET_VALUE=par.Tfac
      widget_control, state.id.psf_sampling, SET_VALUE=par.psf_sampling
      widget_control, state.id.band,         SET_VALUE=par.band
      WIDGET_CONTROL, state.id.pos_ang,      SET_VALUE=par.pos_ang
      WIDGET_CONTROL, state.id.off_axis,     SET_VALUE=par.off_axis
      WIDGET_CONTROL, state.id.int_ratio,    SET_VALUE=par.int_ratio
      state.par = par
     
   end

   'cancel'  : begin
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
function aic_gui, n_module, proj_name, GROUP_LEADER=group

; error status from the event handler procedure
common error_block, error

; retrieve the module information
info = aic_info()

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
   par_base    : 0L, $ ; parameter base id
   Rfac        : 0L, $
   Tfac        : 0L, $
   psf_sampling: 0L, $
   band        : 0L, $
   planet      : 0L, $
   off_axis    : 0L, $
   pos_ang     : 0L, $
   int_ratio   : 0L  $
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
   dummy = widget_label(state.id.par_base, VALUE='parameters',/FRAME)
   state.id.par_base = widget_base(state.id.par_base, /COL)

      dummy = widget_base(state.id.par_base, /COL)

      dummy1 = widget_base(dummy, /ROW)

      state.id.Rfac = cw_field(dummy1,                      $
                              TITLE='reflexion factor', $
                              /COLUMN,                          $
                              VALUE=state.par.Rfac,         $
                              UVALUE='Rfac',                $
                              /FLOATING,                        $
                              /ALL_EVENTS                       )

      state.id.Tfac = cw_field(dummy1,                     $
                              TITLE='transmission factor', $
                              /COLUMN,                     $
                              VALUE=state.par.Tfac,                  $
                              UVALUE='Tfac',                         $
                              /FLOATING,                              $
                              /ALL_EVENTS                             )

      state.id.psf_sampling = cw_field(dummy1,                           $
                              TITLE='sampling points per lambda/D [px]', $
                              /COLUMN,                                   $
                              VALUE=state.par.psf_sampling,              $
                              UVALUE='psf_sampling',                     $
                              /INTEGER,                                  $
                              /ALL_EVENTS                                )

      nada = widget_label(dummy, VALUE=' ')

      dumdumdum = n_phot(0., BAND=band_tab)
      n_band = N_ELEMENTS(band_tab)
      value  = where(band_tab eq par.band)
      state.id.band = CW_BGROUP(dummy,                         $
                                LABEL_LEFT='Observing band: ', $
                                band_tab, /ROW,                $
                                BUTTON_UVALUE=indgen(n_band),  $
                                SET_VALUE=value,               $
                                UVALUE='band',                 $
                                /EXCLUSIVE                     )

      nada = widget_label(state.id.par_base, VALUE=' ')

      state.id.planet = widget_base(state.id.par_base, ROW=2, /FRAME)
      dummy = WIDGET_LABEL(state.id.planet, VALUE='companion/planet characteristics', /FRAME)
      planet_base_id = WIDGET_BASE(state.id.planet, /ROW)

      state.id.off_axis = cw_field(planet_base_id,                             $
                                          TITLE='companion off-axis [arcsec]', $
                                          /COLUMN,                             $
                                          VALUE=state.par.off_axis,            $
                                          UVALUE='off_axis',                   $
                                          /FLOATING,                           $
                                          /ALL_EVENTS                          )

      state.id.pos_ang = cw_field(planet_base_id,                                $
                                         TITLE='companion position angle [deg]', $
                                         /COLUMN,                                $
                                         VALUE=state.par.pos_ang,                $
                                         UVALUE='pos_ang',                       $
                                         /FLOATING,                              $
                                         /ALL_EVENTS                             )

      state.id.int_ratio = cw_field(planet_base_id,                           $
                                           TITLE='companion intensity ratio', $
                                           /COLUMN,                           $
                                           VALUE=state.par.int_ratio,         $
                                           UVALUE='int_ratio',                $
                                           /FLOATING,                         $
                                           /ALL_EVENTS                        )

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
widget_control, root_base_id, SET_UVALUE=state
widget_control, root_base_id, /REALIZE

xmanager, 'aic_gui', root_base_id, GROUP_LEADER=group

return, error
end