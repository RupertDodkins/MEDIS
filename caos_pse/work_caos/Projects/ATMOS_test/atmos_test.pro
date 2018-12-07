; --
; -- CAOS Application builder. Version 7.0
; --
; -- file:atmos_test.pro
; --
; -- Main procedure file for project: 
;  Projects/ATMOS_test
; -- Automatically generated on: Sun Mar  4 19:04:25 2018
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
 
PRO atmos_test, mode
COMMON caos_block, tot_iter, this_iter

if (n_params() eq 0) then begin
setenv, 'CAOS_ROOT=/Data/PythonProjects/MEDIS/caos_pse/'
setenv, 'CAOS_WORK=/Data/PythonProjects/MEDIS/caos_pse/work_caos/'
setenv, 'IDL_STARTUP=/Data/PythonProjects/MEDIS/caos_pse/work_caos/caos_startup.pro'
caos_init
endif else begin
;do nothing
endelse
filename = '/Data/PythonProjects/MEDIS/data/atmos/idl_params.csv'
print, 'Reading', filename
idl_params = READ_CSV(filename)
tot_iter = uint(idl_params.field1[0])
atmosfile = idl_params.field2+'telz'
show_caosparams = idl_params.field3
;if (n_params() eq 0) then begin
;   tot_iter=iter_gui(       1)
;endif else begin
;;do nothing
;endelse
this_iter = 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Load Parameter variables ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; - Module: atm_00001
atm_00001_c=0
if (n_params() eq 0) then begin
cd, '/Data/PythonProjects/MEDIS/caos_pse/work_caos/Projects/ATMOS_test'
if (show_caosparams eq 'True') then begin
   print,atm_gui(       1)
   endif else begin
;do nothing
endelse
cd, '/Data/PythonProjects/MEDIS/caos_pse/work_caos/'
endif
RESTORE, 'Projects/ATMOS_test/atm_00001.sav'
atm_00001_p=par
;print, atm_00001_p
;print, atm_00001_p.delta_t
; - Module: src_00002
src_00002_c=0
if (n_params() eq 0) then begin
cd, '/Data/PythonProjects/MEDIS/caos_pse/work_caos/Projects/ATMOS_test'
if (show_caosparams eq 'True') then begin
   print,src_gui(       2)
   endif else begin
;do nothing
endelse

cd, '/Data/PythonProjects/MEDIS/caos_pse/work_caos/'
endif
RESTORE, 'Projects/ATMOS_test/src_00002.sav'
src_00002_p=par
; - Module: gpr_00003
gpr_00003_c=0
if (n_params() eq 0) then begin
cd, '/Data/PythonProjects/MEDIS/caos_pse/work_caos/Projects/ATMOS_test'
if (show_caosparams eq 'True') then begin
   print,gpr_gui(       3)
   endif else begin
;do nothing
endelse

cd, '/Data/PythonProjects/MEDIS/caos_pse/work_caos/'
endif
RESTORE, 'Projects/ATMOS_test/gpr_00003.sav'
gpr_00003_p=par
;;;;;;;;;;;;;;;;;
; Initialization;
;;;;;;;;;;;;;;;;;

t0=systime(/SEC)
print, " "
print, "=== RUNNING INITIALIZATION... ==="
@Projects/ATMOS_test/mod_calls.pro
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
	@Projects/ATMOS_test/mod_calls.pro
        ;filename = '/Data/PythonProjects/MEDIS/caos_pse/work_caos/Projects/atmos/data/180207/telz'
        frame = STRING((this_iter-1)*atm_00001_p.delta_t, FORMAT='(F0)')
        ;print, size(O_003_00.screen)
        print, (this_iter-1)*atm_00001_p.delta_t
        MWRFITS, O_003_00.screen, atmosfile+frame+'.fits', /CREATE
ENDFOR							; End Main Loop
ts=systime(/SEC)-t0
print, " "
print, "=== CPU time for initialization phase    =", ti, " s."
print, "=== CPU time for simulation phase        =", ts, " s."
print, "    [=> CPU time/iteration=", strtrim(ts/tot_iter,2), "s.]"
print, "=== total CPU time (init.+simu. phases)  =", ti+ts, " s."
print, " "
;if (n_params() eq 0) then begin
;   ret=dialog_message("QUIT IDL Virtual Machine ?",/info)
;endif else begin
;;do nothing
;endelse

;;;;;;;;;;;;;;;;;
; End Main      ;
;;;;;;;;;;;;;;;;;

END
