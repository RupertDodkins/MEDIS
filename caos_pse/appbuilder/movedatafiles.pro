
;T+
; \subsubsection{Procedure: {\tt MoveDataFiles}}
;
; This procedure moves/copies all the data files (.fits .fts .asc .txt .dat)
; from a given project directory to a destination project directory. 
;
; Files are either moved or copied as directed by the value of the
; argument {\tt OpType} ('M' or 'C')
;
;T-

; created 26 feb. 2004 - marcel carbillet [marcel@arcetri.astro.it]

PRO MoveDataFiles, Dest, Source, OpType

IF Dest EQ Source THEN RETURN		; If source and destination are the
					; same, do nothing

; FITS files
SrcWild = Source + !CAOS_ENV.Delim + '*.fits'
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

SrcWild = Source + !CAOS_ENV.Delim + '*.fts'
SrcList = FINDFILE(SrcWild,COUNT=nfiles)
FOR i=0,nfiles-1 DO BEGIN
        aux = str_sep(SrcList[i],!CAOS_ENV.Delim)
        fileName = aux[N_ELEMENTS(aux)-1]
        DstFile = Dest + !CAOS_ENV.Delim + fileName
        IF OpType eq 'M' THEN                   $
                rename, SrcList[i], DstFile     $
        ELSE                                    $
                filecopy, SrcList[i], DstFile
ENDFOR

; TEXT files
SrcWild = Source + !CAOS_ENV.Delim + '*.txt'
SrcList = FINDFILE(SrcWild,COUNT=nfiles)
FOR i=0,nfiles-1 DO BEGIN
        aux = str_sep(SrcList[i],!CAOS_ENV.Delim)
        fileName = aux[N_ELEMENTS(aux)-1]
        DstFile = Dest + !CAOS_ENV.Delim + fileName
        IF OpType eq 'M' THEN                   $
                rename, SrcList[i], DstFile     $
        ELSE                                    $
                filecopy, SrcList[i], DstFile
ENDFOR

; ASCII files
SrcWild = Source + !CAOS_ENV.Delim + '*.asc'
SrcList = FINDFILE(SrcWild,COUNT=nfiles)
FOR i=0,nfiles-1 DO BEGIN
        aux = str_sep(SrcList[i],!CAOS_ENV.Delim)
        fileName = aux[N_ELEMENTS(aux)-1]
        DstFile = Dest + !CAOS_ENV.Delim + fileName
        IF OpType eq 'M' THEN                   $
                rename, SrcList[i], DstFile     $
        ELSE                                    $
                filecopy, SrcList[i], DstFile
ENDFOR

; generic DATA files
SrcWild = Source + !CAOS_ENV.Delim + '*.dat'
SrcList = FINDFILE(SrcWild,COUNT=nfiles)
FOR i=0,nfiles-1 DO BEGIN
        aux = str_sep(SrcList[i],!CAOS_ENV.Delim)
        fileName = aux[N_ELEMENTS(aux)-1]
        DstFile = Dest + !CAOS_ENV.Delim + fileName
        IF OpType eq 'M' THEN                   $
                rename, SrcList[i], DstFile     $
        ELSE                                    $
                filecopy, SrcList[i], DstFile
ENDFOR

END
