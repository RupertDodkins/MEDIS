

;T+
; \subsubsection{Function: {\tt OpenProject}}
; \label{openproject}
;
; This is the main entry point called when an existing project must be
; opened. It manages the project selection interaction with the user
; and then calls {\tt doRESTORE} to restore the project.
;
; The parameter {\tt IdOff} manages project merging. If it is 0 the project
; is to be opened into an empty worksheet. If it is greater than 0 it means
; that a project is currently active and the one to be opened is to be
; merged with the existing one. In this case {\tt IdOff} is an offset to
; be added to all the new projects' modules ID in order to be sure that 
; all modules ID's are unique.
;
;T-

FUNCTION OpenProject, Parent, info, IdOff

COMMON Worksheet_Common, ModIDgen, DirName, ProjectModified, GridD, $
                         Slot0XY, FileVersion, AB_Name, AB_Version, AB_Date

COMMON OpenCommon, MaxId

prjname=''

PrjList = GetPrjList()

Goon=1

prjname=SelectFile('Select Project to open',PrjList,prjname,Parent)

IF prjname EQ '' THEN RETURN, 'No project opened'

fullpath = filepath(prjname,ROOT=DirName)

found=is_a_dir(fullpath)

(*info).MvPrj=OBJ_NEW()

IF found THEN BEGIN
   found_proc=file_test(!caos_env.work+fullpath+!caos_env.delim+strlowcase(prjname)+'.pro')

   if (found_proc eq 0) then begin
    dialog=dialog_message(['- Opening Old version Project -','    SAVE it before running'],/info)
   endif
       
   savefile = filepath('project.pro',ROOT=fullpath)
   ret=doRESTORE(savefile,info,IdOff)

ENDIF ELSE RETURN, 'Project not found'

RETURN, ret

END

