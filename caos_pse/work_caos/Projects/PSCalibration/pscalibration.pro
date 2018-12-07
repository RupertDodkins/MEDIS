; --
; -- CAOS Application builder. Version 7.0
; --
; -- file:pscalibration.pro
; --
; -- Main procedure file for project: 
;  Projects/PSCalibration
; -- Automatically generated on: Tue Jun 21 12:14:55 2016
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
 
PRO pscalibration, mode
COMMON caos_block, tot_iter, this_iter

if (n_params() eq 0) then begin
setenv, 'CAOS_ROOT=/Users/marcel/Simul/caos_pse/'
setenv, 'CAOS_WORK=/Users/marcel/Simul/caos_pse/work_caos/'
setenv, 'IDL_STARTUP=/Users/marcel/Simul/caos_pse/work_caos/caos_startup.pro'
caos_init
endif else begin
;do nothing
endelse
tot_iter =          153
if (n_params() eq 0) then begin
   tot_iter=iter_gui(         153)
endif else begin
;do nothing
endelse
this_iter = 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Load Parameter variables ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; - Module: src_00002
src_00002_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/PSCalibration'
print,src_gui(       2)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/PSCalibration/src_00002.sav'
src_00002_p=par
; - Module: mds_00001
mds_00001_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/PSCalibration'
print,mds_gui(       1)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/PSCalibration/mds_00001.sav'
mds_00001_p=par
; - Module: gpr_00003
gpr_00003_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/PSCalibration'
print,gpr_gui(       3)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/PSCalibration/gpr_00003.sav'
gpr_00003_p=par
; - Module: pyr_00004
pyr_00004_c=0
pyr_00004_t=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/PSCalibration'
print,pyr_gui(       4)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/PSCalibration/pyr_00004.sav'
pyr_00004_p=par
; - Module: slo_00005
slo_00005_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/PSCalibration'
print,slo_gui(       5)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/PSCalibration/slo_00005.sav'
slo_00005_p=par
; - Module: dis_00010
dis_00010_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/PSCalibration'
print,dis_gui(      10)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/PSCalibration/dis_00010.sav'
dis_00010_p=par
; - Module: scd_00006
scd_00006_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/PSCalibration'
print,scd_gui(       6)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/PSCalibration/scd_00006.sav'
scd_00006_p=par
; - Module: dis_00007
dis_00007_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/PSCalibration'
print,dis_gui(       7)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/PSCalibration/dis_00007.sav'
dis_00007_p=par
; - Module: dis_00008
dis_00008_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/PSCalibration'
print,dis_gui(       8)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/PSCalibration/dis_00008.sav'
dis_00008_p=par
; - Module: dis_00009
dis_00009_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/PSCalibration'
print,dis_gui(       9)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/PSCalibration/dis_00009.sav'
dis_00009_p=par

;;;;;;;;;;;;;;;;;
; Initialization;
;;;;;;;;;;;;;;;;;

t0=systime(/SEC)
print, " "
print, "=== RUNNING INITIALIZATION... ==="
@Projects/PSCalibration/mod_calls.pro
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
	@Projects/PSCalibration/mod_calls.pro
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
