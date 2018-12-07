;T+
; \subsubsection{Procedure: {\tt RmProject}}
;
; The following routine deletes a project from the {\tt ./Projects}
; directory.
;
;T-

PRO RmProject, Parent			; Removes a project

prjname=''

PrjList=GetPrjList()

prjname=SelectFile('Select Project to delete',PrjList,prjname,Parent)

IF prjname EQ '' THEN RETURN

fullpath = FILEPATH(prjname,ROOT='.',SUB='Projects')

found=is_a_dir(fullpath)

IF found THEN BEGIN
	qst = "Ok to delete project " + prjname + "?"
	IF AskConfirm(qst,Parent) THEN rmdir, fullpath
ENDIF

END
