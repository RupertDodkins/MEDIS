;T+
; \subsubsection{Procedure: {\tt SetOverlay}}
; \label{sect:setover}
; 
; In order to allow a ``project move'' operation (to move an entire
; project around the worksheet) a graphic gadget has been defined
; which is substantially a shaded rectangular box surrounding the 
; project which can be moved by dragging one of the corners.
;
; The box is implemented as an ``overlay widget'' superimposed to the
; worksheet widget. The following procedure is used to set up the ``overlay
; widget'' and activate a specific event handler.
;
;T-

PRO SetOverlay, Box, Scr, info			; Set up the Overlay status

COMMON Over_common, Rect, Screen, XStep, YStep, GrPoly, GrRect, GrView

Rect=Box
Screen=Scr

Dxy = (*info).oGrid->slot2screen([1,1]) - (*info).oGrid->slot2screen([0,0])

XStep= Dxy[0]
YStep= Dxy[1]

VwSize=(*info).oGrid->GetSize()
GrView = OBJ_NEW( 'IDLgrView',           $
                 /TRANSPARENT,           $
                 VIEWPLANE_RECT = [0,0,VwSize[0],VwSize[1]] )
GrRect = OBJ_NEW('IDLgrModel')
GrView->add, GrRect

Rect = Rect + [ -5, +5, +5, -5 ]

GrPoly = OBJ_NEW('IDLgrPolygon',                      $
                      DATA=[ [Rect[0],Rect[2]],       $
                             [Rect[1],Rect[2]],       $
                             [Rect[1],Rect[3]],       $
                             [Rect[0],Rect[3]] ],     $
;                     THICK=0,                        $
                      COLOR=[220,220,220],            $
                      STYLE = 2,                      $
                      LINESTYLE = 0      )
GrRect->add, GrPoly

(*info).oWin->DRAW, GrView

;;WIDGET_CONTROL, (*info).win, EVENT_PRO='Worksheet_Event'  ; EA 2007+
;;WIDGET_CONTROL, (*info).win, DRAW_MOTION_EVENTS=1	    ; EA 2007+

END