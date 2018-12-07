; $Id: dis_gui.pro,v 7.0 2016/04/21 marcel.carbillet $
;+
; NAME:
;    dis_gui
;
; PURPOSE:
;    dis_gui generates the Graphical User Interface (GUI) for
;    setting the parameters of module DIS of package "Utilities".
;    A parameter file called dis_nnnnn.sav is created, where nnnnn
;    is the number n_module associated to the module instance.
;    The file is stored in the project directory proj_name located
;    in the working directory.
;
; CATEGORY:
;    module's Graghical User Interface routine
;
; CALLING SEQUENCE:
;    error = dis_gui(n_module, proj_name)
; 
; INPUTS:
;    n_module : integer scalar. Number associated to the intance
;               of the sav module. n_module > 0.
;    proj_name: string. Name of the current project.
;
; OUTPUTS:
;    error: long scalar, error code (see !caos_error var in caos_init.pro).
;
; COMMON BLOCKS:
;    none.
;
; CALLED NON-IDL FUNCTIONS:
;    ...
;
; MODIFICATION HISTORY:
;    program written: april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr],
;                     Andrea La Camera (DIBRIS) [andrea.lacamera@unige.it]:
;                    -global merging of dsp_gui of module DSP (from Soft.
;                     Pack. AIRY 6.1 ) and dis_gui of module DIS (from Soft.
;                     Pack. CAOS 5.2) for new CAOS Problem-Solving Env. 7.0.
;    modifications  : date,
;                     author (institute) [email@address]:
;                    -description of modification.
;
;-
;
pro dis_gui_set, state

widget_control, state.id.title, SET_BUTTON=state.par.title
if state.par.title EQ 0 then begin
   widget_control, state.id.title_info, SENSITIVE=0
endif else begin
   widget_control, state.id.title_info, SENSITIVE=1
endelse

if state.par.type eq 2 then begin
   widget_control, state.id.power, /SENSITIVE
endif else begin
  widget_control, state.id.power, SENSITIVE=0
endelse

end

;;;;;;;;;;;;;;;;;;;
; GUI events loop ;
;;;;;;;;;;;;;;;;;;;
;
pro dis_gui_event, event

common error_block, error

; read the GUI state structure
widget_control, event.top, GET_UVALUE=state

; handle a kill request (considered as a cancel event).
if tag_names(event, /STRUCTURE_NAME) eq 'WIDGET_KILL_REQUEST' then begin
   error = !caos_error.cancel
   widget_control, event.top, /DESTROY
endif

; handle other events.
; get the user value of the event sender
widget_control, event.id, GET_UVALUE=uvalue

case uvalue of

    'enable_title': begin
        state.par.title = event.select
        dis_gui_set, state
        widget_control, event.top, SET_UVALUE=state
    end

    'set_title': begin
        widget_control, event.id, GET_VALUE=val
        state.par.title_info = val[0]
        widget_control, event.top, SET_UVALUE=state
    end
    'iteration': begin
        state.par.iteration = event.value
        widget_control, event.top, SET_UVALUE=state
    end
    'type': begin
        state.par.type = event.value
        dis_gui_set, state
        widget_control, event.top, SET_UVALUE=state
    end
    'power': begin
        state.par.power = event.value
        widget_control, event.top, SET_UVALUE=state
    end
    'color' : begin
        state.par.color = event.index
        widget_control, event.top, SET_UVALUE=state
    end
    'xsize': begin
        state.par.xsize = event.value
        widget_control, event.top, SET_UVALUE=state
    end
    'ysize': begin
        state.par.ysize = event.value
        widget_control, event.top, SET_UVALUE=state
    end     
    'zoom_fac': begin
        state.par.zoom_fac = event.value
        widget_control, event.top, SET_UVALUE=state
    end
   ; handle event from standard save button
   'save': begin

      if state.par.iteration eq 0 then begin
         dummy = dialog_message(["number of iterations cannot be 0"], $
                                DIALOG_PARENT=event.top,              $
                                TITLE='DIS error',                    $
                                /ERROR)
         ; return without saving if the test failed
         return
      endif

      ; check before saving the parameter file if filename already exists
      check_file = findfile(state.dis_file)
      if check_file[0] ne "" then begin
         answ = dialog_message(['file '+state.dis_file+' already exists.', $
                                'do you want to overwrite it ?'],          $
                               DIALOG_PARENT=event.top,                    $
                               TITLE='DIS warning',                        $
                               /QUEST)
         ; return without saving if the user doesn't want to overwrite the
         ; existing parameter file
         if strlowcase(answ) eq "no" then return
      endif else begin
         answ = dialog_message(['file '+state.dis_file+' will be saved.'], $
                               DIALOG_PARENT=event.top,                    $
                               TITLE='DIS information',                    $
                               /INFO                                       )
         ; inform were the parameters will be saved
      endelse

      ; save the parameter data file
      par = state.par
      save, par, FILENAME = state.dis_file

      ; kill the GUI returning a null error
      error = !caos_error.ok
      widget_control, event.top, /DESTROY

   end

   ; standard help button
  'help': begin
   online_help, book=(dis_info()).help, /FULL_PATH
;         widget_control, /HOURGLASS       
;       CASE !VERSION.OS_FAMILY OF
;         'Windows'   :     begin
;                    spawn, !caos_env.browser+" "+(dis_info()).help,/NOSHELL
;                   end
;         else    :  begin
;                     spawn, !caos_env.browser+" "+(dis_info()).help+" &"
;                   end
;       ENDCASE
   end
   
   ; standard restore button:
   'restore': begin

      ; restore the desired parameter file
      par = 0
      title = "parameter file to restore"
      restore, filename_gui(state.def_file,                          $
                            title,                                   $
                            GROUP_LEADER=event.top,                  $
                            FILTER=state.par.module.mod_name+"*sav", $
                            /NOEDIT,                                 $
                            /MUST_EXIST,                             $
                            /ALL_EVENTS                              )

      ; update the current module number
      par.module.n_module = state.par.module.n_module

      ; set the default values for all the widgets
      widget_control, state.id.title,      SET_VALUE=par.title
      widget_control, state.id.title_info, SET_VALUE=par.title_info
      widget_control, state.id.iteration,  SET_VALUE=par.iteration
      widget_control, state.id.type,       SET_VALUE=par.type
      widget_control, state.id.color,      SET_COMBOBOX_SELECT=par.color
      widget_control, state.id.power,      SET_VALUE=par.power
      widget_control, state.id.zoom_fac,   SET_VALUE=par.zoom_fac

      ; update the state structure
      state.par = par

      ; reset the setting parameters status
      dis_gui_set, state

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

function dis_gui, n_module, proj_name, GROUP_LEADER=group

; error status from the event handler procedure
common error_block, error

; retrieve the module information
info = dis_info()

; check if a saved parameter file exists. If it exists it is restored,
; otherwise the default parameter file is restored.
dis_file = mk_par_name(info.mod_name, n_module, PROJ_NAME=proj_name)
def_file = mk_par_name(info.mod_name, PACK_NAME=info.pack_name, /DEFAULT)
par=0
check_file = findfile(dis_file)
if check_file[0] eq '' then begin
   restore, def_file
   par.module.n_module = n_module
   if par.module.mod_name ne info.mod_name then        $
      message, 'the default parameter file ('+def_file $
              +') is from another module: please take the right one'
   if (par.module.ver ne info.ver) then                $
      message, 'the default parameter file ('+def_file $
              +') is not compatible: please generate it again'
endif else begin
   restore, dis_file
   if (par.module.mod_name ne info.mod_name) then $
      message, 'the parameter file '+dis_file     $
              +' is from another module: please generate a new one'
endelse

id = $
   { $                   ; widget id structure
      title      : 0L, $ ; title widget buuton
      title_info : 0L, $ ; widget title text base
      type       : 0L, $ ; display type widget
      power      : 0L, $ ; power widget
      color      : 0L, $ ; color table
      xsize      : 0L, $ ; size of the frame -X-
      ysize      : 0L, $ ; size of the frame -Y-
      zoom_fac   : 0L, $ ; zoom-in factor widget
      iteration  : 0L  $
   }

state = $
   {    $                   ; widget state structure
   dis_file: dis_file, $    ; actual name of the file where save params
   def_file: def_file, $    ; default name of the file where save params
   id      : id,       $    ; widget id structure
   par     : par       $    ; parameter structure
   }

; root base
modal = n_elements(group) ne 0
root_base_id = widget_base(                                                 $
                  TITLE=strupcase(info.mod_name)+' parameters setting GUI', $
                  MODAL=modal,                                              $
                  /COL,                                                     $
                  GROUP_LEADER=group                                        )

; set the status structure
widget_control, root_base_id, SET_UVALUE=state

   ; parameters base
   par_base = widget_base(root_base_id, FRAME = 10, ROW=2)
   dummy = widget_label(par_base, VALUE='Parameters', /FRAME)
   par_base_id = widget_base(par_base, /COL)

     title_base = widget_base(par_base_id, /COL)
            state.id.title = cw_bgroup(title_base,             $
                                       [ 'Setting user-defined title'], $
                                       UVALUE="enable_title", /NONEXCLUSIVE, $
                                       set_value=state.par.title  )
                                       
            state.id.title_info = cw_field(title_base, $
                                  TITLE='Display-window title: ', xsize=40, $
                                  /STRING, VALUE=state.par.title_info,  $
                                  /ALL_EVENTS, UVALUE='set_title'   )

      ; # of iterations per display
      state.id.iteration = cw_field(par_base_id,                            $
                            TITLE='Nb of iterations per display: ', $
                            UVALUE='iteration',  VALUE=state.par.iteration,  $
                            /ALL_EVENTS, /INTEGER, xsize=5  )

      ; color table
      loadct, GET_NAMES=color_str, /SILENT
      label=WIDGET_LABEL(par_base_id, value="Map display color: ", /ALIGN_LEFT)
      state.id.color=WIDGET_COMBOBOX(par_base_id, value=color_str, $
                                     uvalue='color', /DYNAMIC_RESIZE)

      ; size of the frame
      size_base = widget_base(par_base_id, /ROW)
      label = WIDGET_LABEL(size_base, value="Size of the window: ", /ALIGN_LEFT)
      state.id.xsize = cw_field(size_base,  TITLE='X =',  $
                                UVALUE='xsize',  VALUE=state.par.xsize, $
                                /ALL_EVENTS, /INTEGER, xsize=5)

      ; options for img_t and src_t data only
      label=WIDGET_LABEL(par_base_id,                                                     $
                         value="OPTIONS FOR IMG_T AND SRC_T DATA ONLY IN THE FOLLOWING:", $
                         /ALIGN_LEFT                                                      )

      ; display type
      state.id.type = cw_bgroup(par_base_id,                           $
                                LABEL_LEFT='Map display type: ',       $
                                ['simple','log10(1+map)','map^power'], $
                                UVALUE='type',  SET_VALUE=state.par.type, $
                                COLUMN=3, /EXCLUSIVE  )

      ;power for display (type "map^power" case)
      state.id.power = cw_field(par_base_id,                               $
                                TITLE='Display the map at the power of: ', $
                                UVALUE='power', VALUE=state.par.power,  $
                                /ALL_EVENTS, /FLOAT, xsize=10 )
      
      state.id.ysize = cw_field(size_base,  TITLE='Y =',  $
                                UVALUE='ysize',  VALUE=state.par.ysize, $
                                /ALL_EVENTS, /INTEGER, xsize=5)

      ; zoom-in factor
      state.id.zoom_fac = cw_field(par_base_id,  TITLE='Zoom-in factor =',  $
                                UVALUE='zoom_fac',  VALUE=state.par.zoom_fac, $
                                /ALL_EVENTS, /INTEGER, xsize=5)

   ; button base for control buttons (standard buttons)
   btn_base_id = widget_base(root_base_id, FRAME=10, /ROW)
      dummy = widget_button(btn_base_id, VALUE="HELP", UVALUE="help")
      cancel_id = widget_button(btn_base_id, VALUE="CANCEL", UVALUE="cancel")
      if modal then widget_control, cancel_id, /CANCEL_BUTTON
      dummy = widget_button(btn_base_id, VALUE="RESTORE PARAMETERS", $
                            UVALUE="restore"                         )
      save_id = widget_button(btn_base_id, VALUE="SAVE PARAMETERS",  $
                              UVALUE="save"                          )
   if modal then widget_control, save_id, /DEFAULT_BUTTON

; initialize all the sensitive states
dis_gui_set, state

; save the state structure of the GUI in the top base uvalue
widget_control, root_base_id, SET_UVALUE=state

; draw the GUI
widget_control, root_base_id, /REALIZE

;widget_control, state.id.type, SET_COMBOBOX_SELECT = state.par.type
widget_control, state.id.color, SET_COMBOBOX_SELECT = state.par.color

; launch xmanager
xmanager, 'dis_gui', root_base_id, GROUP_LEADER=group

; back to the main calling program
return, error
end