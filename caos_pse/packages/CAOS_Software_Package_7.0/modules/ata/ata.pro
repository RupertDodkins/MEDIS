; $Id: ata.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;       ata
;
; ROUTINE'S PURPOSE:
;       ATA manages the simulation for the ATmosphereAdding (ATA) module,
;       that is:
;       1-call the module's initialisation routine ata_init at the first
;         iteration of the simulation project
;       2-call the module's program routine ata_prog otherwise.
;
; MODULE'S PURPOSE:
;       ATA receives two "atmospheres" as inputs and returns their sum/difference
;       according to weights supplied by user. This module has been developed to
;       check performance of the software with MCAO.
;
; CATEGORY:
;       main module's routine
;
; CALLING SEQUENCE:
;       err = ata(inp_atm_t1, inp_atm_t2, out_atm_t, par)
;
; OUTPUT:
;       error     :long scalar (error code, see !caos_error var in caos_init.pro).
;
; INPUTS:
;       inp_atm_t1:incident atmosphere. (Bottom input in Application builder)
;
;       inp_stm_t2:incident atmosphere. (Top input in Application builder)
;
;       par       :parameters structure from ata_gui. In addition to the usual
;                  tags associated with the overall management of the program,
;                  it contains the following tags:
;
;                  par.wb: assigned weight (+1 or -1) to first input (in
;                          AppBuilder, bottom box!!)
;                  par.wt: assigned weight (+1 or -1) to second input (in
;                          AppBuilder, top box!!)
;
; INCLUDED OUTPUTS:
;       out_atm_t :output atmosphere with intensity arbitrarily normalized to 1.
;
; KEYWORD PARAMETERS:
;       None.      
;
; COMMON BLOCKS:
;       common caos_block, tot_iter, this_iter
;
;       tot_iter   : total number of iteration during the simulation run.
;       this_iter  : current iteration number.
;
; SIDE EFFECTS:
;       None.
;
; RESTRICTIONS:
;       This module does not consider the effect on the intensity as it is not
;       intended to simulate interferometry. It's been developed only to allow
;       easy and fast visualization of MCAO when closing the loop.
;
; CALLED NON-IDL FUNCTIONS:
;       none.
;
; ROUTINE MODIFICATION HISTORY:
;       program written: March 2001,
;                        B. Femenia   (OAA) [bfemenia@arcetri.astro.it].
;       modifications  : january 2003,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -use of variable "calibration" eliminited for version 4.0
;                        of the whole Software System CAOS.
;                      : april 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;
; MODULE MODIFICATION HISTORY:
;       module written : B. Femenia   (OAA) [bfemenia@arcetri.astro.it].
;       modifications  : for version 4.0,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -no more use of the common variable "calibration" and
;                        the tag "calib" (structure "info") for version 4.0 of
;                        the whole Software System CAOS.
;                      : for version 7.0,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted.
;-
;
FUNCTION ata, inp_atm_t1, $ ; input structure 
              inp_atm_t2, $ ; input structure
              out_atm_t , $ ; output structure
              par       , $ ; parameters from ata_gui
              INIT= init    ; INIT structures


COMMON caos_block, tot_iter, this_iter

error = !caos_error.ok                                ; Init error code: no error as default


IF (this_iter EQ 0) THEN BEGIN                              ; INITIALIZATION 
                                                            ;===============
   error = ata_init(inp_atm_t1,inp_atm_t2, out_atm_t, par, $
                    INIT=init)

ENDIF ELSE BEGIN                                            ; NORMAL RUNNING: ATA does not consider
                                                            ;===============  integration nor delay
   error = ata_prog(inp_atm_t1,inp_atm_t2, out_atm_t, par, $
                    INIT=init)

ENDELSE 

RETURN, error
END