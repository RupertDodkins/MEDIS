; $Id: tfl_new_item.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;       tfl_new_item
;
; PURPOSE:
;       ...
;
; CATEGORY:
;       Graghical User Interface utility
;
; CALLING SEQUENCE:
;       ...
;
; INPUTS:
;       ...
;
; OUTPUTS:
;       ...
;
; COMMON BLOCKS:
;       ...
;
;
; MODIFICATION HISTORY:
;       program written: ...
;       modifications  : may 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;-
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; status setting procedure ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
pro tfl_new_item_set, state
; do nothing
end

;;;;;;;;;;;;;;;;;;;;;;
; tfl_gui event loop ;
;;;;;;;;;;;;;;;;;;;;;;
;
pro tfl_new_item_event, event

common tfl_new_item_block, error, item

; Handle a kill request. It is considered as a cancel event.
; The right error returning is guaranteed only if GROUP_LEADER keyword
; is set to a valid parent id in the tfl_gui call.
if tag_names(event, /STRUCTURE_NAME) eq 'WIDGET_KILL_REQUEST' then begin
    error = !CAOS_ERROR.cancel
    widget_control, event.top, /DESTROY
endif

; Handle other events.
; Get the user value of the event sender
widget_control, event.id, GET_UVALUE = uvalue

case uvalue of
                                ; handle event from standard save button
    'save': begin
                                ; restore all the parameter values
        widget_control, event.top, GET_UVALUE=state

        error = !CAOS_ERROR.ok
        widget_control, state.id.re_fld, GET_VALUE=re
        widget_control, state.id.im_fld, GET_VALUE=im
        item = dcomplex(re[0], im[0])
        widget_control, event.top, /DESTROY
    end
    
                                ; exit without saving
    'cancel'  : begin
        error = !CAOS_ERROR.cancel
        widget_control, event.top, /DESTROY
    end

    'tfl_re_fld': begin
    end

    'tfl_im_fld': begin
    end


endcase

end

;;;;;;;;;;;;;;;;;;;;;;;;;
; GUI generation code
;;;;;;;;;;;;;;;;;;;;;;;;;
;
function tfl_new_item, the_item, GROUP_LEADER=group

common tfl_new_item_block, error, item

if n_elements(the_item) eq 0 then begin
    the_item = dcomplex(0d0, 0d0)
endif else begin
    if test_type(the_item, /COMPLEX, /DCOMPLEX, N_EL=n_el) then $
      message, 'the input must be a complex number'
    if n_el ne 1 then $
      message, 'the input must be a scalar'
    the_item=the_item[0]
endelse

error = !CAOS_ERROR.cancel
item = the_item

id = { $                        ; widget id structure
       re_fld  : 0L, $          ; real part field id
       im_fld  : 0L  $          ; imaginary part field id
     }

;par = { $
;        the_item: the_item $    ; the complex value
;      }
        
state = { $                     ; widget state structure
          id      : id       $ ; widget id structure
;          par     : par       $ ; parameter structure
        }


; root base
modal = n_elements(group) ne 0
title = 'Input a zero/pole'
root_base_id = widget_base(TITLE=title, MODAL=modal, /COL, GROUP_LEADER=group)

; data input base structure
data_base_id = widget_base(root_base_id, /FRAME, /ROW)

;
;
; constant factor input
state.id.re_fld = cw_field(data_base_id $
                              , /FLOAT $
                              , TITLE='Real part:' $
                              , VALUE=double(the_item) $
                              , UVALUE='tfl_re_fld')
state.id.im_fld = cw_field(data_base_id $
                              , /FLOAT $
                              , TITLE='Imaginary part:' $
                              , VALUE=imaginary(the_item) $
                              , UVALUE='tfl_im_fld')
;
;
; button base for control buttons (standrd buttons)
btn_base_id = widget_base(root_base_id, /FRAME, /ROW)
save_id = widget_button(btn_base_id, VALUE="Ok", UVALUE="save")
if modal then widget_control, save_id, /DEFAULT_BUTTON
cancel_id = widget_button(btn_base_id, VALUE="Cancel", UVALUE="cancel")
if modal then widget_control, save_id, /CANCEL_BUTTON

;
;
; draw the GUI
widget_control, root_base_id, /realize

; save the state structure of the GUI in the top base uvalue
widget_control, root_base_id, SET_UVALUE=state

; only REAL poles/zeros are allowed in this version
widget_control, state.id.im_fld, SENSITIVE=0

xmanager, 'tfl_new_item', root_base_id, GROUP_LEADER=group


the_item = item
return, error

end