; --
; -- CAOS Project. CAOS Problem-Solving Environment. Version 7.0
; --
; -- file: mod_calls.pro
; --
; -- Module procedures sequence file for project: 
;  GLAO_Example
; -- Automatically generated on: Sun Jun 19 18:55:31 2016
; --

; -- This procedure is invoked at each step of the module sequence loop.
; -- (including preliminary initialization)
; -- 

COMMON caos_block, tot_iter, this_iter
ret = atm(O_001_00,		$
          atm_00001_p,              $
          INIT=atm_00001_c)
IF ret NE 0 THEN ProjectMsg, "atm"

;------------------------------------------------------ Loop is closed Here
IF N_ELEMENTS(O_036_00) GT 0 THEN O_037_00 = O_036_00
;------------------------------------------------------

ret = src(O_015_00,		$
          src_00015_p,              $
          INIT=src_00015_c)
IF ret NE 0 THEN ProjectMsg, "src"

ret = src(O_014_00,		$
          src_00014_p,              $
          INIT=src_00014_c)
IF ret NE 0 THEN ProjectMsg, "src"

ret = src(O_013_00,		$
          src_00013_p,              $
          INIT=src_00013_c)
IF ret NE 0 THEN ProjectMsg, "src"

ret = src(O_003_00,		$
          src_00003_p,              $
          INIT=src_00003_c)
IF ret NE 0 THEN ProjectMsg, "src"

ret = gpr(O_015_00,		$
          O_001_00,		$
          O_008_00,		$
          gpr_00008_p,              $
          INIT=gpr_00008_c)
IF ret NE 0 THEN ProjectMsg, "gpr"

ret = dmc(O_001_00,		$
          O_037_00,		$
          O_002_00,		$
          O_002_01,		$
          dmc_00002_p,              $
          INIT=dmc_00002_c,	$
          TIME=dmc_00002_t)
IF ret NE 0 THEN ProjectMsg, "dmc"

ret = gpr(O_013_00,		$
          O_002_01,		$
          O_005_00,		$
          gpr_00005_p,              $
          INIT=gpr_00005_c)
IF ret NE 0 THEN ProjectMsg, "gpr"

ret = gpr(O_015_00,		$
          O_002_01,		$
          O_007_00,		$
          gpr_00007_p,              $
          INIT=gpr_00007_c)
IF ret NE 0 THEN ProjectMsg, "gpr"

ret = gpr(O_014_00,		$
          O_002_01,		$
          O_006_00,		$
          gpr_00006_p,              $
          INIT=gpr_00006_c)
IF ret NE 0 THEN ProjectMsg, "gpr"

ret = gpr(O_003_00,		$
          O_002_01,		$
          O_004_00,		$
          gpr_00004_p,              $
          INIT=gpr_00004_c)
IF ret NE 0 THEN ProjectMsg, "gpr"

ret = img(O_008_00,		$
          O_074_00,		$
          O_074_01,		$
          img_00074_p,              $
          INIT=img_00074_c,	$
          TIME=img_00074_t)
IF ret NE 0 THEN ProjectMsg, "img"

ret = img(O_007_00,		$
          O_040_00,		$
          O_040_01,		$
          img_00040_p,              $
          INIT=img_00040_c,	$
          TIME=img_00040_t)
IF ret NE 0 THEN ProjectMsg, "img"

ret = sws(O_004_00,		$
          O_022_00,		$
          sws_00022_p,              $
          INIT=sws_00022_c,	$
          TIME=sws_00022_t)
IF ret NE 0 THEN ProjectMsg, "sws"

ret = sws(O_005_00,		$
          O_023_00,		$
          sws_00023_p,              $
          INIT=sws_00023_c,	$
          TIME=sws_00023_t)
IF ret NE 0 THEN ProjectMsg, "sws"

ret = sws(O_006_00,		$
          O_024_00,		$
          sws_00024_p,              $
          INIT=sws_00024_c,	$
          TIME=sws_00024_t)
IF ret NE 0 THEN ProjectMsg, "sws"

ret = bqc(O_024_00,		$
          O_027_00,		$
          bqc_00027_p,              $
          INIT=bqc_00027_c)
IF ret NE 0 THEN ProjectMsg, "bqc"

ret = bqc(O_022_00,		$
          O_025_00,		$
          bqc_00025_p,              $
          INIT=bqc_00025_c)
IF ret NE 0 THEN ProjectMsg, "bqc"

ret = bqc(O_023_00,		$
          O_026_00,		$
          bqc_00026_p,              $
          INIT=bqc_00026_c)
IF ret NE 0 THEN ProjectMsg, "bqc"

ret = com(O_026_00,		$
          O_025_00,		$
          O_028_00,		$
          com_00028_p)
IF ret NE 0 THEN ProjectMsg, "com"

ret = com(O_027_00,		$
          O_028_00,		$
          O_033_00,		$
          com_00033_p)
IF ret NE 0 THEN ProjectMsg, "com"

ret = ave(O_033_00,		$
          O_032_00,		$
          ave_00032_p)
IF ret NE 0 THEN ProjectMsg, "ave"

ret = rec(O_032_00,		$
          O_035_00,		$
          rec_00035_p,              $
          INIT=rec_00035_c)
IF ret NE 0 THEN ProjectMsg, "rec"

ret = dis(O_008_00,		$
          dis_00082_p,              $
          INIT=dis_00082_c)
IF ret NE 0 THEN ProjectMsg, "dis"

ret = dis(O_007_00,		$
          dis_00068_p,              $
          INIT=dis_00068_c)
IF ret NE 0 THEN ProjectMsg, "dis"

ret = dis(O_074_01,		$
          dis_00075_p,              $
          INIT=dis_00075_c)
IF ret NE 0 THEN ProjectMsg, "dis"

ret = tfl(O_035_00,		$
          O_036_00,		$
          tfl_00036_p,              $
          INIT=tfl_00036_c)
IF ret NE 0 THEN ProjectMsg, "tfl"

ret = dis(O_040_01,		$
          dis_00039_p,              $
          INIT=dis_00039_c)
IF ret NE 0 THEN ProjectMsg, "dis"

