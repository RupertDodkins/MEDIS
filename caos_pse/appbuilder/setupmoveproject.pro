;T+
; \subsubsection{Procedure: {\tt SetUpMoveProject}}
; 
; The following procedures gathers the data required to define an 
; ``overlay widget'' which implements the ``move project'' operation,
; then call {\tt SetOverlay} (see sect.~\ref{sect:setover}) to create
; the widget.
;
;T-

PRO SetUpMoveProject,info,Prj
	(*info).cursor='UP_ARROW'
	PrjBox=Prj->GetBox()
	Rect = (*info).oGrid->EnclosingBox(PrjBox)
	GridBox=(*info).oGrid->GetSize()
	GBox=[0,GridBox[2]-1,0,GridBox[3]-1]
	Screen = (*info).oGrid->EnclosingBox(GBox)
	(*info).MvPrj = Prj
	SetOverlay, Rect, Screen, info
END
