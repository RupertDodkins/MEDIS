; --
; -- CAOS Project. CAOS Problem-Solving Environment. Version 7.0
; --
; -- file: mod_calls.pro
; --
; -- Module procedures sequence file for project: 
;  SHSimulation
; -- Automatically generated on: Sun Jun 19 18:37:10 2016
; --

; -- This procedure is invoked at each step of the module sequence loop.
; -- (including preliminary initialization)
; -- 

COMMON caos_block, tot_iter, this_iter
ret = src(O_002_00,		$
          src_00002_p,              $
          INIT=src_00002_c)
IF ret NE 0 THEN ProjectMsg, "src"

ret = atm(O_001_00,		$
          atm_00001_p,              $
          INIT=atm_00001_c)
IF ret NE 0 THEN ProjectMsg, "atm"

;------------------------------------------------------ Loop is closed Here
IF N_ELEMENTS(O_008_00) GT 0 THEN O_009_00 = O_008_00
;------------------------------------------------------

ret = gpr(O_002_00,		$
          O_001_00,		$
          O_003_00,		$
          gpr_00003_p,              $
          INIT=gpr_00003_c)
IF ret NE 0 THEN ProjectMsg, "gpr"

ret = dmi(O_003_00,		$
          O_009_00,		$
          O_004_00,		$
          O_004_01,		$
          dmi_00004_p,              $
          INIT=dmi_00004_c,	$
          TIME=dmi_00004_t)
IF ret NE 0 THEN ProjectMsg, "dmi"

ret = img(O_004_01,		$
          O_016_00,		$
          O_016_01,		$
          img_00016_p,              $
          INIT=img_00016_c,	$
          TIME=img_00016_t)
IF ret NE 0 THEN ProjectMsg, "img"

ret = sws(O_004_01,		$
          O_005_00,		$
          sws_00005_p,              $
          INIT=sws_00005_c,	$
          TIME=sws_00005_t)
IF ret NE 0 THEN ProjectMsg, "sws"

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

ret = tfl(O_007_00,		$
          O_008_00,		$
          tfl_00008_p,              $
          INIT=tfl_00008_c)
IF ret NE 0 THEN ProjectMsg, "tfl"

ret = dis(O_004_00,		$
          dis_00015_p,              $
          INIT=dis_00015_c)
IF ret NE 0 THEN ProjectMsg, "dis"

ret = dis(O_006_00,		$
          dis_00014_p,              $
          INIT=dis_00014_c)
IF ret NE 0 THEN ProjectMsg, "dis"

ret = dis(O_005_00,		$
          dis_00013_p,              $
          INIT=dis_00013_c)
IF ret NE 0 THEN ProjectMsg, "dis"

ret = dis(O_004_01,		$
          dis_00012_p,              $
          INIT=dis_00012_c)
IF ret NE 0 THEN ProjectMsg, "dis"

ret = dis(O_003_00,		$
          dis_00011_p,              $
          INIT=dis_00011_c)
IF ret NE 0 THEN ProjectMsg, "dis"

ret = dis(O_016_01,		$
          dis_00017_p,              $
          INIT=dis_00017_c)
IF ret NE 0 THEN ProjectMsg, "dis"

