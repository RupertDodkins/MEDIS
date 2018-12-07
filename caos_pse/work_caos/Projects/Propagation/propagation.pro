; --
; -- CAOS Application builder. Version 7.0
; --
; -- file:propagation.pro
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
 
PRO propagation, mode
COMMON caos_block, tot_iter, this_iter

if (n_params() eq 0) then begin
setenv, 'CAOS_ROOT=/Users/marcel/Simul/caos_pse/'
setenv, 'CAOS_WORK=/Users/marcel/Simul/caos_pse/work_caos/'
setenv, 'IDL_STARTUP=/Users/marcel/Simul/caos_pse/work_caos/caos_startup.pro'
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

; - Module: atm_00001
atm_00001_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/Propagation'
print,atm_gui(       1)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Propagation/atm_00001.sav'
atm_00001_p=par
; - Module: src_00002
src_00002_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/Propagation'
print,src_gui(       2)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Propagation/src_00002.sav'
src_00002_p=par
; - Module: src_00005
src_00005_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/Propagation'
print,src_gui(       5)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Propagation/src_00005.sav'
src_00005_p=par
; - Module: src_00004
src_00004_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/Propagation'
print,src_gui(       4)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Propagation/src_00004.sav'
src_00004_p=par
; - Module: gpr_00007
gpr_00007_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/Propagation'
print,gpr_gui(       7)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Propagation/gpr_00003.sav'
gpr_00007_p=par
; - Module: gpr_00008
gpr_00008_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/Propagation'
print,gpr_gui(       8)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Propagation/gpr_00003.sav'
gpr_00008_p=par
; - Module: gpr_00003
gpr_00003_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/Propagation'
print,gpr_gui(       3)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Propagation/gpr_00003.sav'
gpr_00003_p=par
; - Module: wfa_00012
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/Propagation'
print,wfa_gui(      12)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Propagation/wfa_00012.sav'
wfa_00012_p=par
; - Module: img_00010
img_00010_c=0
img_00010_t=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/Propagation'
print,img_gui(      10)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Propagation/img_00009.sav'
img_00010_p=par
; - Module: wfa_00013
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/Propagation'
print,wfa_gui(      13)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Propagation/wfa_00012.sav'
wfa_00013_p=par
; - Module: img_00009
img_00009_c=0
img_00009_t=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/Propagation'
print,img_gui(       9)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Propagation/img_00009.sav'
img_00009_p=par
; - Module: stf_00019
stf_00019_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/Propagation'
print,stf_gui(      19)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Propagation/stf_00019.sav'
stf_00019_p=par
; - Module: dis_00014
dis_00014_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/Propagation'
print,dis_gui(      14)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Propagation/dis_00014.sav'
dis_00014_p=par
; - Module: dis_00016
dis_00016_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/Propagation'
print,dis_gui(      16)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Propagation/dis_00016.sav'
dis_00016_p=par
; - Module: dis_00017
dis_00017_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/Propagation'
print,dis_gui(      17)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Propagation/dis_00017.sav'
dis_00017_p=par
; - Module: dis_00018
dis_00018_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/Propagation'
print,dis_gui(      18)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Propagation/dis_00018.sav'
dis_00018_p=par
; - Module: dis_00022
dis_00022_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/Propagation'
print,dis_gui(      22)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Propagation/dis_00022.sav'
dis_00022_p=par
; - Module: dis_00020
dis_00020_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/Propagation'
print,dis_gui(      20)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Propagation/dis_00020.sav'
dis_00020_p=par
; - Module: dis_00021
dis_00021_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/Propagation'
print,dis_gui(      21)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Propagation/dis_00021.sav'
dis_00021_p=par
; - Module: dis_00015
dis_00015_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/Propagation'
print,dis_gui(      15)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
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
if (n_params() eq 0) then begin
   ret=dialog_message("QUIT IDL Virtual Machine ?",/info)
endif else begin
;do nothing
endelse

;;;;;;;;;;;;;;;;;
; End Main      ;
;;;;;;;;;;;;;;;;;

END
