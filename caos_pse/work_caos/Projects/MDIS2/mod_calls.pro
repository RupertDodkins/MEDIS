; --
; -- CAOS Project. CAOS Problem-Solving Environment. Version 7.0
; --
; -- file: mod_calls.pro
; --
; -- Module procedures sequence file for project: 
;  MDIS2
; -- Automatically generated on: Mon Apr 17 22:06:33 2017
; --

; -- This procedure is invoked at each step of the module sequence loop.
; -- (including preliminary initialization)
; -- 

COMMON caos_block, tot_iter, this_iter
ret = atm(O_001_00,		$
          atm_00001_p,              $
          INIT=atm_00001_c)
IF ret NE 0 THEN ProjectMsg, "atm"

ret = src(O_002_00,		$
          src_00002_p,              $
          INIT=src_00002_c)
IF ret NE 0 THEN ProjectMsg, "src"

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

ret = cor(O_004_01,		$
          O_022_00,		$
          cor_00022_p,              $
          INIT=cor_00022_c)
IF ret NE 0 THEN ProjectMsg, "cor"

ret = sws(O_004_01,		$
          O_005_00,		$
          sws_00005_p,              $
          INIT=sws_00005_c,	$
          TIME=sws_00005_t)
IF ret NE 0 THEN ProjectMsg, "sws"

ret = img(O_004_01,		$
          O_016_00,		$
          O_016_01,		$
          img_00016_p,              $
          INIT=img_00016_c,	$
          TIME=img_00016_t)
IF ret NE 0 THEN ProjectMsg, "img"

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

ret = dis(O_022_00,		$
          dis_00023_p,              $
          INIT=dis_00023_c)
IF ret NE 0 THEN ProjectMsg, "dis"

ret = tfl(O_007_00,		$
          O_008_00,		$
          tfl_00008_p,              $
          INIT=tfl_00008_c)
IF ret NE 0 THEN ProjectMsg, "tfl"

ret = dis(O_016_01,		$
          dis_00017_p,              $
          INIT=dis_00017_c)
IF ret NE 0 THEN ProjectMsg, "dis"

