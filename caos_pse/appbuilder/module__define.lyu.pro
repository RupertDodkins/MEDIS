;T+
; \subsubsection{Object Description}
;
; The following code block defines the {\tt Module} object. The term
; ``module'' in this context refers to the IDL Object which has been
; defined to implement the building blocks (also called ``modules'')
; for the {\tt Application Builder}.

; The definition of Module objects follows the IDL guidelines for
; object programming and contains all the details needed to manage the
; module representation within the  {\tt AB}.

; The Module object programming interface, ; i.e.: the initialization call
; and the ``methods'' defined for the object are, as usual, defined in the
; first part of the code fragment.

; Modules are characterized by a ``Module Name'' (a three letters
; identification code) which identifies the type of the module, i.e.:
; specifies the action performed by the module within the simulation program;
; the type of module must be declared when the object is created.

; Modules can be "cloned". I.e.: a new module can be derived by an existing
; one by "cloning". The module Clone shares the same parameters files as
; its father.
;
;T-

; NAME:
;
;       Module     - Module object
;
; Usage:
;
;	MyObject = Obj_New('Module',Type)       - See the INIT function
;
; Methods:
;
;		Part I: Get module related data
;
;	dataStruct = Module->GetData()	 	- Get module data
;	ModID = Module->GetID()	 		- Get module ID
;	slot = Module->GetSlot() 		- Get module position (slot)
;	slot = Module->GetStatus() 		- Get module Status
;       Father = Module->GetFather()		- Get father of clones
;	GraphObj = Module->GetGraph()		- Get Graphics
;	Handle = Module->GetHandle(XY)		- Get Data handle
;	InOut=Module->GetIn(Handle)		- Get input handle
;	[x,y]=Module->GetInCoord(Handle)	- Compute input handle coord.
;	Ninp=Module->GetNInputs()		- Get number of input links
;	InpArray=Module->GetInputs()		- Get array of input links
;	InOut=Module->GetOut(Handle)		- Get output handle
;	[x,y]=Module->GetOutCoord(Handle)	- Compute output handle coord.
;	type = Module->GetType()	 	- Get module type
;
;		Part II: Set module characteristics
;
;	status = Module->ChangeDType(dtype)	- Change data type
;       Module->Offset, slotofst,xyofst		- Translate module slot
;	Module->PutLine,Input,Line		- Add a line to module input
;	Module->SetInType, handle, dtype        - Set input handle data type
;	Module->SetOutType, handle, dtype       - Set output handle data type
;	Status = Module->SetParams(ProjectName)	- Call param interf.
;       Module->SetStatus, Status		- Set module to specified status
;	Module->SetLink(FromMod,FromID,
;	                FromHandle,Input)	- Defines a link
;
;		Part III: Miscellaneous
;
;	Module->DelLink(FromOut,Input)		- Deletes a link
;	Module->List(Unit)			- Print module structure

;T+
; \subsubsection{Method: {\tt INIT}}
;
; Here follows the {\tt INIT} entry point, i.e.: the standard module creation
; procedure. In this procedure the object is created, internal data are
; initialized and the graphic ``structure'' of the object is defined.
;
;T-

FUNCTION Module::INIT, type,         $ 	; type: a 3 character string specifying
                       id,           $ 	; the unique module identification code
                       FATHER=Father	; Father, if the module is a clone

COMMON ModuleList, ListPtr, TypeList, Generic_dtype, IOcolors
COMMON Worksheet_Common, ModIDgen, DirName, ProjectModified, GridD, $
                         Slot0XY, FileVersion, AB_Name, AB_Version, AB_Date
COMMON GenDims, ModWidth, ModHeigth, Slotspace

mod_inf=GetModule(type)
self.Graph.Model = OBJ_NEW('IDLgrModel', /SELECT_TARGET)

IF N_ELEMENTS(Father) GT 0 THEN self.Father=Father

self.ID = id				; Module ID

IF (*mod_inf).rdpar THEN	   $
	self.myColor = [250,0,0]   $	; Preset color (RED)
ELSE				   $
	self.myColor = [0,200,0]	; Preset color (GREEN, because
					; module doesn't require parameters)

self.myDims=[ModWidth,ModHeigth]
self.myslot= [0,0]
self.myPos = Slot0XY

Xvect = [0, 10, 30, 40, 50, 50, 40, 40, 30, 10,  0]	; Auxiliary vector for
Yvect = [0,  0,  0,  0,  0, 30, 30, 15, 30, 30, 30]	; drawing the module
Zvect = [2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2]	; icon

self.Graph.Body = OBJ_NEW('IDLgrModel')			; "Body" is the central
							; part of the icon

self.Graph.Body->add, OBJ_NEW( 'IDLgrPolyline', Xvect, Yvect, $
                          POLYLINES= [ 5, 0, 1, 9, 10, 0,     $
                                       4, 1, 3, 6, 9,         $
                                       4, 3, 4, 5, 6,         $
                                       3, 2, 7, 8      ],     $
                          THICK=3,               $
                          COLOR=self.myColor,    $
                          LINESTYLE = 0      )

inp = (*mod_inf).inp_type
out = (*mod_inf).out_type

self.Ninp=(*mod_inf).Ninp
						; Modules can have 0 or more
						; input handles
cnt=self.Ninp-1				; Initialize input handles
FOR i=0, cnt DO BEGIN
	aux = WHERE(inp[i] EQ TypeList)
	self.Inputs[i].dtype = aux[0]
	self.Inputs[i].Type =1
	self.Inputs[i].handle =i
	self.Inputs[i].ID = -1
	self.Inputs[i].Line = OBJ_NEW()
	self.Inputs[i].Box  = OBJ_NEW()
ENDFOR
						; Modules can have 0 or more
						; output handles
self.Nout=(*mod_inf).Nout
cnt=self.Nout-1
FOR i=0, cnt DO BEGIN
	aux = WHERE(out[i] EQ TypeList)
	self.Outputs[i].dtype = aux[0]
	self.Outputs[i].Type =2
	self.Outputs[i].handle =i
	self.Outputs[i].ID = -1
	self.Outputs[i].Line = OBJ_NEW()
	self.Outputs[i].Box  = OBJ_NEW()
ENDFOR

self.Graph.Inp = OBJ_NEW('IDLgrModel')		; Set the graphic structure
						; for input and output handles

IF self.Ninp LE 0 THEN BEGIN				; No inputs
	self.Graph.Body->add, OBJ_NEW('IDLgrPolyline', $
	                          [0,10, 0,10, 0, 0],  $
	                          [0, 0,30,30, 0,30],  $
	                          [1, 1, 1, 1, 1, 1],  $
	                          THICK=3,             $
	                          COLOR=self.myColor,  $
	                          LINESTYLE = 0        )
ENDIF ELSE BEGIN				; One or more inputs
	x0 = 0
	x1 = self.myDims[0]*0.20
	y0 =0
	Ystep=self.myDims[1]/self.Ninp
	FOR i=0, self.Ninp-1 DO BEGIN
		y1=y0+Ystep-0
		color=IOcolors[*,self.Inputs[i].dtype]

		self.Inputs[i].Box= OBJ_NEW( 'IDLgrPolygon',        $
		                          [x0, x1, x1,x0],          $
		                          [y0, y0, y1,y1],          $
		                          [ 0,  0,  0, 0],          $
		                          COLOR=color,              $
		                          STYLE=2,                  $
                       	                  THICK=3,                  $
		                          LINESTYLE = 0             )
		self.Graph.Inp->add, self.Inputs[i].Box
		IF i GT 0 THEN self.Graph.Body->add,                $
		                    OBJ_NEW('IDLgrPolyline',        $
		                            [x0,x1],                $
		                            [y0,y0],                $
		                            [ 1, 1],                $
;		                            [ 2, 2],                $
			                    COLOR=self.Mycolor,     $
                       	                    THICK=3,                $
		                            LINESTYLE = 0           )
		y0=y1
	ENDFOR
ENDELSE

IF self.Nout LE 0 THEN BEGIN				; No outputs
	self.Graph.Body->add, OBJ_NEW( 'IDLgrPolyline',     $
                       	          [40,50,40,50,40,40],      $     ; X coords
                       	          [ 0, 0,30,30, 0,30],      $     ; Y coords
	                          [1, 1, 1, 1, 1, 1],       $
                       	          THICK=3,                  $
                       	          COLOR=self.myColor,       $
                       	          LINESTYLE = 0      )

ENDIF ELSE BEGIN				; One or more outputs
	x0 = self.myDims[0]*0.80
	x1 = self.myDims[0]
	y0 = 0
	Ystep=self.myDims[1]/self.Nout
	FOR i=0, self.Nout-1 DO BEGIN
		y1=y0+Ystep
		color=IOcolors[*,self.Outputs[i].dtype]
		self.Outputs[i].Box= OBJ_NEW( 'IDLgrPolygon',       $
		                          [x0, x1, x1,x0],          $
		                          [y0, y0, y1,y1],          $
		                          [ 0,  0,  0, 0],          $
		                          COLOR=color,              $
		                          STYLE=2,                  $
		                          LINESTYLE = 0      )
		self.Graph.Inp->add, self.Outputs[i].Box
		IF i GT 0 THEN self.Graph.Body->add,                $
		                    OBJ_NEW('IDLgrPolyline',        $
		                            [x0,x1],                $
		                            [y0,y0],                $
		                            [ 1, 1],                $
;		                            [ 2, 2],                $
			                    COLOR=self.Mycolor,     $
                       	                    THICK=2,                $
		                            LINESTYLE = 0      )
		y0=y1
	ENDFOR
ENDELSE

self.Type = type;

						; Add the module type

tyFont = OBJ_NEW('IDLgrFont', 'Helvetica*Bold', SIZE = 9.0 )
self.Graph.Text = OBJ_NEW( 'IDLgrText', STRUPCASE(type),          $
                      ALIGNMENT = 0.5,                            $
                      COLOR=self.myColor,                         $
                      FONT=tyFont,                                  $
                      LOCATION = [24,12]     )

idFont = OBJ_NEW('IDLgrFont', 'Helvetica*Bold', SIZE = 8.0 )
self.Graph.Id = OBJ_NEW( 'IDLgrText', STRING(self.ID,FORMAT='(I3.3)'),   $
                             ALIGNMENT = 0,                              $
                             COLOR=[0,0,0],                              $
                             FONT=idFont,                                $
                             LOCATION = [13,3]      )

self.Graph.Model->add, self.Graph.Inp
self.Graph.Model->add, self.Graph.Body
self.Graph.Model->add, self.Graph.Text
self.Graph.Model->add, self.Graph.Id

IF OBJ_VALID(Father) THEN BEGIN
	Fid = "F: " + STRING(Father->GetId(),FORMAT='(I3.3)')
	self.Graph.Model->add, OBJ_NEW( 'IDLgrText', Fid,         $
                                        ALIGNMENT = 0,            $
                                        COLOR=[60,60,60],         $
                                        FONT=idFont,              $
                                        LOCATION = [2,32]      )
ENDIF

self.Graph.Model->translate,self.myPos[0],self.myPos[1],0

RETURN, 1
END

;T+
; \subsubsection{Method: {\tt GetData}}
;
; The following function returns a structure containing all internal
; data relevant to the given module. For the sake of efficiency some
; of the data items returned by this function can also be retrieved
; singularly by specific methods.
;
;T-

FUNCTION Module::GetData

RETURN, { Type:self.Type,          $  ; Module Type (string)
          ID:self.ID,              $  ; Module ID   (integer)
          Ninp:self.Ninp,          $  ; Number of Inputs (integer)
          Nout:self.Nout,          $  ; Number of outputs (integer)
          Inputs:self.Inputs,      $  ; Input links (struct)
          Outputs:self.Outputs,    $  ; Output Links (struct)
          myPos:self.myPos,        $  ; Current position (intarray)
          mySlot:self.mySlot,      $  ; Current slot (intarray)
          myDims:self.myDims,      $  ; Module dimensions (intarray)
          Status:self.Status       $  ; Current status (integer)
}

END

;T+
;
; \subsubsection{Method: {\tt GetID}}
;
; The following function returns the module ID. Module ID is assigned
; upon the creation of the module by means of a function which ensures
; the uniqueness of module ID's within the project.
;
;T-

FUNCTION Module::GetID

RETURN, self.ID

END


;T+
;
; \subsubsection{Method: {\tt GetFather}}
;
; Returns the father of the module, or OBJ_NEW() if it is not a clone
;
;T-

FUNCTION Module::GetFather

RETURN, self.Father

END


;T+
;
; \subsubsection{Method: {\tt GetSlot}}
;
; The following function returns the identification of the slot where the
; module is located. Slots in the worksheet are identified by couples
; of numbers in the fashion of two dimensional array elements (see
; section~\ref{GridSect}).
;
;T-

FUNCTION Module::GetSlot			; Returns an intarray

RETURN, self.mySlot

END

;T+
;
; \subsubsection{Method: {\tt GetGraph}}
;
; The following function returns the graphic objects which define
; the aspect of the module on the worksheet.
;
; The function returns an {\tt IDLgrModel} object.
;
;T-

FUNCTION Module::GetGraph

RETURN, self.Graph.Model

END

;T+
;
; \subsubsection{Method: {\tt GetHandle}}
;
; The following function, given a position within the worksheet
; (XY coordinates of a point), returns the structure corresponding
; to the input/output handle found in that position (if any).
;
;T-

FUNCTION Module::GetHandle, XY	; Point position (intarray)
				; Returns InOut structure
				; The field type of the structure codes
				; the return status as follows:

				; -1: Input section, but handle is not free.
				;  0: Parametetr definition section
				;  1: Input section
				;  2: Output section

XYr = XY-self.myPos		; Compute relative point position

Ret={ InOut, Type:0, ID:-1, Handle:0,                     $
             DType:0, Box:OBJ_NEW(), Line:OBJ_NEW() }

IF XYr[0] LT self.myDims[0]*0.2 THEN BEGIN	; Check if in input section
        IF self.Ninp GT 0 THEN BEGIN
		IF self.Ninp EQ 1 THEN Ret.Handle=0 ELSE BEGIN
        		IF XYr[1] LT self.myDims[1]*0.5 THEN      $
				Ret.Handle=0                      $
			ELSE                                      $
				Ret.Handle=1
		ENDELSE

		Ret.Type=1
		Ret.DType=self.Inputs[Ret.Handle].DType

					; if Input handle is already in use
					; return error
		IF self.Inputs[Ret.Handle].ID NE -1 THEN   $	; Handle in use
			Ret.Type= -1
		Ret.ID=self.ID
        ENDIF
ENDIF

IF XYr[0] GT self.myDims[0]*0.8 THEN BEGIN	; Check if output section
        IF self.Nout GT 0 THEN BEGIN
		IF self.Nout EQ 1 THEN Ret.Handle=0 ELSE BEGIN
        		IF XYr[1] LT self.myDims[1]*0.5 THEN      $
				Ret.Handle=0                      $
			ELSE                                      $
				Ret.Handle=1
		ENDELSE
		Ret.Type=2
		Ret.DType = self.Outputs[Ret.Handle].DType
		Ret.ID=self.ID
        ENDIF
ENDIF

RETURN, Ret

END

;T+
;
; \subsubsection{Method: {\tt GetIn}}
;
; The following functions, given an input handle index
; returns the corresponding InOut structure
;
;T-

FUNCTION Module::GetIn, Handle			; Get input handle

RETURN, self.Inputs[Handle]

END

;T+
;
; \subsubsection{Method: {\tt GetInCoord}}
;
; The following function, given an input handle structure index returns
; the corresponding coordinates in the current worksheet.
;
;T-

FUNCTION Module::GetInCoord, Handle

step = self.myDims[1]/self.Ninp
start = 0.5*step

xy = [0, step*Handle+start] + self.myPos

RETURN, xy

END

;T+
;
; \subsubsection{Method: {\tt GetNInputs}}
;
; The following function, returns the number of input handles
; for the module
;
;T-

FUNCTION Module::GetNInputs

RETURN, self.Ninp

END


;T+
;
; \subsubsection{Method: {\tt GetInputs}}
;
; The following function, returns an array containing the input handles
; defined for the module
;
;T-

FUNCTION Module::GetInputs

RETURN, self.Inputs

END

;T+
;
; \subsubsection{Method: {\tt GetOut}}
;
; The following function, given an output handle index
; returns the corresponding InOut structure
;
;T-

FUNCTION Module::GetOut, Handle			; Get input handle

RETURN, self.Outputs[Handle]

END

;T+
;
; \subsubsection{Method: {\tt GetOutCoord}}
;
; The following function, given an output handle index returns
; the corresponding coordinates in the current worksheet.
;
;T-

FUNCTION Module::GetOutCoord, Handle

step = self.myDims[1]/self.Nout
start = 0.5*step

xy = [self.myDims[0], step*Handle+start] + self.myPos

RETURN, xy

END

;T+
;
; \subsubsection{Method: {\tt GetStatus}}
;
; This procedure returns the current status of a module (See also:
; {\tt SetStatus()}).
;
;T-

FUNCTION Module::GetStatus

RETURN, self.Status

END


;T+
;
; \subsubsection{Method: {\tt GetType}}
;
; The following function returns the module type.
;
;T-

FUNCTION Module::GetType

RETURN, self.Type

END


;T+
;
; \subsubsection{Method: {\tt ChangeDType}}
;
; Module inputs and output have specific data types depending on the
; type of the module. Some modules, anyway, are defined as ``generic''
; in that they can be used in connection to many different data types
; (such modules are coded so that they can operate on different data
; types).
;
; The following function is used to set the actual data type for a
; generic type module the first time a link is defined to a typed
; input or output handle.
;
;T-

FUNCTION Module::ChangeDType, dtype

COMMON ModuleList, ListPtr, TypeList, Generic_dtype, IOcolors
COMMON GenDims, ModWidth, ModHeigth, Slotspace
						; Check that module is
						; actually generic
						; Set actual data type
FOR i=0, self.Ninp-1 DO BEGIN
	IF self.Inputs[i].DType EQ Generic_dtype THEN		$
		self->SetInType,i,dtype				$
	ELSE RETURN, 0
ENDFOR

FOR i=0, self.Nout-1 DO BEGIN
	IF self.Outputs[i].DType EQ Generic_dtype THEN		$
		self->SetOutType,i,dtype			$
	ELSE RETURN, 0
ENDFOR

RETURN, 1

END

;T+
;
; \subsubsection{Method: {\tt Offset}}
;
; When a module is created it is initially assigned to slot [0,0]
; and then moved to its final location.
;
; The following procedure moves a module to an assigned slot, with given xy
; position and modifies the coordinates of the graphic elements accordingly.
;
; This procedure assumes that the required slot is free, so the required
; check must be performed prior of the call.
;
; This procedure only affects the module itself and does not relocate
; links which might be defined for the module.
;T-

PRO Module::Offset, slotOfst, xyOfst	; Translate module of given offset
					; slotOfst (intarray): slot offset
					; xyOfst (intarray): corresponding
					;     coordinate offset

self.Graph.Model->Translate, xyOfst[0], xyOfst[1], 0.0

self.mySlot = self.mySlot + slotOfst
self.myPos = self.myPos + xyOfst

END

;T+
;
; \subsubsection{Method: {\tt PutLine}}
;
; The following procedure adds a link line to the module input section.
; The link line is a 'Link' object (see section~\ref{LinkSect}).
;
;T-

PRO Module::PutLine, Input, Line	; Input: input handle specifier (int)
					; Line:  line (Link obj)
self.Inputs[Input].Line = Line
END

;T+
;
; \subsubsection{Method: {\tt SetInType}}
;
; The following function is used to set the actual data type for a specified
; input handle
;
;T-

PRO Module::SetInType, handle, dtype

COMMON ModuleList, ListPtr, TypeList, Generic_dtype, IOcolors
COMMON GenDims, ModWidth, ModHeigth, Slotspace

IF handle LT self.Ninp THEN BEGIN
	self.Inputs[handle].dtype=dtype
	color=IOcolors[*,dtype]				; Change color
	self.Inputs[handle].Box->SetProperty, COLOR=color
ENDIF

END

;T+
;
; \subsubsection{Method: {\tt SetOutType}}
;
; The following function is used to set the actual data type for a specified
; output handle
;
;T-

PRO Module::SetOutType, handle, dtype

COMMON ModuleList, ListPtr, TypeList, Generic_dtype, IOcolors
COMMON GenDims, ModWidth, ModHeigth, Slotspace

IF handle LT self.Nout THEN BEGIN
	self.Outputs[handle].dtype=dtype
	color=IOcolors[*,dtype]				; Change color
	self.Outputs[handle].Box->SetProperty, COLOR=color
ENDIF

END

;T+
;
; \subsubsection{Method: {\tt SetParams}}
;
; Each module has an associated parameter input procedure which must be
; called to define running parameters.
;
; This procedure calls the module specific GUI ({\tt xxx\_gui()}) to allow
; the user to specify run-time parameters for this instance of the module.
;
; If the call of the parameter definition procedure is successful, the
; {\tt SetStatus} method is also called to notify the change of status.
;
;T-

FUNCTION Module::SetParams, ProjectName 	; Returns 0 on success
						;         1 No par set
						;         2 No par required
						; The name of the current
						; project must be specified
						; in the call.

COMMON Worksheet_Common, ModIDgen, DirName, ProjectModified, GridD, $
                         Slot0XY, FileVersion, AB_Name, AB_Version, AB_Date
mod_inf=getmodule(self.type)

IF (*mod_inf).rdpar THEN BEGIN
	if (!VERSION.OS_FAMILY eq 'Windows') then begin
	; L. ABE 2004.03.24
	cd, current=cur_dir
	cd, !CAOS_ENV.ROOT + 'packages\' + (*mod_inf).PKG + '\modules\' + self.type + '\'
	ProcName = STRUPCASE(self.type + '_gui')
	cd,cur_dir
	endif

	;ProcName = STRUPCASE(self.type + '_gui')

	Aux = WHERE(ROUTINE_INFO(/FUNCT) EQ ProcName, Count)

	IF COUNT EQ 0 THEN RESOLVE_ROUTINE, ProcName, /IS_FUNCTION

	LongName = filepath(ProjectName, ROOT=DirName)

	IF OBJ_VALID(self.Father) THEN			$
		Id=self.Father->GetID()			$
	ELSE						$
		Id=self.ID

	RetVal=CALL_FUNCTION(ProcName,Id,LongName)

	IF RetVal NE 0 THEN RetVal=1

ENDIF ELSE RetVal=2

RETURN, RetVal

END


;T+
;
; \subsubsection{Method: {\tt SetStatus}}
;
; This procedure sets the status of a module. The procedure both sets
; the module status word and modifies other module characterstics
; accordingly (E.g.: changes the module color to green when the ``parameter
; defined'' bit is set).
;
;T-

PRO Module::SetStatus, Status 		; The status word bits are defined
					; as follows:
					;
					;   Bit   Meaning
					;    1    Set params has been called

					; Other bits are currently undefined
					; and may be used in following releases

IF (Status AND 1) EQ 1 THEN BEGIN	; Status = Parameter defined
	self.myColor=[0,200,0]

	Parts=Self.Graph.Body->Get(/ALL)

	FOR i=0, N_ELEMENTS(Parts)-1 DO                       $
		Parts[i]->SetProperty, COLOR=self.myColor

	Self.Graph.Text->SetProperty, COLOR=self.myColor

	self.Status = self.Status OR 1
ENDIF

END

;T+
;
; \subsubsection{Method: {\tt SetLink}}
;
; The following function, given the specification of the endpoints of a link
; (a connection between an output handle and an input handle), sets the
; related information in the module.
;
;T-

PRO Module::SetLink, FromOutID, FromOutHandle, Input

COMMON ModuleList, ListPtr, TypeList, Generic_dtype, IOcolors

self.Inputs[Input].ID=FromOutID
self.Inputs[Input].Handle=FromOutHandle

END

;T+
;
; \subsubsection{Method: {\tt DelLink}}
;
; The following function, given the specification of an input handle,
; removes the link (actually sets the ID field to -1) and returns the
; associated link object which must be explicitly destroyed by the
; caller.
;
;T-

FUNCTION Module::DelLink,InputHandle,Input		; Deletes a link

IF self.Inputs[InputHandle].ID GE 0 THEN BEGIN
	self.Inputs[InputHandle].ID = -1
	line = self.Inputs[InputHandle].Line
	RETURN, Self.Inputs[InputHandle]
ENDIF ELSE RETURN, OBJ_NEW()

END

;T+
;
; \subsubsection{Method: {\tt List}}
;
; The following procedure outputs to an assigned logical unit a textual
; description of the module.
;
; This method is commonly used to save the module status onto disk.
;
;T-

PRO Module::List, Unit

IF self.type EQ '+++' THEN 				$
	type=self.type+self.SignChr[0]+self.SignChr[1]	$
ELSE							$
	type=self.type

slot = self.mySlot

IF self.Father EQ OBJ_NEW() THEN                                  $
	PRINTF, Unit, '; MODULE: ', type                          $
ELSE                                                              $
	PRINTF, Unit, '; MODULE: ', type, '     CLONE OF ',self.Father->GetID()

PRINTF, Unit, ';',Self.ID, ' - ID'
PRINTF, Unit, ';',Self.Status, ' - STATUS'
PRINTF, Unit, ';',slot[0],slot[1],' - SLOT'
PRINTF, Unit, ';',self.Ninp,' - Ninputs'
FOR i=0, self.Ninp-1 DO BEGIN
	IF self.Inputs[i].ID GE 0 THEN BEGIN
		Line = self.Inputs[i].Line
		Xvect=Line->GetX()
		Yvect=Line->GetY()
		NPoints=N_ELEMENTS(Xvect)
	ENDIF ELSE NPoints=0
	PRINTF,Unit,';',self.Inputs[i].ID,self.Inputs[i].Handle,' - Input',i, $
	            '    Nptns:',NPoints,'   Dtype:',Self.Inputs[i].DType
	IF NPoints GT 0 THEN BEGIN
		FOR k=0, NPoints-1 DO 	                          $
			PRINTF, Unit, ";	", FIX(Xvect[k]), $
			                           FIX(Yvect[k])
	ENDIF
ENDFOR
PRINTF, Unit, ';',self.Nout,' - Noutputs'
FOR i=0, self.Nout-1 DO BEGIN
	PRINTF,Unit,';',i,' - Output','   Dtype:',Self.Outputs[i].DType
ENDFOR

END

;T+
;
; \subsubsection{Method: {\tt Cleanup}}
;
; The IDL object oriented programming specification requires that any object
; is provided  with a {\tt cleanup} method which is called when the object
; is destroyed. It is used to destroy other objects which might be contained
; in the current one.
;
;T-

PRO Module::Cleanup

IF self.Graph.Model NE OBJ_NEW() THEN OBJ_DESTROY, self.Graph.Model
IF self.Graph.Body  NE OBJ_NEW() THEN OBJ_DESTROY, self.Graph.Body
IF self.Graph.Inp   NE OBJ_NEW() THEN OBJ_DESTROY, self.Graph.Inp
IF self.Graph.Text  NE OBJ_NEW() THEN OBJ_DESTROY, self.Graph.Text
IF self.Graph.Id    NE OBJ_NEW() THEN OBJ_DESTROY, self.Graph.Text
FOR i=0, self.Ninp-1 DO BEGIN
	IF self.Inputs[i].Line NE OBJ_NEW() THEN OBJ_DESTROY, self.Inputs[i].Line
	IF self.Inputs[i].Box NE OBJ_NEW() THEN OBJ_DESTROY, self.Inputs[i].Box
ENDFOR
FOR i=0, self.Nout-1 DO BEGIN
	IF self.Outputs[i].Line NE OBJ_NEW() THEN OBJ_DESTROY, self.Outputs[i].Line
	IF self.Outputs[i].Box NE OBJ_NEW() THEN OBJ_DESTROY, self.Outputs[i].Box
ENDFOR
END

;T+
; \subsubsection{Data Structure}
;
; The following procedure is the required structure definition for the module
; object.
;
;T-

PRO Module__define		; Module data structure definition

struct = { Module,  Type:'   ',                 $ ; Module type
                    ID:-1,                      $ ; Module id
                    Ninp:0,                     $ ; Number of Inputs
                    Nout:0,                     $ ; Number of outputs
                    NinpDef:0,			$ ; Number of Inputs defined
                    NoutDef:0,			$ ; Number of Outputs defined
                    Inputs: REPLICATE({InOut},2), $  ; Input links
                    Outputs: REPLICATE({InOut},2), $  ; Output links
                    myPos:[0,0],                $ ; Current position
                    mySlot:[-1,-1],             $ ; Current slot
                    myDims:[0,0],               $ ; Icon dimensions
                    Status:0,                   $ ; Module status
                    myColor:[0,0,0],            $ ; Current color
                    Graph:{gr, Model:OBJ_NEW(), $ ; Graphical aspect (Model)
                               Body:OBJ_NEW(),  $ ; Box
                               Inp:OBJ_NEW(),   $ ; Input graphics (Links)
                               Text:OBJ_NEW(),  $
                               Id:OBJ_NEW()},   $
                    Father:OBJ_NEW()            $ ; Father if the module is
						  ; a Clone
         }
END
