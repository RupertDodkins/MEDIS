; $Id: src_gui.pro,v 7.0 2016/04/21 marcel.carbillet $
;+
; NAME:
;    src_gui
;
; PURPOSE:
;    src_gui generates the Graphical User Interface (GUI) for
;    setting the parameters of the SouRCe (SRC) module.
;    a parameter file called src_nnnnn.sav is created, where nnnnn
;    is the number n_module associated to the the module instance.
;    the file is stored in the project directory proj_name located
;    in the working directory.
;
; CATEGORY:
;    Graphical User Interface program
;
; CALLING SEQUENCE:
;    error = src_gui(n_module, proj_name)
;
; INPUTS:
;    n_module : integer scalar. Number associated to the intance
;               of the SRC module. n_module > 0.
;    proj_name: string. Name of the current project.
;
; OUTPUTS:
;    error: long scalar, error code (see !caos_error var in caos_init.pro).
;
; COMMON BLOCKS:
;    none.
;
; CALLED NON_IDL FUNCTIONS:
;    n_phot
;    spec2mag
;
; MODIFICATION HISTORY:
;    program written: july 1998,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : february 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -a few modifications for version 1.0.
;                   : march 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -background stuff using lib-routine n_phot added.
;                   : march 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it],
;                     Bruno  Femenia   (OAA) [bfemenia@arcetri.astro.it]:
;                    -double precision for angles stuff.
;                   : march 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it],
;                     Simone Esposito  (OAA) [esposito@arcetri.astro.it]:
;                    -added 2D-object calculation feature.
;                   : december 1999--april 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -enhanced and adapted to version 2.0 (CAOS).
;                   : september 2001,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -table of source magnitudes for each band added.
;                   : october 2002,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -source magnitudes for each band now actually from parameters file
;                     (were re-calculated at each time before from the V-magnitude).
;                   : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 4.0 of the whole Software System CAOS
;                     (variable "pack_name" added, and variable "mod_type"
;                     changed into "mod_name").
;                    -(src_info()).help stuff added (instead of !caos_env.help).
;                   : december 2004,
;                     Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr]:
;                    -no more crash provoked when controlling the Soft.Pack.
;                     version for existing parameter files - just a warning.
;                    -GUI adapted for small screens.
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; status setting provedure on magnitudes ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
pro mag_gui_set, state

dummy   = n_phot(0., BAND=band)
n_bands = n_elements(band)
dummy   = spec2mag('A0', 0., band[0], SPEC_TAB=spec_type)
for i=0,n_bands-1 do $
   state.par.allstarmag[i] = spec2mag(spec_type[state.par.spec_type], $
                                      state.par.starmag, band[i]      )
widget_control, state.id.allstarmag, SET_VALUE=state.par.allstarmag

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; general status setting provedure ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
pro src_gui_set, state

if (state.par.extended eq 1) then begin
   widget_control, state.id.object,  /SENSITIVE
   widget_control, state.id.mapscale,  /SENSITIVE
endif else begin
   widget_control, state.id.object,  SENSITIVE=0
   widget_control, state.id.mapscale,  SENSITIVE=0
endelse

case state.par.map_type of
   0: begin
      widget_control, state.id.disc,  /SENSITIVE
      widget_control, state.id.gauss, SENSITIVE=0
      widget_control, state.id.map,   SENSITIVE=0
   end
   1: begin
      widget_control, state.id.disc,  SENSITIVE=0
      widget_control, state.id.gauss, /SENSITIVE
      widget_control, state.id.map,   SENSITIVE=0
   end
   2: begin
      widget_control, state.id.disc,  SENSITIVE=0
      widget_control, state.id.gauss, SENSITIVE=0
      widget_control, state.id.map,   /SENSITIVE
   end
endcase

if (state.par.natural eq 0) then begin
   widget_control, state.id.dist_z,       /SENSITIVE
   widget_control, state.id.dist_z,       SET_VALUE=state.par.dist_z/1E3
   widget_control, state.id.spec_type,    SENSITIVE=0
   widget_control, state.id.spec_label,   SENSITIVE=0
   widget_control, state.id.allstarmag,   SENSITIVE=0
   widget_control, state.id.allstarlabel, SENSITIVE=0
endif else begin
   widget_control, state.id.dist_z,       SENSITIVE=0
   widget_control, state.id.spec_type,    /SENSITIVE
   widget_control, state.id.spec_label,   /SENSITIVE
   widget_control, state.id.allstarmag,   /SENSITIVE
   widget_control, state.id.allstarlabel, /SENSITIVE
endelse

end

;;;;;;;;;;;;;;;;;;;
; GUI events loop ;
;;;;;;;;;;;;;;;;;;;
;
pro src_gui_event, event

common error_block, error

widget_control, event.top, GET_UVALUE=state

if tag_names(event, /STRUCTURE_NAME) eq 'WIDGET_KILL_REQUEST' then begin
    error = !caos_error.cancel
    widget_control, event.top, /DESTROY
endif

widget_control, event.id, GET_UVALUE=uvalue

case uvalue of

   'off_axis': begin
      state.par.off_axis = event.value/3600D*!DtoR
      widget_control, event.top, SET_UVALUE=state
   end

   'angle': begin
      state.par.angle = event.value*double(!DtoR)
      widget_control, event.top, SET_UVALUE=state
   end

   'dist_z': begin
      state.par.dist_z = event.value*1E3
      widget_control, event.top, SET_UVALUE=state
   end

   'starmag': begin
      state.par.starmag = event.value
      mag_gui_set, state
      widget_control, event.top, SET_UVALUE=state
   end

   'spec_type': begin
      state.par.spec_type = event.index
      mag_gui_set, state
      widget_control, event.top, SET_UVALUE=state
   end

   'allstarmag': if (event.type eq 0) then begin
      widget_control, event.id,  GET_VALUE =dummy
      state.par.allstarmag = dummy
      widget_control, event.top, SET_UVALUE=state
   endif

   'skymag': if (event.type eq 0) then begin
      widget_control, event.id,  GET_VALUE =dummy
      state.par.skymag = dummy
      widget_control, event.top, SET_UVALUE=state
   endif

   'menu_ext': begin
      state.par.extended = event.value
      src_gui_set, state
      widget_control, event.top, SET_UVALUE=state
   end

   'map_type': begin
      state.par.map_type = event.value
      src_gui_set, state
      widget_control, event.top, SET_UVALUE=state
   end

   'disc': begin
      state.par.disc = event.value/3600D*!DtoR
      widget_control, event.top, SET_UVALUE=state
   end

   'gauss_size': begin
      state.par.gauss_size = event.value/3600D*!DtoR
      widget_control, event.top, SET_UVALUE=state
   end

   'gauss_xwaist': begin
      state.par.gauss_xwaist = event.value/3600D*!DtoR
      widget_control, event.top, SET_UVALUE=state
   end

   'gauss_ywaist': begin
      state.par.gauss_ywaist = event.value/3600D*!DtoR
      widget_control, event.top, SET_UVALUE=state
   end

   'menu_nat': begin
      state.par.natural = event.value
      src_gui_set, state
      widget_control, event.top, SET_UVALUE=state
   end

   'map': begin
      widget_control, event.id,  GET_VALUE =dummy
      state.par.map = dummy[0]
      widget_control, event.top, SET_UVALUE=state
   end

   'mapscale': begin
      state.par.mapscale = event.value/3600D*!DtoR
      widget_control, event.top, SET_UVALUE=state
   end

   'save' : begin

      ; check map scale wrt object size
      if (state.par.extended eq 1) then begin
         if (                                                                $
   (state.par.map_type eq 0 and state.par.mapscale ge state.par.disc) or     $
   (state.par.map_type eq 1 and state.par.mapscale ge state.par.gauss_size)  $
            ) then begin
            dummy = dialog_message(['your 2D source is defined on a number', $
                                    'of pixels less than or equal to one:',  $
                                    'please check it again...'],             $
                                   DIALOG_PARENT=event.top,                  $
                                   TITLE='SRC error',                        $
                                   /ERROR                                    )
            return
         endif
      endif

      if (state.par.natural eq 1) then state.par.dist_z = !VALUES.F_INFINITY

      ; check before saving the parameter file if filename already exists
      check_file = findfile(state.sav_file)
      if check_file[0] ne "" then begin
         answ = dialog_message(['a file '+state.sav_file+' already exists:', $
                                'would you like to overwrite it ?'],         $
                               DIALOG_PARENT=event.top,                      $
                               TITLE='SRC warning',                          $
                               /QUEST                                        )
         if strlowcase(answ) eq "no" then return
      endif else begin
         answ = dialog_message(['file '+state.sav_file+' will be saved.'], $
                               DIALOG_PARENT=event.top,                    $
                               TITLE='SRC information',                    $
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

   'help' : online_help, book=(src_info()).help, /FULL_PATH

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
      dummy = !RADEG*3600D
      widget_control, state.id.off_axis,     SET_VALUE=par.off_axis*dummy
      widget_control, state.id.angle,        SET_VALUE=par.angle*!RADEG
      widget_control, state.id.dist_z,       SET_VALUE=par.dist_z/1e3
      widget_control, state.id.starmag,      SET_VALUE=par.starmag
      widget_control, state.id.allstarmag,   SET_VALUE=par.allstarmag
      widget_control, state.id.skymag,       SET_VALUE=par.skymag
      widget_control, state.id.spec_type,    SET_DROPLIST_SELECT=par.spec_type
      widget_control, state.id.extended,     SET_VALUE=par.extended
      widget_control, state.id.map_type,     SET_VALUE=par.map_type
      widget_control, state.id.disc,         SET_VALUE=par.disc*dummy
      widget_control, state.id.gauss_size,   SET_VALUE=par.gauss_size*dummy
      widget_control, state.id.gauss_xwaist, SET_VALUE=par.gauss_xwaist*dummy
      widget_control, state.id.gauss_ywaist, SET_VALUE=par.gauss_ywaist*dummy
      widget_control, state.id.map,          SET_VALUE=par.map
      widget_control, state.id.mapscale,     SET_VALUE=float(par.mapscale)*dummy

      state.par = par
      src_gui_set, state
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
function src_gui, n_module, proj_name, GROUP_LEADER=group

; error status from the event handler procedure
common error_block, error

; retrieve the module information
info = src_info()

; parameter file checks
sav_file = mk_par_name(info.mod_name, n_module, PROJ_NAME=proj_name)
def_file = mk_par_name(info.mod_name, PACK_NAME=info.pack_name, /DEFAULT)
par=0
check_file = findfile(sav_file)
if check_file[0] eq '' then begin
    restore, def_file
    par.module.n_module = n_module
    if (par.module.mod_name ne info.mod_name) then     $
      message, 'the default parameter file ('+def_file $
              +') is from another module: please take the right one'
   if (par.module.ver ne info.ver) then                $
      message, 'the default parameter file ('+def_file $
              +') is not compatible: please generate it again'
endif else begin
    restore, sav_file
    if (par.module.mod_name ne info.mod_name) then $
      message, 'the parameter file '+sav_file      $
              +' is from another module: please generate a new one'
   if (par.module.ver ne info.ver) then begin
      print, '************************************************************'
      print, 'WARNING: the parameter file '+sav_file
      print, 'is probably from an older version than '+info.pack_name+' !!'
      print, 'You should possibly need to generate it again...'
      print, '************************************************************'
   endif
endelse

; widget id. struc.
id = $
   { $
   off_axis    : 0L, $
   angle       : 0L, $
   dist_z      : 0L, $
   starmag     : 0L, $
   allstarmag  : 0L, $
   allstarlabel: 0L, $
   skymag      : 0L, $
   extended    : 0L, $
   object      : 0L, $
   disc        : 0L, $
   gauss       : 0L, $
   gauss_size  : 0L, $
   gauss_xwaist: 0L, $
   gauss_ywaist: 0L, $
   map_type    : 0L, $
   natural     : 0L, $
   map         : 0L, $
   mapscale    : 0L, $
   spec_type   : 0L, $
   spec_label  : 0L  $
   }

; general state id. struc.
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

   par_base_id = widget_base(root_base_id, FRAME=10, /COL)

      ext_base_id = widget_base(par_base_id, ROW=3, /FRAME)
      dummy = widget_label(ext_base_id, VALUE='source morphology', /FRAME)
      ext_base_id = widget_base(ext_base_id, COL=2)

         dummo = widget_base(ext_base_id, ROW=2)
         state.id.extended = cw_bgroup(dummo,                  $
                                       ['point-like source',         $
                                        'extended 2D-object'],       $
                                       SET_VALUE=state.par.extended, $
                                       UVALUE='menu_ext',            $
                                       /EXCLUSIVE                    )

         state.id.object = widget_base(ext_base_id, ROW=2)

	    dummy = widget_base(state.id.object, COL=2)

               state.id.map_type = cw_bgroup(dummy,                       $
                                            ['uniform disc object',       $
                                             'gaussian object',           $
                                             'user-defined object'],      $
                                            SET_VALUE=state.par.map_type, $
                                            UVALUE='map_type',            $
                                            /EXCLUSIVE                    )

               ext_base_map = widget_base(dummy, ROW=3)
          
                  state.id.disc = cw_field(ext_base_map,                      $
					   TITLE="disc radius [arcsec]: ",    $
                                           VALUE=state.par.disc*!RADEG*3600,  $
					   UVALUE='disc',                     $
					   /ALL_EVENTS                        )

                  state.id.gauss = widget_base(ext_base_map, COL=3)
		     state.id.gauss_size = cw_field(state.id.gauss,         $
                                        TITLE="image size [arcsec]",        $
                                        /COLUMN,                            $
                                        VALUE=                              $
					state.par.gauss_size*!RADEG*3600,   $
                                        UVALUE='gauss_size',                $
                                        /ALL_EVENTS                         ) 
                     state.id.gauss_xwaist = cw_field(state.id.gauss,       $
                                        TITLE="x-waist [arcsec]",           $
                                        /COLUMN,                            $
                                        VALUE=                              $
				        state.par.gauss_xwaist*!RADEG*3600, $
                                        UVALUE='gauss_xwaist',              $
                                        /ALL_EVENTS                         )
                     state.id.gauss_ywaist = cw_field(state.id.gauss,       $
                                        TITLE="y-waist [arcsec]",           $
                                        /COLUMN,                            $
                                        VALUE=                              $
					state.par.gauss_ywaist*!RADEG*3600, $
                                        UVALUE='gauss_ywaist',              $
                                        /ALL_EVENTS                         )

                  state.id.map = cw_field(ext_base_map,                       $
                                    TITLE='extended object map file address', $
                                    /COLUMN,                                  $
                                    VALUE=state.par.map,                      $
                                    UVALUE='map',                             $
                                    /ALL_EVENTS                               )

            state.id.mapscale = cw_field(dummo,                      $
                                         TITLE='map scale [arcsec/px]: ',      $
                                         VALUE=                                $
                                         float(state.par.mapscale)*!RADEG*3600,$
	                                 UVALUE='mapscale',                    $
                                         /ALL_EVENTS                           )

   pos_base_id = widget_base(par_base_id, ROW=2, /FRAME)
   dummy = widget_label(pos_base_id, VALUE='source coordinates', /FRAME)
   pos_base_id = widget_base(pos_base_id, COL=2)

      state.id.natural = cw_bgroup(pos_base_id,                 $
                                   ['laser guide star',         $
                                    'natural object'],          $
                                   SET_VALUE=state.par.natural, $
                                   UVALUE='menu_nat',           $
                                   /EXCLUSIVE                   )

      pos_base_id1 = widget_base(pos_base_id, COLUMN=3)
         state.id.off_axis = cw_field(pos_base_id1,                            $
                                      TITLE='off-axis angle [arcsec]',         $
                                      /COLUMN,                                 $
                                      VALUE=state.par.off_axis*!RADEG*3600D,   $
                                      UVALUE='off_axis',                       $
                                      /FLOATING,                               $
                                      /ALL_EVENTS                              )
            state.id.angle = cw_field(pos_base_id1,                            $
                                      TITLE='position angle [deg]',            $
                                      /COLUMN,                                 $
                                      VALUE=state.par.angle*!RADEG,            $
                                      UVALUE='angle',                          $
                                      /FLOATING,                               $
                                      /ALL_EVENTS                              )
            state.id.dist_z = cw_field(pos_base_id1,                           $
                                       TITLE='laser guide star distance [km]', $
                                       /COLUMN,                                $
                                       VALUE=state.par.dist_z/1E3,             $
                                       UVALUE='dist_z',                        $
                                       /FLOATING,                              $
                                       /ALL_EVENTS                             )

      mag_base_id = widget_base(par_base_id, ROW=2, /FRAME)
      dummy = widget_label(mag_base_id,                     $
                           VALUE='photometry/spectrometry', $
                           /FRAME                           )
      mag_base_id = widget_base(mag_base_id, ROW=3)

         star_base_id = widget_base(mag_base_id, COL=2)

            state.id.starmag = cw_field(star_base_id,                 $
                                        TITLE='source V-magnitude: ', $
                                        VALUE=state.par.starmag,      $
                                        UVALUE='starmag',             $
                                        /FLOATING,                    $
                                        /ALL_EVENTS                   )

            spec_base_id = widget_base(star_base_id, COL=2)
               state.id.spec_label = widget_label(spec_base_id,         $
                                                  VALUE='spectral type:')
               dummy = spec2mag('A0', 0., 'V', SPEC_TAB=spec_type)
               state.id.spec_type = widget_droplist(spec_base_id,     $
                                                    VALUE=spec_type,  $
                                                    UVALUE='spec_type')
               widget_control, state.id.spec_type, $
                               SET_DROPLIST_SELECT=state.par.spec_type

         allstar_base_id = widget_base(mag_base_id, ROW=2)
            state.id.allstarlabel = widget_label(allstar_base_id,      $
                                 VALUE=                                $
                                 "source magnitudes vs. spectral bands")
            dummy = n_phot(0., BAND=band)
            state.id.allstarmag = widget_table(allstar_base_id,    $
                                           ROW_LABELS=['mag.'],    $
                                           COLUMN_LABELS=band,     $
                                           VALUE=state.par.allstarmag, $
                                           UVALUE='allstarmag',        $
                                           /EDITABLE,              $
                                           YSIZE=1                 )

         back_base_id = widget_base(mag_base_id, ROW=2)
            dummy = widget_label(back_base_id,                                 $
                                 VALUE=                                        $
                                 "sky background magnitudes vs. spectral bands")
;            dummy = n_phot(0., BAND=band)
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
src_gui_set, state
widget_control, root_base_id, SET_UVALUE=state
widget_control, root_base_id, /REALIZE
xmanager, 'src_gui', root_base_id, GROUP_LEADER=group

return, error
end