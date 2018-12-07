; $Id: cw_filename.pro,v 1.2 2003/06/10 18:29:25 riccardi Exp $
;
;+
; NAME:
;       CW_FILENAME
;
; PURPOSE:
;       
;
; CATEGORY:
;	Compound widgets.
;
; CALLING SEQUENCE:
;	widget = CW_FILENAME(parent)
;
; INPUTS:
;       PARENT - The ID of the parent widget.
;
; KEYWORD PARAMETERS:
;	UVALUE - Supplies the user value for the widget.
;       VALUE  - Supplies the initial filename (scalar string)
;
;       TITLE        -+
;       ALL_EVENTS    |
;       FRAME         |
;       FIELDFONT     +--- See cw_field function
;       FONT          |
;       NOEDIT        |
;       RETURN_EVENTS |
;       XSIZE        -+
;
;       PATH         -+
;       FILTER        +--- See Dialog_pickfile function
;       FIX_FILTER    |
;       MUST_EXIST   -+
;
;       GET_PATH - if set only directories can be input
;
;
; OUTPUTS:
;       The ID of the created widget is returned.
;
; PROCEDURE:
;	WIDGET_CONTROL, id, SET_VALUE=value can be used to change the
;		current value displayed by the widget.
;
;	WIDGET_CONTROL, id, GET_VALUE=var can be used to obtain the current
;		value displayed by the widget.
;
; MODIFICATION HISTORY:
;       April 1999, written by A. Riccardi <riccardi@arcetri.astro.it>
;-


PRO cw_filename_set_value, id, value

	; This routine is used by WIDGET_CONTROL to set the value for
	; your compound widget.  It accepts one variable.  
	; You can organize the variable as you would like.  If you have
	; more than one setting, you may want to use a structure that
	; the user would need to build and then pass in using 
	; WIDGET_CONTROL, compoundid, SET_VALUE = structure.

	; Return to caller.
  ON_ERROR, 2

	; Retrieve the state.
  stash = WIDGET_INFO(id, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY

  WIDGET_CONTROL, state.id, SET_VALUE=strtrim(value,2)

	; Restore the state.
  WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY

END



FUNCTION cw_filename_get_value, id

	; This routine is by WIDGET_CONTROL to get the value from 
	; your compound widget.  As with the set_value equivalent,
	; you can only pass one value here so you may need to load
	; the value by using a structure or array.

	; Return to caller.
  ON_ERROR, 2

	; Retrieve the structure from the child that contains the sub ids.
  stash = WIDGET_INFO(id, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY
  
  WIDGET_CONTROL, state.id, GET_VALUE=value

	; Restore the state.
  WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY

  return, value

END

;-----------------------------------------------------------------------------

FUNCTION cw_filename_event, ev

	; This routine handles all the events that happen in your
	; compound widget and if the events need to be passed along
	; this routine should return the new event.  If nobody needs
	; to know about the event that just occured, this routine 
	; can just return 0.  If your routine never needs to pass
	; along an event, this routine can be a procedure instead
	; of a function.  Whichever type used must be set below in the
	; WIDGET_BASE call using either the EVENT_PROC or EVENT_FUNC 
	; keyword.  An event function that returns a scalar 0 is 
	; essentially an event procedure.

  parent=ev.handler


	; Retrieve the structure from the child that contains the sub ids.
  stash = WIDGET_INFO(parent, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=state

	; Process your compound widgets events here.
	; If the event doesn't need to propagate up any further, just 
	; return 0 and the event will stop here.  Otherwise, modify
        ; the event for your usage and return it.
  WIDGET_CONTROL, ev.id, GET_UVALUE=uvalue
  
  case uvalue of
      
       "cw_filename_browse": begin
          WIDGET_CONTROL, state.id, GET_VALUE=value
          value=value[0]
          ;; check if it is an existing directory
          dir_exist = is_a_dir(value)
          
          if dir_exist then begin
              inp_path=value
              filename=""
          endif else begin
              filename = sep_path(value, ROOT=root, SUB=sub)
              if filename eq "" then begin
                  ;; "value" string contains a not valid dir name
                  inp_path=""
              endif else begin
                  ;; check if the dir containing filename is a valid
                  ;; directory
                  inp_path=filepath("", ROOT=root, SUB=sub)
                  the_dir_exist = is_a_dir(inp_path)
                  if not the_dir_exist then inp_path=""
              endelse
          endelse
          
          new_filename=dialog_pickfile(FILE=filename, $
                                   GET_PATH=the_path, $
                                   PATH=inp_path, $
                                   GROUP=ev.top, $
                                   TITLE=state.title, $
                                   FILTER=state.filter, $
                                   FIX_FILTER=state.fix_filter, $
                                   MUST_EXIST=state.must_exist)
          
          if new_filename ne "" then begin
              if state.get_path then new_filename=the_path
              widget_control, state.id, SET_VALUE=new_filename
              value = new_filename
              update = 1
          endif else begin
              update = 0
          endelse
          
          if state.return_events or state.all_events then begin
              RETURN, { ID:parent, TOP:ev.top, HANDLER:0L, $
                        VALUE:value, UPDATE:update}
          endif else begin
              return, 0
          endelse
      END
      
      "cw_filename_fld": begin
          WIDGET_CONTROL, state.id, GET_VALUE=value
          value = value[0]
          return, { ID:parent, TOP:ev.top, HANDLER:0L, $
                    VALUE:value, UPDATE:ev.update}
      end
  endcase
end

;-----------------------------------------------------------------------------

FUNCTION cw_filename, parent, UVALUE = uval, VALUE=value, $
                      TITLE=title, ALL_EVENTS=all_events, $
                      FRAME=frame, FIELDFONT=field_font, $
                      FONT=font, NOEDIT=noedit, $
                      RETURN_EVENTS=return_events, XSIZE=xsize, $
                      GET_PATH=get_path, $
                      FILTER=filter, FIX_FILTER=fix_filter, $
                      MUST_EXIST=must_exist

	; You should not use the user value of the main base for
	; your compound widget as the person using your compound widget
	; may want it for his or her own use.  
	; You also should not use the user value of the first widget you
	; install in the base as it is used to keep track of the state.

	; state structure for your compound widget.

  IF (N_PARAMS() EQ 0) THEN MESSAGE, 'Must specify a parent for CW_FILENAME'

  ON_ERROR, 2					;return to caller

	; Defaults for keywords
  IF n_elements(uval)  eq 0 THEN uval = 0
  IF n_elements(value) eq 0 THEN value = "" ELSE value=strtrim(value,2)
  IF n_elements(title) eq 0 THEN title = "Filename:"
  IF n_elements(filter) eq 0 then filter = "*"
  
  get_path = keyword_set(get_path)
  all_events = keyword_set(all_events)
  return_events = keyword_set(return_events)
  fix_filter = keyword_set(fix_filter)
  must_exist = keyword_set(must_exist)
  
	; Rather than use a common block to store the widget IDs of the 
	; widgets in your compound widget, put them into this structure so
	; that you can have multiple instances of your compound widget.
  state = { $
            id:0L, $
            get_path: get_path, $
            title: title, $
            filter: filter, $
            fix_filter: fix_filter, $
            must_exist: must_exist, $
            return_events: return_events, $
            all_events: all_events $
          }

  mainbase = WIDGET_BASE(parent, UVALUE = uval,                    $
                         EVENT_FUNC = "cw_filename_event",         $
                         FUNC_GET_VALUE = "cw_filename_get_value", $
                         PRO_SET_VALUE = "cw_filename_set_value",  $
                         /ROW, FRAME=frame)
  
  ; the base where the state structute will be stored
  uv_base = WIDGET_BASE(mainbase, /ROW)
	; Here you would define the sub-components of your widget.  There
        ; is an example component which is just a label.
  
  state.id = CW_FIELD(uv_base, TITLE=title,                 $
                      /COL, /STRING, ALL_EVENTS=all_events, $
                      RETURN_EVENTS=return_events,          $
                      FIELDFONT=field_font,                 $
                      FONT=font, NOEDIT=noedit,             $
                      XSIZE=xsize,                          $
                      VALUE = value, UVALUE="cw_filename_fld")
  
  dummy = WIDGET_BUTTON(uv_base, UVALUE="cw_filename_browse", $
                        VALUE="Browse...")

	; Save out the initial state structure into the first childs UVALUE.
  WIDGET_CONTROL, WIDGET_INFO(mainbase, /CHILD), SET_UVALUE=state

	; Return the base ID of your compound widget.  This returned
	; value is all the user will know about the internal structure
	; of your widget.
  RETURN, mainbase

END





