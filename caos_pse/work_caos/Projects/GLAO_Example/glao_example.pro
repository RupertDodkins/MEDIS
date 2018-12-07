; --
; -- CAOS Application builder. Version 7.0
; --
; -- file:glao_example.pro
; --
; -- Main procedure file for project: 
;  Projects/GLAO_Example
; -- Automatically generated on: Sun Jun 19 18:55:31 2016
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
 
PRO glao_example, mode
COMMON caos_block, tot_iter, this_iter

if (n_params() eq 0) then begin
setenv, 'CAOS_ROOT=/Users/marcel/Simul/caos_pse/'
setenv, 'CAOS_WORK=/Users/marcel/Simul/caos_pse/work_caos/'
setenv, 'IDL_STARTUP=/Users/marcel/Simul/caos_pse/work_caos/caos_startup.pro'
caos_init
endif else begin
;do nothing
endelse
tot_iter =          200
if (n_params() eq 0) then begin
   tot_iter=iter_gui(         200)
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
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/GLAO_Example'
print,atm_gui(       1)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/GLAO_Example/atm_00001.sav'
atm_00001_p=par
; - Module: s*s_00037
; - Module: src_00015
src_00015_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/GLAO_Example'
print,src_gui(      15)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/GLAO_Example/src_00015.sav'
src_00015_p=par
; - Module: src_00014
src_00014_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/GLAO_Example'
print,src_gui(      14)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/GLAO_Example/src_00014.sav'
src_00014_p=par
; - Module: src_00013
src_00013_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/GLAO_Example'
print,src_gui(      13)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/GLAO_Example/src_00013.sav'
src_00013_p=par
; - Module: src_00003
src_00003_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/GLAO_Example'
print,src_gui(       3)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/GLAO_Example/src_00003.sav'
src_00003_p=par
; - Module: gpr_00008
gpr_00008_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/GLAO_Example'
print,gpr_gui(       8)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/GLAO_Example/gpr_00004.sav'
gpr_00008_p=par
; - Module: dmc_00002
dmc_00002_c=0
dmc_00002_t=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/GLAO_Example'
print,dmc_gui(       2)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/GLAO_Example/dmc_00002.sav'
dmc_00002_p=par
; - Module: gpr_00005
gpr_00005_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/GLAO_Example'
print,gpr_gui(       5)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/GLAO_Example/gpr_00004.sav'
gpr_00005_p=par
; - Module: gpr_00007
gpr_00007_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/GLAO_Example'
print,gpr_gui(       7)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/GLAO_Example/gpr_00004.sav'
gpr_00007_p=par
; - Module: gpr_00006
gpr_00006_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/GLAO_Example'
print,gpr_gui(       6)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/GLAO_Example/gpr_00004.sav'
gpr_00006_p=par
; - Module: gpr_00004
gpr_00004_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/GLAO_Example'
print,gpr_gui(       4)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/GLAO_Example/gpr_00004.sav'
gpr_00004_p=par
; - Module: img_00074
img_00074_c=0
img_00074_t=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/GLAO_Example'
print,img_gui(      74)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/GLAO_Example/img_00040.sav'
img_00074_p=par
; - Module: img_00040
img_00040_c=0
img_00040_t=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/GLAO_Example'
print,img_gui(      40)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/GLAO_Example/img_00040.sav'
img_00040_p=par
; - Module: sws_00022
sws_00022_c=0
sws_00022_t=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/GLAO_Example'
print,sws_gui(      22)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/GLAO_Example/sws_00022.sav'
sws_00022_p=par
; - Module: sws_00023
sws_00023_c=0
sws_00023_t=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/GLAO_Example'
print,sws_gui(      23)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/GLAO_Example/sws_00022.sav'
sws_00023_p=par
; - Module: sws_00024
sws_00024_c=0
sws_00024_t=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/GLAO_Example'
print,sws_gui(      24)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/GLAO_Example/sws_00022.sav'
sws_00024_p=par
; - Module: bqc_00027
bqc_00027_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/GLAO_Example'
print,bqc_gui(      27)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/GLAO_Example/bqc_00025.sav'
bqc_00027_p=par
; - Module: bqc_00025
bqc_00025_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/GLAO_Example'
print,bqc_gui(      25)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/GLAO_Example/bqc_00025.sav'
bqc_00025_p=par
; - Module: bqc_00026
bqc_00026_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/GLAO_Example'
print,bqc_gui(      26)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/GLAO_Example/bqc_00025.sav'
bqc_00026_p=par
; - Module: com_00028
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/GLAO_Example'
print,com_gui(      28)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/GLAO_Example/com_00028.sav'
com_00028_p=par
; - Module: com_00033
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/GLAO_Example'
print,com_gui(      33)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/GLAO_Example/com_00033.sav'
com_00033_p=par
; - Module: ave_00032
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/GLAO_Example'
print,ave_gui(      32)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/GLAO_Example/ave_00032.sav'
ave_00032_p=par
; - Module: rec_00035
rec_00035_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/GLAO_Example'
print,rec_gui(      35)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/GLAO_Example/rec_00035.sav'
rec_00035_p=par
; - Module: dis_00082
dis_00082_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/GLAO_Example'
print,dis_gui(      82)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/GLAO_Example/dis_00082.sav'
dis_00082_p=par
; - Module: dis_00068
dis_00068_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/GLAO_Example'
print,dis_gui(      68)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/GLAO_Example/dis_00068.sav'
dis_00068_p=par
; - Module: dis_00075
dis_00075_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/GLAO_Example'
print,dis_gui(      75)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/GLAO_Example/dis_00075.sav'
dis_00075_p=par
; - Module: tfl_00036
tfl_00036_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/GLAO_Example'
print,tfl_gui(      36)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/GLAO_Example/tfl_00036.sav'
tfl_00036_p=par
; - Module: dis_00039
dis_00039_c=0
if (n_params() eq 0) then begin
cd, '/Users/marcel/Simul/caos_pse/work_caos/Projects/GLAO_Example'
print,dis_gui(      39)
cd, '/Users/marcel/Simul/caos_pse/work_caos/'
endif
RESTORE, 'Projects/GLAO_Example/dis_00039.sav'
dis_00039_p=par

;;;;;;;;;;;;;;;;;
; Initialization;
;;;;;;;;;;;;;;;;;

t0=systime(/SEC)
print, " "
print, "=== RUNNING INITIALIZATION... ==="
@Projects/GLAO_Example/mod_calls.pro
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
	@Projects/GLAO_Example/mod_calls.pro
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
