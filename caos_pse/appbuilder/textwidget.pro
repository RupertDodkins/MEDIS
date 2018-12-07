;T+
; \subsubsection{External Entry Point: TextWidget}
;
; The following group of routines of code implement an event driven widget 
; for the specification of a text comment to add to a Project. 
; Figure~\ref{textwidgfig} shows the widget appearance.
; The user can specify the desired text appearance and then ``click''
; on the ``Apply'' button to put the text onto the Worksheet
;
; \begin{figure}[htb]
; \centerline{ \psfig{figure=textwidget.eps,width=4 cm} }
; \caption{The file Selection Widget\label{textwidgfig}}
; \end{figure}
;
; \subsubsection{Event handler: {\tt SelFromListEvent}}
;
; The following procedure is the event handler from the ``file selected''
; event. The event is fired when the user presses the mouse button onto 
; the widget. The Event ID value is then use to select among various
; possible events.
;
;T-

PRO TxButtonEvent, event

COMMON for_txwg_only, FontNames, string_id, Apply_ID, Can_ID, Font_id,   $
                      size_id, angle_id,                                 $
                      String, Font, Size, Angle

IF event.id EQ Can_ID THEN BEGIN		; Cancel button pressed
	widget_control, event.top, /destroy	; return from widget
	String = ''
ENDIF

IF event.id EQ Apply_ID THEN BEGIN			; Ok button pressed
	widget_control, string_id, get_value=Text
	String=Text[0]
	select=widget_info(font_id, /droplist_select)
	Font =  FontNames[select]
	widget_control, size_id, get_value=Text
	READS, Text[0], Size
	widget_control, angle_id, get_value=Text
	READS, Text[0], Angle
	widget_control, event.top, /destroy	; return from widget

ENDIF 

END

;T+
; \subsubsection{Function: {\tt TextWidget}}
; \label{selectfile}
;
; The following function is the externally visible entry point. When called
; it displays the text specification widget and goes to a wait loop for event
; management. The loop is terminated when the appropriate event is
; received.
;
; The function returns an {\tt IDLgrText} object, possibly NULL.
;
;T-

FUNCTION TextWidget, Parent

COMMON for_txwg_only

FontNames=['Helvetica',                           $
           'Helvetica*bold',                      $
           'Helvetica*italic',                    $
           'Courier*bold',                        $
           'Courier*italic',                      $
           'Courier',                             $
           'Times']

Size=20
Angle=0
						; setup the base widget
base = widget_base(TITLE = Title,         $
                   Group_leader=Parent,   $
                   /modal                 )
						; Add a title
Spare = Widget_Label(base,                $
                     Value='Write in the text string, select font, size, etc. and press Apply', 	$
                     FRAME=3,             $
                     /ALIGN_CENTER    )

						; Add the editable text field
string_id = widget_text(base,                     $
                      /EDITABLE,                $
                      FRAME=2,                  $
                      YOFFSET=25,               $
                      XSIZE = 80)
						; add the font list
font_ID = widget_droplist(base,                       $
                          VALUE=FontNames,            $
                          YOFFSET=65,                 $
                          event_pro='TxButtonEvent',  $
                          /NO_COPY                       )
						; Add the font size
Spare = Widget_Label(base,                $
                     Value='Size: ', 	$
                     FRAME=2,             $
                     YOFFSET=70,               $
                     XOFFSET=160           )
size_id = widget_text(base,                     $
                      /EDITABLE,                $
                      FRAME=2,                  $
                      VALUE='20',               $
                      Xsize=3,                  $
                      YOFFSET=65,               $
                      XOFFSET = 200)

						; Add the orientation
Spare = Widget_Label(base,                $
                     Value='Angle: ', 	$
                     FRAME=2,             $
                     YOFFSET=70,               $
                     XOFFSET=260           )
angle_id = widget_text(base,                     $
                      /EDITABLE,                $
                      FRAME=2,                  $
                      VALUE='0',               $
                      Xsize=3,                  $
                      YOFFSET=65,               $
                      XOFFSET = 300)

Apply_ID = Widget_Button(base,            $ 	; Add the Apply button
                      value='Apply',      $
                      YOFFSET=65,         $
                      XOFFSET=360,        $
                      XSIZE=70,           $
                      /ALIGN_CENTER,      $
                      event_pro='TxButtonEvent')

						; Add the CANCEL button
Can_ID = Widget_Button(base,              $
                       value='CANCEL',    $
                       YOFFSET=65,        $
                       XOFFSET=430,       $
                       XSIZE=70,          $
                      /ALIGN_CENTER,      $
                       event_pro='TxButtonEvent')


WIDGET_CONTROL, base, /realize		; display the widget

XMANAGER, 'TextWidget', base		; Loop on events

IF String NE "" THEN BEGIN
	angle=fix(angle)
	sina = sin(angle*0.017453293)
	cosa = cos(angle*0.017453293)
	bline= [cosa,sina]
	fo = OBJ_NEW('IdlGrFont', NAME=Font, SIZE=Size)
	Txt =  OBJ_NEW('Text', String, angle)
	Txt->SetProperty, ALIGNMENT = 0,                    $
                          COLOR=[0,0,0],                    $
                          FONT=fo,                          $
                          BASELINE=bline,                   $
                          LOCATION = [0,0] 

ENDIF ELSE Txt = OBJ_NEW()

RETURN, Txt

END
