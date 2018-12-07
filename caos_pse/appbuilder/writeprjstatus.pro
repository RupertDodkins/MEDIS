;T+
; \subsubsection{Procedure: {\tt WritePrjStatus}}
;
; The following procedure updates the worksheet widget top line
; where the project status is displayed.
;
;T-

PRO WritePrjStatus, info

COMMON Worksheet_Common, ModIDgen, DirName, ProjectModified, GridD, $
                         Slot0XY, FileVersion, AB_Name, AB_Version, AB_Date

IF ProjectModified THEN stat = 'modified' ELSE stat = 'unmodified'

txt = 'Project name: ' + (*info).Project->GetName() $
    + '   Status: ' + stat

WIDGET_CONTROL, (*info).Label, SET_VALUE=txt

WIDGET_CONTROL, (*info).NIters,                      $
                SET_VALUE= (*info).Project->GetIter()


END
