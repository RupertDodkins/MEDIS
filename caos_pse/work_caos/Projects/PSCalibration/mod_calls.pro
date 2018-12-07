; --
; -- CAOS Project. CAOS Problem-Solving Environment. Version 7.0
; --
; -- file: mod_calls.pro
; --
; -- Module procedures sequence file for project: 
;  PSCalibration
; -- Automatically generated on: Tue Jun 21 12:14:55 2016
; --

; -- This procedure is invoked at each step of the module sequence loop.
; -- (including preliminary initialization)
; -- 

COMMON caos_block, tot_iter, this_iter
ret = src(O_002_00,		$
          src_00002_p,              $
          INIT=src_00002_c)
IF ret NE 0 THEN ProjectMsg, "src"

ret = mds(O_001_00,		$
          mds_00001_p,              $
          INIT=mds_00001_c)
IF ret NE 0 THEN ProjectMsg, "mds"

ret = gpr(O_002_00,		$
          O_001_00,		$
          O_003_00,		$
          gpr_00003_p,              $
          INIT=gpr_00003_c)
IF ret NE 0 THEN ProjectMsg, "gpr"

ret = pyr(O_003_00,		$
          O_004_00,		$
          O_004_01,		$
          pyr_00004_p,              $
          INIT=pyr_00004_c,	$
          TIME=pyr_00004_t)
IF ret NE 0 THEN ProjectMsg, "pyr"

ret = slo(O_004_00,		$
          O_005_00,		$
          slo_00005_p,              $
          INIT=slo_00005_c)
IF ret NE 0 THEN ProjectMsg, "slo"

ret = dis(O_004_00,		$
          dis_00010_p,              $
          INIT=dis_00010_c)
IF ret NE 0 THEN ProjectMsg, "dis"

ret = scd(O_005_00,		$
          O_001_00,		$
          scd_00006_p,              $
          INIT=scd_00006_c)
IF ret NE 0 THEN ProjectMsg, "scd"

ret = dis(O_005_00,		$
          dis_00007_p,              $
          INIT=dis_00007_c)
IF ret NE 0 THEN ProjectMsg, "dis"

ret = dis(O_003_00,		$
          dis_00008_p,              $
          INIT=dis_00008_c)
IF ret NE 0 THEN ProjectMsg, "dis"

ret = dis(O_004_01,		$
          dis_00009_p,              $
          INIT=dis_00009_c)
IF ret NE 0 THEN ProjectMsg, "dis"

