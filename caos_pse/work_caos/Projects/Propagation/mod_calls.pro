; --
; -- CAOS Project. CAOS Problem-Solving Environment. Version 7.0
; --
; -- file: mod_calls.pro
; --
; -- Module procedures sequence file for project: 
;  Propagation
; -- Automatically generated on: Sun Jun 19 18:04:53 2016
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

ret = src(O_005_00,		$
          src_00005_p,              $
          INIT=src_00005_c)
IF ret NE 0 THEN ProjectMsg, "src"

ret = src(O_004_00,		$
          src_00004_p,              $
          INIT=src_00004_c)
IF ret NE 0 THEN ProjectMsg, "src"

ret = gpr(O_004_00,		$
          O_001_00,		$
          O_007_00,		$
          gpr_00007_p,              $
          INIT=gpr_00007_c)
IF ret NE 0 THEN ProjectMsg, "gpr"

ret = gpr(O_005_00,		$
          O_001_00,		$
          O_008_00,		$
          gpr_00008_p,              $
          INIT=gpr_00008_c)
IF ret NE 0 THEN ProjectMsg, "gpr"

ret = gpr(O_002_00,		$
          O_001_00,		$
          O_003_00,		$
          gpr_00003_p,              $
          INIT=gpr_00003_c)
IF ret NE 0 THEN ProjectMsg, "gpr"

ret = wfa(O_007_00,		$
          O_003_00,		$
          O_012_00,		$
          wfa_00012_p)
IF ret NE 0 THEN ProjectMsg, "wfa"

ret = img(O_007_00,		$
          O_010_00,		$
          O_010_01,		$
          img_00010_p,              $
          INIT=img_00010_c,	$
          TIME=img_00010_t)
IF ret NE 0 THEN ProjectMsg, "img"

ret = wfa(O_008_00,		$
          O_003_00,		$
          O_013_00,		$
          wfa_00013_p)
IF ret NE 0 THEN ProjectMsg, "wfa"

ret = img(O_003_00,		$
          O_009_00,		$
          O_009_01,		$
          img_00009_p,              $
          INIT=img_00009_c,	$
          TIME=img_00009_t)
IF ret NE 0 THEN ProjectMsg, "img"

ret = stf(O_003_00,		$
          O_019_00,		$
          stf_00019_p,              $
          INIT=stf_00019_c)
IF ret NE 0 THEN ProjectMsg, "stf"

ret = dis(O_012_00,		$
          dis_00014_p,              $
          INIT=dis_00014_c)
IF ret NE 0 THEN ProjectMsg, "dis"

ret = dis(O_009_01,		$
          dis_00016_p,              $
          INIT=dis_00016_c)
IF ret NE 0 THEN ProjectMsg, "dis"

ret = dis(O_010_01,		$
          dis_00017_p,              $
          INIT=dis_00017_c)
IF ret NE 0 THEN ProjectMsg, "dis"

ret = dis(O_003_00,		$
          dis_00018_p,              $
          INIT=dis_00018_c)
IF ret NE 0 THEN ProjectMsg, "dis"

ret = dis(O_019_00,		$
          dis_00022_p,              $
          INIT=dis_00022_c)
IF ret NE 0 THEN ProjectMsg, "dis"

ret = dis(O_007_00,		$
          dis_00020_p,              $
          INIT=dis_00020_c)
IF ret NE 0 THEN ProjectMsg, "dis"

ret = dis(O_008_00,		$
          dis_00021_p,              $
          INIT=dis_00021_c)
IF ret NE 0 THEN ProjectMsg, "dis"

ret = dis(O_013_00,		$
          dis_00015_p,              $
          INIT=dis_00015_c)
IF ret NE 0 THEN ProjectMsg, "dis"

