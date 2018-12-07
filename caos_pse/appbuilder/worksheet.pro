;;
;; CAOS Application Builder main code
;;
;; - Created by Luca Fini (OAA) [lfini@arcetri.astro.it].
;;
;; - Modifications from beta version (1998) to version 5.0 (2005)
;;   implemented by:
;;   * Luca Fini (OAA) [lfini@arcetri.astro.it],
;;   * Marcel Carbillet (OAA->LUAN) [marcel.carbillet@unice.fr],
;;   * Armando Riccardi (OAA) [riccardi@arcetri.astro.it],
;;   * Brice Le Roux (OAA->LAM) [brice.leroux@oamp.fr].
;;
;; - Modifications for version 5.1:
;;   * Evelyne Augier (LUAN) [evelyne.augier@unice.fr]:
;;     + fixed annoying problem of positioning when a project get open.
;;
;; - Modifications for version 5.2:
;;   * Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr]:
;;     + power spectrum type (pws_t) added for forthcoming Soft.Pack.PAOLAC
;;     + CPU time computation added (routine saveproject.pro modified)
;;
;; - Modifications for version 6.0:
;;   * Evelyne Augier (LUAN) [evelyne.augier@unice.fr]:
;;     + fixed two annoying problems:
;;	      - after a project is saved, new links created were not displayed.
;;	      - 'Open Project' and 'CANCEL' caused a program failure.
;;     (routines worksheet.pro and setoverlay.pro modified)
;;
;; - Modifications for version 6.1:
;;   * Gabriele Desiderà (DISI) [desidera@disi.unige.it],
;;   * Andrea La Camera (DISI) [lacamera@disi.unige.it]:
;;     + LINC-NIRVANA data type (lnd_t) added for forthcoming Soft.Pack.AIRY-LN
;;
;; - Modifications for version 7.0:
;;   * Gabriele Desiderà (DISI) [desidera@disi.unige.it],
;;   * Marcel Carbillet (Fizeau) [marcel.carbillet@unice.fr],
;;   * Andrea La Camera (DISI) [lacamera@disi.unige.it]:
;;     + i/o color compatibility pb
;;     + 'Save Project' creates a procedure representing the project. 
;;       This procedure can be run using the 'RUN' command and is also used to
;;       create a "Virtualized Project" to be used by the IDL Virtual Machine.
;;     + 'OpenProject' detects if a Project has been created with an older version
;;       of the CAOS System and gives a warning to the user to save the Project
;;       before running it in order to convert it for use with this new version of
;;       the CAOS System. 
;;     + The 'RUN' button permits to launch through the worksheet the procedure
;;       representing the current Project. 'RUN' can also be used directly from
;;       the IDL/CAOS prompt:
;;       CAOS System > RUN,"project_name"  
;;     + The 'VM' button creates a "virtualized" (in the sense of the IDL Virtual
;;       Machine) version of the project opened in the worksheet (by means of the
;;       procedure "savevmproject.pro"). A ".sav" file with the same name of the
;;       project is then created in the of Projects folder and can be used also from
;;       the IDL/CAOS prompt:
;;       CAOS System > project_name
;;
;; - Modifications for version 7.1:
;;   * Andrea La Camera (DIBRIS) [lacamera@unige.it],
;;   * Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;;     + "saveproject.pro" modified in order to always place output modules at the
;;       bottom of procedure "modcall.pro". This change was necessary due to the
;;       stopping rules newly implemented within the last version of the Software
;;       Package AIRY (6.0).
;;
;; - Modification for new unified CAOS Problem-Solving Environment 7.0:
;;   * Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;;    + CAOS Application Builder (now caos_pse_7.0/appbuilder) unified with CAOS
;;      Library (now caos_pse_7.0/library) and a bunch of utilities (including the
;;      Template Package 5.0 and display utilities and writing/reading data
;;      utilities) gathered together in caos_pse_7.0/packages/Utilities.
;;
;; - Releases:
;;   * version 5.0 released February 17th, 2005.
;;   * version 5.1 released March 16th, 2006.
;;   * version 5.2 released December 22nd, 2006.
;;   * version 6.0 released March 13rd, 2007.
;;   * version 6.1 released November 25th, 2008.
;;   * version 7.0 released April 28th, 2009.
;;   * version 7.1 released November 12th, 2012.
;;   * new unified CAOS Problem-Solving Environment 7.0 to be released in June 2016.
;;

;T+
; \subsection{Auxiliary Procedures}
;
; \subsubsection{Procedure: {\tt NewView}}
;
; The following procedure is called whenever the screen must be
; redrawn to create a new View object
;
;
;T-

PRO NewView, info

IF OBJ_VALID((*info).oView) THEN BEGIN
	IF (*info).oView->Count() GT 0 THEN (*info).oView->Remove, /ALL
	OBJ_DESTROY,(*info).oView
ENDIF

VwSize = (*info).oGrid->GetSize()

(*info).oView = OBJ_NEW( 'IDLgrView',    $		; Create view
                  VIEWPLANE_RECT = [0,0,VwSize[0],VwSize[1]] )

(*info).oView->add, (*info).oGrid

END



;T+
; \subsection{Event Handlers}
;
; \subsubsection{Procedure {\tt Worksheet\_Event}}
;
; The following procedure is the main event handler related to the worksheet
; It is used to process all the events related to the worksheet.
;
;T-

PRO Worksheet_Event, myEvent

COMMON Worksheet_Common, ModIDgen, DirName, ProjectModified, GridD, $
                         Slot0XY, FileVersion, AB_Name, AB_Version, $
                         AB_Date, dir_wildcard, file_wildcard

COMMON Over_common, Rect, Screen, XStep, YStep, GrPoly, GrRect, GrView

WIDGET_CONTROL, myEvent.top, GET_UVALUE=info
WIDGET_CONTROL, myEvent.top, /CLEAR_EVENTS

name=TAG_NAMES(myEvent, /STRUCTURE_NAME)

IF name EQ 'WIDGET_KILL_REQUEST' THEN BEGIN
	WIDGET_CONTROL, myEvent.top, /DESTROY
	RETURN
ENDIF

Redraw=0
msg=''
wtd=''			; What to do

CASE myEvent.type OF				; Event loop
0: BEGIN 					; Button press Events
	slot=(*info).oGrid->Screen2slot([myEvent.x,myEvent.y])	; Get Slot

	CASE (*info).Status OF

;======================================================================
	'DL': BEGIN				; Delete Module request
		IF slot[0] LT 0 THEN RETURN
		IF ProjectModified EQ 0 THEN BEGIN
			ProjectModified=1
			WritePrjStatus, info
		ENDIF
		Module = (*info).Project->GetModFromSlot(slot)
		IF Module NE OBJ_NEW() THEN BEGIN
			Point=Module->GetHandle([myEvent.x, myEvent.y])

			CASE Point.type OF
			-1: msg='I'			; Delete input handle
			0: msg='M'			; Delete module
			2: msg='Cannot delete output handle!'
			3: msg='M'
			4: msg='M'
			5: msg='M'
			ELSE: BEGIN			; Input handle empty
							; cannot delete
				msg='Nothing to do here!'
			      END
			ENDCASE
			IF msg EQ 'M' THEN BEGIN	; Actually delete module
				IF ProjectModified EQ 0 THEN BEGIN
					ProjectModified=1
					WritePrjStatus, info
				ENDIF
				RmLinks,Module,info
;				gr= Module->Getgraph()
;				(*info).oView->Remove, gr	; Remove model from view
				(*info).Project->DelModule, Module	; remove module from project
;				OBJ_DESTROY, Module		; Destroy
				(*info).Status='00'
				Redraw=1
				msg=''
			ENDIF
			IF msg EQ 'I' THEN BEGIN	; Actually delete link
				LinkToDelete=Module->DelLink(Point.Handle)
				(*info).Project->RemoveGr, LinkToDelete.Line
				OBJ_DESTROY, LinkToDelete.Line
				(*info).Status='00'
				Redraw=1
				msg=''
			ENDIF
		ENDIF ELSE BEGIN
			msg='Nothing to do here!'
		ENDELSE
		(*info).Status='00'
	      END
;===================================================================
	'CL': BEGIN				; Clone Module request
		IF slot[0] LT 0 THEN RETURN
		Module = (*info).Project->GetModFromSlot(slot)
		IF OBJ_VALID(Module) THEN BEGIN
			IF OBJ_CLASS(Module) EQ 'MODULE' THEN BEGIN
				IF Module->GetFather() NE OBJ_NEW() THEN  $
					Module = Module->GetFather()
				type=Module->GetType()
				Status=Module->GetStatus()
				ModIDgen=ModIdGen+1 		; Generate unique ID
				(*info).KeepObj=OBJ_NEW('Module',         $
			                        	type,             $
			                        	ModIDgen,         $
			                        	FATHER=Module )
				(*info).KeepObj->SetStatus,Status
				(*info).Status='FR'
				(*info).oWin->SetCurrentCursor, 'ICON'

				WIDGET_CONTROL, (*info).oTxt,              $
			               	SET_VALUE='Put clone into an empty slot'
				ENDIF ELSE BEGIN
					msg='Only plain modules can be cloned !'
					(*info).Status='00'
				ENDELSE
			ENDIF ELSE BEGIN
				msg='Nothing to do here!'
				(*info).Status='00'
			ENDELSE
	      END
;===================================================================
	'FR': BEGIN				; First positioning
		IF slot[0] LT 0 THEN RETURN
		IF (*info).Project->GetModFromSlot(slot) EQ OBJ_NEW() THEN BEGIN
			IF ProjectModified EQ 0 THEN BEGIN
				ProjectModified=1
				WritePrjStatus, info
			ENDIF
			SlotXY = (*info).oGrid->Slot2screen(slot)-Slot0XY
			(*info).KeepObj->Offset, slot, SlotXY
		        (*info).Project->PushModule,(*info).KeepObj
			(*info).Status='00'
			Redraw=1
		ENDIF
	      END

	'00': BEGIN				; Click over Module
						; Join definition
						; or parameter request
		IF slot[0] LT 0 THEN RETURN
		IF ProjectModified EQ 0 THEN BEGIN
			ProjectModified=1
			WritePrjStatus, info
		ENDIF
		Module = (*info).Project->GetModFromSlot(slot)
		IF Module NE OBJ_NEW() THEN BEGIN
			Point=Module->GetHandle([myEvent.x, myEvent.y])

			CASE Point.type OF
			-1: BEGIN		; Input handle active: error

				msg='Input Handle already used !'
				(*info).Status='00'
			    END

			0: BEGIN		; Set param request
				name = (*info).Project->GetName()
				CASE Module->SetParams(name) OF
				0: BEGIN	; Parameters have been set
						; Modify status of all clones
					CList = (*info).Project->GetClones(Module)
					FOR i=0, N_ELEMENTS(CList)-1 DO       $
						CList[i]->SetStatus,1
					Redraw=1
				   END
				1: wtd='Parameter setting cancelled by user'
				2: wtd='This module has no parameters to set'
				ENDCASE
				(*info).Status='00'
			   END
			1: BEGIN		; Input selected
				(*info).LinkDir=1
				(*info).VecIx=1
		    		wtd='Click over module output to join'
				(*info).Status='EP'
				(*info).KeepPnt=Point
			   END
			2: BEGIN		; Output selected
				(*info).LinkDir=0
				(*info).VecIx=1
		    		wtd='Click over module input to join'
				(*info).Status='EP'
				(*info).KeepPnt=Point
			   END
			3: BEGIN		; Combiner sign 0 selected
				Module->ToggleSign0;
				(*info).Status='00'
				Redraw=1
			   END
			4: BEGIN		; Combiner sign 1 selected
				Module->ToggleSign1;
				(*info).Status='00'
				Redraw=1
			   END
			5: BEGIN		; Combiner unused area
				msg='Nothing to do here!'
				(*info).Status='00'
			   END
			ENDCASE
		ENDIF ELSE BEGIN
			msg='Nothing to do here!'
			(*info).Status='00'
		ENDELSE
	      END

	'EP': BEGIN				; Join end point
		IF ProjectModified EQ 0 THEN BEGIN
			ProjectModified=1
			WritePrjStatus, info
		ENDIF
		Module = (*info).Project->GetModFromSlot(slot)
		IF Module NE OBJ_NEW() THEN BEGIN
			Point=Module->GetHandle([myEvent.x, myEvent.y])

			CASE Point.type OF

			1: BEGIN			; Input Handle
				IF (*info).KeepPnt.Type NE 2 THEN BEGIN
					Err=1
				ENDIF ELSE BEGIN
					FromOut=(*info).KeepPnt
					ToIn=Point
					Err=0
				ENDELSE
			   END

			2: BEGIN			; Output handle
				IF (*info).KeepPnt.Type NE 1 THEN BEGIN
					Err=1
				ENDIF ELSE BEGIN
					FromOut=Point
					ToIn=(*info).KeepPnt
					Err=0
				ENDELSE
			   END

			0: BEGIN
				msg = 'No connection here!'
				Err=1
			   END
			-1: BEGIN
				msg = 'Input Handle already used !'
				Err=1
			   END
			ENDCASE
			IF Msg EQ '' THEN BEGIN
				msg=JoinMods(FromOut,ToIn,info)
				IF Msg EQ '' THEN Redraw=1
			ENDIF
			(*info).Status='00'

	        ENDIF ELSE BEGIN		; Save intermediate points
			(*info).KeepX[(*info).VecIx]=FIX(myevent.x/5.0+0.5)*5
			(*info).KeepY[(*info).VecIx]=FIX(myevent.y/5.0+0.5)*5
			(*info).VecIx=(*info).VecIx+1
		ENDELSE
	      END

;=============================================================================
	'MP': BEGIN				; Move Project

		NewSlot=(*info).oGrid->Screen2slot([Rect[0]+5,Rect[2]-5])
		PrjBox=(*info).MvPrj->GetBox()
		SlotOfst = NewSlot - [PrjBox[0],PrjBox[2]]
		xyOfst = (*info).oGrid->Slot2screen(NewSlot) -              $
	         	(*info).oGrid->Slot2screen([PrjBox[0],PrjBox[2]])

		NewView, info			; Create new vieport

		(*info).MvPrj->Translate,SlotOfst,xyOfst
		UnsetOverlay, info
		CASE (*info).AuxStatus OF
		'OP': BEGIN
			(*info).Project=(*info).MvPrj
			ModIdGen = (*info).Project->GetMaxId()+1
			WritePrjStatus, info
		      END

		'ME': BEGIN
			dest = filepath((*info).MvPrj->GetName(),ROOT=DirName)
			source = filepath((*info).Project->GetName(),ROOT=DirName)
			IdOff=(*info).AuxInt
			MergeParFiles, dest, Source, IdOff

			(*info).Project->Merge,(*info).MvPrj


			ModIdGen = (*info).Project->GetMaxId()+1
			ProjectModified=1
			WritePrjStatus, info
		      END
		ELSE:
		ENDCASE
		NewView,info
		PrGraphs = (*info).Project->GetGraph()
		FOR i=0,N_ELEMENTS(PrGraphs)-1 DO 			$
			IF OBJ_VALID(PrGraphs[i]) THEN 			$
				(*info).oView->add,PrGraphs[i]
		(*info).Status='00'
		Redraw=1
   	      END

;=============================================================================
	'TX': BEGIN				; Add comment text
		(*info).KeepObj->SetPosition,[myEvent.x,myEvent.y]
		(*info).Project->AddGraph,(*info).KeepObj
		ProjectModified=1
		WritePrjStatus, info
		Redraw=1
	      END
;=============================================================================
			
	ELSE: msg= 'Event Loop, Unexpected state: ' + (*info).Status

	ENDCASE

	IF msg NE '' THEN r=DIALOG_MESSAGE(msg)

	WIDGET_CONTROL, myEvent.top, SET_UVALUE=info

	IF Redraw THEN (*info).oWin->DRAW, (*info).oView

	WIDGET_CONTROL, (*info).oTxt, SET_VALUE=wtd

	IF (*info).Status EQ '00' THEN BEGIN
		(*info).oWin->SetCurrentCursor, 'ARROW'	; Reset cursor default
	ENDIF

   END

2: BEGIN				; Motion event
					; (only Project moving can generate
					;  motion events)
   XGuard = ABS(XStep*0.51)
   YGuard = ABS(YStep*0.51)
					; Drag the Box
   IF ABS(myEvent.x-Rect[0]) LT ABS(myEvent.x-Rect[1]) THEN  $
	XOfst=myEvent.X-Rect[0]                              $
   ELSE                                                      $
	XOfst=myEvent.X-Rect[1]

   IF ABS(myEvent.y-Rect[2]) LT ABS(myEvent.y-Rect[3]) THEN  $
	YOfst=myEvent.y-Rect[2]                              $
   ELSE                                                      $
	YOfst=myEvent.y-Rect[3]

   IF XOfst LT 0 THEN XOfst=MAX([XOfst,Screen[0]-Rect[0]])
   IF XOfst GT 0 THEN XOfst=MIN([XOfst,Screen[1]-Rect[1]])

   IF YOfst LT 0 THEN YOfst=MAX([YOfst,Screen[0]-Rect[0]])
   IF YOfst GT 0 THEN YOfst=MIN([YOfst,Screen[1]-Rect[1]])

   ToMove=0
   IF (ABS(XOfst) GT XGuard) THEN BEGIN
	IF XOfst GT 0 THEN XMove = XStep ELSE XMove = -XStep
	ToMove=1
   ENDIF ELSE XMove=0
   IF (ABS(YOfst) GT YGuard) THEN BEGIN
	IF YOfst LT 0 THEN YMove = YStep ELSE YMove = -YStep
	ToMove=1
   ENDIF ELSE YMove=0

   IF ToMove THEN BEGIN
	(*info).oWin->DRAW, (*info).oView

   	Rect[0] = Rect[0] + XMove
   	Rect[1] = Rect[1] + XMove

   	Rect[2] = Rect[2] + YMove
   	Rect[3] = Rect[3] + YMove

   	GrPoly->SetProperty, DATA=[ [Rect[0],Rect[2]],       $
                                    [Rect[1],Rect[2]],       $
                                    [Rect[1],Rect[3]],       $
                                    [Rect[0],Rect[3]] ]
	
   	(*info).oWin->DRAW, GrView
   ENDIF

   END

4: (*info).oWin->DRAW, (*info).oView
	
ELSE:
ENDCASE

RETURN
END



;T+
; \subsubsection{Procedure {\tt CheckModif}}
;
; The following procedure is called to check wether the project
; has been modified and must be saved pirior of following actions
;
;T-

PRO CheckModif, info, parent

COMMON Worksheet_Common, ModIDgen, DirName, ProjectModified, GridD, $
                         Slot0XY, FileVersion, AB_Name, AB_Version, $
                         AB_Date, dir_wildcard, file_wildcard

WIDGET_CONTROL, (*info).NIters, GET_VALUE=NumIters

Nitsprj=(*info).Project->GetIter()         ; check for changed number of
                                           ; iterations

IF NumIters NE Nitsprj THEN ProjectModified=1

IF ProjectModified THEN BEGIN
	IF AskConfirm(["Current project has been modified",         $
	  "Do you want to save it prior of exiting ?"],   $
	   parent) THEN SaveProject, info, parent
ENDIF

END


;T+
; \subsubsection{Procedure {\tt EditEvent}}
;
; The following procedure is the event handler for the management of
; the {\bf edit} pull-down menu.
;
;T-

PRO EditEvent, myEvent		; Edit menu event routine

; DBG - name=TAG_NAMES(myEvent, /STRUCTURE_NAME)
; DBG - PRINT, 'FILE_EVENT: ', name

WIDGET_CONTROL, myEvent.id, GET_UVALUE=sel	; Get Menu item ID

WIDGET_CONTROL, myEvent.top, GET_UVALUE=info	; Get window info

(*info).Status=sel;				; Record status

CASE sel OF
'CL': BEGIN
	specinfo='Click on module to clone'
	(*info).cursor='UP_ARROW'
      END
'DL': BEGIN
	specinfo='Click on module name to delete a module, on handle to delete a link'
	(*info).cursor='UP_ARROW'
      END
'MP': BEGIN
	specinfo='Drag project box to new position'
	SetUpMoveProject,info,(*info).Project
	WIDGET_CONTROL, (*info).win, EVENT_PRO='Worksheet_Event'  ;; EA 2007+
	WIDGET_CONTROL, (*info).win, DRAW_MOTION_EVENTS=1       ;; EA 2007+	
	(*info).AuxStatus='MP'
      END
'TX': BEGIN
	specinfo='Adding text to Project'
	Txt = TextWidget(myEvent.top)
	IF OBJ_VALID(Txt) THEN BEGIN
		(*info).KeepObj=Txt
		(*info).cursor='CROSSHAIR'
		specinfo='Click left button on desired text position'
	ENDIF ELSE					$
		(*info).Status='00'
      END
ENDCASE

WIDGET_CONTROL, (*info).oTxt, SET_VALUE=specinfo
(*info).oWin->SetCurrentCursor, (*info).cursor			; Change cursor

WIDGET_CONTROL, myEvent.top, SET_UVALUE=info, /NO_COPY	; Update window info

END

;;;T+
;;; \subsubsection{Procedure {\tt PrjLibEvent}}
;;;
;;; The following procedure is the event handler for the management of
;;; the {\bf Project Lib} pull-down menu.
;;;
;;;T-
;;
;;PRO PrjLibEvent, myEvent		; Edit menu event routine
;;
;;COMMON Worksheet_Common, ModIDgen, DirName, ProjectModified, GridD, $
;;                         Slot0XY, FileVersion, AB_Name, AB_Version, $
;;                         AB_Date, dir_wildcard, file_wildcard
;;
;;WIDGET_CONTROL, myEvent.id, GET_UVALUE=sel	; Get Menu item ID
;;
;;WIDGET_CONTROL, myEvent.top, GET_UVALUE=info	; Get window info
;;
;;IF ModIdGen GT 0 THEN				$
;;	IdOff=(*info).Project->GetMaxID()+1 	$
;;ELSE						$
;;	IdOff=0
;;
;;filename = filepath('project.pro',ROOT=!CAOS_ENV.ProjectLib,SUBDIR=sel)
;;
;;ff=FINDFILE(filename,count=nf)
;;
;;IF nf EQ 1 THEN BEGIN
;;	RESOLVE_ROUTINE, 'doRESTORE',/IS_FUNCTION
;;	ret=doRESTORE(filename,info,IdOff)
;;ENDIF ELSE						$
;;	ret='Project file not found'
;;
;;IF ret NE '' THEN r=DIALOG_MESSAGE(ret,/ERROR) ELSE BEGIN
;;	(*info).Status='MP'
;;	IF IdOff EQ 0 THEN 		$
;;		(*info).AuxStatus='OP'	$
;;	ELSE				$
;;		(*info).AuxStatus='ME'
;;
;;	(*info).AuxInt=IdOff
;;	specinfo='Drag project box to new position'
;;	SetUpMoveProject,info,(*info).MvPrj
;;	WIDGET_CONTROL, (*info).oTxt, SET_VALUE=specinfo
;;ENDELSE
;;
;;END

;T+
; \subsubsection{Procedure {\tt RunEvent}}
;
; The following procedure is the event handler for the management of
; the {\bf run} pull-down menu.
;
;T-

PRO RunEvent, myEvent		; Edit menu event routine

; DBG - name=TAG_NAMES(myEvent, /STRUCTURE_NAME)
; DBG - PRINT, 'FILE_EVENT: ', name

WIDGET_CONTROL, myEvent.id, GET_UVALUE=sel	; Get Menu item ID

WIDGET_CONTROL, myEvent.top, GET_UVALUE=info	; Get window info

(*info).RunMode=sel;				; Record status

CASE sel OF
'RP': BEGIN                             ; Run the project
	CheckModif, info, myEvent.top
    run,((*info).Project->GetName())
       ; RESOLVE_ROUTINE,'project_'+((*info).Project->GetName()),/compile_full_file;'project'
        ;ret=execute('project_'+((*info).Project->GetName()))
        ;print,!PATH
      END
'PP': BEGIN                             ; Profile the project
	CheckModif, info, myEvent.top
        command = '@Projects' + !CAOS_ENV.Delim +        $
                   (*info).Project->GetName() +          $
                   !CAOS_ENV.Delim + 'profiler.pro'
        ret=execute(command)
      END
ENDCASE

WIDGET_CONTROL, myEvent.top, SET_UVALUE=info, /NO_COPY	; Update window info

END

;T+
; \subsubsection{Procedure {\tt VMEvent}}
;
; The following procedure is the event handler for the management of
; the {\bf VM} pull-down menu.
;
;T-

PRO VMEvent, myEvent		; Edit menu event routine

WIDGET_CONTROL, myEvent.id, GET_UVALUE=sel	; Get Menu item ID

WIDGET_CONTROL, myEvent.top, GET_UVALUE=info	; Get window info

CASE sel OF
'VM': BEGIN                             ; Run the project
	CheckModif, info, myEvent.top
    ;run,((*info).Project->GetName())
    savevmproject,((*info).Project->GetName())
      END
ENDCASE

WIDGET_CONTROL, myEvent.top, SET_UVALUE=info, /NO_COPY	; Update window info

END



;T+
; \subsubsection{Main Entry Point: mod\_menu}
;
; The following set of routines are used to generate the module selection menu
; based on the module list created by {\tt mod\_list\_crea} (see
; sect.~\ref{modlistcreasect}).
; The {\tt AB} code uses the main entry point: {\tt mod\_menu}
; (Sect.~\ref{modmenu}).
;
; \noindent {\bf Note:}
; The list of modules generated by {\tt mod\_list\_crea} is augmented with the
; special modules which are displayed properly separated from the other.
;
;
; \subsubsection{Procedure: {\tt ModMenuEvent}}
;
;       This is the event handler for the Module menu
;
;T-

PRO ModMenuEvent, event

COMMON Worksheet_Common, ModIDgen, DirName, ProjectModified, GridD, $
                         Slot0XY, FileVersion, AB_Name, AB_Version, AB_Date

widget_control, event.id, get_value=value

type=STRLOWCASE(STRMID(value,0,3))              ; Extract module type

widget_control, event.top, get_uvalue=info      ; Get info on window

ModIDgen=ModIDgen+1                     ; Generate unique Module ID

CASE type OF
;'+++': BEGIN
;    (*info).KeepObj = OBJ_NEW('Combiner',ModIDgen)
;    dummy=dialog_message(["The Combiner module will be",$
;                          "used in future releases."], $
;                         DIALOG_PARENT=event.top)
;    END
's*s': (*info).KeepObj = OBJ_NEW('FdbStop',ModIDgen)
ELSE: (*info).KeepObj = OBJ_NEW('Module', type, ModIDgen)
ENDCASE

(*info).Status='FR'
(*info).oWin->SetCurrentCursor, 'ICON'

WIDGET_CONTROL, (*info).oTxt, SET_VALUE='Put module into an empty slot'

RETURN
END



;T+
; \subsubsection{Procedure {\tt FileEvent}}
;
; The following procedure is the event handler for the management of
; the {\bf file} pull-down menu.
;
;T-

PRO fileEvent, myEvent		; dummy event handler

COMMON Worksheet_Common, ModIDgen, DirName, ProjectModified, GridD, $
                         Slot0XY, FileVersion, AB_Name, AB_Version, $
                         AB_Date, dir_wildcard, file_wildcard

; DBG -	name=TAG_NAMES(myEvent, /STRUCTURE_NAME)
; DBG -	PRINT, 'FILE_EVENT: ', name

WIDGET_CONTROL, myEvent.id, GET_UVALUE=sel

WIDGET_CONTROL, myEvent.top, GET_UVALUE=info

CASE sel OF
'EX': BEGIN					; Exit from program
	CheckModif, info, myEvent.top

	WIDGET_CONTROL, myEvent.top, /DESTROY
      END
'NW': BEGIN
	CheckModif, info, myEvent.top

	NewWorksheet, info
	(*info).Project=OBJ_NEW('Project')
	(*info).MvPrj=OBJ_NEW('Project')              ;;; EA 2007
	PrGraphs = (*info).Project->GetGraph()
	FOR i=0,N_ELEMENTS(PrGraphs)-1 DO 			$
		IF OBJ_VALID(PrGraphs[i]) THEN 			$
			(*info).oView->add,PrGraphs[i]
	(*info).MvPrj=(*info).Project              ;;; EA 2007 +
	SetOverlay, [0,0,0,0], [0,0,0,0], info          ;;; EA 2007+

	(*info).oWin->DRAW,(*info).oView
      END
'SV': BEGIN
	SaveProject, info, myEvent.top
	(*info).Status='00'

;;	Debut lignes ajoutees Fevrier 2007 - EA 2007+
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        WIDGET_CONTROL, (*info).win, DRAW_MOTION_EVENTS=0  
        WIDGET_CONTROL, (*info).win, EVENT_PRO='Worksheet_Event' 
        WIDGET_CONTROL, (*info).oTxt, SET_VALUE='' 
        PrjBox=(*info).MvPrj->GetBox()		 
        NewView, info                   
        UnsetOverlay, info
        (*info).Project=(*info).MvPrj
        ModIdGen = (*info).Project->GetMaxId()+1
        WritePrjStatus, info
        NewView,info
        PrGraphs = (*info).Project->GetGraph()
        FOR i=0,N_ELEMENTS(PrGraphs)-1 DO                       $
            IF OBJ_VALID(PrGraphs[i]) THEN                  $
              (*info).oView->add,PrGraphs[i]
	(*info).oWin->DRAW,(*info).oView 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;      Fin lignes ajoutees Fevrier 2007 - EA 2007+

      END
'ME': BEGIN
	IF ModIdGen GT 0 THEN				$
		IdOff=(*info).Project->GetMaxID()+1 	$
	ELSE						$
		IdOff=0

	msg = OpenProject(myEvent.top,info,IdOff)

	IF msg NE '' THEN BEGIN
		r=DIALOG_MESSAGE(msg)
		(*info).Status='00'
	ENDIF ELSE BEGIN
		(*info).Status='MP'
		IF IdOff EQ 0 THEN 		$
			(*info).AuxStatus='OP'	$
		ELSE				$
			(*info).AuxStatus='ME'
		specinfo='Drag project box to new position'
		SetUpMoveProject,info,(*info).MvPrj
		WIDGET_CONTROL, (*info).win, EVENT_PRO='Worksheet_Event'  ; EA 2007+
		WIDGET_CONTROL, (*info).win, DRAW_MOTION_EVENTS=1 ; EA 2007+
		WIDGET_CONTROL, (*info).oTxt, SET_VALUE=specinfo
	END
      END
'OP': BEGIN
	CheckModif, info, myEvent.top

	NewWorksheet, info
	
	;;      Debut lignes ajoutees Fevrier 2007 - EA 2007+
	;;      Reinitialisations des pointeurs
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        (*info).Project=OBJ_NEW('Project')
        (*info).MvPrj=OBJ_NEW('Project')              ;;; EA 2007
	WritePrjStatus, info  
        PrGraphs = (*info).Project->GetGraph()
        FOR i=0,N_ELEMENTS(PrGraphs)-1 DO                       $
                IF OBJ_VALID(PrGraphs[i]) THEN                  $
                        (*info).oView->add,PrGraphs[i]
        (*info).MvPrj=(*info).Project              ;;; EA 2007 +
        SetOverlay, [0,0,0,0], [0,0,0,0], info          ;;; EA 2007+

         (*info).oWin->DRAW,(*info).oView
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;      Fin lignes ajoutees Fevrier 2007 - EA 2007+


	msg = OpenProject(myEvent.top,info,0)
	IF msg NE '' THEN BEGIN
		r=DIALOG_MESSAGE(msg)
		(*info).Status='00'
	ENDIF ELSE BEGIN
		(*info).Status='MP' 
		(*info).AuxStatus='OP'
		specinfo='Drag project box to new position'
		SetUpMoveProject,info,(*info).MvPrj
		WIDGET_CONTROL, (*info).oTxt, SET_VALUE=specinfo
		WIDGET_CONTROL, (*info).win, DRAW_MOTION_EVENTS=0 ;; EA
		WIDGET_CONTROL, (*info).win, EVENT_PRO='Worksheet_Event' ;;EA
		WIDGET_CONTROL, (*info).oTxt, SET_VALUE='' ;;EA
		WIDGET_CONTROL, myEvent.top, SET_UVALUE=info

;;;;;;;;;;;;;;;; EA 22 fevrier 2006
                PrjBox=(*info).MvPrj->GetBox()

                NewView, info                   ; Create new vieport

                UnsetOverlay, info
                (*info).Project=(*info).MvPrj
                ModIdGen = (*info).Project->GetMaxId()+1
                WritePrjStatus, info

                NewView,info
                PrGraphs = (*info).Project->GetGraph()
                FOR i=0,N_ELEMENTS(PrGraphs)-1 DO                       $
                        IF OBJ_VALID(PrGraphs[i]) THEN                  $
                                (*info).oView->add,PrGraphs[i]
                (*info).Status='00'
                Redraw=1

;; FIN ;; EA 22 fevrier 2006

(*info).oWin->DRAW, (*info).oView

	END
      END
'RM': BEGIN				; Remove project
	RmProject, myEvent.top
      END

'PR': BEGIN 

	(*info).oPrinter->DRAW, (*info).oView		; Print Project
	(*info).oPrinter->NewDocument
      END

'PS': BEGIN				; Set printer
	ret = DIALOG_PRINTERSETUP((*info).oPrinter)
      END
ELSE:
ENDCASE

END


;T+
; \subsubsection{Procedure {\tt HelpEvent}}
;
; The following procedure is the event handler for the management of
; the edit pull-down menu.
;
;T-

PRO HelpEvent, myEvent		; Help menu event routine

COMMON Worksheet_Common, ModIDgen, DirName, ProjectModified, GridD, $
                         Slot0XY, FileVersion, AB_Name, AB_Version, $
                         AB_Date, dir_wildcard, file_wildcard

WIDGET_CONTROL, myEvent.id, GET_UVALUE=sel

WIDGET_CONTROL, myEvent.top, GET_UVALUE=info

CASE sel OF
'AB': r=DIALOG_MESSAGE([ ' CAOS Problem-Solving Environment', $
                         ' Version '+AB_Version, $
                         ' ('+AB_Date+') ' ], $
                         /INFORMATION               )

ELSE: BEGIN
	r=DIALOG_MESSAGE('Utility not implemented yet!')
      END
ENDCASE

END

;T+
; \subsection{The Worksheet}
;
; \subsubsection{Procedure: {\tt worksheet}}
;
; The following procedure is the main entry point invoked by the user
; to activate the {\tt Application Builder}.
;
; When called it creates the needed data structures and sets up
; the worksheet widget, then calls {\tt NewWorksheet} to activate
; an empty worksheet and finally starts the widget event driven
; loop.
;
;T-

PRO worksheet, Xslots, Yslots


COMMON Worksheet_Common, ModIDgen, DirName, ProjectModified, GridD, $
                         Slot0XY, FileVersion, AB_Name, AB_Version, $
                         AB_Date, dir_wildcard, file_wildcard
COMMON ModuleList, ListPtr, TypeList, Generic_dtype, IOcolors

COMMON caos_block, tot_iter, this_iter

COMMON Over_common, Rect, Screen, XStep, YStep, GrPoly, GrRect, GrView  ;;; EA 2007+

AB_Name='CAOS Problem-Solving Environment'
AB_Version='7.0'          ; Specifies version of Application Builder
AB_Date='March 2016'      ; Specifies date of Application Builder
FileVersion=8             ; Specifies version of project.pro file

DirName = 'Projects'
ModIDgen = 0

;;CAOS_INIT				; Initialize CAOS system

; --------------------------------------------------- BEGIN SYSDEP
CASE !VERSION.OS_FAMILY of
    "unix": BEGIN
	dir_wildcard = ''
	file_wildcard = '*'
	prefix=!CAOS_ENV.modules	; To override different behaviours
					; of FINDFILE()
    END

    "Windows": BEGIN
	dir_wildcard = STRING(replicate((byte("?"))[0],!CAOS_ENV.module_len))
	file_wildcard = dir_wildcard
	prefix=''
    END

    ELSE: BEGIN
        MESSAGE, "Operating System ("+!VERSION.OS_FAMILY+") not supported"
    END
ENDCASE
; --------------------------------------------------- END SYSDEP


IF N_PARAMS() LT 1 THEN Xslots = 10
IF N_PARAMS() LT 2 THEN Yslots = 10

GridD=[Xslots, Yslots]

MOD_LIST_CREA        		; Create module list

;;PrjLibMenu = MakeStructMenu(!CAOS_ENV.ProjectLib,'.col','1\ProjectLib\PrjLibEvent')

RESOLVE_ROUTINE, 'rmdir'		; To avoid some pitfalls
RESOLVE_ROUTINE, 'Module__define'
RESOLVE_ROUTINE, 'openproject',/IS_FUNCTION
RESOLVE_ROUTINE, 'SetUpMoveProject' ;; EA
RESOLVE_ROUTINE, 'SetOverlay' ;;EA
RESOLVE_ROUTINE, 'UnsetOverlay' ;; EA
;;RESOLVE_ALL

InOut = { InOut, Type:0, 	$	; Module type index
                 ID:-1, 	$	; Module ID
                 Handle:0, 	$	; Output module handle
                 DType:0, 	$	; Data type index
                 Box:OBJ_NEW(), $	; Associated colored box
                 Line:OBJ_NEW() }	; Associated line
							; Set up Widgets
info = PTR_NEW( {oWin:OBJ_NEW(),                  $
                 oView:OBJ_NEW(),                 $
                 oGrid:OBJ_NEW(),                 $
                 oPrinter:OBJ_NEW(),              $
                 RunMode:'RP',                    $
                 cursor:'',                       $
                 win:0L,                          $
                 Wks:0L,                          $
                 Label:0L,                        $
                 NIters:0L,                       $
                 KeepObj:OBJ_NEW(),               $
                 KeepX:INTARR(100),               $
                 KeepY:INTARR(100),               $
                 VecIx:0,                         $
                 LinkDir:0,                       $
                 oTxt:0,                          $
                 Status:'',                       $
                 KeepPnt:{InOut,0,-1,0,0,OBJ_NEW(),OBJ_NEW()}, $
                 Project:OBJ_NEW('Project'),               $ ;; EA 2007
                 MvPrj:OBJ_NEW('Project'),                 $ ;; EA 2007
                 AuxInt:0,                        $
                 AuxStatus:''                        } )

wks = Widget_base(TITLE=AB_Name+' - '+AB_Version,    $
;                  ROW=3,                            $
                  /COLUMN, APP_MBAR = TopBar)
;                  APP_MBAR = TopBar)

fileMenu = Widget_button(TopBar, VALUE='File',       $	; Set up File menu
                         EVENT_PRO='fileEvent',      $
                         /MENU)
newMenuBut  = Widget_button(fileMenu,                $
                            VALUE='New Project',     $
                            UVALUE='NW')
openMenuBut = Widget_button(fileMenu,                $
                            VALUE='Open Project',    $
                            UVALUE='OP')
mergeMenuBut = Widget_button(fileMenu,               $
                            VALUE='Merge Project',   $
                            UVALUE='ME')
svMenuBut = Widget_button(fileMenu,                  $
                            VALUE='Save Project',    $
                            UVALUE='SV')
rmMenuBut = Widget_button(fileMenu,                  $
                            VALUE='Delete Project',  $
                            UVALUE='RM')
prMenuBut = Widget_button(fileMenu,                  $
                            VALUE='Print Project',   $
                            UVALUE='PR')
prMenuBut = Widget_button(fileMenu,                  $
                            VALUE='Set Printer',     $
                            UVALUE='PS')
exitMenuBut = Widget_button(fileMenu,                $
                            VALUE='Exit',            $
                            UVALUE='EX',             $
                            /SEPARATOR )

edtMenu  = Widget_button(TopBar, VALUE='Edit',       $ 	; Set up edit menu
                         EVENT_PRO='EditEvent',       $
                         /MENU)
clonMenuBut  = Widget_button(edtMenu,                $
                         VALUE='Clone module',       $
                         UVALUE='CL')
deleMenuBut  = Widget_button(edtMenu,                $
                         VALUE='Delete item',      $
                         UVALUE='DL')

TextMenuBut  = Widget_button(edtMenu,                $
                         VALUE='Add Text',           $
                         UVALUE='TX')

MvprMenuBut  = Widget_button(edtMenu,                $
                         VALUE='Move project',       $
                         UVALUE='MP')


;;LibMenu = CW_PDMENU(TopBar,PrjLibMenu,        $   ; Set up project library menu
;;           /RETURN_FULL_NAME, DELIM=!CAOS_ENV.Delim, /MBAR)

Modules   = CW_PDMENU(TopBar,(*ListPtr).Menu,        $
              /RETURN_NAME, /MBAR )

runMenu  = Widget_button(TopBar, VALUE='Run',       $ 	; Set run edit menu
                         EVENT_PRO='RunEvent',      $
                         /MENU)

RunPrjButt  = Widget_button(runMenu,                $
                         VALUE='Run Project',       $
                         UVALUE='RP')

;;RunPrfButt  = Widget_button(runMenu,                    $
;;                         VALUE='Profile Project',       $
;;                         UVALUE='PP')

VMMenu  = Widget_button(TopBar, VALUE='VM',       $ 	; Set VM edit menu
                         EVENT_PRO='VMEvent',      $
                         /MENU)

VMPrjButt  = Widget_button(VMMenu,                $
                         VALUE='BUILD VM-Project',       $
                         UVALUE='VM')

hlpMenu  = Widget_button(TopBar,                     $ ; Set up Help Menu
                         VALUE='Help',               $
                         EVENT_PRO='HelpEvent',      $
                         /MENU, /HELP           )
hlpMenuBut  = Widget_button(hlpMenu,                 $
                            VALUE='About '+ AB_Name, $
                            UVALUE='AB')
hlpMenuBut  = Widget_button(hlpMenu,                 $
                            VALUE='Search',          $
                            UVALUE='SR')


(*info).Wks=wks

NewWorksheet, info


(*info).Project=OBJ_NEW('Project');
(*info).MvPrj=(*info).Project           ;;; EA 2007

PrGraphs = (*info).Project->GetGraph()
FOR i=0,N_ELEMENTS(PrGraphs)-1 DO 			$
	IF OBJ_VALID(PrGraphs[i]) THEN (*info).oView->add,PrGraphs[i]

VwSize = (*info).oGrid->GetSize()

bb = WIDGET_BASE(wks,/ROW)
(*info).Label=Widget_text(bb)

bb1=WIDGET_BASE(bb,/ALIGN_RIGHT)
(*info).NIters=CW_FIELD(bb1,Title='Iterations:',/LONG,XSIZE=10)


(*info).win = Widget_draw(wks, XSIZE=VwSize[0], YSIZE=VwSize[1], $
                                  GRAPHICS_LEVEL = 2,            $
                                  UVALUE = 'draw',               $
                                  /BUTTON_EVENTS,                $
                                  /EXPOSE_EVENTS        )
(*info).oTxt = Widget_text(wks)

WritePrjStatus, info

Widget_Control, wks, /REALIZE

Widget_Control, (*info).win, GET_VALUE= oWin

(*info).oWin=oWin

SetOverlay, [0,0,0,0], [0,0,0,0], info             ;;;; EA 2007+
(*info).oPrinter=OBJ_NEW('IDLgrPrinter',COLOR_MODEL=1)	; Preset printer object

(*info).oWin->DRAW, (*info).oView

Widget_Control, wks, SET_UVALUE=info	; Prepare to pass the info to objects

Xmanager, 'worksheet', wks, /NO_BLOCK   ; Start the X manager

END