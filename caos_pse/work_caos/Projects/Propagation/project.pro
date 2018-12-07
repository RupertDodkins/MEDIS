;FILEVER:        8
;PROJECT: Propagation
;       0 - PROJECT TYPE
;          50 - ITERATIONS
;      20 - NMODS
;       0       4       0       6 - Box
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
; MODULE: src
;       4 - ID
;       1 - STATUS
;       0       3 - SLOT
;       0 - Ninputs
;       1 - Noutputs
;       0 - Output   Dtype:       5
; MODULE: src
;       5 - ID
;       1 - STATUS
;       0       5 - SLOT
;       0 - Ninputs
;       1 - Noutputs
;       0 - Output   Dtype:       5
; MODULE: img
;       9 - ID
;       1 - STATUS
;       2       1 - SLOT
;       1 - Ninputs
;       3       0 - Input       0    Nptns:           2   Dtype:       6
;	     140     435
;	     160     435
;       2 - Noutputs
;       0 - Output   Dtype:       3
;       1 - Output   Dtype:       3
; MODULE: wfa
;      12 - ID
;       1 - STATUS
;       2       2 - SLOT
;       2 - Ninputs
;       7       0 - Input       0    Nptns:           2   Dtype:       6
;	     140     335
;	     160     377
;       3       0 - Input       1    Nptns:           2   Dtype:       6
;	     140     435
;	     160     392
;       1 - Noutputs
;       0 - Output   Dtype:       6
; MODULE: dis
;      14 - ID
;       1 - STATUS
;       3       2 - SLOT
;       1 - Ninputs
;      12       0 - Input       0    Nptns:           2   Dtype:       6
;	     210     385
;	     230     385
;       0 - Noutputs
; MODULE: dis
;      15 - ID
;       1 - STATUS
;       3       4 - SLOT
;       1 - Ninputs
;      13       0 - Input       0    Nptns:           2   Dtype:       6
;	     210     285
;	     230     285
;       0 - Noutputs
; MODULE: dis
;      16 - ID
;       1 - STATUS
;       3       1 - SLOT
;       1 - Ninputs
;       9       1 - Input       0    Nptns:           2   Dtype:       3
;	     210     442
;	     230     435
;       0 - Noutputs
; MODULE: dis
;      17 - ID
;       1 - STATUS
;       3       3 - SLOT
;       1 - Ninputs
;      10       1 - Input       0    Nptns:           2   Dtype:       3
;	     210     342
;	     230     335
;       0 - Noutputs
; MODULE: dis
;      18 - ID
;       1 - STATUS
;       2       0 - SLOT
;       1 - Ninputs
;       3       0 - Input       0    Nptns:           2   Dtype:       6
;	     140     435
;	     160     485
;       0 - Noutputs
; MODULE: stf
;      19 - ID
;       1 - STATUS
;       3       0 - SLOT
;       1 - Ninputs
;       3       0 - Input       0    Nptns:           4   Dtype:       6
;	     140     435
;	     150     460
;	     220     460
;	     230     485
;       1 - Noutputs
;       0 - Output   Dtype:       9
; MODULE: dis
;      20 - ID
;       1 - STATUS
;       2       5 - SLOT
;       1 - Ninputs
;       7       0 - Input       0    Nptns:           4   Dtype:       6
;	     140     335
;	     145     335
;	     145     275
;	     160     235
;       0 - Noutputs
; MODULE: dis
;      21 - ID
;       1 - STATUS
;       2       6 - SLOT
;       1 - Ninputs
;       8       0 - Input       0    Nptns:           2   Dtype:       6
;	     140     235
;	     160     185
;       0 - Noutputs
; MODULE: dis
;      22 - ID
;       1 - STATUS
;       4       0 - SLOT
;       1 - Ninputs
;      19       0 - Input       0    Nptns:           2   Dtype:       9
;	     280     485
;	     300     485
;       0 - Noutputs
; MODULE: gpr     CLONE OF        3
;       7 - ID
;       1 - STATUS
;       1       3 - SLOT
;       2 - Ninputs
;       4       0 - Input       0    Nptns:           2   Dtype:       5
;	      70     335
;	      90     327
;       1       0 - Input       1    Nptns:           4   Dtype:       1
;	      70     485
;	      80     465
;	      80     350
;	      90     342
;       1 - Noutputs
;       0 - Output   Dtype:       6
; MODULE: gpr     CLONE OF        3
;       8 - ID
;       1 - STATUS
;       1       5 - SLOT
;       2 - Ninputs
;       5       0 - Input       0    Nptns:           2   Dtype:       5
;	      70     235
;	      90     227
;       1       0 - Input       1    Nptns:           5   Dtype:       1
;	      70     485
;	      80     460
;	      80     350
;	      80     250
;	      90     242
;       1 - Noutputs
;       0 - Output   Dtype:       6
; MODULE: img     CLONE OF        9
;      10 - ID
;       1 - STATUS
;       2       3 - SLOT
;       1 - Ninputs
;       7       0 - Input       0    Nptns:           2   Dtype:       6
;	     140     335
;	     160     335
;       2 - Noutputs
;       0 - Output   Dtype:       3
;       1 - Output   Dtype:       3
; MODULE: wfa     CLONE OF       12
;      13 - ID
;       1 - STATUS
;       2       4 - SLOT
;       2 - Ninputs
;       8       0 - Input       0    Nptns:           2   Dtype:       6
;	     140     235
;	     160     277
;       3       0 - Input       1    Nptns:           4   Dtype:       6
;	     140     435
;	     150     405
;	     150     300
;	     160     292
;       1 - Noutputs
;       0 - Output   Dtype:       6
;
;TEXT: structure function
;        0  - Angle
;    0   0   0  - Color
; Courier*italic  - Fontname
;       14.0000  - Size
;      228     454  - Location
;
;TEXT: Anisoplanatism
;        0  - Angle
;    0   0   0  - Color
; Courier  - Fontname
;       20.0000  - Size
;      301     372  - Location
;
;TEXT: Cone effect
;        0  - Angle
;    0   0   0  - Color
; Courier  - Fontname
;       20.0000  - Size
;      301     272  - Location
;
;TEXT: on-axis NGS
;        0  - Angle
;    0   0   0  - Color
; Courier*italic  - Fontname
;       14.0000  - Size
;        5     400  - Location
;
;TEXT: off-axis NGS
;        0  - Angle
;    0   0   0  - Color
; Courier*italic  - Fontname
;       14.0000  - Size
;        5     300  - Location
;
;TEXT: on-axis LGS
;        0  - Angle
;    0   0   0  - Color
; Courier*italic  - Fontname
;       14.0000  - Size
;        3     201  - Location
; --
; -- CAOS Application builder. Version 7.0
; --
; -- file: project.pro
; --
; -- Main procedure file for project: 
;  Projects/Propagation
; -- Automatically generated on: Sun Jun 19 18:04:53 2016
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

; - Module: atm_00001
atm_00001_c=0
RESTORE, 'Projects/Propagation/atm_00001.sav'
atm_00001_p=par
; - Module: src_00002
src_00002_c=0
RESTORE, 'Projects/Propagation/src_00002.sav'
src_00002_p=par
; - Module: src_00005
src_00005_c=0
RESTORE, 'Projects/Propagation/src_00005.sav'
src_00005_p=par
; - Module: src_00004
src_00004_c=0
RESTORE, 'Projects/Propagation/src_00004.sav'
src_00004_p=par
; - Module: gpr_00007
gpr_00007_c=0
RESTORE, 'Projects/Propagation/gpr_00003.sav'
gpr_00007_p=par
; - Module: gpr_00008
gpr_00008_c=0
RESTORE, 'Projects/Propagation/gpr_00003.sav'
gpr_00008_p=par
; - Module: gpr_00003
gpr_00003_c=0
RESTORE, 'Projects/Propagation/gpr_00003.sav'
gpr_00003_p=par
; - Module: wfa_00012
RESTORE, 'Projects/Propagation/wfa_00012.sav'
wfa_00012_p=par
; - Module: img_00010
img_00010_c=0
img_00010_t=0
RESTORE, 'Projects/Propagation/img_00009.sav'
img_00010_p=par
; - Module: wfa_00013
RESTORE, 'Projects/Propagation/wfa_00012.sav'
wfa_00013_p=par
; - Module: img_00009
img_00009_c=0
img_00009_t=0
RESTORE, 'Projects/Propagation/img_00009.sav'
img_00009_p=par
; - Module: stf_00019
stf_00019_c=0
RESTORE, 'Projects/Propagation/stf_00019.sav'
stf_00019_p=par
; - Module: dis_00014
dis_00014_c=0
RESTORE, 'Projects/Propagation/dis_00014.sav'
dis_00014_p=par
; - Module: dis_00016
dis_00016_c=0
RESTORE, 'Projects/Propagation/dis_00016.sav'
dis_00016_p=par
; - Module: dis_00017
dis_00017_c=0
RESTORE, 'Projects/Propagation/dis_00017.sav'
dis_00017_p=par
; - Module: dis_00018
dis_00018_c=0
RESTORE, 'Projects/Propagation/dis_00018.sav'
dis_00018_p=par
; - Module: dis_00022
dis_00022_c=0
RESTORE, 'Projects/Propagation/dis_00022.sav'
dis_00022_p=par
; - Module: dis_00020
dis_00020_c=0
RESTORE, 'Projects/Propagation/dis_00020.sav'
dis_00020_p=par
; - Module: dis_00021
dis_00021_c=0
RESTORE, 'Projects/Propagation/dis_00021.sav'
dis_00021_p=par
; - Module: dis_00015
dis_00015_c=0
RESTORE, 'Projects/Propagation/dis_00015.sav'
dis_00015_p=par

;;;;;;;;;;;;;;;;;
; Initialization;
;;;;;;;;;;;;;;;;;

t0=systime(/SEC)
print, " "
print, "=== RUNNING INITIALIZATION... ==="
@Projects/Propagation/mod_calls.pro
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
	@Projects/Propagation/mod_calls.pro
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
