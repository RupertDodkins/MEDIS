; --
; -- CAOS Application builder. Version 7.0
; --
; -- file:palomar2.pro
; --
; -- Main procedure file for project: 
;  Projects/Palomar2
; -- Automatically generated on: Wed Apr 19 22:36:50 2017
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
 
PRO palomar2, mode
COMMON caos_block, tot_iter, this_iter

if (n_params() eq 0) then begin
setenv, 'CAOS_ROOT=/home/kids/Downloads/caos_pse/'
setenv, 'CAOS_WORK=/home/kids/Downloads/caos_pse/work_caos/'
setenv, 'IDL_STARTUP=/home/kids/Downloads/caos_pse/work_caos/caos_startup.pro'
caos_init
endif else begin
;do nothing
endelse
tot_iter =           10
if (n_params() eq 0) then begin
   tot_iter=iter_gui(          10)
endif else begin
;do nothing
endelse
this_iter = 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Load Parameter variables ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; - Module: s*s_00009
; - Module: src_00002
src_00002_c=0
if (n_params() eq 0) then begin
cd, '/home/kids/Downloads/caos_pse/work_caos/Projects/Palomar2'
print,src_gui(       2)
cd, '/home/kids/Downloads/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Palomar2/src_00002.sav'
src_00002_p=par
; - Module: atm_00016
atm_00016_c=0
if (n_params() eq 0) then begin
cd, '/home/kids/Downloads/caos_pse/work_caos/Projects/Palomar2'
print,atm_gui(      16)
cd, '/home/kids/Downloads/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Palomar2/atm_00016.sav'
atm_00016_p=par
; - Module: gpr_00003
gpr_00003_c=0
if (n_params() eq 0) then begin
cd, '/home/kids/Downloads/caos_pse/work_caos/Projects/Palomar2'
print,gpr_gui(       3)
cd, '/home/kids/Downloads/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Palomar2/gpr_00003.sav'
gpr_00003_p=par
; - Module: dmi_00004
dmi_00004_c=0
dmi_00004_t=0
if (n_params() eq 0) then begin
cd, '/home/kids/Downloads/caos_pse/work_caos/Projects/Palomar2'
print,dmi_gui(       4)
cd, '/home/kids/Downloads/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Palomar2/dmi_00004.sav'
dmi_00004_p=par
; - Module: img_00018
img_00018_c=0
img_00018_t=0
if (n_params() eq 0) then begin
cd, '/home/kids/Downloads/caos_pse/work_caos/Projects/Palomar2'
print,img_gui(      18)
cd, '/home/kids/Downloads/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Palomar2/img_00018.sav'
img_00018_p=par
; - Module: img_00010
img_00010_c=0
img_00010_t=0
if (n_params() eq 0) then begin
cd, '/home/kids/Downloads/caos_pse/work_caos/Projects/Palomar2'
print,img_gui(      10)
cd, '/home/kids/Downloads/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Palomar2/img_00010.sav'
img_00010_p=par
; - Module: sws_00005
sws_00005_c=0
sws_00005_t=0
if (n_params() eq 0) then begin
cd, '/home/kids/Downloads/caos_pse/work_caos/Projects/Palomar2'
print,sws_gui(       5)
cd, '/home/kids/Downloads/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Palomar2/sws_00005.sav'
sws_00005_p=par
; - Module: cor_00015
cor_00015_c=0
if (n_params() eq 0) then begin
cd, '/home/kids/Downloads/caos_pse/work_caos/Projects/Palomar2'
print,cor_gui(      15)
cd, '/home/kids/Downloads/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Palomar2/cor_00015.sav'
cor_00015_p=par
; - Module: bqc_00006
bqc_00006_c=0
if (n_params() eq 0) then begin
cd, '/home/kids/Downloads/caos_pse/work_caos/Projects/Palomar2'
print,bqc_gui(       6)
cd, '/home/kids/Downloads/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Palomar2/bqc_00006.sav'
bqc_00006_p=par
; - Module: rec_00007
rec_00007_c=0
if (n_params() eq 0) then begin
cd, '/home/kids/Downloads/caos_pse/work_caos/Projects/Palomar2'
print,rec_gui(       7)
cd, '/home/kids/Downloads/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Palomar2/rec_00007.sav'
rec_00007_p=par
; - Module: dis_00013
dis_00013_c=0
if (n_params() eq 0) then begin
cd, '/home/kids/Downloads/caos_pse/work_caos/Projects/Palomar2'
print,dis_gui(      13)
cd, '/home/kids/Downloads/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Palomar2/dis_00013.sav'
dis_00013_p=par
; - Module: dis_00012
dis_00012_c=0
if (n_params() eq 0) then begin
cd, '/home/kids/Downloads/caos_pse/work_caos/Projects/Palomar2'
print,dis_gui(      12)
cd, '/home/kids/Downloads/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Palomar2/dis_00012.sav'
dis_00012_p=par
; - Module: tfl_00008
tfl_00008_c=0
if (n_params() eq 0) then begin
cd, '/home/kids/Downloads/caos_pse/work_caos/Projects/Palomar2'
print,tfl_gui(       8)
cd, '/home/kids/Downloads/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Palomar2/tfl_00008.sav'
tfl_00008_p=par
; - Module: dis_00019
dis_00019_c=0
if (n_params() eq 0) then begin
cd, '/home/kids/Downloads/caos_pse/work_caos/Projects/Palomar2'
print,dis_gui(      19)
cd, '/home/kids/Downloads/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Palomar2/dis_00019.sav'
dis_00019_p=par

;;;;;;;;;;;;;;;;;
; Initialization;
;;;;;;;;;;;;;;;;;

t0=systime(/SEC)
print, " "
print, "=== RUNNING INITIALIZATION... ==="
@Projects/Palomar2/mod_calls.pro
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
	@Projects/Palomar2/mod_calls.pro
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
