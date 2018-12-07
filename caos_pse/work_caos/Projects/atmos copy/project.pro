;FILEVER:        8
;PROJECT: atmos
;       0 - PROJECT TYPE
;          10 - ITERATIONS
;       3 - NMODS
;       0       1       0       1 - Box
; MODULE: atm
;       1 - ID
;       1 - STATUS
;       0       0 - SLOT
;       0 - Ninputs
;       1 - Noutputs
;       0 - Output   Dtype:       1
; MODULE: src
;       2 - ID
;       1 - STATUS
;       0       1 - SLOT
;       0 - Ninputs
;       1 - Noutputs
;       0 - Output   Dtype:       5
; MODULE: gpr
;       3 - ID
;       1 - STATUS
;       1       1 - SLOT
;       2 - Ninputs
;       2       0 - Input       0    Nptns:           2   Dtype:       5
;	      70     435
;	      90     427
;       1       0 - Input       1    Nptns:           2   Dtype:       1
;	      70     485
;	      90     442
;       1 - Noutputs
;       0 - Output   Dtype:       6
;
;TEXT: DM
;        0  - Angle
;    0   0   0  - Color
; Courier*italic  - Fontname
;       14.0000  - Size
;      159     403  - Location
;
;TEXT: SH wfs
;        0  - Angle
;    0   0   0  - Color
; Courier*italic  - Fontname
;       14.0000  - Size
;      227     404  - Location
;
;TEXT: wf rec.
;        0  - Angle
;    0   0   0  - Color
; Courier*italic  - Fontname
;       14.0000  - Size
;      363     401  - Location
;
;TEXT: ctrl
;        0  - Angle
;    0   0   0  - Color
; Courier*italic  - Fontname
;       14.0000  - Size
;      443     402  - Location
;
;TEXT: close the loop
;        0  - Angle
;    0   0   0  - Color
; Courier*italic  - Fontname
;       14.0000  - Size
;      508     404  - Location
;
;TEXT: imaging
;        0  - Angle
;    0   0   0  - Color
; Courier*italic  - Fontname
;       14.0000  - Size
;      211     502  - Location
;
;TEXT: turbulent atm.
;        0  - Angle
;    0   0   0  - Color
; Courier*italic  - Fontname
;       14.0000  - Size
;        1     501  - Location
;
;TEXT: NGS
;        0  - Angle
;    0   0   0  - Color
; Courier*italic  - Fontname
;       14.0000  - Size
;        4     402  - Location
;
;TEXT: telescope
;        0  - Angle
;    0   0   0  - Color
; Courier*italic  - Fontname
;       14.0000  - Size
;       71     401  - Location
; --
; -- CAOS Application builder. Version 7.0
; --
; -- file: project.pro
; --
; -- Main procedure file for project: 
;  Projects/atmos
; -- Automatically generated on: Thu Dec 28 12:38:34 2017
; --
;

;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Error message procedure ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

PRO ProjectMsg, TheMod
;              Common Block definition
;              =======================
;                  Total nmb Current  
;                  of iter.  iteration
;                  --------  ---------
COMMON caos_block, tot_iter, this_iter

MESSAGE,"Error calling Module: "+TheMod+" at iteration:"+STRING(this_iter)
END

COMMON caos_block, tot_iter, this_iter

tot_iter =           10
this_iter = 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Load Parameter variables ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; - Module: atm_00001
atm_00001_c=0
RESTORE, 'Projects/atmos/atm_00001.sav'
atm_00001_p=par
; - Module: src_00002
src_00002_c=0
RESTORE, 'Projects/atmos/src_00002.sav'
src_00002_p=par
; - Module: gpr_00003
gpr_00003_c=0
RESTORE, 'Projects/atmos/gpr_00003.sav'
gpr_00003_p=par

;;;;;;;;;;;;;;;;;
; Initialization;
;;;;;;;;;;;;;;;;;

t0=systime(/SEC)
print, " "
print, "=== RUNNING INITIALIZATION... ==="
@Projects/atmos/mod_calls.pro
ti=systime(/SEC)-t0

;;;;;;;;;;;;;;;;
; Loop Control ;
;;;;;;;;;;;;;;;;

t0=systime(/SEC)
print, " "
print, "=== RUNNING SIMULATION...     ==="
FOR this_iter=1L, tot_iter DO BEGIN		; Begin Main Loop
	print, "=== ITER. #"+strtrim(this_iter)+"/"+$
         strtrim(tot_iter,1)+"...", FORMAT="(A,$)"
  if this_iter LT tot_iter then begin
     for k=0,79 do print, string(8B), format="(A,$)"
  endif else print, " " 
	@Projects/atmos/mod_calls.pro
ENDFOR							; End Main Loop
ts=systime(/SEC)-t0
print, " "
print, "=== CPU time for initialization phase    =", ti, " s."
print, "=== CPU time for simulation phase        =", ts, " s."
print, "    [=> CPU time/iteration=", strtrim(ts/tot_iter,2), "s.]"
print, "=== total CPU time (init.+simu. phases)  =", ti+ts, " s."
print, " "
;;;;;;;;;;;;;;;;;
; End Main      ;
;;;;;;;;;;;;;;;;;

END
