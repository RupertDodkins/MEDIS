;T+
; \subsubsection{Object Description}
; 
; The project object is the support for the management of the set of
; modules which together represent the simulation application program.
; 
; It is actually a dynamic list of modules with the operations needed for
; list management implemented as methods.
; 
;T-

; NAME:
;
;       Project     - Project define block
;
; Usage:
;
;	Project = Obj_New('Project')
;
; Methods:
;
;	Project->GiveName,'ProjectName'		; Give a name to project
;	name=Project->GetName()			; Get project name
;	Project->List				; List a Project
;       Project->PushModule, Module		; Add a module to project
;       Project->Merge, prj			; merges into another project
;       graph=Project->GetGraph()		; Returns project graphics
;       graph=Project->PopGraph()		; Pops project graphics
;       Project->RemoveGr()			; Removes graphic element
;       Project->AddGraph,gr			; Add graphic element
;       Module = Project->PopModule()		; Delete topmost module from 
;       Project->DelModule, Module		; delete a module from a project
;	Module = Project->GetModFromSlot(slot)	; Find the module in given slot
;	Module = Project->FindModule(ModID)	; Find the module With given ID
;	ModArray= Project->GetList()		; Get module list
;	ModArray= Project->ConnList(ID)		; Get list of modules with 
;						; given module as input.
;	ModArray= Project->GetClones(Module)	; Get All clones of given module
;	maxModID = Project->GetMaxID()		; Get Maximum ID
;	Project->SetMaxID, MaxID		; Set Maximum ID
;	Niter = Project->GetIter()		; Get Number of Iterations
;	Project->SetIter, N		        ; Set Number of Iterations
;	Ptype = Project->GetType()		; Get Project type ID
;	Project->SetType, N		        ; Set Project type ID
;	Box = Project->GetBox()	        ; Returns Project box corners:
;				        ; [XslotMin,XslotMax,YslotMin,YslotMax]
;	Project->Translate,SlotOfst,xyOfst	; Translate project
;
; Notes:
;	A project is essentially a linked list of Modules
;

;T+
; \subsubsection{Internal Methods}
;
; The following procedures and functions are not part of the interface 
; of the {\tt project} module in that they are support procedures used
; by actual methods.
;
; \subsubsubsection{ ModListElm__define }
;
; The following procedure manages the linked list
; where modules are stored. It is actually used only to define a list
; element as an IDL structure.
;T-

PRO ModListElm__define		; Module List Element structure definition

struct = { ModListElm, Module:OBJ_NEW(),           $ ; This Module
                       Next:PTR_NEW()              $ ; Pointer to Next Module
         }
END


;T+
; \subsubsubsection{ ExtractTxtElm }
;
; The following procedure Extracts IdlGrText objects from a container
; possibly descending the container's structure and stores them in 
; another container.
;
;T-

PRO ExtractTxtElm, Obj, Bin
IF OBJ_VALID(Obj) THEN BEGIN
	GrArray = Obj->get(/all,Count=Nelm)
	FOR i=0, Nelm-1 DO BEGIN
		WhichClass=OBJ_CLASS(GrArray[i])
		IF WhichClass EQ 'IDLGRMODEL' THEN 		$
			ExtractTxtElm, GrArray[i], Bin		$
		ELSE BEGIN
			IF WhichClass EQ 'TEXT' THEN		$
				IF Bin[0] EQ OBJ_NEW() THEN 	$
					Bin[0] = GrArray[i]	$
				ELSE				$
					Bin = [Bin, GrArray[i]]
		ENDELSE
	ENDFOR
ENDIF

END


;T+
; \subsubsection{Method: {\tt INIT}}
;
;T-

FUNCTION Project::INIT, name		; Initialize Project

self.PrjName = 'newproject'
self.ModGraph=OBJ_NEW('IDLgrModel')
self.Layers = PTR_NEW([OBJ_NEW('IDLgrModel')])
self.NIters=1L;

RETURN, 1
END

;T+
; \subsubsection{Method: {\tt GiveName}}
;
; This procedure gives a name to the project.
;
;T-

PRO Project::GiveName, name		; Change name to the project

self.PrjName = name

END

;T+
; \subsubsection{Method: {\tt GetName}}
;
; The following function returns the current name of the project.
;
;T-

FUNCTION Project::GetName			; Returns project name

RETURN, self.PrjName

END

;T+
; \subsubsection{Method: {\tt GetGraph}}
;
; Graphic details associated to the project are stored into internally
; maintained graphic objects of the type {\tt IDLgrModel}. The project's
; graphic details are returned into an array. The first element contains
; the bodies of all modules, the following elements contain all the other
; graphics (links, and text comments) subdivided in different layers,
; one layer is added to the array any times a translate operation is
; performed. 
;
;T-

FUNCTION Project::GetGraph			; Returns project graphics

RETURN, [self.ModGraph, (*self.Layers)]

END


;T+
; \subsubsection{Method: {\tt PopGraph}}
;
; Graphic details associated to the project are returned as in function
; {\tt GetGraph}. The internal objects are also set to NULL so that
; destroying the project object doesn't also destroys the graphic objects.
; This is needed by the Merge function.
;
; This function returns the same graphic object array as the Method: 
; {\tt GetGraph}.
;T-

FUNCTION Project::PopGraph			; Returns project graphics

Graph = [self.ModGraph, (*self.Layers)]

self.ModGraph = OBJ_NEW()
PTR_FREE, self.Layers
self.Layers=PTR_NEW()

RETURN, Graph

END


;T+
;
; \subsubsection{Method: {\tt AddGraph}}
;
; The following procedure adds a graphic element to the project. The element
; is added to the topmost layer of the project.
;
;T-

PRO Project::AddGraph,gr			

(*self.Layers)[0]->add,gr

END

;T+
;
; \subsubsection{Method: {\tt RemoveGr}}
;
; The following procedure removes a graphic element from the project
;
;T-

PRO Project::Removegr,gr			; Removes graphic element

FOR i=0,N_ELEMENTS(*self.Layers)-1 DO BEGIN
	IF (*self.Layers)[i]->IsContained(Gr) THEN 	$
		(*self.Layers)[i]->remove,gr
ENDFOR

END





;T+
; \subsubsection{Method: {\tt Merge}}
;
; This procedure merges into the object another project.
; The two projects mus have been created so that
; all modules have unique ID's because no check is performed.
;
; The project just merged is destroyed.
;
;T-

PRO Project::Merge, Source

Goon=1

WHILE Goon EQ 1 DO BEGIN			; First move modules
	Obj=Source->PopModule()
	IF OBJ_VALID(Obj) THEN 		$
		self->PushModule,Obj	$
	ELSE				$
		Goon=0
ENDWHILE

Graphs = Source->PopGraph()		; Then move graphics elements

FOR i=1,N_ELEMENTS(Graphs)-1 DO (*self.Layers)[0]->add,Graphs[i]

OBJ_DESTROY,Source
OBJ_DESTROY,Graphs[0]			; These are the module bodies and 
					; can be destroyed
END


;T+
;
; \subsubsection{Method: {\tt PushModule}}
;
; The following procedure pushes (adds) a new module to a project.
;
;T-

PRO Project::PushModule, Module			; Add a module to project

NewElm = OBJ_NEW('ModListElm')		; Create new list element
NewElm.Module=Module
NewElm.Next=Self.Body
Self.Body=PTR_NEW(NewElm)

Self.counter = Self.counter+1		; Update module counter
gr=Module->GetGraph()
Self.ModGraph->add,gr			; Add module to project graphics

END

;T+
;
; \subsubsection{Method: {\tt PopModule}}
;
; The following function pops (removes) the topmost module from a project. 
; The removed module object is returned to the caller.
;
;T-

FUNCTION Project::PopModule			; Delete topmost module from 
						; a project list. Return popped
						; module
RetMod=OBJ_NEW()

IF self.Body NE PTR_NEW() THEN BEGIN
	Current=self.Body
	RetMod=(*Current).Module
	self.ModGraph->remove,RetMod->GetGraph()
	self.Body=(*Current).Next
	OBJ_DESTROY,*Current
	self.Counter = self.Counter-1
ENDIF
	
RETURN, RetMod

END

;T+
;
; \subsubsection{Method: {\tt GetBox}}
;
; The following function finds the slot box where the project is
; located and returns it as a four elements array {\tt [minX,maxX,minY,maxY]}.
;
;T-

FUNCTION Project::GetBox			; Returns Project box dimension
						; (in slots)
Current = self.Body
Maxx=0
Minx=100000
Maxy=0
Miny=100000

WHILE Current NE PTR_NEW() DO BEGIN
	TheSlot=(*Current).Module->GetSlot()
	IF TheSlot[0] LT Minx THEN Minx=TheSlot[0]
	IF TheSlot[1] LT Miny THEN Miny=TheSlot[1]
	IF TheSlot[0] GT Maxx THEN Maxx=TheSlot[0]
	IF TheSlot[1] GT Maxy THEN Maxy=TheSlot[1]

	Current = (*Current).Next
ENDWHILE

RETURN, [Minx,Maxx,Miny,Maxy]
END

;T+
;
; \subsubsection{Method: {\tt Translate}}
;
; The following procedure translates a project of given amount (both
; a slot offset and the corresponding screen coordinate offset must be 
; provided).
;
;T-

PRO Project::Translate,SlotOfst,xyOfst		; Translate project

Current = self.Body

WHILE Current NE PTR_NEW() DO BEGIN		; Translate modules
	(*Current).Module->Offset,SlotOfst,xyOfst
	Ninp=(*Current).Module->GetNInputs()
	ModInp=(*Current).Module->GetInputs()
	FOR i=0, Ninp-1 DO   			$
		IF ModInp[i].ID GE 0 THEN ModInp[i].line->Translate,xyOfst
	Current = (*Current).Next
ENDWHILE

					; Translate Text elements
TempBin = OBJARR(1)			; Create temporary container

FOR i=0,N_ELEMENTS(*Self.layers)-1 DO ExtractTxtElm, (*self.Layers)[i], TempBin

LastElm=N_ELEMENTS(TempBin)-1;
IF TempBin[0] EQ OBJ_NEW() THEN LastElm = -1

FOR i=0, LastElm DO TempBin[i]->Translate,xyOfst

					; Translate graphic items
;Newlayer = OBJ_NEW('IDLgrModel')	; Create a new Layer
;AnObj=Self.Graph->Get()			; Populate layer
;WHILE OBJ_VALID(AnObj) DO BEGIN
;	Self.Graph->remove,AnObj
;	NewLayer->add,AnObj
;	AnObj=Self.Graph->Get()
;ENDWHILE

;Self.Layers->add, NewLayer		; Add to layer lists
;Self.Layers->Translate,xyOfst		; Translate Layers

FOR i=0,N_ELEMENTS(*Self.Layers)-1 DO 				$
	IF OBJ_VALID((*self.Layers)[i]) THEN			$
		(*self.Layers)[i]->Translate,xyOfst[0],xyOfst[1],0

self.Layers = PTR_NEW([ OBJ_NEW('IDLgrModel'), *Self.Layers ],/NO_COPY)

END

;T+
;
; \subsubsection{Method: {\tt GetModFromSlot}}
;
; The following function finds the module of the project which is
; contained in given grid slot.
;
;T-

FUNCTION Project::GetModFromSlot, slot		; Find the module in given slot

RetMod=OBJ_NEW()
Current = self.Body

WHILE Current NE PTR_NEW() DO BEGIN
	TheSlot=(*Current).Module->GetSlot()
	IF Total(TheSlot EQ slot) EQ 2 THEN BEGIN  ; Module found
		RetMod=(*Current).Module
		GOTO, LoopEnd	; This terminates WHILE loop
	ENDIF
	Current = (*Current).Next
ENDWHILE
LoopEnd:

RETURN, RetMod

END

;T+
;
; \subsubsection{Method: {\tt List}}
;
; The following function outputs onto a given logical unit a printable
; representation of the project. It is mainly used to store the project
; structure on top of the {\tt project.pro} procedure file 
; (see Sect.~\ref{projectsect}).
;
;T-

PRO Project::List,Unit,SlotOfst,xyOfst			; List project

COMMON Worksheet_Common, ModIDgen, DirName, ProjectModified, GridD, $
                         Slot0XY, FileVersion, AB_Name, AB_Version, AB_Date
Box = self->GetBox();


PRINTF, Unit,';FILEVER: ', FileVersion
PRINTF, Unit,';PROJECT: ', self.PrjName
PRINTF, Unit, ';', self.PrjType, ' - PROJECT TYPE'
PRINTF, Unit, ';', self.NIters,  ' - ITERATIONS'
PRINTF, Unit, ';', self.Counter, ' - NMODS'

PRINTF, Unit,';', Box[0],Box[1],Box[2],Box[3], ' - Box'

;
;					First print Modules descriptions
;
Current = self.Body
WHILE Current NE PTR_NEW() DO BEGIN
	IF (*Current).Module->GetFather() EQ OBJ_NEW() THEN 	$
	                               (*Current).Module->List,Unit
	Current = (*Current).Next
ENDWHILE
;
;					Then print clones descriptions
;
Current = self.Body
WHILE Current NE PTR_NEW() DO BEGIN
	IF (*Current).Module->GetFather() NE OBJ_NEW() THEN 	$
	                               (*Current).Module->List,Unit
	Current = (*Current).Next
ENDWHILE
					; List text elements
TempBin = OBJARR(1)			; Create temporary container

FOR i=0,N_ELEMENTS(*Self.layers)-1 DO 			$
	ExtractTxtElm, (*self.Layers)[i], TempBin

LastElm=N_ELEMENTS(TempBin)-1;
IF TempBin[0] EQ OBJ_NEW() THEN LastElm = -1

FOR i=0, LastElm DO BEGIN
	PRINTF, Unit,';'
	TempBin[i]->GetProperty, STRING=String,			$
	                         COLOR=Color,			$
	                         FONT=Font

	Font->GetProperty, NAME=FontName, SIZE=Size

	Location = TempBin[i]->GetPosition()
	Angle = TempBin[i]->GetAngle()

	PRINTF, Unit,';TEXT: ', String
	PRINTF, Unit,'; ', Angle,    '  - Angle'
	PRINTF, Unit,'; ', Color[0],        			$
	                   Color[1],				$
	                   Color[2],     '  - Color'
	PRINTF, Unit,'; ', FontName,     '  - Fontname'
	PRINTF, Unit,'; ', Size,         '  - Size'
	PRINTF, Unit,'; ', Location[0],				$
	                   Location[1],  '  - Location'
ENDFOR

END

;T+
;
; \subsubsection{Method: {\tt DelModule}}
;
; The following procedure deletes a module from a project.
;
;T-

PRO Project::DelModule, Module			; delete a module from a project

Previous=PTR_NEW()
Current = self.Body

WHILE Current NE PTR_NEW() DO BEGIN

	IF (*Current).Module EQ Module THEN BEGIN  ; Module found, delete it
		IF Previous EQ PTR_NEW() THEN               $
			self.Body = (*Current).Next         $
		ELSE                                        $
			(*Previous).Next = (*Current).Next

		TheMod=(*Current).Module
		self.ModGraph->remove,TheMod->GetGraph()
		OBJ_DESTROY, *Current
		OBJ_DESTROY, TheMod
		self.counter = self.counter-1
		GOTO, LoopEnd	; This terminates WHILE loop
	ENDIF

	Previous=Current
	Current=(*Previous).Next
ENDWHILE
		
LoopEnd:

END


;T+
;
; \subsubsection{Method: {\tt FindModule}}
;
; This function scans the module list to find module with given Module ID.
;
;T-

FUNCTION Project::FindModule, ModID

Current = self.Body

EndLoop=0
Ret=OBJ_NEW()

REPEAT BEGIN
	IF Current NE PTR_NEW() THEN BEGIN
		IF (*Current).Module->GetID() EQ ModID THEN BEGIN
			EndLoop=1
			Ret=(*Current).Module
		ENDIF ELSE Current = (*Current).Next
	ENDIF ELSE EndLoop=1
ENDREP UNTIL EndLoop

RETURN, Ret

END

;T+
;
; \subsubsection{Method: {\tt SetMaxID}}
;
; For the purpose of generating unique module ID's this function is
; used to set the max value of ID among all the modules in the project.
;
;T-

PRO Project::SetMaxID, MaxID			; Set Maximum ID

self.MaxID = MaxID

END

;T+
;
; \subsubsection{Method: {\tt GetMaxID}}
;
; This function returns the max ID value among project modules.
;
;T-


FUNCTION Project::GetMaxID			; Get Maximum ID

RETURN, self.MaxID

END

;T+
;
; \subsubsection{Method: {\tt SetIter}}
;
; This method sets the number of iterations of the project
;
;T-

PRO Project::SetIter, N			; Set Number of iterations

self.NIters = N

END


;T+
;
; \subsubsection{Method: {\tt GetIter}}
;
; This method gets the number of iterations of the project
;
;T-


FUNCTION Project::GetIter			; Get Maximum ID

RETURN, self.NIters

END

;T+
;
; \subsubsection{Method: {\tt SetType}}
;
; This method sets the project type ID
;
;T-

PRO Project::SetType, N			; Set Number of iterations

IF N LE 0 THEN N=0
IF N GT 1 THEN N=1

self.PrjType = N

END




;T+
;
; \subsubsection{Method: {\tt GetType}}
;
; This method gets the number of iterations of the project
;
;T-


FUNCTION Project::GetType			; Get Maximum ID

RETURN, self.PrjType

END



;T+
;
; \subsubsection{Method: {\tt GetClones}}
;
; This function returns an array containing all modules which are clones
; of the given module, including the father module. If the module has not 
; clones the list contains only the module itself.
;
;T-

FUNCTION Project::GetClones, Module

ModArray = OBJARR(1)

IF Module->GetFather() EQ OBJ_NEW() THEN		$
	ModArray[0] = Module				$
ELSE							$
	ModArray[0] = Module->GetFather()

Current = self.Body

WHILE Current NE PTR_NEW() DO BEGIN
	IF (*Current).Module->GetFather() EQ ModArray[0] THEN	$
	ModArray= [ ModArray, (*Current).Module ]
	Current = (*Current).Next
ENDWHILE

RETURN, ModArray

END

;T+
;
; \subsubsection{Method: {\tt GetList}}
;
; This function returns an array containing all modules in the project.
;
;T-

FUNCTION Project::GetList

ModArray = OBJARR(self.Counter)

Current = self.Body

i=0

WHILE Current NE PTR_NEW() DO BEGIN
	ModArray[i]=(*Current).Module
	Current = (*Current).Next
	i=i+1
ENDWHILE

RETURN, ModArray

END


;T+
;
; \subsubsection{Method: {\tt Cleanup}}
;
;T-

PRO project::Cleanup

Current = self.Body

WHILE Current NE PTR_NEW() DO BEGIN
	hold = (*Current).Next
	OBJ_DESTROY,(*Current).Module
	OBJ_DESTROY,*Current
	Current = hold
ENDWHILE

IF PTR_VALID(self.Layers) THEN BEGIN
	FOR i=0,N_ELEMENTS(*self.Layers)-1 DO 				$
		IF OBJ_VALID((*self.Layers)[i]) THEN 			$
			OBJ_DESTROY, (*self.Layers)[i]

	PTR_FREE, self.Layers
ENDIF

END

;T+
; \subsubsection{Data Structure}
;
; The following procedure is the required structure definition for the module
; object.
; 
;T-

PRO Project__define		; Project data structure definition

struct = { Project,                       $
           PrjName:'',                    $ ; Project name
           MaxID:0,                       $ ; Remember max Mod ID
           Counter:0,                     $ ; Internal Counter
           NIters:1L,                      $ ; Number of iterations
           PrjType:0,                     $ ; Project type:
					    ;  0 - Simulation
					    ;  1 - Calibration
; ---      Offset:[0,0],                  $ ; Project origin offset
                                            ; (keeps track of translations)
           ModGraph:OBJ_NEW(),            $ ; Module graphics
           Layers:PTR_NEW(),              $ ; Translation layers
           Body:PTR_NEW()                 $ ; Project contents
         }
                                                    
END
