;FILEVER:        8
;PROJECT: PSSimulation
;       0 - PROJECT TYPE
;          50 - ITERATIONS
;      14 - NMODS
;       0       7       0       2 - Box
; MODULE: dis
;      18 - ID
;       1 - STATUS
;       4       2 - SLOT
;       1 - Ninputs
;       5       0 - Input       0    Nptns:           2   Dtype:       4
;	     280     427
;	     300     385
;       0 - Noutputs
; MODULE: dis
;      16 - ID
;       1 - STATUS
;       5       2 - SLOT
;       1 - Ninputs
;       6       0 - Input       0    Nptns:           2   Dtype:       7
;	     350     435
;	     370     385
;       0 - Noutputs
; MODULE: dis
;      15 - ID
;       1 - STATUS
;       4       0 - SLOT
;       1 - Ninputs
;       5       1 - Input       0    Nptns:           2   Dtype:       3
;	     280     442
;	     300     485
;       0 - Noutputs
; MODULE: dis
;      14 - ID
;       1 - STATUS
;       2       2 - SLOT
;       1 - Ninputs
;       3       0 - Input       0    Nptns:           2   Dtype:       6
;	     140     435
;	     160     385
;       0 - Noutputs
; MODULE: dis
;      13 - ID
;       1 - STATUS
;       3       2 - SLOT
;       1 - Ninputs
;       4       1 - Input       0    Nptns:           2   Dtype:       6
;	     210     442
;	     230     385
;       0 - Noutputs
; MODULE: s*s
;      10 - ID
;       0 - STATUS
;       7       1 - SLOT
;       1 - Ninputs
;       9       0 - Input       0    Nptns:           2   Dtype:       8
;	     490     435
;	     510     435
;       1 - Noutputs
;       0 - Output   Dtype:       8
; MODULE: tfl
;       9 - ID
;       1 - STATUS
;       6       1 - SLOT
;       1 - Ninputs
;       7       0 - Input       0    Nptns:           2   Dtype:       8
;	     420     435
;	     440     435
;       1 - Noutputs
;       0 - Output   Dtype:       8
; MODULE: rec
;       7 - ID
;       1 - STATUS
;       5       1 - SLOT
;       1 - Ninputs
;       6       0 - Input       0    Nptns:           2   Dtype:       7
;	     350     435
;	     370     435
;       1 - Noutputs
;       0 - Output   Dtype:       8
; MODULE: slo
;       6 - ID
;       1 - STATUS
;       4       1 - SLOT
;       1 - Ninputs
;       5       0 - Input       0    Nptns:           2   Dtype:       4
;	     280     427
;	     300     435
;       1 - Noutputs
;       0 - Output   Dtype:       7
; MODULE: pyr
;       5 - ID
;       1 - STATUS
;       3       1 - SLOT
;       1 - Ninputs
;       4       1 - Input       0    Nptns:           2   Dtype:       6
;	     210     442
;	     230     435
;       2 - Noutputs
;       0 - Output   Dtype:       4
;       1 - Output   Dtype:       3
; MODULE: dmi
;       4 - ID
;       1 - STATUS
;       2       1 - SLOT
;       2 - Ninputs
;       3       0 - Input       0    Nptns:           2   Dtype:       6
;	     140     435
;	     160     427
;      10       0 - Input       1    Nptns:           6   Dtype:       8
;	     560     435
;	     570     435
;	     570     460
;	     150     460
;	     150     450
;	     160     442
;       2 - Noutputs
;       0 - Output   Dtype:       6
;       1 - Output   Dtype:       6
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
; MODULE: src
;       2 - ID
;       1 - STATUS
;       0       1 - SLOT
;       0 - Ninputs
;       1 - Noutputs
;       0 - Output   Dtype:       5
; MODULE: atm
;       1 - ID
;       1 - STATUS
;       0       0 - SLOT
;       0 - Ninputs
;       1 - Noutputs
;       0 - Output   Dtype:       1
;
;TEXT: DM
;        0  - Angle
;    0   0   0  - Color
; Courier*italic  - Fontname
;       12.0000  - Size
;      159     403  - Location
;
;TEXT: reconstruction & control
;        0  - Angle
;    0   0   0  - Color
; Courier*italic  - Fontname
;       12.0000  - Size
;      362     407  - Location
;
;TEXT: turbulent atm.
;        0  - Angle
;    0   0   0  - Color
; Courier*italic  - Fontname
;       12.0000  - Size
;        3     501  - Location
;
;TEXT: NGS
;        0  - Angle
;    0   0   0  - Color
; Courier*italic  - Fontname
;       12.0000  - Size
;       19     402  - Location
;
;TEXT: pyramid
;        0  - Angle
;    0   0   0  - Color
; Courier*italic  - Fontname
;       12.0000  - Size
;      223     406  - Location
; --
; -- CAOS Application builder. Version 7.0
; --
; -- file: project.pro
; --
; -- Main procedure file for project: 
;  Projects/PSSimulation
; -- Automatically generated on: Mon Apr 17 21:24:35 2017
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

tot_iter =           50
this_iter = 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Load Parameter variables ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; - Module: s*s_00010
; - Module: src_00002
src_00002_c=0
RESTORE, 'Projects/PSSimulation/src_00002.sav'
src_00002_p=par
; - Module: atm_00001
atm_00001_c=0
RESTORE, 'Projects/PSSimulation/atm_00001.sav'
atm_00001_p=par
; - Module: gpr_00003
gpr_00003_c=0
RESTORE, 'Projects/PSSimulation/gpr_00003.sav'
gpr_00003_p=par
; - Module: dmi_00004
dmi_00004_c=0
dmi_00004_t=0
RESTORE, 'Projects/PSSimulation/dmi_00004.sav'
dmi_00004_p=par
; - Module: pyr_00005
pyr_00005_c=0
pyr_00005_t=0
RESTORE, 'Projects/PSSimulation/pyr_00005.sav'
pyr_00005_p=par
; - Module: slo_00006
slo_00006_c=0
RESTORE, 'Projects/PSSimulation/slo_00006.sav'
slo_00006_p=par
; - Module: rec_00007
rec_00007_c=0
RESTORE, 'Projects/PSSimulation/rec_00007.sav'
rec_00007_p=par
; - Module: dis_00018
dis_00018_c=0
RESTORE, 'Projects/PSSimulation/dis_00018.sav'
dis_00018_p=par
; - Module: dis_00016
dis_00016_c=0
RESTORE, 'Projects/PSSimulation/dis_00016.sav'
dis_00016_p=par
; - Module: dis_00015
dis_00015_c=0
RESTORE, 'Projects/PSSimulation/dis_00015.sav'
dis_00015_p=par
; - Module: dis_00014
dis_00014_c=0
RESTORE, 'Projects/PSSimulation/dis_00014.sav'
dis_00014_p=par
; - Module: dis_00013
dis_00013_c=0
RESTORE, 'Projects/PSSimulation/dis_00013.sav'
dis_00013_p=par
; - Module: tfl_00009
tfl_00009_c=0
RESTORE, 'Projects/PSSimulation/tfl_00009.sav'
tfl_00009_p=par

;;;;;;;;;;;;;;;;;
; Initialization;
;;;;;;;;;;;;;;;;;

t0=systime(/SEC)
print, " "
print, "=== RUNNING INITIALIZATION... ==="
@Projects/PSSimulation/mod_calls.pro
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
	@Projects/PSSimulation/mod_calls.pro
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
