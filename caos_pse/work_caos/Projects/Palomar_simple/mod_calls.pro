; --
; -- CAOS Project. CAOS Problem-Solving Environment. Version 7.0
; --
; -- file: mod_calls.pro
; --
; -- Module procedures sequence file for project: 
;  Palomar_simple
; -- Automatically generated on: Wed Sep  6 17:23:59 2017
; --

; -- This procedure is invoked at each step of the module sequence loop.
; -- (including preliminary initialization)
; -- 

COMMON caos_block, tot_iter, this_iter
;------------------------------------------------------ Loop is closed Here
IF N_ELEMENTS(O_008_00) GT 0 THEN O_009_00 = O_008_00
;------------------------------------------------------

ret = src(O_002_00,		$
          src_00002_p,              $
          INIT=src_00002_c)
IF ret NE 0 THEN ProjectMsg, "src"

ret = atm(O_016_00,		$
          atm_00016_p,              $
          INIT=atm_00016_c)
IF ret NE 0 THEN ProjectMsg, "atm"

ret = gpr(O_002_00,		$
          O_016_00,		$
          O_003_00,		$
          gpr_00003_p,              $
          INIT=gpr_00003_c)
IF ret NE 0 THEN ProjectMsg, "gpr"

; added by Rupert D
;sem_stat_ab = MRDFITS('/Data/PythonProjects/MEDIS/caos_pse/work_caos/Projects/Palomar_simple/telz3.fits')

;print, size(sem_stat_ab), sem_stat_ab[0,0]
;o_003_00.screen = o_003_00.screen + sem_stat_ab
print, 'GPR output', o_003_00.screen[0:10]
; ---------------

ret = dmi(O_003_00,		$
          O_009_00,		$
          O_004_00,		$
          O_004_01,		$
          dmi_00004_p,              $
          INIT=dmi_00004_c,	$
          TIME=dmi_00004_t)
IF ret NE 0 THEN ProjectMsg, "dmi"

ret = sws(O_004_01,		$
          O_005_00,		$
          sws_00005_p,              $
          INIT=sws_00005_c,	$
          TIME=sws_00005_t)
IF ret NE 0 THEN ProjectMsg, "sws"

ret = img(O_004_01,		$
          O_010_00,		$
          O_010_01,		$
          img_00010_p,              $
          INIT=img_00010_c,	$
          TIME=img_00010_t)
IF ret NE 0 THEN ProjectMsg, "img"

ret = cor(O_004_01,		$
          O_015_00,		$
          cor_00015_p,              $
          INIT=cor_00015_c)
IF ret NE 0 THEN ProjectMsg, "cor"

ret = bqc(O_005_00,		$
          O_006_00,		$
          bqc_00006_p,              $
          INIT=bqc_00006_c)
IF ret NE 0 THEN ProjectMsg, "bqc"

ret = rec(O_006_00,		$
          O_007_00,		$
          rec_00007_p,              $
          INIT=rec_00007_c)
IF ret NE 0 THEN ProjectMsg, "rec"

ret = dis(O_010_01,		$
          dis_00012_p,              $
          INIT=dis_00012_c)
IF ret NE 0 THEN ProjectMsg, "dis"

ret = tfl(O_007_00,		$
          O_008_00,		$
          tfl_00008_p,              $
          INIT=tfl_00008_c)
IF ret NE 0 THEN ProjectMsg, "tfl"

ret = dis(O_015_00,		$
          dis_00022_p,              $
          INIT=dis_00022_c)
IF ret NE 0 THEN ProjectMsg, "dis"
