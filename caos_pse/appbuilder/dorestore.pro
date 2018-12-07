
;T+
; \subsubsection{External Entry Point: OpenProject}
;
; The following group of routines are used to open a new project reading data
; from a project directory. The structure of a project directory has been
; dealt with in a preceeding section (see sect.~\ref{projectsect}).
; The {\tt AB} code uses the main entry point: {\tt OpenProject}
; (Sect.~\ref{openproject}).
;
; \subsubsection{Procedure: {\tt ScanInput}}
;
; The following procedure is called by {\tt ScanModules} (see below) to
; decode the input section of the module textual representation.
;
;T-

; 26 July 2004 - modified in order to work also under windows XP
;                (in addition to Unix/Linux - not tested for MacOS and vms)
;              - lyu abe [lyu.abe@unice.fr],
;                brice le roux [leroux@arcetri.astro.it],
;                marcel carbillet [marcel@arcetri.astro.it].

PRO ScanInput, Mode, Unit, fVersion, Module, InputN, xyOfst, info, IdOff
					; Scans the Input handle description
					; For mode=1, recreates the project
					;             strucutre
					; For mode=2, fills in the input data
COMMON OpenCommon, MaxId

Fline=''
Px=INTARR(100)
Py=INTARR(100)

Id = Module->GetID()			; Get module ID, possibly already offset

READF, Unit, Fline
Fline=STRMID(Fline,1,80)
READS, Fline, FromID, FromHandle

IF FromId GT 0 THEN FromId = FromId + IdOff	; Add Id offset if
						; input is defined

IF Mode EQ 1 THEN                                           $
	IF FromID GE 0 THEN Module->SetLink,FromID,         $
                                       FromHandle,InputN

IF fVersion LE 3 THEN	          $
	n=STRPOS(Fline,'Extra:')  $	; Search for multipoint
ELSE                              $	; line
	n=STRPOS(Fline,'Nptns:')	; Search for # of points
IF n GT 0 THEN BEGIN			; line
	Fline=STRMID(Fline,n+6,40)	; Extract # of points
	READS, Fline, Nxy
ENDIF ELSE Nxy=0
n=STRPOS(Fline,'Dtype:')		; Search input datatype
IF n GT 0 THEN BEGIN
	Fline=STRMID(Fline,n+6,40)	; Extract Input type
	READS, Fline, Dtype
	IF Mode EQ 1 THEN Module->SetInType,InputN,Dtype
ENDIF

IF fVersion LE 3 THEN BEGIN	; Up to version 3 only extra
	FirstK=1 		; line coordinates where stored
	LastK= Nxy
ENDIF ELSE BEGIN		; After version 3 all line
	FirstK=0		; coordinates are stored
	LastK= Nxy-1
ENDELSE

IF Nxy GT 0 THEN BEGIN
	FOR k=FirstK, LastK DO BEGIN	; Read line coordinates
		READF, Unit, Fline
		Fline=STRMID(Fline,1,80)
		READS, Fline, xx,yy
		Px[k]=xx
		Py[k]=yy
	ENDFOR
ENDIF

IF FromID GE 0 THEN BEGIN
	IF Mode EQ 2 THEN BEGIN
		FromModule=(*info).MvPrj->FindModule(FromID)
		ToModule=(*info).MvPrj->FindModule(Id)

		IF fVersion LE 3 THEN BEGIN	; Put in coordinates of
						; input and output handles
			xy=FromModule->GetOutCoord(FromHandle)
			Px[0]=xy[0]
			Py[0]=xy[1]
			xy=ToModule->GetInCoord(InputN)
			Nxy=Nxy+1;
			Px[Nxy]=xy[0]
			Py[Nxy]=xy[1]
			Nxy=Nxy+1;
		ENDIF
		Px=Px[INDGEN(Nxy)]
		Py=Py[INDGEN(Nxy)]
		Px = Px + xyOfst[0]		; Relocate links coord.
		Py = Py + xyOfst[1]
		Line=ComputeLine(0,Px,Py)
		ToModule->PutLine,InputN,Line
		(*info).MvPrj->AddGraph, Line
	ENDIF
ENDIF

END

;T+
; \subsubsection{Procedure: {\tt ScanModules}}
;
; The following procedure is called by {\tt doRESTORE} (see below) to
; decode the module textual representation at the beginning of the
; module section of the project textual representation. It calls
; {\tt ScanInput} for each input defined to decode the input specific
; textual representation.
;
; The Project description printout procedure ensures that all clones
; descriptions are written after plain modules descriptions, so that
; when a clone is encountered, the corresponding module has been already
; created.
;
;T-

PRO ScanModules, Mode, Unit, fVersion, NModules, xyOfst, info, IdOff
					; Scans the module description
					; For mode=1, recreates the project
					;             structure
					; For mode=2, fills in the input data

COMMON Worksheet_Common, ModIDgen, DirName, ProjectModified, GridD, $
                         Slot0XY, FileVersion, AB_Name, AB_Version, AB_Date

COMMON OpenCommon, MaxId

Fline=''
slot=INTARR(2)
xyPos=INTARR(2)
Status=0

FOR ModN=0, Nmodules-1 DO BEGIN
	READF, Unit, Fline
	ModType=STRMID(Fline,10,3)		; Extract mod type from line
	IF ModType EQ '   ' THEN ModType='+++'	; For compatibility with
						; FileVersions < 3
	IF STRLEN(Fline) GT 18 THEN BEGIN	; Test if a clone
		Fline=STRMID(Fline,28,80)	; Extract Father ID
		READS, Fline, fID
	ENDIF ELSE fID=0

	fID = fID + IdOff

	READF, Unit, Fline
	Fline=STRMID(Fline,1,80)	; Read Module ID
	READS, Fline, Id
	Id = Id + IdOff
	IF Mode EQ 1 THEN BEGIN
		IF Id GT MaxId THEN MaxId = Id
		CASE ModType OF
		'+++': BEGIN				; Combiner
			IF fID GT 0 THEN BEGIN
				Father = (*info).MvPrj->FindModule(fId)
				Module=OBJ_NEW('Combiner',Id, FATHER=Father)
			ENDIF ELSE Module=OBJ_NEW('Combiner',Id)

			Signs=STRMID(Fline,13,2)
			Module->SetSigns,Signs
		       END
		's*s': BEGIN				; Feedback stop
			IF fID GT 0 THEN BEGIN
				Father = (*info).MvPrj->FindModule(fId)
				Module=OBJ_NEW('FdbStop',Id, FATHER=Father)
			ENDIF ELSE Module=OBJ_NEW('FdbStop',Id)
		       END
		ELSE:  BEGIN				; Generic module
			IF fID GT 0 THEN BEGIN
				Father = (*info).MvPrj->FindModule(fId)
				Module=OBJ_NEW('Module', ModType, Id, FATHER=Father)
			ENDIF ELSE Module=OBJ_NEW('Module', ModType, Id)
		       END
		ENDCASE
		IF ModIDGen LT Id THEN ModIDGen=Id
	ENDIF ELSE Module=(*info).MvPrj->FindModule(Id)


	IF fVersion GT 1 THEN BEGIN
		READF, Unit, Fline
		Fline=STRMID(Fline,1,80)
		READS, Fline, Status		; Read module status
		IF Mode EQ 1 THEN Module->SetStatus,Status   ; Set module status
	END

	READF, Unit, Fline
	Fline=STRMID(Fline,1,80)	; Read Slot position
	READS, Fline, slot

	IF fVersion LT 3 THEN BEGIN
		READF, Unit, Fline
		Fline=STRMID(Fline,1,80)	; Read XY position (unused)
		READS, Fline, xyPos		; Eliminated from FileVersion 3
	ENDIF

	xyPos = (*info).oGrid->slot2screen(slot)-Slot0XY
	IF Mode EQ 1 THEN Module->Offset,slot,xyPos
	IF Mode EQ 1 THEN (*info).MvPrj->PushModule,Module

	READF, Unit, Fline
	Fline=STRMID(Fline,1,80)	; read number of inputs
	READS, Fline, Ninputs

	xyOfst=[0,0]
	IF (fVersion GT 3) AND (fVersion LT 8) THEN  $ ; Fix bug on some
		xyOfst = Slot0XY                       ; fileversions

	FOR InputN=0, Ninputs-1 DO BEGIN
		ScanInput, Mode, Unit, fVersion, Module, InputN, $
		           xyOfst, info, IdOff
	ENDFOR

	IF fVersion GT 0 THEN BEGIN	; Check for file version
		READF, Unit, Fline
		Fline=STRMID(Fline,1,80)	; read number of outputs
		READS, Fline, Nout
		FOR OutN=0, Nout-1 DO BEGIN
			READF, Unit, Fline
			n=STRPOS(Fline,'Dtype:')	; Search output datatype
			Fline=STRMID(Fline,n+6,40)	; Extract # of points
			READS, Fline, Dtype
			IF Mode EQ 1 THEN Module->SetOutType,OutN,Dtype
		ENDFOR
	ENDIF
ENDFOR

END

;T+
; \subsubsection{Procedure: {\tt ScanText}}
;
; The following procedure is called by {\tt doRESTORE} (see below) to
; decode the comment text ASCII representation from the file header.
;
;T-

PRO ScanText, Unit, info			; Scan text representation

COMMON OpenCommon, MaxId

Color=INTARR(3)
Location=INTARR(2)
FontName=''
Fline=''

READF, Unit, Fline
WHILE STRMID(Fline,0,1) EQ ';' DO BEGIN
	IF STRMID(Fline,1,5) EQ 'TEXT:' THEN BEGIN
		String=STRTRIM(STRMID(Fline,7,120),2)
		READF, Unit, Fline
		Fline=STRMID(Fline,1,40)	; read alignment
		READS, Fline, Angle
		READF, Unit, Fline
		Fline=STRMID(Fline,1,40)	; read color
		READS, Fline, Color
		READF, Unit, Fline		; read fontname
		n=STRPOS(Fline,'-')-2
		FontName=STRTRIM(STRMID(Fline,1,n),2)
		READF, Unit, Fline		; read Font size
		Fline=STRMID(Fline,1,40)
		READS, Fline, Size
		READF, Unit, Fline		; read Location
		Fline=STRMID(Fline,1,40)
		READS, Fline, Location

		fo = OBJ_NEW('IDLgrFont', FontName, SIZE=Size )

		angle=fix(angle)
		sina = sin(angle*0.017453293)
		cosa = cos(angle*0.017453293)
		bline= [cosa,sina]

		Txt =  OBJ_NEW('Text', String, Angle )
		Txt->SetProperty, ALIGNMENT=0,                      $
		                  COLOR=Color,                      $
                                  BASELINE=bline,                   $
		                  FONT=fo
		Txt->SetPosition,Location
		(*info).MvPrj->AddGraph,Txt
	ENDIF
	READF, Unit, Fline
ENDWHILE

END


;T+
; \subsubsection{Function: {\tt doRESTORE}}
;
; The following procedure is called by {\tt OpenProject} (see below) to
; decode the project textual representation. After reading the project
; general parameters the function creates the required objects and then
; it calls {\tt ScanModules} to decode the modules textual representation.
;
; \noindent {\bf Note:} The scanning of project textual representation is
;           done in two passes: in the first pass the project structure is
;           created, while some data items (notably the data flow links)
;           must be filled in in the second pass.
;T-

FUNCTION doRESTORE, savefile, info, IdOff	; Returns '' or error message

COMMON Worksheet_Common, ModIDgen, DirName, ProjectModified, GridD, $
                         Slot0XY, FileVersion, AB_Name, AB_Version, AB_Date

COMMON OpenCommon, MaxId

MaxId=0

(*info).MvPrj=OBJ_NEW('Project')

OPENR, Unit,savefile,/GET_LUN

Fline=''
Goon=1
fVersion=0
WHILE Goon DO BEGIN			; Look for Project start
	READF, Unit, Fline
	IF STRMID(Fline, 1, 8) EQ 'PROJECT:' THEN BEGIN
		Goon=0
	ENDIF
	IF STRMID(Fline, 1, 8) EQ 'APPBLDR:' THEN BEGIN
		Fline=STRMID(Fline,10,30)
		READS, Fline, Version
	ENDIF
	IF STRMID(Fline, 1, 8) EQ 'FILEVER:' THEN BEGIN
		Fline=STRMID(Fline,10,30)
		READS, Fline, fVersion
	ENDIF
ENDWHILE

PrjName=STRMID(Fline,10,70)
PrjName=STRTRIM(PrjName)

(*info).MvPrj->GiveName,PrjName

IF fVersion GT 5 THEN BEGIN
	READF, Unit, Fline
	Fline=STRMID(Fline,1,80)		; Get rid of comment char
	READS, Fline, Ptype
	(*info).MvPrj->SetType,Ptype
	READF, Unit, Fline
	Fline=STRMID(Fline,1,80)		; Get rid of comment char
	READS, Fline, Nitr
	(*info).MvPrj->SetIter,Nitr
ENDIF

READF, Unit, Fline
Fline=STRMID(Fline,1,80)		; Get rid of comment char
READS, Fline, NModules

PrjBox=INTARR(4)
READF, Unit, Fline
Fline=STRMID(Fline,1,80)		; Get rid of comment char
READS, Fline, PrjBox

PrjSize=[PrjBox[1]-PrjBox[0]+1, $	; Get Project size
         PrjBox[3]-PrjBox[2]+1]

Gsize = (*info).oGrid->GetSize()	; Get worksheet size

IF (Gsize[2] LT Prjsize[0]) OR   $
   (Gsize[3] LT PrjSize[1])      $
	THEN BEGIN
	CLOSE,Unit
	RETURN, 'Project too big to fit into worksheet'
	ENDIF

POINT_LUN, -Unit, BeginModules		; Get file pointer for rewinding

xyOfst=[0,0]

ScanModules, 1, Unit, fVersion, NModules, $		; First scan
                 xyOfst, info, IdOff

(*info).MvPrj->SetMaxId, MaxId
					; After version 3, graphic elements
					; coordinates are relative to project
					; origin
IF fVersion GT 3	 THEN    $
	xyOfst = (*info).oGrid->Slot2screen([PrjBox[0],PrjBox[3]])

;			Now set up link lines (It is done a separate loop
;			because not all the modules are available during
;			the first scan)

POINT_LUN, Unit, BeginModules		; reset file pointer to beginning
					; of modules description

ScanModules, 2, Unit, fVersion, NModules, $		; Second scan
                 xyOfst, info, IdOff

ScanText, Unit, info			; Scan text representation

ProjectModified=0


PrGraphs = (*info).MvPrj->GetGraph()
FOR i=0,N_ELEMENTS(PrGraphs)-1 DO 			$
	IF OBJ_VALID(PrGraphs[i]) THEN 			$
		(*info).oView->add,PrGraphs[i]

(*info).oWin->DRAW, (*info).oView

							; Change cursor
IF (*info).cursor NE '' THEN (*info).oWin->SetCurrentCursor, (*info).cursor

CLOSE,Unit

RETURN, ''

END

