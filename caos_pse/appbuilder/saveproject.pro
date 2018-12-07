;T+
; \subsubsection{External Entry Point: SaveProject}
;
; The following set of routines are used to save the status of a project
; onto disk. Details on the structure of project directories have been
; dealt with in a preceeding section (see sect.~\ref{projectsect}).
; The {\tt AB} code uses the main entry point: {\tt SaveProject} 
; (Sect.~\ref{saveproject}).
;
; \noindent {\bf Note:} The {\tt SaveProject} function generates the two
; files {\tt project.pro} and {\tt mod\_calls.pro}. Parameter files are
; created as the result of calling each module paramenter definition GUI
; routine.
;
; \subsubsection{Procedure: {\tt ModuleCode}}
;
; The following procedure is called by {\tt WriteCode} (see below) to 
; generate and write onto the output file the function call to invoke
; a module.
;
;T-
; modified 20 june 2016: debugged for other OS than linux (use of !caos_env.delim instead of '/')

PRO ModuleCode, ModData, ModInfo, is, prof, Fdp

Nargs = ModData.Ninp + ModData.Nout + 1		; How many args ?
IF (*ModInfo).init EQ 1B THEN Nargs = Nargs + 1
IF (*ModInfo).time EQ 1B THEN Nargs = Nargs + 1

IF prof THEN PRINTF, fdP, "PROFSTART"

ModId = STRING(ModData.ID,FORMAT='(I5.5)')

prefix = "ret = " + ModData.Type + "("

FOR k=0, ModData.Ninp-1 DO BEGIN
	IF Nargs LE 1 THEN postfix = ")" ELSE postfix = ",		$"
	Nargs = Nargs-1
	FeedFromId=ModData.Inputs[k].ID
	FeedFromHandle=ModData.Inputs[k].handle
	VarPf="O_"
	IF FeedFromId LT 0 THEN BEGIN
		FeedFromId=is
		FeedFromHandle=k
		VarPf="I_"
	ENDIF
	var = VarPf + STRING(FeedFromId,FORMAT='(I3.3)') + '_' +    $
	              STRING(FeedFromHandle,FORMAT='(I2.2)')

	PRINTF, fdP, prefix,var,postfix
	prefix = "          "
ENDFOR

FOR k=0, ModData.Nout-1 DO BEGIN
	IF Nargs LE 1 THEN postfix = ")" ELSE postfix = ",		$"
	Nargs = Nargs-1
	var = "O_" + STRING(ModData.ID,FORMAT='(I3.3)') + '_' +    $
		     STRING(k,FORMAT='(I2.2)')
	PRINTF, fdP, prefix,var,postfix
	prefix = "          "
ENDFOR

       ;;test to support the case in which there aren't INIT and TIME
IF Nargs LE 1 THEN postfix = ")" ELSE postfix = ",              $"
 
var=ModData.Type + '_' + ModId + '_p'
PRINTF, fdP, prefix,var,postfix
prefix = "          "
Nargs = Nargs-1

IF (*ModInfo).init EQ 1B THEN BEGIN	; Module requires 
						; initialization
	IF Nargs LE 1 THEN postfix = ")" ELSE postfix = ",	$"
	Nargs = Nargs-1
	var='INIT='+ ModData.Type + '_' + ModID + "_c"
	PRINTF, fdP, prefix,var,postfix
	prefix = "          "
ENDIF 

IF (*ModInfo).time EQ 1B THEN BEGIN	; Module requires 
       					        ; time data
	IF Nargs LE 1 THEN postfix = ")" ELSE postfix = ",		$"
	Nargs = Nargs-1
	Var='TIME='+ ModData.Type + '_' + ModID + "_t"
	PRINTF, fdP, prefix,var,postfix
	prefix = "          "
ENDIF 

IF prof THEN BEGIN
    PRINTF, fdP, "TIME=PROFELAPSED()"
    PRINTF, fdP, "MYPROFILE, ",ModData.ID,", TIME"
ENDIF

PRINTF, fdP, 'IF ret NE 0 THEN ProjectMsg, "', ModData.Type, '"'
PRINTF, fdP, ""

END

;T+
; \subsubsection{Procedure: {\tt FdbCode}}
;
; The following procedure is called by {\tt WriteCode} (see below) to 
; generate and write onto the output file the code which implements
; the {\tt FeedBack} special module.
;
;T-

PRO FdbCode, ModData, ModInfo, Fdp

ModId = STRING(ModData.ID,FORMAT='(I5.5)')

Outvar = "O_" + STRING(ModData.ID,FORMAT='(I3.3)') + '_' +    $
		     STRING(0,FORMAT='(I2.2)')

FeedFromId=ModData.Inputs[0].ID			; Setup first operand
FeedFromHandle=ModData.Inputs[0].handle
VarPf= "O_"
IF FeedFromId LT 0 THEN BEGIN
	FeedFromId=is
	FeedFromHandle=0
	VarPf="I_"
ENDIF
Invar = VarPf + STRING(FeedFromId,FORMAT='(I3.3)') + '_' +    $
                   STRING(FeedFromHandle,FORMAT='(I2.2)')

PRINTF, fdP, ";------------------------------------------------------ Loop is closed Here"
PRINTF, fdP, "IF N_ELEMENTS(",Invar,") GT 0 THEN ", Outvar," = ", Invar
PRINTF, fdP, ";------------------------------------------------------"
PRINTF, fdP, ""

END


;T+
; \subsubsection{Function: {\tt Resolve}}
;
; The following procedure is called by {\tt WriteCode} (see below) to 
; derive from the project structure the correct sequence of module calls.
;
; On success modules in the list are associated with a sequence number
; which represents the order of the function calls in the simulation program.
;
; The function fais if an infinite loop is detected, i.e.: a feedback link
; is not connected to the special input of any of the ``Feedback'' special 
; modules (either {\tt FdbStop} or {\tt Combiner}).
;
; \subsubsection{Algorithm}
;
; \noindent {\bf Note:}
; In the following description we call {\tt ancestors} of a given module
; all the modules whose output is connected to an input of the latter.
;
; \begin{itemize}
;
; \item[1] Initialization. The list of module is scanned once and sequence
;          number 0 is assigned to modules with no input required. These 
;          will be computed first.
;
; \end{itemize}
;
; Then the list of modules is scanned repeatedly, performing the following
; operations:
;
; \begin{itemize}
;
; \item[2.1] To each module with any input connected to a module output it
;            is assigned the sequence number with the following rule:
;
;            \begin{displaymath} 
;                    SeqNumber = MAX(SeqNumbers\:of\:ancestors) + 1 
;            \end{displaymath}
;
; \item[2.2] Any input which is a "feedback input" is ignored in rule 2.1.
;
; \item[3]   If during the last scan no module has had its sequence number
;            modified the loop is terminated.
;
; \end{itemize}
;
; MODIFICATION :::: ANDREA LA CAMERA (2012/05/25)
; AFTER THE END OF THE ALGORITHM, THE DEPTH OF EACH MODULE WITH NO OUTPUT (Nout=0)
; IS SET TO THE MAXIMUM VALUE FOUND IN THE PREVIOUS ALGORITHM. IN SUCH A WAY,
; OUTPUT MODULES ARE ALWAYS PLACED IN THE BOTTOM OF THE PROCEDURE/MODCALL
;T-

FUNCTION Resolve, ModArray 		; RETURN:
					; 1 on success
					; 0 on failure (the project has an
					;               infinite loop)

MaxDepth=-1
ToQuote=1
LastMod = N_ELEMENTS(ModArray)-1
WHILE ToQuote DO BEGIN
	ToQuote=0
	FOR i=0, LastMod DO BEGIN		; Adjust Module depths
		MaxDepth=ModArray[i].Depth
		CASE ModArray[i].Type OF
		'+++':	LastInp=ModArray[i].Ninp-2	; Combiner Ignore close loop inp.
		's*s': LastInp=-1		; Feedb. Ignore input
		ELSE: LastInp=ModArray[i].Ninp-1
		ENDCASE

		FOR j=0, LastInp DO BEGIN
			ParentID = ModArray[i].Inputs[j].ID
			Aux=WHERE(ModArray.ID EQ ParentID,cnt1)
			IF cnt1 GT 0 THEN BEGIN
				ParentIndex = Aux[0]
				NewDepth=ModArray[ParentIndex].Depth+1
				IF NewDepth GT MaxDepth THEN BEGIN
					MaxDepth=NewDepth
					ToQuote=1
				ENDIF
			ENDIF
		ENDFOR
		ModArray[i].Depth=MaxDepth
	ENDFOR
	IF MaxDepth GT LastMod THEN RETURN, 0	; Detect infinite loops
ENDWHILE

maxdepth=max(ModArray[*].Depth)
for i=0,N_ELEMENTS(ModArray)-1 do begin
   if ModArray[i].Nout EQ 0 then ModArray[i].Depth=maxdepth
endfor

RETURN, 1

END

;T+
; \subsubsection{Function: {\tt WriteCode}}
;
; This procedure writes the code for the main script to run the
; simulation program.
;
; If called with the argumrent "prof" set to 1, it also includes the
; code to profile the program
;
;
;T-

FUNCTION WriteCode, Project, dd, LoopSpec, $    ; RETURN:
         PrjDir, callfile, prof, fdM, fdM_proc, fdP           ;  0  on success.
						    ; 1  Project is empty
						    ; 2  infinite loop has 
						    ;    been detected

COMMON Worksheet_Common, ModIDgen, DirName, ProjectModified, GridD, $
                         Slot0XY, FileVersion, AB_Name, AB_Version, AB_Date

IF LoopSpec LE 1 THEN LoopSpec = 1

PrjArray = Project->GetList()

Cnt = N_ELEMENTS(PrjArray)

IF Cnt LE 0 THEN RETURN, 1

ModArray = MAKE_ARRAY(cnt,                                  $
                      VALUE={ Type:'',                      $
                              Ninp:0,                       $
                              Nout:0,                       $
                              ID:0,                         $
                              Depth:0,                      $
                              Inputs: Replicate({InOut}, 2)   } )


FOR i=0, cnt-1 DO BEGIN 		; Populate module array with data
	modData = PrjArray[i]->GetData()
	ModArray[i].Type=ModData.Type
	ModArray[i].ID=ModData.ID
	ModArray[i].Ninp=ModData.Ninp
	ModArray[i].Nout=ModData.Nout
	ModArray[i].Inputs=ModData.Inputs
ENDFOR

ret=Resolve(ModArray)			; Compute module calling order

if ret EQ 0 THEN RETURN, 2		; Infinite loop detected

SortIds = SORT(ModArray.Depth)

IF prof THEN BEGIN
;********************************************** CODE FOR PROJECT.PRO ******************************************************
PRINTF, fdM, "; --"
PRINTF, fdM, "; -- CAOS Application builder. Version "+AB_Version
PRINTF, fdM, "; --"
PRINTF, fdM, "; -- file: profiler.pro"
PRINTF, fdM, "; --"
PRINTF, fdM, "; -- Main procedure file (profiler version) for project: "
if strlen(PrjDir) LE 77 then begin
   PRINTF, fdM, ";  "+strtrim(PrjDir,1) 
endif else begin
   PRINTF, fdM, ";  "+strtrim(PrjDir[0:76],1)
   PRINTF, fdM, ";  "+strtrim(PrjDir[77:strlen(PrjDir)-1],1)
endelse
PRINTF, fdM, ";   "+strtrim(PrjDir[0:76],1)
PRINTF, fdM, "; -- Automatically generated on: ", dd
PRINTF, fdM, "; --"
PRINTF, fdM, ";"
;******************************************* END CODE FOR PROJECT.PRO ****************************************************

;********************************************** CODE FOR PROCEDURE ******************************************************
PRINTF, fdM_proc, "; --"
PRINTF, fdM_proc, "; -- CAOS Application builder. Version "+AB_Version
PRINTF, fdM_proc, "; --"
name_prj=(strsplit(PrjDir,!caos_env.delim,/Extract))[1]
PRINTF, fdM_proc, "; -- file:"+strlowcase(name_prj)+".pro"
PRINTF, fdM_proc, "; --"
PRINTF, fdM_proc, "; -- Main procedure file (profiler version) for project: "
if strlen(PrjDir) LE 77 then begin
   PRINTF, fdM_proc, ";  "+strtrim(PrjDir,1) 
endif else begin
   PRINTF, fdM_proc, ";  "+strtrim(PrjDir[0:76],1)
   PRINTF, fdM_proc, ";  "+strtrim(PrjDir[77:strlen(PrjDir)-1],1)
endelse
PRINTF, fdM_proc, "; -- Automatically generated on: ", dd
PRINTF, fdM_proc, "; --"
PRINTF, fdM_proc, ";"
;********************************************* END CODE FOR PROCEDURE ****************************************************

ENDIF ELSE BEGIN
;********************************************** CODE FOR PROJECT.PRO ******************************************************
PRINTF, fdM, "; --"
PRINTF, fdM, "; -- CAOS Application builder. Version "+AB_Version
PRINTF, fdM, "; --"
PRINTF, fdM, "; -- file: project.pro"
PRINTF, fdM, "; --"
PRINTF, fdM, "; -- Main procedure file for project: "
if strlen(PrjDir) LE 77 then begin
   PRINTF, fdM, ";  "+strtrim(PrjDir,1) 
endif else begin
   PRINTF, fdM, ";  "+strtrim(PrjDir[0:76],1)
   PRINTF, fdM, ";  "+strtrim(PrjDir[77:strlen(PrjDir)-1],1)
endelse
PRINTF, fdM, "; -- Automatically generated on: ", dd
PRINTF, fdM, "; --"
PRINTF, fdM, ";"
;******************************************* END CODE FOR PROJECT.PRO ****************************************************

;**********************************************CODE FOR PROCEDURE******************************************************
PRINTF, fdM_proc, "; --"
PRINTF, fdM_proc, "; -- CAOS Application builder. Version "+AB_Version
PRINTF, fdM_proc, "; --"
name_prj=(strsplit(PrjDir,!caos_env.delim,/Extract))[1]
PRINTF, fdM_proc, "; -- file:"+strlowcase(name_prj)+".pro"
PRINTF, fdM_proc, "; --"
PRINTF, fdM_proc, "; -- Main procedure file for project: "
if strlen(PrjDir) LE 77 then begin
   PRINTF, fdM_proc, ";  "+strtrim(PrjDir,1) 
endif else begin
   PRINTF, fdM_proc, ";  "+strtrim(PrjDir[0:76],1)
   PRINTF, fdM_proc, ";  "+strtrim(PrjDir[77:strlen(PrjDir)-1],1)
endelse
PRINTF, fdM_proc, "; -- Automatically generated on: ", dd
PRINTF, fdM_proc, "; --"
PRINTF, fdM_proc, ";"
;********************************************* END CODE FOR PROCEDURE ****************************************************

ENDELSE
;********************************************** CODE FOR PROJECT.PRO ******************************************************
PRINTF, fdM, ""
PRINTF, fdM, ";;;;;;;;;;;;;;;;;;;;;;;;;;;"
PRINTF, fdM, "; Error message procedure ;"
PRINTF, fdM, ";;;;;;;;;;;;;;;;;;;;;;;;;;;"
PRINTF, fdM, ""
PRINTF, fdM, "PRO ProjectMsg, TheMod"
PRINTF, fdM, ";              Common Block definition"
PRINTF, fdM, ";              ======================="
PRINTF, fdM, ";                  Total nmb Current  "
PRINTF, fdM, ";                  of iter.  iteration"
PRINTF, fdM, ";                  --------  ---------"
PRINTF, fdM, "COMMON caos_block, tot_iter, this_iter"
PRINTF, fdM, ""
PRINTF, fdM, "MESSAGE,",'"',"Error calling Module: ",           $
                           '"',"+TheMod+",'"'," at iteration:",    $
                           '"',"+STRING(this_iter)"
PRINTF, fdM, "END"
;******************************************* END CODE FOR PROJECT.PRO ****************************************************

;**********************************************CODE FOR PROCEDURE******************************************************
PRINTF, fdM_proc, ""
PRINTF, fdM_proc, ";;;;;;;;;;;;;;;;;;;;;;;;;;;"
PRINTF, fdM_proc, "; Error message procedure ;"
PRINTF, fdM_proc, ";;;;;;;;;;;;;;;;;;;;;;;;;;;"
PRINTF, fdM_proc, ""
PRINTF, fdM_proc, "PRO ProjectMsg, TheMod"
PRINTF, fdM_proc, ";              Common Block definition"
PRINTF, fdM_proc, ";              ======================="
PRINTF, fdM_proc, ";                  Total nmb Current  "
PRINTF, fdM_proc, ";                  of iter.  iteration"
PRINTF, fdM_proc, ";                  --------  ---------"
PRINTF, fdM_proc, "COMMON caos_block, tot_iter, this_iter"
PRINTF, fdM_proc, ""
PRINTF, fdM_proc, "MESSAGE,",'"',"Error calling Module: ",           $
                           '"',"+TheMod+",'"'," at iteration:",    $
                           '"',"+STRING(this_iter)"
PRINTF, fdM_proc, "END"
;********************************************* END CODE FOR PROCEDURE ****************************************************

;********************************************** CODE FOR PROJECT.PRO ******************************************************
PRINTF, fdM, ""
PRINTF, fdM, "COMMON caos_block, tot_iter, this_iter"

IF prof THEN PRINTF, fdM, "COMMON Prof_Common, ProfArray"

PRINTF, fdM, ""
PRINTF, fdM, "tot_iter = ",STRING(LoopSpec)
PRINTF, fdM, "this_iter = 0"

IF prof THEN BEGIN
  PRINTF, fdM, ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;"
  PRINTF, fdM, "; Create     profiling structure ;"
  PRINTF, fdM, ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;"

  PRINTF, fdM, "ModMax = ", MAX(SortIds)+1

  PRINTF, fdM, "ProfArray= MAKE_ARRAY(ModMax,{Type:'',Count:0L,Time:0.0 })"
  PRINTF, fdM, "ProfArray[0].Type='DUM'"
ENDIF

PRINTF, fdM, ";;;;;;;;;;;;;;;;;;;;;;;;;;;;"
PRINTF, fdM, "; Load Parameter variables ;"
PRINTF, fdM, ";;;;;;;;;;;;;;;;;;;;;;;;;;;;"
PRINTF, fdM, ""

;******************************************* END CODE FOR PROJECT.PRO ****************************************************

;**********************************************CODE FOR PROCEDURE******************************************************
name_prj=(strsplit(PrjDir,!caos_env.delim,/Extract))[1]
PRINTF,fdM_proc,' '
PRINTF, fdM_proc, "PRO "+strlowcase(name_prj)+", mode"
PRINTF, fdM_proc, "COMMON caos_block, tot_iter, this_iter"

IF prof THEN PRINTF, fdM_proc, "COMMON Prof_Common, ProfArray"

PRINTF, fdM_proc, ""
PRINTF, fdM_proc,  'if (n_params() eq 0) then begin'
printf,fdM_proc,"setenv, 'CAOS_ROOT="+!caos_env.root+"'"
printf,fdM_proc,"setenv, 'CAOS_WORK="+!caos_env.work+"'"
;printf,fdM_proc,"setenv, 'CAOS_HTML="+!caos_env.browser+"'"
printf,fdM_proc,"setenv, 'IDL_STARTUP="+!caos_env.work+"caos_startup.pro'"
printf,fdM_proc,"caos_init"
PRINTF, fdM_proc,  'endif else begin'
PRINTF, fdM_proc,  ';do nothing'
PRINTF, fdM_proc,  'endelse'


PRINTF, fdM_proc, "tot_iter = ",STRING(LoopSpec)
PRINTF, fdM_proc,  'if (n_params() eq 0) then begin'
PRINTF, fdM_proc,  '   tot_iter=iter_gui('+STRING(LoopSpec)+')'
PRINTF, fdM_proc,  'endif else begin'
PRINTF, fdM_proc,  ';do nothing'
PRINTF, fdM_proc,  'endelse'

PRINTF, fdM_proc, "this_iter = 0"

IF prof THEN BEGIN
  PRINTF, fdM, ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;"
  PRINTF, fdM, "; Create     profiling structure ;"
  PRINTF, fdM, ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;"

  PRINTF, fdM, "ModMax = ", MAX(SortIds)+1

  PRINTF, fdM, "ProfArray= MAKE_ARRAY(ModMax,{Type:'',Count:0L,Time:0.0 })"
  PRINTF, fdM, "ProfArray[0].Type='DUM'"
ENDIF

PRINTF, fdM_proc, ";;;;;;;;;;;;;;;;;;;;;;;;;;;;"
PRINTF, fdM_proc, "; Load Parameter variables ;"
PRINTF, fdM_proc, ";;;;;;;;;;;;;;;;;;;;;;;;;;;;"
PRINTF, fdM_proc, ""

;******************************************* END CODE FOR PROCEDURE ****************************************************


FOR i=0, cnt-1 DO BEGIN			; Printout Initialization lines

    is=SortIds[i]

    ModData = PrjArray[is]->GetData()
    ModFather = PrjArray[is]->GetFather()
    ModInfo=getmodule(ModData.Type)

    ModuleName = ModData.Type+'_'+STRING(ModData.ID,FORMAT='(I5.5)')

    PRINTF, fdM, "; - Module: ", ModuleName
    PRINTF, fdM_proc, "; - Module: ", ModuleName
    IF prof THEN BEGIN
         PRINTF, fdM, "ProfData[",ModData.ID,"] = {'",ModData.Type,"',0L,0.0}"
         PRINTF, fdM_proc,"ProfData[",ModData.ID,"] = {'",ModData.Type,"',0L,0.0}"
    ENDIF
    
    IF (*ModInfo).rdpar THEN BEGIN		; If module requires parameter


        IF (*ModInfo).init EQ 1 THEN BEGIN		; initializ.
								; required
        	PRINTF, fdM, ModuleName, '_c=0'
        	PRINTF, fdM_proc,ModuleName, '_c=0'
        ENDIF

              	IF (*ModInfo).time EQ 1B THEN BEGIN        ; Time data
                                                        	; required
            	PRINTF, fdM, ModuleName, '_t=0'
            	PRINTF, fdM_proc,ModuleName, '_t=0'
        ENDIF
							; Restore Parameters
        IF OBJ_VALID(ModFather) THEN			$
            Id = ModFather->GetID()			$
        ELSE						$
            Id = ModData.ID

        ParFile= mk_par_name(ModData.type,        $
                             Id,                  $
                             PROJ_NAME=PrjDir)

;******************************************* CODE FOR PROJECT.PRO ****************************************************
        PRINTF, fdM, "RESTORE, '" + ParFile + "'"
        PRINTF, fdM, ModuleName, '_p=par'
        ;PRINTF, fdM,   'endelse'
;***************************************** END CODE FOR PROJECT.PRO **************************************************
                             
;******************************************* CODE FOR PROCEDURE ****************************************************
        PRINTF, fdM_proc,  'if (n_params() eq 0) then begin'
        PRINTF, fdM_proc,  "cd, '"+!caos_env.work+PrjDir+"'"
        PRINTF, fdM_proc,  "print,"+ModData.type+"_gui("+STRING(ModData.ID)+")"
        PRINTF, fdM_proc,  "cd, '"+!caos_env.work+"'"
        PRINTF, fdM_proc,  'endif'; else begin'
        PRINTF, fdM_proc, "RESTORE, '" + ParFile + "'"
        PRINTF, fdM_proc, ModuleName, '_p=par'
        ;PRINTF, fdM,   'endelse'
;******************************************* END CODE FOR PROCEDURE ****************************************************

    ENDIF
ENDFOR

;******************************************* CODE FOR PROJECT.PRO ****************************************************
PRINTF, fdM, ""
PRINTF, fdM, ";;;;;;;;;;;;;;;;;"
PRINTF, fdM, "; Initialization;"
PRINTF, fdM, ";;;;;;;;;;;;;;;;;"
PRINTF, fdM, ""

PRINTF, fdM, 't0=systime(/SEC)'
PRINTF, fdM, 'print, " "'
PRINTF, fdM, 'print, "=== RUNNING INITIALIZATION... ==="'
PRINTF, fdM, '@', callfile
PRINTF, fdM, 'ti=systime(/SEC)-t0'

PRINTF, fdM, ""
PRINTF, fdM, ";;;;;;;;;;;;;;;;"
PRINTF, fdM, "; Loop Control ;"
PRINTF, fdM, ";;;;;;;;;;;;;;;;"
PRINTF, fdM, ""


PRINTF, fdM, 't0=systime(/SEC)'
PRINTF, fdM, 'print, " "'
PRINTF, fdM, 'print, "=== RUNNING SIMULATION...     ==="'
PRINTF, fdM, "FOR this_iter=1L, tot_iter DO BEGIN		; Begin Main Loop"
PRINTF, fdM, '	print, "=== ITER. #"+strtrim(this_iter)+"/"+$'
PRINTF, fdM, '         strtrim(tot_iter,1)+"...", FORMAT="(A,$)"'
PRINTF, fdM, '  if this_iter LT tot_iter then begin'
PRINTF, fdM, '     for k=0,79 do print, string(8B), format="(A,$)"'
PRINTF, fdM, '  endif else print, " " '
PRINTF, fdM, '	@', callfile
PRINTF, fdM, "ENDFOR							; End Main Loop"
PRINTF, fdM, 'ts=systime(/SEC)-t0'

PRINTF, fdM, 'print, " "'
PRINTF, fdM, 'print, "=== CPU time for initialization phase    =", ti, " s."'
PRINTF, fdM, 'print, "=== CPU time for simulation phase        =", ts, " s."'
PRINTF, fdM, 'print, "    [=> CPU time/iteration=", strtrim(ts/tot_iter,2), "s.]"'
PRINTF, fdM, 'print, "=== total CPU time (init.+simu. phases)  =", ti+ts, " s."'
PRINTF, fdM, 'print, " "'
PRINTF, fdM, ";;;;;;;;;;;;;;;;;"
PRINTF, fdM, "; End Main      ;"
PRINTF, fdM, ";;;;;;;;;;;;;;;;;"
PRINTF, fdM, ""
PRINTF, fdM, "END"
;***************************************** END CODE FOR PROJECT.PRO **************************************************

;******************************************* CODE FOR PROCEDURE ****************************************************
PRINTF, fdM_proc, ""
PRINTF, fdM_proc, ";;;;;;;;;;;;;;;;;"
PRINTF, fdM_proc, "; Initialization;"
PRINTF, fdM_proc, ";;;;;;;;;;;;;;;;;"
PRINTF, fdM_proc, ""

PRINTF, fdM_proc, 't0=systime(/SEC)'
PRINTF, fdM_proc, 'print, " "'
PRINTF, fdM_proc, 'print, "=== RUNNING INITIALIZATION... ==="'
PRINTF, fdM_proc, '@', callfile
PRINTF, fdM_proc, 'ti=systime(/SEC)-t0'

PRINTF, fdM_proc, ""
PRINTF, fdM_proc, ";;;;;;;;;;;;;;;;"
PRINTF, fdM_proc, "; Loop Control ;"
PRINTF, fdM_proc, ";;;;;;;;;;;;;;;;"
PRINTF, fdM_proc, ""


PRINTF, fdM_proc, 't0=systime(/SEC)'
PRINTF, fdM_proc, 'print, " "'
PRINTF, fdM_proc, 'print, "=== RUNNING SIMULATION...     ==="'
PRINTF, fdM_proc, "FOR this_iter=1L, tot_iter DO BEGIN		; Begin Main Loop"
PRINTF, fdM_proc, '	print, "=== ITER. #"+strtrim(this_iter)+"/"+$'
PRINTF, fdM_proc, '         strtrim(tot_iter,1)+"...", FORMAT="(A,$)"'
PRINTF, fdM_proc, '  if this_iter LT tot_iter then begin'
PRINTF, fdM_proc, '     for k=0,79 do print, string(8B), format="(A,$)"'
PRINTF, fdM_proc, '  endif else print, " " '
PRINTF, fdM_proc, '	@', callfile
PRINTF, fdM_proc, "ENDFOR							; End Main Loop"
PRINTF, fdM_proc, 'ts=systime(/SEC)-t0'

PRINTF, fdM_proc, 'print, " "'
PRINTF, fdM_proc, 'print, "=== CPU time for initialization phase    =", ti, " s."'
PRINTF, fdM_proc, 'print, "=== CPU time for simulation phase        =", ts, " s."'
PRINTF, fdM_proc, 'print, "    [=> CPU time/iteration=", strtrim(ts/tot_iter,2), "s.]"'
PRINTF, fdM_proc, 'print, "=== total CPU time (init.+simu. phases)  =", ti+ts, " s."'
PRINTF, fdM_proc, 'print, " "'

PRINTF, fdM_proc,  'if (n_params() eq 0) then begin'
PRINTF, fdM_proc,  '   ret=dialog_message("QUIT IDL Virtual Machine ?",/info)'
PRINTF, fdM_proc,  'endif else begin'
PRINTF, fdM_proc,  ';do nothing'
PRINTF, fdM_proc,  'endelse'
PRINTF, fdM_proc, ""
PRINTF, fdM_proc, ";;;;;;;;;;;;;;;;;"
PRINTF, fdM_proc, "; End Main      ;"
PRINTF, fdM_proc, ";;;;;;;;;;;;;;;;;"
PRINTF, fdM_proc, ""
PRINTF, fdM_proc, "END"
;******************************************* END CODE FOR PROCEDURE ****************************************************

					; Generating routine calls
PRINTF, fdP, "; --"
PRINTF, fdP, "; -- CAOS Project. ", AB_Name, ". Version ", AB_Version
PRINTF, fdP, "; --"
PRINTF, fdP, "; -- file: mod_calls.pro";,callfile
PRINTF, fdP, "; --"
PRINTF, fdP, "; -- Module procedures sequence file for project: "
if strlen(Project->GetName()) LE 77 then begin
   PRINTF, fdP, ";  "+strtrim(Project->GetName(),1) 
endif else begin
   PRINTF, fdP, ";  "+strtrim((Project->GetName())[0:76],1)
   PRINTF, fdP, ";  "+strtrim((Project->GetName())[77:strlen(Project->GetName())-1],1)
endelse
PRINTF, fdP, "; -- Automatically generated on: ", dd
PRINTF, fdP, "; --"
PRINTF, fdP, ""
PRINTF, fdP, "; -- This procedure is invoked at each step of the module sequence loop."
PRINTF, fdP, "; -- (including preliminary initialization)"
PRINTF, fdP, "; -- "
PRINTF, fdP, ""
PRINTF, fdP, "COMMON caos_block, tot_iter, this_iter"

IF prof THEN PRINTF, fdP, "COMMON Prof_Common, ProfArray"

FOR i=0, cnt-1 DO BEGIN		; Printout Project computation lines

 is=SortIds[i]

 ModData = PrjArray[is]->GetData()
 ModInfo=getmodule(ModData.Type)

 CASE ModData.Type OF
    's*s': BEGIN
	FdbCode, ModData, ModInfo, fdP
       END
    ELSE: ModuleCode, ModData, ModInfo, is, prof, fdP

    ENDCASE

ENDFOR

RETURN, 0
END

;T+
; \subsubsection{Procedure: {\tt SaveProject}}		\label{saveproject}
;
; This is the main entry point called when a project must be saved onto
; disk. It manages the project name specification interaction with the user
; and then creates the project code (files: {\tt project.pro} and
; {\tt mod\_calls.pro}, see detailed description is sect.~\ref{projectsect}).
;
;T-

; modified 26 feb. 2004: added call to routine MoveDataFiles
;                       - marcel carbillet [marcel@arcetri.astro.it]
; modified 20 june 2016: debugged for other OS than linux (use of !caos_env.delim instead of '/')

PRO SaveProject, info, Parent

COMMON Worksheet_Common, ModIDgen, DirName, ProjectModified, GridD, $
                         Slot0XY, FileVersion, AB_Name, AB_Version, AB_Date

ThisProject = (*info).project
PreviousName = ThisProject->GetName()

special_char=['-',':',';','?','!','"',"'",'^','@','|','/','*',"\"]   ;special characters to avoid in the project name


WIDGET_CONTROL, (*info).NIters, GET_VALUE=NumIters
ThisProject->SetIter, NumIters

IF NOT is_a_dir(DirName) THEN mkdir, DirName

PrjList = GetPrjList()

REPEAT BEGIN
	prjname=SelectFile('Specify a name to save Project',PrjList,PreviousName,Parent)
	ok_prjname=1
	    
	IF prjname NE '' THEN BEGIN		; A name has been specified
		yes=1
        i_char=0
        while ((ok_prjname eq 1) and (i_char lt (size(special_char))[1])) do begin
          ok_prjname=(strpos(prjname,special_char[i_char]) eq -1)
          i_char++
        endwhile
        if ok_prjname eq 0 then begin
          dialog=dialog_message(["Project name cannot contain special characters such as:",$
                                 ' ','         '+strjoin(special_char,' ')])
          yes=0
        endif else begin
          PrjDir = filepath(prjname,ROOT=DirName)

		  IF is_a_dir(PrjDir) THEN BEGIN
			yes=AskConfirm('Project ' + prjname + ' exists. Override?',Parent)
		  ENDIF
		endelse
	ENDIF ELSE BEGIN			; Cancel ...
		PrjDir=''
		yes=1
	ENDELSE
ENDREP UNTIL yes

  
IF PrjDir EQ '' THEN RETURN
						; Save the project structure

name_prj=(strsplit(PrjDir,!caos_env.delim,/Extract))[1]


PreviousDir =  filepath(PreviousName,ROOT=DirName)

projfile = filepath('project.pro',ROOT=PrjDir)
projfile_proc= filepath(strlowcase(name_prj)+'.pro',ROOT=PrjDir)
proffile = filepath('profiler.pro',ROOT=PrjDir)
modcfile = filepath('mod_calls.pro',ROOT=PrjDir)
modpfile = filepath('mod_calls_prof.pro',ROOT=PrjDir)
projtemp = filepath('project.tmp',ROOT=PrjDir)
projtemp_proc = filepath(strlowcase(name_prj)+'.tmp',ROOT=PrjDir)
modctemp = filepath('mod_calls.tmp',ROOT=PrjDir)
projback = filepath('project.bak',ROOT=PrjDir)
projback_proc = filepath(strlowcase(name_prj)+'.bak',ROOT=PrjDir)
modcback = filepath('mod_calls.bak',ROOT=PrjDir)

IF NOT is_a_dir(PrjDir) THEN mkdir,PrjDir

ThisProject->GiveName,prjname

ThisProject->setMaxID, ModIDgen		; Save Module ID generator

PrjBox=ThisProject->GetBox()
SlotOfst= [PrjBox[0],PrjBox[2]]

xyOfst= (*info).oGrid->Slot2screen(SlotOfst) -			$
        (*info).oGrid->Slot2screen([0,0])

dd=SYSTIME(0)

OPENW, fdM,projtemp,/GET_LUN
OPENW, fdM_proc,projtemp_proc, /GET_LUN
OPENW, fdP,modctemp,/GET_LUN
;;OPENW, fdM_P,proffile,/GET_LUN
;;OPENW, fdP_P,modpfile,/GET_LUN

					; Write project structure
ThisProject->Translate,-SlotOfst,-xyOfst
ThisProject->List,fdM

LoopSpec=long((*info).Project->GetIter())

					; Write Project code
Status=WriteCode(ThisProject,dd,LoopSpec,PrjDir,modcfile,0,fdM,fdM_proc,fdP)

;;					; Write Profiler code
;;Status1=WriteCode(ThisProject,dd,LoopSpec,PrjDir,modpfile,1,fdM_P,fdP_P)

FREE_LUN,fdM
FREE_LUN,fdM_proc
FREE_LUN,fdP
;;FREE_LUN,fdM_P
;;FREE_LUN,fdP_P

CASE Status OF
0: BEGIN
	rename, projfile, projback
	rename, projfile_proc,projback_proc
	rename, modcfile, modcback
	rename, projtemp, projfile
	rename, projtemp_proc,projfile_proc
	rename, modctemp, modcfile
;					Move or copy all parameter files
	IF PreviousName eq 'newproject' THEN Op='M' ELSE Op = 'C'

	MoveParFiles,PrjDir,PreviousDir,Op
	MoveDataFiles,PrjDir,PreviousDir,Op

	r=DIALOG_MESSAGE(['Project saved to files:',projfile,projfile_proc,modcfile],/INFORMATION)
	ProjectModified=0;
	WritePrjStatus, info
   END
1: BEGIN
	r=DIALOG_MESSAGE(['Project is empty'],/WARNING)
   END
2: BEGIN
	r=DIALOG_MESSAGE(['Infinite loop detected','Project file has not been created'],/ERROR)
   END
ENDCASE

END
