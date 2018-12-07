; $Id: dmi.pro,v 7.0 2016/04/29 marcel.carbillet $
;+
; NAME:
;    dmi
;
; ROUTINE'S PURPOSE:
;    dmi manages the simulation for the Deformable MIrror (DMI) module,
;    that is:
;       1-call the module's initialisation routine dmi_init at the first
;         iteration of the simulation (or calibration) project,
;       2-call the module's program routine dmi_prog otherwise, managing
;         at the same time the possible time integration/delay.
;
; MODULE'S PURPOSE:
;    This module takes commands from one input and an incident wavefront
;    from another input, computes the correcting mirror shape (corresponding
;    to the commands: first output) AND the corrected wavefront (incident
;    wavefront + correcting mirror shape: second output).
;
;    The inputs are then a COM_T structure and a WFP_T structure. If the COM_T
;    structure is undefined (first loop) both the outputs correspond to a flat
;    mirror.
;
;    The outputs are two WFP_T structures, containing the correcting mirror
;    shape in one hand (1st output), and the corrected wavefront to be analyzed
;    by a wavefront sensor in the other hand.
;
;    During a "normal running" simulation (the interaction matrix is already
;    computed) the DMI module uses the commands coming from the reconstructor
;    computes the corresponding mirror shape, subtract it from the incident
;    wavefront and outputs the correcting mirror shape as well as  the
;    corrected wavefront.
;
;    The piston mode is always subtracted from the mirror shape.
;
; CATEGORY:
;    main module's routine
;
; CALLING SEQUENCE:
;    error = dmi(inp_wfp_t, $ ; input wavefront to be corrected
;                inp_com_t, $ ; input commands for the correction
;                out_wfp_c, $ ; output correcting mirror shape
;                             ; (computed from the commands)
;                out_wfp_t, $ ; output corrected wavefront
;                             ; (i.e. inp_wfp_t + out_wfp_c)
;                par,       $ ; parameters structure
;                INIT=init, $ ; initialisation data structure
;                TIME=time  ) ; time integration/delay management structure
;
; INPUTS:
;    inp_wfp_t: structure of type wfp_t.
;               This is the incident wavefront on the mirror.
;    inp_com_t: structure of type com_t.
;               These are the commands sent to the mirror.
;
; INCLUDED OUTPUTS:
;    out_wfp_c: structure of type wfp_t.
;               This is the wavefront corresponding to the input commands.
;               (the so-called correcting mirror shape)
;    out_wfp_t: structure of type wfp_t.
;               This is the reflected-corrected wavefront.
;
; KEYWORD PARAMETERS:
;    INIT: initialisation data structure.
;    TIME: time managing structure
;
; OUTPUT:
;    error: error code [long scalar].
;
; COMMON BLOCKS:
;    common caos_block, tot_iter, this_iter, calibration, signature
;
;    tot_iter   : total number of iteration during the simulation run.
;    this_iter  : current iteration number.
;    calibration: is it a calibration project ? (yes=1B, no=0B)
;
; SIDE EFFECTS:
;    none.
;
; RESTRICTIONS:
;    none.
;
; CALLED NON-IDL FUNCTIONS:
;    ...
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: december 1998,
;                     Francoise Delplancke (ESO) [fdelplan@eso.org].
;    modifications  : december 1999--january 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 2.0 (CAOS).
;                    -help updated.
;                   : january 2005,
;                     Christophe Verinaud (ESO) [cverinau@eso.org]:
;                    -delay debugged !!
;                     (error in the shift of time.old_comm - was ok for a delay
;                     of 1 time unit but wrong if delay>1).
;                   : january 2006,
;                     Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr]:
;                    -help corrected (was related to a very old version of DMI).
;
; MODULE MODIFICATION HISTORY:
;    module written : december 1998,
;                     Francoise Delplancke (ESO) [fdelplan@eso.org].
;    modifications  : december 1999--may 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -largely modified in order to fit with version 2.0 (CAOS)
;                     [the output out_mir_t is eliminated thanks to the
;                      off-line calibration new feature, and the correcting
;                      wavefront is added as an output (out_wfp_c) in order
;                      to do not artificially duplicate the DMI module when
;                      several sources are present].
;                   : january-march 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -!caos_error.dmi.* variables eliminated for
;                     compliance with the CAOS Software System, version 4.0.
;                    -no more use of any common variable except tot_iter
;                     and this_iter.
;                   : january 2005,
;                     Christophe Verinaud (ESO) [cverinau@eso.org]:
;                    -delay debugged !!
;                     (error in the shift of time.old_comm - was ok for a delay
;                     of 1 time unit but wrong if delay>1).
;                   : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
function dmi, inp_wfp_t, $      ; incident wavefront
              inp_com_t, $      ; commands
              out_wfp_c, $      ; correcting mirror shape       [BOTTOM BOX]
              out_wfp_t, $      ; reflected-corrected wavefront [TOP    BOX]
              par,       $      ; parameters structure
              INIT=init, $      ; initialization structure
              TIME=time         ; time managing structure

; CAOS global common block
common caos_block, tot_iter, this_iter

; initialization of the error code
error = !caos_error.ok

; module's actions
if (this_iter eq 0) then begin
   ; initialisation section
   ;
   error = dmi_init(inp_wfp_t,inp_com_t,out_wfp_c,out_wfp_t,par,INIT=init)

endif else begin
   ; running section
   ;
   ; check over the validity of the commands
   if (inp_com_t.data_status ne !caos_data.not_valid) then begin
      IF (inp_com_t.flag NE 0) THEN BEGIN
         ; if the command input is present but that they are not real actuator
         ; commands (but mode coefficients or wavefront), then send an error
         print, 'DMI ERROR:'
         print, ' The command input must be real actuator commands.'
         print, ' But you have configured the related input-linked module to'
         print, ' output either mode coefficients or wavefront amplitudes.'
         print, ' Please correct it.'
         return, !caos_error.module_error
      ENDIF
   endif

   ; the no-time-delay case
   if (par.time_delay eq 0) then begin

      error = dmi_prog(inp_wfp_t,inp_com_t,out_wfp_c,out_wfp_t,par,INIT=init)

   ; the time-delay case
   endif else begin

      if ((size(time))[0] eq 0) then $
         time = {old_comm: fltarr(init.nm, par.time_delay+1)}

      time.old_comm = shift(temporary(time.old_comm), 0, -1)

      time.old_comm[*, par.time_delay] = inp_com_t.command
      ; shifting the commands by a delay of 1 unit of time
      ; putting the current commands in the last column of old_comm

      inp_com_t.command = time.old_comm[*,0]
      ; taking the "old" commands at the right time

      error = dmi_prog(inp_wfp_t,inp_com_t,out_wfp_c,out_wfp_t,par,INIT=init)

   endelse

endelse
 
; back to calling program
return, error
end