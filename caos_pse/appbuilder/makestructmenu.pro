;T+
; \subsubsection{Function: {\tt MakeSubDir}} 
;
; This function builds the part of project library menu related to a single 
; subdirectory.
; It is intended to be called recursively in order to build up the
; entire menu structure.
;
;T-


PRO MakeSubDir, Menu, Path, DirExtn, opt_subdir

COMMON Worksheet_Common

makepath=FILEPATH(ROOT=Path,dir_wildcard)

FileList=FINDFILE(makepath,COUNT=nfiles)

FOR i=0,nfiles-1 DO BEGIN
	n=RSTRPOS(FileList[i],!CAOS_ENV.Delim)
	IF n GE 0 THEN 					$  ; STRMID will fail if
		Fname = STRMID(FileList[i],n+1,1024)	$  ; filename is longer
	ELSE						$  ; than 1024 chars.
		Fname=FileList[i]			   ; but is needed for
							   ; compatibility

	IF Fname EQ 'CVS' THEN CONTINUE       ; Do not consider CVS directories

	IF STRPOS(Fname,DirExtn) GE 0 THEN BEGIN		; Collection
		IF i EQ nfiles-1 THEN Pref='3\' ELSE Pref='1\'
		Menu = [ Menu, Pref+Fname ]
		SubPath = Path + !CAOS_ENV.Delim + Fname + opt_subdir
                                 
		MakeSubDir,Menu, SubPath, DirExtn, opt_subdir
	ENDIF ELSE BEGIN
		IF i EQ nfiles-1 THEN Pref='2\' ELSE Pref='0\'
		Menu = [ Menu, Pref+Fname ]
	ENDELSE
ENDFOR

END

;T+
; \subsubsection{Function: {\tt MakeStructMenu}}         \label{makestructmenu}
;
; This function builds a menu which allow to select a project from a
; library of preassembled projects which are distributed together with
; the {\tt AB} code.

; The library projects are physically stored under the cAOs root directory
; and can be nested by adding subdirectories with special names. as shown
; in the following example:
;
; \begin{quote} 
; \tt 
; cAOs~Root/prjlib/Project-1   \\
; ~~~~~~~~~~~~~~~~~Project-2   \\
; ~~~~~~~~~~~~~~~~~ ......     \\
; ~~~~~~~~~~~~~~~~~Calib.sub/SubProject-1		\\
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~SubProject-2		\\
; ~~~~~~~~~~~~~~~~~ ......     \\
;                      
; \end{quote}
;
; The top directory {\tt prjlib} contains only subdirectories. Each subdirectory 
; either contains a project or is a project collection. Project collection
; subdirectory have names ending in the suffix {\tt .col} and have the
; same structure as the top directory.
; 
; The function returns a string array in the format required by the function
; CW_PDMENU().
;
;T-

FUNCTION MakeStructMenu, MenuRoot, DirExtn, MenuHeader

COMMON Worksheet_Common

Menu=[MenuHeader]

subdir = ""

MakeSubDir, Menu, MenuRoot, DirExtn, subdir
 
RETURN, Menu

END
