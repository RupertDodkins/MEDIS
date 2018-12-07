; $Id: tfl_dof_gui.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;       tfl_dof_gui
;
; PURPOSE:
;       Create and manage a dilaog panel to enter the number
;       of different filters to be defined in the tfl_gui interface.
;       The user can choose between to define just one filter and apply
;       it to all the command degrees of freedom, or to define a different
;       filter for each degree of freedom. In the latter case the number
;       of degree of freedom must be entered.
;
; CATEGORY:
;       Graghical User Interface utility
;
; CALLING SEQUENCE:
;       error = tfl_dof_gui(n_dof)
;
; INPUTS:
;       n_dof:    named variable containing an integer scalar. Number of
;                 default degree of freedom.
;                 n_dof eq 1 means: the same filter shape for all the
;                 command degree of freedom.
;
; OUTPUTS:
;       n_dof: integer scalar. The number of degree of freedom entered
;              by the user. n_dof eq 1 means: the same filter for all
;              the command degree of freedom.
;       error: long scalar, error code (see !caos_error var in caos_init.pro).
;
; COMMON BLOCKS:
;       none.
;
;
; MODIFICATION HISTORY:
;       program written: 12/03/1999, S. Esposito (OAA),
;                        <esposito@arcetri.astro.it>.
;       modifications  : may 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;-
;
pro tfl_dof_set, state

case state.par.filter of
    0: begin
        widget_control, state.id.ndegrees, SENSITIVE=0
        widget_control, state.id.file_base, SENSITIVE=0
    end

    1: begin
        widget_control, state.id.ndegrees, /SENSITIVE
        widget_control, state.id.file_base, SENSITIVE=0
    end


    2: begin
        widget_control, state.id.ndegrees, SENSITIVE=0
        widget_control, state.id.file_base, /SENSITIVE
    end
endcase

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; status setting procedure ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
pro tfl_dof_gui_event, event

common error_block, error
common tfl_dof_gui_block, nodof1, filename1

; read the GUI state structure
widget_control, event.top, GET_UVALUE=state

; handle a kill request (considered as a cancel event).
; the right error returning is guaranteed only if GROUP_LEADER keyword
; is set to a valid parent id in the xxx_gui call.
if tag_names(event, /STRUCTURE_NAME) eq 'WIDGET_KILL_REQUEST' then begin
   error = !caos_error.cancel
   widget_control, event.top, /DESTROY
endif

; handle other events.
; get the user value of the event sender
widget_control, event.id, GET_UVALUE=uvalue

case uvalue of

    'set_filter': begin
        state.par.filter = event.value
        tfl_dof_set, state
        widget_control, event.top, SET_UVALUE=state
    end

   'set_nodof': begin
        ; set the # of dof
        state.par.nodof = event.value
        ; write the state structure
        widget_control, event.top, SET_UVALUE=state
   end

   'file_fld': begin
        widget_control, state.id.file_fld, GET_VALUE=filename
        state.par.filename = filename[0]
        widget_control, event.top, SET_UVALUE=state
   end

    'file_btn': begin
        filename = state.par.filename
        ans = findfile(filename)
        if ans[0] eq '' then filename = ''
        filename = dialog_pickfile(FILE=filename, GROUP=event.top, $
                                   FILTER='*.dat', $
                                   TITLE='Select the ascii file defining the filters', $
                                   /MUST_EXIST)
        if filename eq '' then return

        state.par.filename = filename
        widget_control, state.id.file_fld, SET_VALUE=filename
        widget_control, event.top, SET_UVALUE=state
   end


   'ok': begin
        nodof = state.par.nodof
        filename = state.par.filename

        case state.par.filter of

            0: begin
                filename1= ''
                nodof1 = 1
            end

            1: begin
                nodof = state.par.nodof
                if nodof lt 1 then begin
                    dummy = dialog_message("The number of degree of freedom cannot" $
                                   + " be less then 1." $
                                   , TITLE = "TFL Error" $
                                   , DIALOG_PARENT=event.top $
                                   , /ERR)
                    ;; return without exiting
                    return
                endif
                nodof1 = nodof
                filename = ''
            end

            2: begin
                filename = state.par.filename
                if filename eq '' then begin
                    count = 0
                endif else begin
                    ans = findfile(filename, COUNT=count)
                endelse
                if count eq 0 then begin
                    dummy = dialog_message("The file "+filename+" doesn't exist", $
                                           TITLE = "TFL Error", $
                                           DIALOG_PARENT=event.top, $
                                           /ERR)
                    ;; return without exiting
                    return
                endif
                nodof1 = 0
                filename1 = state.par.filename
             end
        endcase
        error = !caos_error.ok
        widget_control, event.top, /DESTROY
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

function tfl_dof_gui, nodof, filename, GROUP_LEADER=group

; error status from the event handler procedure
common error_block, error
common tfl_dof_gui_block, nodof1, filename1


if test_type(nodof, /NOFLOATING, N_EL=n) then begin
    message, "Unexpected input: nodof must be an integer" $
        , CONT = (not !CAOS_DEBUG)
    return, !CAOS_ERROR.unexpected
endif
if n ne 1 then begin
    message, "Unexpected input: nodof must be a scalar" $
        , CONT = (not !CAOS_DEBUG)
    return, !CAOS_ERROR.unexpected
endif

if nodof lt 0 then begin
    message, "Unexpected input value: nodof must be greater or equal then 0" $
        , CONT = (not !CAOS_DEBUG)
    return, !CAOS_ERROR.unexpected
endif

if n_elements(filename) eq 0 then begin
    filename = ''
endif else begin
    if test_type(filename, /STRING, N_EL=n) then begin
        message, "Unexpected input: filename must be a string" $
          , CONT = (not !CAOS_DEBUG)
        return, !CAOS_ERROR.unexpected
    endif
    if n ne 1 then begin
        message, "Unexpected input: filename must be a scalar string" $
          , CONT = (not !CAOS_DEBUG)
        return, !CAOS_ERROR.unexpected
    endif
    filename = filename[0]
endelse

if (filename eq '') and (nodof eq 0) then begin
    message, ["Unexpected inputs: filename cannot be an empty string", $
              "and nodof equal to zero at the same time"], $
             CONT = (not !CAOS_DEBUG)
    return, !CAOS_ERROR.unexpected
endif

nodof1 = nodof
filename1 = filename
error = !CAOS_ERROR.ok

if filename eq "" then begin
    if nodof EQ 1 then filter = 0 else filter = 1
endif else begin
    filter = 2
endelse

par = $
   { $
   nodof: nodof, $
   filename: filename, $
   filter: filter $
   }

id = $
   { $                     ; widget id structure
   method   : 0L, $ ; method bgroup id
   ndegrees : 0L, $ ; time delay field id
   file_fld : 0L, $ ; filename field id
   file_base: 0L, $ ; filename base id
   file_btn : 0L  $ ; filename browse button id
   }

state = $
   {    $                ; widget state structure
   id      : id,       $ ; widget id structure
   par     : par       $ ; parameter structure
   }

; root base
modal = n_elements(group) ne 0
root_base_id = widget_base(TITLE=' setting number of degrees of freedom', $
                           MODAL=modal,                                        $
                           /COL,                                               $
                           GROUP_LEADER=group)

; parameters base with frame and title
par_base = widget_base(root_base_id, /FRAME, /COL)

; exclusive bgroup
state.id.method = cw_bgroup(par_base,                     $
                            label_top = 'Filter definition for each degree of freedom:',    $
                            ['same filter','different filter','read filter data from file'], $
                            COLUMN=3,                           $
                            SET_VALUE=state.par.filter,         $
                            /EXCLUSIVE,                         $
                            UVALUE='set_filter')

; editable integer field
state.id.ndegrees = cw_field(par_base,                        $
                             TITLE='# of degrees of freedom', $
                             /COLUMN,                         $
                             VALUE=state.par.nodof,           $
                             /INTEGER,                        $
                             UVALUE="set_nodof",              $
                             /ALL_EVENTS)

; editable filename field with browse button
file_base = widget_base(par_base, /ROW)
state.id.file_base = file_base
state.id.file_fld  = cw_field(file_base,                $
                              TITLE='Filename:',        $
                              /ROW,                     $
                              VALUE=state.par.filename, $
                              /STRING,                  $
                              UVALUE="file_fld",        $
                              /ALL_EVENTS)
state.id.file_btn  = widget_button(file_base,         $
                                   VALUE='Browse...', $
                                   UVALUE='file_btn')

; button base for control buttons (standard buttons)
btn_base_id = widget_base(root_base_id, $
                          /FRAME,       $
                          /ROW)
cancel_id = widget_button(btn_base_id,    $
                          VALUE="CANCEL", $
                          UVALUE="cancel")
if modal then widget_control, cancel_id, /CANCEL_BUTTON
save_id   = widget_button(btn_base_id,             $
                          VALUE="OK", $
                          UVALUE="ok")
if modal then widget_control, save_id, /DEFAULT_BUTTON

; save the state structure of the GUI in the top base uvalue
widget_control, root_base_id, SET_UVALUE=state

tfl_dof_set, state

; draw the GUI
widget_control, root_base_id, /REALIZE

xmanager, 'tfl_dof_gui', root_base_id, GROUP_LEADER=group

nodof = nodof1
filename = filename1

return, error
end