
;T+
; \subsubsection{Procedure: {\tt MoveParFiles}}
;
; This procedure moves/copies all the parameter files from a given project
; directory to a destination project directory. 
;
; Files are either moved or copied as directed by the value of the
; argument {\tt OpType} ('M' or 'C')
;
;T-


PRO MoveParFiles, Dest, Source, OpType

IF Dest EQ Source THEN RETURN		; If source and destination are the
					; same, do nothing

SrcWild = Source + !CAOS_ENV.Delim + '*.sav'

SrcList = FINDFILE(SrcWild,COUNT=nfiles)

FOR i=0,nfiles-1 DO BEGIN
	aux = str_sep(SrcList[i],!CAOS_ENV.Delim)
	fileName = aux[N_ELEMENTS(aux)-1]
	DstFile = Dest + !CAOS_ENV.Delim + fileName
	IF OpType eq 'M' THEN			$
		rename, SrcList[i], DstFile	$
	ELSE					$
		filecopy, SrcList[i], DstFile
ENDFOR

END
