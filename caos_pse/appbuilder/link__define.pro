;T+
; \subsubsection{Object Description}
;
; This code block defines the {\tt Link} object. It is a subclass of
; the IDLgrPolyline object used to define links connecting module
; outputs to module inputs.
;
;T-

; NAME:
;
;       Link     - Link object
;
; Usage:
;
;	MyLink = Obj_New('Link',VectX,VextY);
;
; Methods:
;
;	See: IDLgrPolyline
;
;	Xvec = Link->GetX
;	Yvec = Link->GetY
;	Link->Translate,xyOfst
;

;T+
; \subsubsection{Method: {\tt INIT}}
;
; The {\tt Link} object is actually a subclass of the IDL standard graphic 
; 'IDLgrPolyline' to which a few features have been added, as explained 
; below.
;
;T-

FUNCTION Link::INIT, VectX, VectY

IF self->IDLgrPolyline::INIT( VectX,        $
                              VectY,        $
                              THICK=2,      $
                              COLOR=[0,0,0]  ) THEN BEGIN
	self.LinkX=PTR_NEW(VectX)
	self.LinkY=PTR_NEW(VectY)
	RETURN, 1
ENDIF ELSE RETURN, 0

END


;T+
; \subsubsection{Method: {\tt GetX}}
;
; This function returns the X coordinate vector defining the link line.
;
;T-

FUNCTION Link::GetX

RETURN, (*self.LinkX)

END

;T+
; \subsubsection{Method: {\tt GetY}}
;
; This function returns the Y coordinate vector defining the link line.
;
;T-

FUNCTION Link::GetY

RETURN, (*self.LinkY)

END

;T+
; \subsubsection{Method: {\tt Translate}}
;
; This Procedure translates the entire link to a new position.
;
;T-

PRO Link::Translate,xyOfst

(*self.LinkX) = (*self.LinkX) + xyOfst[0]
(*self.LinkY) = (*self.LinkY) + xyOfst[1]

END

;T+
; \subsubsection{Data Structure}
;
; The following procedure is the required structure definition for the 
; {\tt Link} object.
; 
;T-

PRO Link__define		; Link data structure definition

struct = { Link, LinkX:PTR_NEW(), LinkY:PTR_NEW(), INHERITS IDLgrPolyline }

END

