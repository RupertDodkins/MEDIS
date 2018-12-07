; --
; -- CAOS Project. CAOS Problem-Solving Environment. Version 7.0
; --
; -- file: mod_calls.pro
; --
; -- Module procedures sequence file for project: 
;  PSSimulation
; -- Automatically generated on: Mon Apr 17 21:24:35 2017
; --

; -- This procedure is invoked at each step of the module sequence loop.
; -- (including preliminary initialization)
; -- 

COMMON caos_block, tot_iter, this_iter
;------------------------------------------------------ Loop is closed Here
IF N_ELEMENTS(O_009_00) GT 0 THEN O_010_00 = O_009_00
;------------------------------------------------------

ret = src(O_002_00,		$
          src_00002_p,              $
          INIT=src_00002_c)
IF ret NE 0 THEN ProjectMsg, "src"

ret = atm(O_001_00,		$
          atm_00001_p,              $
          INIT=atm_00001_c)
IF ret NE 0 THEN ProjectMsg, "atm"

ret = gpr(O_002_00,		$
          O_001_00,		$
          O_003_00,		$
          gpr_00003_p,              $
          INIT=gpr_00003_c)
IF ret NE 0 THEN ProjectMsg, "gpr"

ret = dmi(O_003_00,		$
          O_010_00,		$
          O_004_00,		$
          O_004_01,		$
          dmi_00004_p,              $
          INIT=dmi_00004_c,	$
          TIME=dmi_00004_t)
IF ret NE 0 THEN ProjectMsg, "dmi"

ret = pyr(O_004_01,		$
          O_005_00,		$
          O_005_01,		$
          pyr_00005_p,              $
          INIT=pyr_00005_c,	$
          TIME=pyr_00005_t)
IF ret NE 0 THEN ProjectMsg, "pyr"

ret = slo(O_005_00,		$
          O_006_00,		$
          slo_00006_p,              $
          INIT=slo_00006_c)
IF ret NE 0 THEN ProjectMsg, "slo"

ret = rec(O_006_00,		$
          O_007_00,		$
          rec_00007_p,              $
          INIT=rec_00007_c)
IF ret NE 0 THEN ProjectMsg, "rec"

ret = dis(O_005_00,		$
          dis_00018_p,              $
          INIT=dis_00018_c)
IF ret NE 0 THEN ProjectMsg, "dis"

ret = dis(O_006_00,		$
          dis_00016_p,              $
          INIT=dis_00016_c)
IF ret NE 0 THEN ProjectMsg, "dis"

ret = dis(O_005_01,		$
          dis_00015_p,              $
          INIT=dis_00015_c)
IF ret NE 0 THEN ProjectMsg, "dis"

ret = dis(O_003_00,		$
          dis_00014_p,              $
          INIT=dis_00014_c)
IF ret NE 0 THEN ProjectMsg, "dis"

ret = dis(O_004_01,		$
          dis_00013_p,              $
          INIT=dis_00013_c)
IF ret NE 0 THEN ProjectMsg, "dis"

ret = tfl(O_007_00,		$
          O_009_00,		$
          tfl_00009_p,              $
          INIT=tfl_00009_c)
IF ret NE 0 THEN ProjectMsg, "tfl"

