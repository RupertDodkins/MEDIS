; --
; -- CAOS Application builder. Version 7.0
; --
; -- file:palomar_simple.pro
; --
; -- Main procedure file for project: 
;  Projects/Palomar_simple
; -- Automatically generated on: Wed Sep  6 16:37:41 2017
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
 
PRO palomar_simple, mode
COMMON caos_block, tot_iter, this_iter

if (n_params() eq 0) then begin
setenv, 'CAOS_ROOT=/Data/PythonProjects/MEDIS/caos_pse/'
setenv, 'CAOS_WORK=/Data/PythonProjects/MEDIS/caos_pse/work_caos/'
setenv, 'IDL_STARTUP=/Data/PythonProjects/MEDIS/caos_pse/work_caos/caos_startup.pro'
caos_init
endif else begin
;do nothing
endelse
tot_iter =            5
if (n_params() eq 0) then begin
   tot_iter=iter_gui(           5)
endif else begin
;do nothing
endelse
this_iter = 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Load Parameter variables ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; - Module: s*s_00009
; - Module: atm_00016
atm_00016_c=0
if (n_params() eq 0) then begin
cd, '/Data/PythonProjects/MEDIS/caos_pse/work_caos/Projects/Palomar_simple'
;print,atm_gui(      16)
cd, '/Data/PythonProjects/MEDIS/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Palomar_simple/atm_00016.sav'
atm_00016_p=par
; - Module: src_00002
src_00002_c=0
if (n_params() eq 0) then begin
cd, '/Data/PythonProjects/MEDIS/caos_pse/work_caos/Projects/Palomar_simple'
;print,src_gui(       2)
cd, '/Data/PythonProjects/MEDIS/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Palomar_simple/src_00002.sav'
src_00002_p=par
; - Module: gpr_00003
gpr_00003_c=0
if (n_params() eq 0) then begin
cd, '/Data/PythonProjects/MEDIS/caos_pse/work_caos/Projects/Palomar_simple'
;print,gpr_gui(       3)
cd, '/Data/PythonProjects/MEDIS/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Palomar_simple/gpr_00003.sav'
gpr_00003_p=par
; - Module: dmi_00004
dmi_00004_c=0
dmi_00004_t=0
if (n_params() eq 0) then begin
cd, '/Data/PythonProjects/MEDIS/caos_pse/work_caos/Projects/Palomar_simple'
;print,dmi_gui(       4)
cd, '/Data/PythonProjects/MEDIS/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Palomar_simple/dmi_00004.sav'
dmi_00004_p=par
; - Module: img_00010
img_00010_c=0
img_00010_t=0
if (n_params() eq 0) then begin
cd, '/Data/PythonProjects/MEDIS/caos_pse/work_caos/Projects/Palomar_simple'
;print,img_gui(      10)
cd, '/Data/PythonProjects/MEDIS/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Palomar_simple/img_00010.sav'
img_00010_p=par
; - Module: cor_00015
cor_00015_c=0
if (n_params() eq 0) then begin
cd, '/Data/PythonProjects/MEDIS/caos_pse/work_caos/Projects/Palomar_simple'
;print,cor_gui(      15)
cd, '/Data/PythonProjects/MEDIS/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Palomar_simple/cor_00015.sav'
cor_00015_p=par
; - Module: sws_00005
sws_00005_c=0
sws_00005_t=0
if (n_params() eq 0) then begin
cd, '/Data/PythonProjects/MEDIS/caos_pse/work_caos/Projects/Palomar_simple'
;print,sws_gui(       5)
cd, '/Data/PythonProjects/MEDIS/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Palomar_simple/sws_00005.sav'
sws_00005_p=par
; - Module: bqc_00006
bqc_00006_c=0
if (n_params() eq 0) then begin
cd, '/Data/PythonProjects/MEDIS/caos_pse/work_caos/Projects/Palomar_simple'
;print,bqc_gui(       6)
cd, '/Data/PythonProjects/MEDIS/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Palomar_simple/bqc_00006.sav'
bqc_00006_p=par
; - Module: rec_00007
rec_00007_c=0
if (n_params() eq 0) then begin
cd, '/Data/PythonProjects/MEDIS/caos_pse/work_caos/Projects/Palomar_simple'
;print,rec_gui(       7)
cd, '/Data/PythonProjects/MEDIS/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Palomar_simple/rec_00007.sav'
rec_00007_p=par
; - Module: dis_00022
dis_00022_c=0
if (n_params() eq 0) then begin
cd, '/Data/PythonProjects/MEDIS/caos_pse/work_caos/Projects/Palomar_simple'
;print,dis_gui(      22)
cd, '/Data/PythonProjects/MEDIS/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Palomar_simple/dis_00012.sav'
dis_00022_p=par
; - Module: tfl_00008
tfl_00008_c=0
if (n_params() eq 0) then begin
cd, '/Data/PythonProjects/MEDIS/caos_pse/work_caos/Projects/Palomar_simple'
;print,tfl_gui(       8)
cd, '/Data/PythonProjects/MEDIS/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Palomar_simple/tfl_00008.sav'
tfl_00008_p=par
; - Module: dis_00012
dis_00012_c=0
if (n_params() eq 0) then begin
cd, '/Data/PythonProjects/MEDIS/caos_pse/work_caos/Projects/Palomar_simple'
;print,dis_gui(      12)
cd, '/Data/PythonProjects/MEDIS/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Palomar_simple/dis_00012.sav'
dis_00012_p=par
; - Module: wft_00019
if (n_params() eq 0) then begin
cd, '/Data/PythonProjects/MEDIS/caos_pse/work_caos/Projects/Palomar_simple'
;print,wft_gui(      19)
cd, '/Data/PythonProjects/MEDIS/caos_pse/work_caos/'
endif
RESTORE, 'Projects/Palomar_simple/wft_00019.sav'
wft_00019_p=par

;;;;;;;;;;;;;;;;;
; Initialization;
;;;;;;;;;;;;;;;;;

t0=systime(/SEC)
print, " "
print, "=== RUNNING INITIALIZATION... ==="
@Projects/Palomar_simple/mod_calls.pro
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
  ;print, 'GPR', o_003_00.screen[0:10]
	@Projects/Palomar_simple/mod_calls.pro
        print, 'new DMI', o_003_00.screen[0:10]
        print, 'hereeeeee'; added by Rupert D
        ;print, o_015_00.image[0:10]
        ;fname = 'cor'+strtrim(this_iter)+'.fits'
        ;print, fname
        ;MWRFITS, o_015_00.image, fname
        MWRFITS, o_003_00.screen, '/Data/PythonProjects/MEDIS/caos_pse/work_caos/Projects/Palomar_simple/telz'+strtrim(this_iter)+'.fits'
;help, dis_00022, /st
;MWRFITS, dis_00022.image, 'pdf'+strtrim(this_iter)+'.fits'

; ---------------
     ENDFOR                     ; End Main Loop
ts=systime(/SEC)-t0
print, " "
print, "=== CPU time for initialization phase    =", ti, " s."
print, "=== CPU time for simulation phase        =", ts, " s."
print, "    [=> CPU time/iteration=", strtrim(ts/tot_iter,2), "s.]"
print, "=== total CPU time (init.+simu. phases)  =", ti+ts, " s."
print, " "
;print, 'GPR', o_003_00.screen[0:10]

if (n_params() eq 0) then begin
   ret=dialog_message("QUIT IDL Virtual Machine ?",/info)
endif else begin
;do nothing
endelse


;;;;;;;;;;;;;;;;;
; End Main      ;
;;;;;;;;;;;;;;;;;

END
