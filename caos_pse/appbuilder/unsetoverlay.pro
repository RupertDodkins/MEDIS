;T+
; \subsubsection{Procedure: {\tt UnsetOverlay}}
; 
; The following procedure is used to terminate the ``overlay widget''
; created by {\tt SetOverlay} (see sect.~\ref{sect:setover}).
;
;T-

PRO UnsetOverlay, info				; Exit the Overlay status

COMMON Over_common, Rect, Screen, XStep, YStep, GrPoly, GrRect, GrView

OBJ_DESTROY,GrView
OBJ_DESTROY,GrRect
OBJ_DESTROY,GrPoly

WIDGET_CONTROL, (*info).win, EVENT_PRO='Worksheet_Event'
WIDGET_CONTROL, (*info).win, DRAW_MOTION_EVENTS=0
WIDGET_CONTROL, (*info).oTxt, SET_VALUE=''

(*info).oWin->DRAW, (*info).oView

END
