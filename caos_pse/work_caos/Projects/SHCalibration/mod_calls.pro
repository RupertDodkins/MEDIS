; --
; -- CAOS Project. CAOS Problem-Solving Environment. Version 7.0
; --
; -- file: mod_calls.pro
; --
; -- Module procedures sequence file for project: 
;  SHCalibration
; -- Automatically generated on: Sun Jun 19 18:16:50 2016
; --

; -- This procedure is invoked at each step of the module sequence loop.
; -- (including preliminary initialization)
; -- 

COMMON caos_block, tot_iter, this_iter
ret = mds(O_001_00,		$
          mds_00001_p,              $
          INIT=mds_00001_c)
IF ret NE 0 THEN ProjectMsg, "mds"

ret = src(O_002_00,		$
          src_00002_p,              $
          INIT=src_00002_c)
IF ret NE 0 THEN ProjectMsg, "src"

ret = gpr(O_002_00,		$
          O_001_00,		$
          O_003_00,		$
          gpr_00003_p,              $
          INIT=gpr_00003_c)
IF ret NE 0 THEN ProjectMsg, "gpr"

ret = sws(O_003_00,		$
          O_004_00,		$
          sws_00004_p,              $
          INIT=sws_00004_c,	$
          TIME=sws_00004_t)
IF ret NE 0 THEN ProjectMsg, "sws"

ret = bqc(O_004_00,		$
          O_005_00,		$
          bqc_00005_p,              $
          INIT=bqc_00005_c)
IF ret NE 0 THEN ProjectMsg, "bqc"

ret = scd(O_005_00,		$
          O_001_00,		$
          scd_00007_p,              $
          INIT=scd_00007_c)
IF ret NE 0 THEN ProjectMsg, "scd"

ret = dis(O_003_00,		$
          dis_00008_p,              $
          INIT=dis_00008_c)
IF ret NE 0 THEN ProjectMsg, "dis"

ret = dis(O_004_00,		$
          dis_00009_p,              $
          INIT=dis_00009_c)
IF ret NE 0 THEN ProjectMsg, "dis"

ret = dis(O_005_00,		$
          dis_00010_p,              $
          INIT=dis_00010_c)
IF ret NE 0 THEN ProjectMsg, "dis"

