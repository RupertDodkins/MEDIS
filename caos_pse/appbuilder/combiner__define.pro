;T+
; \subsubsection{Object Description}
;
; The following  code block defines the {\tt Combiner} object. It is a special 
; Module used to manage the feedback of a closed loop.
;
; This object is defined as a subclass of the module object from which inherits
; all the methods adding a few of them as specified later.
;
;T-
;
; NAME:
;
;       Combiner     - Combiner object
;
; Usage:
;
;	MyCombiner = Obj_New('Combiner');
;
; Methods:
;
;	See Module
;
;	Combiner->ToggleSign0		    ; Toggle sign to input 0
;	Combiner->ToggleSign1		    ; Toggle sign to input 1
;	Combiner->SetSigns		    ; Set both signs
;	signs = Combiner->GetSigns	    ; get signs
;	Handle = Combiner->GetHandle, XY    ; Get handle

;T+
; \subsubsection{Method: {\tt INIT}}
;
; The INIT entry points call the corresponding method of the superclass
; and then adds a few features (mainly needed for the management of
; input signs).
;
;T-

FUNCTION Combiner::INIT, Id

COMMON ModuleList, ListPtr, TypeList, Generic_dtype, IOcolors
COMMON Worksheet_Common, ModIDgen, DirName, ProjectModified, GridD, $
                         Slot0XY, FileVersion, AB_Name, AB_Version, AB_Date
COMMON GenDims, ModWidth, ModHeigth, Slotspace

IF self->Module::INIT('+++',Id) THEN BEGIN	; Create module
self.Graph.Model->remove, self.Graph.Text	; Remove name

						; Add feedback input
	self.Graph.Body->add,                            $
	                       OBJ_NEW( 'IDLgrPolygon',  $
                       	       [11,18,11],               $     ; X coords
                       	       [15,22.5,30],             $     ; Y coords
                               [1,1,1],                  $
                               STYLE=2,                  $
                       	       COLOR=[0,0,0],            $
                       	       LINESTYLE = 0      )

	self.SignChr[0]='+'
	self.SignChr[1]='+'
	Font = OBJ_NEW('IDLgrFont', 'Helvetica*Bold', SIZE = 13 )
	self.SignObj[0]=OBJ_NEW('IDLgrText', self.SignChr[0],               $
                                ALIGNMENT = 0.5,                            $
                                COLOR=[0,0,0],                              $
                                FONT=Font,                                  $
                                LOCATION = [5,5]     )
	self.SignObj[1]=OBJ_NEW('IDLgrText', self.SignChr[1],               $
                                ALIGNMENT = 0.5,                            $
                                COLOR=[0,0,0],                              $
                                FONT=Font,                                  $
                                LOCATION = [5,20]     )
	self.Graph.Body->add,self.SignObj[0]
	self.Graph.Body->add,self.SignObj[1]

	RETURN, 1
ENDIF ELSE RETURN, 0

END

;T+
; \subsubsection{Method: {\tt ToggleSign0}}
;
; This procedure toggle the sign associated with input 0.
;
;T-

PRO Combiner::ToggleSign0

IF self.SignChr[0] EQ '+' THEN BEGIN
	self.SignChr[0]= '-'
ENDIF ELSE BEGIN
	self.SignChr[0]= '+'
ENDELSE
self.SignObj[0]->SetProperty,STRING=self.Signchr[0]
END

;T+
; \subsubsection{Method: {\tt ToggleSign1}}
;
; This procedure toggle the sign associated with input 1.
;
;T-

PRO Combiner::ToggleSign1

IF self.SignChr[1] EQ '+' THEN BEGIN
	self.SignChr[1]= '-'
ENDIF ELSE BEGIN
	self.SignChr[1]= '+'
ENDELSE
self.SignObj[1]->SetProperty,STRING=self.Signchr[1]
END

;T+
; \subsubsection{Method: {\tt GetSigns}}
;
; This function returns the currently defined signs for input 0 and 1
;
;T-

FUNCTION Combiner::GetSigns			; Returns signs

RETURN, self.SignChr

END

;T+
; \subsubsection{Method: {\tt SetSigns}}
;
; This procedure sets the signs for both input 0 and 1.
;
;T-

PRO Combiner::SetSigns,Signs				; Set signs

IF STRMID(Signs,0,1) EQ '-' THEN s0='-' ELSE s0='+'
IF STRMID(Signs,1,1) EQ '-' THEN s1='-' ELSE s1='+'

self.SignChr = [s0,s1]
self.SignObj[0]->SetProperty,STRING=self.SignChr[0]
self.SignObj[1]->SetProperty,STRING=self.SignChr[1]

END

;T+
; \subsubsection{Method: {\tt GetHandle}}
;
; The following function, overrides the module superclass function to
; allow the detection of ``clicks'' in the input sign area. It actually 
; changes the response of the object when the pointer is set to the 
; central part of the module icon. Because the {\tt combiner} has not an 
; associated parameter definition GUI routine, codes to identify the 
; nearest sign on the icon are returned via the {\tt InOut} structure.
;
;T-
	
FUNCTION Combiner::GetHandle, XY		; Event position
						; Returns InOut structure

XYr = XY-self.myPos			; Compute relative event position

IF (XYr[0] LT self.myDims[0]*0.2) OR  $
   (XYr[0] GT self.myDims[0]*0.8)       THEN BEGIN  ; Sezione ingresso/uscita
	RETURN, self->Module::GetHandle(XY)
ENDIF ELSE BEGIN				    ; Central area
	Ret={ InOut, Type:0, ID:-1, Handle:0, 		$
	      DType:0, Box:OBJ_NEW(), Line:OBJ_NEW() }
	Ret.type=5
	IF XYr[0] LT self.myDims[0]*0.5 THEN BEGIN  ; Sign area

		IF XYr[1] LT self.myDims[1]*0.5 THEN	$
			ret.Type=3			$
		ELSE					$
			ret.Type=4
	ENDIF 
ENDELSE

RETURN, Ret

END

;T+
; \subsubsection{Data Structure}
;
; The following procedure is the required structure definition for the 
; combiner object.
; 
;T-

PRO Combiner__define		; Module data structure definition

struct = { Combiner, SignObj:[OBJ_NEW(),OBJ_NEW()], 		$
                     SignChr:['+','+'], INHERITS Module }

END

