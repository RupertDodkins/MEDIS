;T+
; \subsubsection{Object Description}
;
; This code block defines the {\tt Link} object. It is a subclass of
; the IDLgrText object used to define comment strings.
;
;T-

; NAME:
;
;       Text     - Text object
;
; Usage:
;
;	MyText = Obj_New('Text',String);
;
; Methods:
;
;	See: IDLgrText
;
;	Angle = text->GetAngle()
;	XYpos = text->GetPosition()
;	text->Translate,xyOfst
;

;T+
; \subsubsection{Method: {\tt INIT}}
;
; The {\tt text} object is actually a subclass of the IDL standard graphic 
; object 'IDLgrText' to which a few features have been added, as explained 
; below.
;
;T-

FUNCTION Text::INIT, String, Angle

IF self->IDLgrText::INIT(String) THEN BEGIN
	self.XYpos=[0,0]
	self.Angle=Angle
	RETURN, 1
ENDIF ELSE RETURN, 0

END


;T+
; \subsubsection{Method: {\tt SetPosition}}
;
; This function sets the XY current position of the string.
;
;T-

PRO Text::SetPosition, XY

self.XYpos=XY

self->IDLgrText::SetProperty,LOCATION=XY

END


;T+
; \subsubsection{Method: {\tt GetAngle}}
;
; This function returns the angular orientation of the string
;
;T-

FUNCTION Text::GetAngle

RETURN, self.Angle

END


;T+
; \subsubsection{Method: {\tt GetPosition}}
;
; This function returns the XY current position of the string.
;
;T-

FUNCTION Text::GetPosition

RETURN, self.XYpos

END

;T+
; \subsubsection{Method: {\tt Translate}}
;
; This Procedure translates the text string to a new position.
;
;T-

PRO Text::Translate,xyOfst

self.XYpos = self.XYpos + xyOfst

END

;T+
; \subsubsection{Data Structure}
;
; The following procedure is the required structure definition for the 
; {\tt Text} object.
; 
;T-

PRO Text__define		; Link data structure definition

struct = { Text, XYpos:[0,0], angle:0, INHERITS IDLgrText }

END

