
;T+
; \subsubsection{Procedure: {\tt NewWorksheet}}
;
; The following procedure is called whenever a new empty worksheed must
; be created. If a worksheet is already alive it is first destroyed.
;
;T-

PRO NewWorksheet, info

COMMON Worksheet_Common, ModIDgen, DirName, ProjectModified, GridD, $
                         Slot0XY, FileVersion, AB_Name, AB_Version, AB_Date

ModIDgen = 0				; Initialize Module ID Generator

IF OBJ_VALID((*info).oGrid) THEN OBJ_DESTROY, (*info).oGrid
IF OBJ_VALID((*info).Project) THEN OBJ_DESTROY, (*info).Project

(*info).oGrid = OBJ_NEW('Grid', GridD[0], GridD[1])

Slot0XY=(*info).oGrid->slot2screen([0,0])

NewView, info

(*info).Status    = ''
ProjectModified=0

END
