; $Id: sav_gui.pro,v 7.0 2016/05/03 marcel.carbillet $
;+
; NAME:
;    sav_gui
;
; PURPOSE:
;    sav_gui generates the Graphical User Interface (GUI) for
;    setting the parameters of the sav module.
;    A parameter file called sav_nnnnn.sav is created, where nnnnn
;    is the number n_module associated to the module instance.
;    The file is stored in the project directory proj_name located
;    in the working directory.
;
; CATEGORY:
;    module's Graghical User Interface routine
;
; CALLING SEQUENCE:
;    error = sav_gui(n_module, proj_name)
; 
; INPUTS:
;    n_module : integer scalar. Number associated to the intance
;               of the sav module. n_module > 0.
;    proj_name: string. Name of the current project.
;
; OUTPUTS:
;    error: error code [long scalar]
;
; COMMON BLOCKS:
;    none.
;
; CALLED NON-IDL FUNCTIONS:
;    none.
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: march 1999,
;                     Simone Esposito (OAA) [esposito@arcetri.astro.it].
;    modifications  : march 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -dialog-message widgets added in order to prevent
;                     appending new output structures to an already saved
;                     file, if not desired.
;                   : june 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -the "nb of iterations" widget is now a "cw_field"
;                     instead of a "widget_slider" limited to 100 iterations.
;                   : december 1999--january 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -enhanced and adapted to version 2.0 (CAOS).
;                   : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]
;                    -adapted to version 4.0 of the whole Software System CAOS
;                     (variable "pack_name" added, and variable "mod_type"
;                     changed into "mod_name").
;                    -(sav_info()).help stuff added (instead of !caos_env.help).
;                   : december 2004,
;                     Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr]:
;                    -no more crash provoked when controlling the Soft.Pack.
;                     version for existing parameter files - just a warning.
;                   : february 2007,
;                     Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr]:
;                    -control of the the Soft.Pack. debugged (the warning was
;                     here *always* (partly) printed )...
;                   : may 2016,
;                     Ulysse Perruchon-Monge & Adama Sy (Dépt.Physique UNS),
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -moved from Soft.Pack.CAOS 5.2 to new package "Utilities"
;                     of new version (7.0) of the CAOS PSE,
;                    -simple IDL "save" format and FITS format added.
;
;-
;
;;;;;;;;;;;;;;;;;;;;;;
; sav_gui event loop ;
;;;;;;;;;;;;;;;;;;;;;;
;
pro sav_gui_event, event

common error_block, error

; read the GUI state structure
widget_control, event.top, GET_UVALUE=state

; handle a kill request (considered as a cancel event).
if tag_names(event, /STRUCTURE_NAME) eq 'WIDGET_KILL_REQUEST' then begin
   error = !caos_error.cancel
   widget_control, event.top, /DESTROY
endif

; handle other events.
widget_control, event.id, GET_UVALUE=uvalue
case uvalue of

    'save_data': begin
        state.par.data_file = event.value
        widget_control, event.top, SET_UVALUE=state
    end
    
    'iteration': begin
        state.par.iteration = event.value
        widget_control, event.top, SET_UVALUE=state
    end
    
    'format': begin
      state.par.format = event.value
      widget_control, event.top, SET_UVALUE=state
    end
    
   ; handle event from standard save button
   'save': begin

      if state.par.iteration eq 0 then begin
         dummy = dialog_message(["number of iterations cannot be 0"], $
                                DIALOG_PARENT=event.top,         $
                                TITLE='SAV error',               $
                                /ERROR)
         ; return without saving if the test failed
         return
      endif

      ; check if output structure filename already exists
      if state.par.format eq 0 then begin
         check_file = findfile(state.par.data_file+".xdr")
         if check_file[0] ne "" then begin
            answ = dialog_message(                                         $
                ['file '+state.par.data_file+' already exists.',           $
                 'do you want to append other output structures to it ?'], $
                DIALOG_PARENT=event.top,                                   $
                TITLE='SAV warning',                                       $
                /QUEST)
            ; return without saving if the user doesn't want to overwrite the
            ; existing output file
            if strlowcase(answ) eq "no" then return
         endif
      endif else if state.par.format eq 1 then begin
         check_file = findfile(state.par.data_file+".sav")
         if check_file[0] ne "" then begin
            answ = dialog_message(                                         $
                ['file '+state.par.data_file+' already exists.',           $
                 'do you want to overwrite it ?'],                         $
                DIALOG_PARENT=event.top,                                   $
                TITLE='SAV warning',                                       $
                /QUEST)
            ; return without saving if the user doesn't want to overwrite the
            ; existing output file
            if strlowcase(answ) eq "no" then return
         endif
      endif else if state.par.format eq 2 then begin
         check_file = findfile(state.par.data_file+".fits")
         if check_file[0] ne "" then begin
            answ = dialog_message(                                         $
                ['file '+state.par.data_file+' already exists.',           $
                 'do you want to overwrite it ?'],                         $
                DIALOG_PARENT=event.top,                                   $
                TITLE='SAV warning',                                       $
                /QUEST)
            ; return without saving if the user doesn't want to overwrite the
            ; existing output file
            if strlowcase(answ) eq "no" then return
         endif
      endif else message, 'SAV error: formats other than .xdr, .sav and .fits are not taken into account.'

      ; save data in the parameter file.
      ; check before if filename already exists
      check_file = findfile(state.sav_file)
      if check_file[0] ne "" then begin
         answ = dialog_message(['file '+state.sav_file+' already exists.', $
                                'do you want to overwrite it ?'],          $
                               DIALOG_PARENT=event.top,                    $
                               TITLE='SAV warning',                        $
                               /QUEST)
         ; return without saving if the user doesn't want to overwrite the
         ; existing parameter file
         if strlowcase(answ) eq "no" then return
      endif else begin
         answ = dialog_message(['file '+state.sav_file+' will be saved.'], $
                               DIALOG_PARENT=event.top,                    $
                               TITLE='SAV information',                    $
                               /INFO                                       )
         ; inform were the parameters will be saved
      endelse
 
      ; save the parameter data file
      par = state.par
      save, par, FILENAME = state.sav_file

      ; kill the GUI returning a null error
      error = !caos_error.ok
      widget_control, event.top, /DESTROY
   end
    
   ; standard help button
   'help': begin
      widget_control, /HOURGLASS
      spawn, !caos_env.browser+" "+(sav_info()).help+"\#" $
            +strupcase(state.par.module.mod_name)+"&"
   end

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
      widget_control, state.id.data_file, SET_VALUE=par.data_file
      widget_control, state.id.iteration, SET_VALUE=par.iteration

      ; write the reseted state structure
      state.par = par

      ; write the GUI state structure
      widget_control, event.top, SET_UVALUE=state
   end

   ; standard cancel button (exit without saving)
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
function sav_gui, n_module, proj_name, GROUP_LEADER=group

; error status from the event handler procedure
common error_block, error

; get info structure
info = sav_info()

; check if a saved parameter file exists.
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

; build the widget id structure
id = $
   { $                     ; widget id structure
   par_base        : 0L, $ ; data widget base
      but_data_base: 0L, $ ; exclusive button widget base
      data_file    : 0L, $ ; data file widget base
      iteration    : 0L, $ ; nb-of-iterations-per-saving widget base
      format       : 0L  $ ; format widget base
   }

; build the state structure
state = $
   {    $                   ; widget state structure
   sav_file: sav_file, $    ; name of the file where save params
   def_file: def_file, $    ; name of the file where save params
   id      : id,       $    ; widget id structure
   par     : par       $    ; parameter structure
   }

; root base
modal = n_elements(group) ne 0
title = strupcase(info.mod_name)+' parameters setting GUI'
root_base_id = widget_base(TITLE=title, MODAL=modal, /COL, GROUP_LEADER=group)

; set the status structure
widget_control, root_base_id, SET_UVALUE=state

   ; parameters base
   state.id.par_base = widget_base(root_base_id, FRAME=10, ROW=2)
   dummy = widget_label(state.id.par_base, VALUE='parameters', /FRAME)
   par_base_id = widget_base(state.id.par_base, /COL)

      state.id.but_data_base = widget_base(par_base_id, /NONEXCLUSIVE)  

      state.id.data_file = cw_filename(par_base_id,                      $
                     TITLE='data file generic name (with NO extension)', $
                                       VALUE=state.par.data_file,        $
                                       UVALUE='save_data',               $
                                       /ALL_EVENTS                       )

   ; # of iterations per saving
   state.id.iteration = cw_field(par_base_id,                          $
                                 TITLE='nb of iterations per saving: ',$
                                 VALUE = state.par.iteration,          $
                                 /INTEGER,                             $
                                 UVALUE = 'iteration',                 $
                                 /ALL_EVENTS                           )

   ; file format
   state.id.format = cw_bgroup(par_base_id,                              $
                               LABEL_LEFT='file format ?',               $
                               ['XDR format (=> file.sav and file.xdr)', $
                                'simple SAVE format (=> file.sav)',      $
                                'FITS format (=> file.fits, img_t only!)'],$
                               ROW=3,                                    $
                               SET_VALUE = state.par.format,             $
                               UVALUE = 'format',                        $
                               /EXCLUSIVE                                )

   ; base for footnote
   note_base_id = widget_base(root_base_id, /COL, FRAME=10)
      dummy = ['NOTE:',                                                      $
               'The XDR format file created can be read with utility RST  ', $
               '(found in Utilities pack_lib), the simple SAVE format file', $
               'by using the standard IDL routine RESTORE, the FITS format', $
               'file by using module RSC (if data of type "img_t").       '  ]
      dummy = widget_text(note_base_id, $
                          VALUE=dummy,  $
                          YSIZE=N_ELEMENTS(dummy))

   ; standard buttons
   btn_base_id = widget_base(root_base_id, FRAME=10, /ROW)
      dummy = widget_button(btn_base_id, VALUE="HELP", UVALUE="help")
      cancel_id = widget_button(btn_base_id, VALUE="CANCEL", UVALUE="cancel")
      if modal then widget_control, cancel_id, /CANCEL_BUTTON
      dummy = widget_button(btn_base_id, VALUE="RESTORE PARAMETERS", $
                            UVALUE="restore")
      save_id = widget_button(btn_base_id, VALUE="SAVE PARAMETERS", $
                              UVALUE="save")
      if modal then widget_control, save_id, /DEFAULT_BUTTON

; save the state structure of the GUI in the top base uvalue
widget_control, root_base_id, SET_UVALUE=state

; draw the GUI
widget_control, root_base_id, /REALIZE

xmanager, 'sav_gui', root_base_id, GROUP_LEADER=group

return, error
end