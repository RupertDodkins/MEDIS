; --
; -- CAOS Application builder. Version 7.0
; --
; -- file:pssimulation.pro
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
 
PRO pssimulation, mode
COMMON caos_block, tot_iter, this_iter

if (n_params() eq 0) then begin
setenv, 'CAOS_ROOT=/home/kids/Downloads/caos_pse/'
setenv, 'CAOS_WORK=/home/kids/Downloads/caos_pse/work_caos/'
setenv, 'IDL_STARTUP=/home/kids/Downloads/caos_pse/work_caos/caos_startup.pro'
caos_init
endif else begin
;do nothing
endelse
tot_iter =           50
if (n_params() eq 0) then begin
   tot_iter=iter_gui(          50)
endif else begin
;do nothing
endelse
this_iter = 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Load Parameter variables ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; - Module: s*s_00010
; - Module: src_00002
src_00002_c=0
if (n_params() eq 0) then begin
cd, '/home/kids/Downloads/caos_pse/work_caos/Projects/PSSimulation'
print,src_gui(       2)
cd, '/home/kids/Downloads/caos_pse/work_caos/'
endif
RESTORE, 'Projects/PSSimulation/src_00002.sav'
src_00002_p=par
; - Module: atm_00001
atm_00001_c=0
if (n_params() eq 0) then begin
cd, '/home/kids/Downloads/caos_pse/work_caos/Projects/PSSimulation'
print,atm_gui(       1)
cd, '/home/kids/Downloads/caos_pse/work_caos/'
endif
RESTORE, 'Projects/PSSimulation/atm_00001.sav'
atm_00001_p=par
; - Module: gpr_00003
gpr_00003_c=0
if (n_params() eq 0) then begin
cd, '/home/kids/Downloads/caos_pse/work_caos/Projects/PSSimulation'
print,gpr_gui(       3)
cd, '/home/kids/Downloads/caos_pse/work_caos/'
endif
RESTORE, 'Projects/PSSimulation/gpr_00003.sav'
gpr_00003_p=par
; - Module: dmi_00004
dmi_00004_c=0
dmi_00004_t=0
if (n_params() eq 0) then begin
cd, '/home/kids/Downloads/caos_pse/work_caos/Projects/PSSimulation'
print,dmi_gui(       4)
cd, '/home/kids/Downloads/caos_pse/work_caos/'
endif
RESTORE, 'Projects/PSSimulation/dmi_00004.sav'
dmi_00004_p=par
; - Module: pyr_00005
pyr_00005_c=0
pyr_00005_t=0
if (n_params() eq 0) then begin
cd, '/home/kids/Downloads/caos_pse/work_caos/Projects/PSSimulation'
print,pyr_gui(       5)
cd, '/home/kids/Downloads/caos_pse/work_caos/'
endif
RESTORE, 'Projects/PSSimulation/pyr_00005.sav'
pyr_00005_p=par
; - Module: slo_00006
slo_00006_c=0
if (n_params() eq 0) then begin
cd, '/home/kids/Downloads/caos_pse/work_caos/Projects/PSSimulation'
print,slo_gui(       6)
cd, '/home/kids/Downloads/caos_pse/work_caos/'
endif
RESTORE, 'Projects/PSSimulation/slo_00006.sav'
slo_00006_p=par
; - Module: rec_00007
rec_00007_c=0
if (n_params() eq 0) then begin
cd, '/home/kids/Downloads/caos_pse/work_caos/Projects/PSSimulation'
print,rec_gui(       7)
cd, '/home/kids/Downloads/caos_pse/work_caos/'
endif
RESTORE, 'Projects/PSSimulation/rec_00007.sav'
rec_00007_p=par
; - Module: dis_00018
dis_00018_c=0
if (n_params() eq 0) then begin
cd, '/home/kids/Downloads/caos_pse/work_caos/Projects/PSSimulation'
print,dis_gui(      18)
cd, '/home/kids/Downloads/caos_pse/work_caos/'
endif
RESTORE, 'Projects/PSSimulation/dis_00018.sav'
dis_00018_p=par
; - Module: dis_00016
dis_00016_c=0
if (n_params() eq 0) then begin
cd, '/home/kids/Downloads/caos_pse/work_caos/Projects/PSSimulation'
print,dis_gui(      16)
cd, '/home/kids/Downloads/caos_pse/work_caos/'
endif
RESTORE, 'Projects/PSSimulation/dis_00016.sav'
dis_00016_p=par
; - Module: dis_00015
dis_00015_c=0
if (n_params() eq 0) then begin
cd, '/home/kids/Downloads/caos_pse/work_caos/Projects/PSSimulation'
print,dis_gui(      15)
cd, '/home/kids/Downloads/caos_pse/work_caos/'
endif
RESTORE, 'Projects/PSSimulation/dis_00015.sav'
dis_00015_p=par
; - Module: dis_00014
dis_00014_c=0
if (n_params() eq 0) then begin
cd, '/home/kids/Downloads/caos_pse/work_caos/Projects/PSSimulation'
print,dis_gui(      14)
cd, '/home/kids/Downloads/caos_pse/work_caos/'
endif
RESTORE, 'Projects/PSSimulation/dis_00014.sav'
dis_00014_p=par
; - Module: dis_00013
dis_00013_c=0
if (n_params() eq 0) then begin
cd, '/home/kids/Downloads/caos_pse/work_caos/Projects/PSSimulation'
print,dis_gui(      13)
cd, '/home/kids/Downloads/caos_pse/work_caos/'
endif
RESTORE, 'Projects/PSSimulation/dis_00013.sav'
dis_00013_p=par
; - Module: tfl_00009
tfl_00009_c=0
if (n_params() eq 0) then begin
cd, '/home/kids/Downloads/caos_pse/work_caos/Projects/PSSimulation'
print,tfl_gui(       9)
cd, '/home/kids/Downloads/caos_pse/work_caos/'
endif
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
if (n_params() eq 0) then begin
   ret=dialog_message("QUIT IDL Virtual Machine ?",/info)
endif else begin
;do nothing
endelse

;;;;;;;;;;;;;;;;;
; End Main      ;
;;;;;;;;;;;;;;;;;

END
