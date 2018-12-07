; $Id: cfb.pro,v 7.0 2016/04/27 marcel.carbillet $
;+
; NAME:
;    cfb
;
; ROUTINE'S PURPOSE:
;    CFB manages the simulation for the Calibration FiBer (CFB) module,
;    that is:
;       1-call the module's initialisation routine cfb_init at the first
;         iteration of the project
;       2-call the module's program routine cfb_prog otherwise, managing
;         at the same time the possible time integration/delay.
;
; MODULE'S PURPOSE:
;    This module simulates the PLANE wavefront coming from a calibration fiber
;    together with the calibration source map (i.e. calibration fiber is an
;    extended object!!) to be used in special calibration projects for modules
;    needing such calibration. Unlike the MCA **special** module (see doc header
;    in mca.pro), the use of such module is not restricted to those special
;    projects. In fact, the user might also decide to calibrate TCE or REC by
;    feeding their **SPECIAL** calibration projects with "real" atmospheric
;    corrupted wavefronts obtained with the typical combination of SRC+ATM+GPR
;    modules which  can be helpful in some particular situations.
;    In summary, CBF produces a "PLANE" wavefront coming from an extended source
;    (with a Gaussian irradiance pattern) which is optically located at
;    infinity.
;
; CATEGORY:
;    main module's routine
;
; CALLING SEQUENCE:
;    error = cfb(out_wfp_t,   $ ; output structure
;                par          $ ; parameter structure
;               )
;
; OUTPUT:
;    error: long scalar (error code, see !caos_error var in caos_init.pro).
;
; INPUTS:
;    None
;
; INCLUDED OUTPUTS:
;    out_wfp_t: structure of type wfp_t containing the map describing the fiber
;               distribution of light together with a flat wavefront.
;
; KEYWORD PARAMETERS:
;    INIT : initialisation data structure.
;
; COMMON BLOCKS:
;    common caos_ao_block, tot_iter, this_iter
;
;    tot_iter   : total number of iteration during the simulation run.
;    this_iter  : current iteration number.
;
; SIDE EFFECTS:
;    none.
;
; RESTRICTIONS:
;    At this point only Gaussian irradiance patterns are considered.
;
; CALLED NON-IDL FUNCTIONS:
;    none.
;
; ROUTINE MODIFICATION HISTORY:
;    program written: Nov 1999,
;                     B. Femenia   (OAA) [bfemenia@arcetri.astro.it]
;
;    modifications  : May 2000,
;                     B. Femenia   (OAA) [bfemenia@arcetri.astro.it]
;                    -updating documentation in header.                 
;                   : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -use of variable "calibration" eliminited for version 4.0
;                     of the whole CAOS Software System.
;
; MODULE MODIFICATION HISTORY:
;    module written : B. Femenia   (OAA) [bfemenia@arcetri.astro.it]
;
;    modifications  : for version 4.0,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -no more use of the common variable "calibration" and
;                     the tag "calib" (structure "info") for version 4.0 of
;                     the whole CAOS Software System.
;                   : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
FUNCTION cfb, out_wfp_t,   $ ; Output structure of type wfp_t 
              par            ; CFB parameters structure

; CAOS global common block
COMMON caos_block, tot_iter, this_iter

error = !caos_error.ok                  ; Init error code: no error as default

IF (this_iter EQ 0) THEN BEGIN          ; INITIALIZATION 
                                        ;===============
   error = cfb_init(out_wfp_t, par)

ENDIF ;ELSE BEGIN                       ; NORMAL RUNNING: CFB does not consider
      ;                                 ;===============  integration nor delay
      ;error = cfb_prog(out_wfp_t, par)
      ;ENDELSE
   
;NOTE: Output from CFB module will not change, so only 1 iteration within
;====  CFB_INIT is required to build the OUTPUT. Such output will remain
;      unaltered during the whole calibration process so there is no need for a
;      call to CFB_PROG.

RETURN, error
END