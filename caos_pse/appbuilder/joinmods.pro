;T+
; \subsubsection{Function: {\tt JoinMods}}
;
; The following function is called to actually create a link when
; the user terminates the definition of it by cliking on the other
; end of the link.
;
; \noindent {\bf Note:}
; A link definition begins when the user clicks on eiter an input
; or an output handle of a module and terminates when the user clicks
; on the other endpoint (output or input, respectively). In between
; by clicking on other points of the worksheet other intemediate points can
; be defined.
;
;T-

FUNCTION JoinMods , FromOut, ToIn, info	; Returns error message

ToM = (*info).Project->FindModule(ToIn.ID)
FromM = (*info).Project->FindModule(FromOut.ID)

Rt=CheckLink(FromM,FromOut.Handle,    $
             ToM, ToIn.Handle          )

IF rt GT 0 THEN BEGIN 	; Set up link info

	ToM->SetLink,FromOut.ID,            $
	                FromOut.Handle,     $
	                ToIn.Handle

	IF (*info).LinkDir EQ 0 THEN BEGIN
		Fp= FromM->GetOutCoord(FromOut.Handle)
		Lp= ToM->GetInCoord(ToIn.Handle)
	ENDIF ELSE BEGIN
		Fp= ToM->GetInCoord(ToIn.Handle)
		Lp= FromM->GetOutCoord(FromOut.Handle)
	ENDELSE
	Nxy=(*info).VecIx
	(*info).KeepX[0]=Fp[0]
	(*info).KeepY[0]=Fp[1]
	(*info).KeepX[Nxy]=Lp[0]
	(*info).KeepY[Nxy]=Lp[1]
	Nxy=Nxy+1
	Line=ComputeLine((*info).LinkDir,                $
	                 (*info).KeepX[INDGEN(Nxy)],     $
	                 (*info).KeepY[INDGEN(Nxy)])
	ToM->PutLine, ToIn.Handle, Line
	(*info).Project->AddGraph, Line
	Redraw=1
	msg=''
ENDIF ELSE msg='Link Error!' 

RETURN, msg

END

