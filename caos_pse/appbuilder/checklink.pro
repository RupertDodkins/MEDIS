;T+
; \subsubsection{Function: {\tt CheckLink}}
;
; The following function performs the tests required to check if a link
; can be actually created.
;
; \noindent {\bf Note:}
; A legal link must join a module output to a free module input, and 
; either data types at the two ends of the link are the same or
; one of the modules joined is of type generic.
;
;T-

FUNCTION CheckLink, FromM, FromOut, ToM, ToIn

COMMON ModuleList, ListPtr, TypeList, Generic_dtype, IOcolors

OutSpec = FromM->GetOut(FromOut)		; Get output specification
InSpec = ToM->GetIn(ToIn)			; Get input specification

IF OutSpec.dtype EQ InSpec.dtype THEN RETURN, 1

IF OutSpec.dtype EQ Generic_dtype THEN BEGIN
	rt=FromM->ChangeDType(InSpec.DType)
ENDIF ELSE BEGIN
	IF InSpec.DType EQ Generic_dtype THEN BEGIN
		rt=ToM->ChangeDType(OutSpec.DType)
	ENDIF ELSE rt=0
ENDELSE

RETURN, rt
	
END
