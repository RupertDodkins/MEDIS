; --
; -- CAOS Application builder. Version 7.0
; --
; -- file:shcalibration.pro
; --
; -- Main procedure file for project: 
;  Projects/SHCalibration
; -- Automatically generated on: Sun Jun 19 18:16:50 2016
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
 
PRO shcalibration, mode
COMMON caos_block, tot_iter, this_iter

if (n_params() eq 0) then begin
setenv, 'CAOS_ROOT=/Users/marcel/Simul/caos_pse/'
setenv, 'CAOS_WORK=/Users/marcel/Simul/caos_pse/work_caos/'
setenv, 'IDL_STARTUP=/Users/marcel/Simul/caos_pse/work_caos/caos_startup.pro'
caos_init
endif else begin
;do nothing
endelse
tot_iter =           44
if (n_params() eq 0) then begin
   tot_iter=iter_gui(          44)
endif else begin
;do nothing
endelse
this_iter = 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Load Parameter variables ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; - Module: mds_00001
mds_00001_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/SHCalibration'
print,mds_gui(       1)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/SHCalibration/mds_00001.sav'
mds_00001_p=par
; - Module: src_00002
src_00002_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/SHCalibration'
print,src_gui(       2)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/SHCalibration/src_00002.sav'
src_00002_p=par
; - Module: gpr_00003
gpr_00003_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/SHCalibration'
print,gpr_gui(       3)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/SHCalibration/gpr_00003.sav'
gpr_00003_p=par
; - Module: sws_00004
sws_00004_c=0
sws_00004_t=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/SHCalibration'
print,sws_gui(       4)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/SHCalibration/sws_00004.sav'
sws_00004_p=par
; - Module: bqc_00005
bqc_00005_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/SHCalibration'
print,bqc_gui(       5)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/SHCalibration/bqc_00005.sav'
bqc_00005_p=par
; - Module: scd_00007
scd_00007_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/SHCalibration'
print,scd_gui(       7)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/SHCalibration/scd_00007.sav'
scd_00007_p=par
; - Module: dis_00008
dis_00008_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/SHCalibration'
print,dis_gui(       8)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/SHCalibration/dis_00008.sav'
dis_00008_p=par
; - Module: dis_00009
dis_00009_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/SHCalibration'
print,dis_gui(       9)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/SHCalibration/dis_00009.sav'
dis_00009_p=par
; - Module: dis_00010
dis_00010_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/SHCalibration'
print,dis_gui(      10)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/SHCalibration/dis_00010.sav'
dis_00010_p=par

;;;;;;;;;;;;;;;;;
; Initialization;
;;;;;;;;;;;;;;;;;

t0=systime(/SEC)
print, " "
print, "=== RUNNING INITIALIZATION... ==="
@Projects/SHCalibration/mod_calls.pro
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
	@Projects/SHCalibration/mod_calls.pro
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
