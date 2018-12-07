;T+
; \subsubsection{Procedure: {\tt RmLinks}}
;
; The following procedure removes all links related to a given module.
; Both input and output links are removed.
;
; \noindent {\bf Note:}
; Links are stored in the input section data structure of a module. In order
; to find output links of a given module a search through all modules must
; be performed to find modules which receive input from the current one.
;
;T-

PRO RmLinks, Module, info		; Delete all links related to a module

Modlist=(*info).Project->GetList(); 	Get Module list
cnt=N_ELEMENTS(ModList)-1

MyID = Module->GetID()			; Get module ID

					; The following loop deletes input 
					; links of all the other modules
					; connected to this one
FOR i=0,cnt DO BEGIN				; For each module
	ModData=ModList[i]->GetData()		; Get module data
	FOR j=0,ModData.Ninp-1 DO BEGIN		; Analyze module inputs
		IF ModData.Inputs[j].ID EQ MyID THEN BEGIN
			Obj=ModList[i]->DelLink(j)		; Remove link
			(*info).Project->RemoveGr, Obj.line
			OBJ_DESTROY, Obj.line
		ENDIF
	ENDFOR
ENDFOR
					; Now delete input links
ModData=Module->GetData()		; Get module data
FOR j=0,ModData.Ninp-1 DO BEGIN
	IF ModData.Inputs[j].ID NE -1 THEN  BEGIN
		Obj=Module->DelLink(j)		; Delete link
		(*info).oGrid->remove, Obj.line
		OBJ_DESTROY, Obj.Line
	ENDIF
ENDFOR

END
