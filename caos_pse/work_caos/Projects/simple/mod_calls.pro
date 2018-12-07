; --
; -- CAOS Project. CAOS Problem-Solving Environment. Version 7.0
; --
; -- file: mod_calls.pro
; --
; -- Module procedures sequence file for project: 
;  simple
; -- Automatically generated on: Mon Apr 17 20:53:24 2017
; --

; -- This procedure is invoked at each step of the module sequence loop.
; -- (including preliminary initialization)
; -- 

COMMON caos_block, tot_iter, this_iter
ret = src(O_006_00,		$
          src_00006_p,              $
          INIT=src_00006_c)
IF ret NE 0 THEN ProjectMsg, "src"

ret = atm(O_001_00,		$
          atm_00001_p,              $
          INIT=atm_00001_c)
IF ret NE 0 THEN ProjectMsg, "atm"

ret = src(O_002_00,		$
          src_00002_p,              $
          INIT=src_00002_c)
IF ret NE 0 THEN ProjectMsg, "src"

ret = gpr(O_006_00,		$
          O_001_00,		$
          O_007_00,		$
          gpr_00007_p,              $
          INIT=gpr_00007_c)
IF ret NE 0 THEN ProjectMsg, "gpr"

ret = gpr(O_002_00,		$
          O_001_00,		$
          O_003_00,		$
          gpr_00003_p,              $
          INIT=gpr_00003_c)
IF ret NE 0 THEN ProjectMsg, "gpr"

ret = wfa(O_007_00,		$
          O_003_00,		$
          O_011_00,		$
          wfa_00011_p)
IF ret NE 0 THEN ProjectMsg, "wfa"

ret = dis(O_011_00,		$
          dis_00010_p,              $
          INIT=dis_00010_c)
IF ret NE 0 THEN ProjectMsg, "dis"

ret = dis(O_007_00,		$
          dis_00009_p,              $
          INIT=dis_00009_c)
IF ret NE 0 THEN ProjectMsg, "dis"

ret = dis(O_003_00,		$
          dis_00004_p,              $
          INIT=dis_00004_c)
IF ret NE 0 THEN ProjectMsg, "dis"

