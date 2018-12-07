
;T+
; \subsubsection{Procedure: {\tt MergeParFiles}}
;
; This procedure copies all the parameter files from a project which is
; merged to another project to the destination project directory. 
;
; Parameter file names are renamed according to new names assigned to
; modules (renaming is obtained by offsetting each module id by a given
; amount).
;
;T-

PRO MergeParFiles, Dest, Source, Offset

IF Dest EQ Source THEN RETURN		; If source and destination are the
					; same, do nothing

SrcWild = Source + !CAOS_ENV.Delim + '*.sav'

SrcList = FINDFILE(SrcWild,COUNT=nfiles)

FOR i=0,nfiles-1 DO BEGIN
	aux = str_sep(SrcList[i],!CAOS_ENV.Delim)
	fileName = aux[N_ELEMENTS(aux)-1]
	modt = STRMID(FileName,0,3)

	IF STRPOS(fileName,'_') GE 0 THEN BEGIN		; Try to ignore *.sav
							; files other than
							; parameter files
		READS, STRMID(fileName,4,5),modId

		modId = modId + Offset
		DstFile = mk_par_name(modt,modId)

		DstFile = Dest + !CAOS_ENV.Delim + fileName
		filecopy, SrcList[i], DstFile
	ENDIF
ENDFOR

END
