;T+
; \subsubsection{External Entry Point: SelectFile}
;
; The following group of routines of code implement an event driven widget 
; for the selection of a filename among a list. Figure~\ref{selfilefig} shows
; the select file widget appearance: the filename can be either selected from 
; the filelist or entered within an editable text field.
;
; The {\tt AB} code uses the main entry point: {\tt SelectFile} 
; (Sect.~\ref{selectfile}).
;
; \begin{figure}[htb]
; \centerline{ \psfig{figure=selectfile.eps,width=4 cm} }
; \caption{The file Selection Widget\label{selfilefig}}
; \end{figure}
;
; \subsubsection{Event handler: {\tt NewlineEvent}}
;
; The following procedure is the event handler for ``newline'' events
; generated in the file selection widget. The newline event is usually
; equivalent to clicking on the ``OK'' button.
;
;T-

PRO NewlineEvent, event
  
  COMMON for_askforfile_only, Ok_ID, Can_ID, File_Id, Field_ID, $
     FileList, Selection
  
  WIDGET_CONTROL, Field_id, get_value=Selection
  
  WIDGET_CONTROL, event.top, /destroy
  
END

;T+
; \subsubsection{Event handler: {\tt SelFromListEvent}}
;
; The following procedure is the event handler from the ``file selected''
; event. The event is fired when the user presses the mouse button onto 
; the widget. The Event ID value is then use to select among various
; possible events.
;
;T-

PRO SelFromListEvent, event
  
  COMMON for_askforfile_only, Ok_ID, Can_ID, File_Id, Field_ID, FileList, Selection
  
  IF event.id EQ File_ID THEN BEGIN     ; Filename selected
     Selection=FileList[event.index]    ; Remeber file index
     widget_control, Field_id, set_value=Selection
  ENDIF
  
  IF event.id EQ Can_ID THEN BEGIN ; Cancel button pressed
     Selection=''
     widget_control, event.top, /destroy ; return from widget
  ENDIF
  
  IF event.id EQ Ok_ID THEN BEGIN           ; Ok button pressed
     IF Selection EQ '' THEN BEGIN          ; This to retrieve
        widget_control, Field_id, $         ; the edited value
                        get_value=Selection
     ENDIF
     widget_control, event.top, /destroy ; return from widget
  ENDIF
  
END

;T+
; \subsubsection{Function: {\tt SelectFile}}
; \label{selectfile}
;
; The following function is the externally visible entry point. When called
; it displays the file selection widget and goes to a wait loop for event
; management. The loop is terminated when the appropriate event is
; received.
;
;T-

FUNCTION SelectFile,Title, PrjList, PrjName, Parent ; returns a filename
  
  COMMON for_askforfile_only, Ok_ID, Can_ID, File_Id, Field_ID, FileList, Selection
  
  FileList=PrjList
  FileListLen = max(strlen(FileList))+2
  Selection=''
  
                                ; setup the base widget
  base = widget_base(TITLE = Title, Group_leader=Parent, /modal,/COL)
  Ok_id = Widget_Label(base, FRAME=3, Value=Title)

                                ; Add the editable text field
  base2 = widget_base(base, /COL)
  field_id = widget_text(base2, event_pro='NewlineEvent', $
                         /EDITABLE, VALUE=PrjName, XSIZE = FileListLen )

                                ; add the list of files
  File_ID = widget_list(base2, event_pro='SelFromListEvent',  $
                        VALUE=PrjList, XSIZE=FileListLen, YSIZE=9, $
                        /NO_COPY )
  
                                ; Add the OK/Cancel buttons
  base3 = widget_base(base, /ROW)
  Ok_ID = Widget_Button(base3, value='OK', XSIZE=70, /ALIGN_CENTER, $
                        event_pro='SelFromListEvent')
  Can_ID = Widget_Button(base3, value='CANCEL', XSIZE=70, /ALIGN_CENTER, $
                         event_pro='SelFromListEvent')



WIDGET_CONTROL, base, /realize		; display the widget

XMANAGER, 'SelectFile', base		; Loop on events

aux=SIZE(Selection)
IF aux[0]>0 THEN RETURN, Selection[0] ELSE RETURN, Selection

END
