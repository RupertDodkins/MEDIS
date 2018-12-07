; $Id: dmc.pro,v 7.0 2016/04/29 marcel.carbillet $
;+
; NAME:
;    dmc
;
; ROUTINE'S PURPOSE:
;    dmc manages the simulation for the Deformable Mirror Conjugated
;    (DMC) module, that is:
;       1-call the module's initialisation routine dmc_init at the first
;         iteration of the simulation project,
;       2-call the module's program routine dmc_prog otherwise, managing
;         at the same time the possible time integration/delay.
;
; MODULE'S PURPOSE:
;    This module takes commands from one input and an incident wavefront
;    from another input, computes the correcting mirror shape (corresponding
;    to the commands: first output) AND the corrected wavefront (incident
;    wavefront + correcting mirror shape: second output) -- in terms of
;    atmosphere layer, including so a conjugation altitude.
;
;    The inputs are then a COM_T structure and a ATM_T structure. If the COM_T
;    structure is undefined (first loop) both the outputs corresponds to a flat
;    mirror.
;
;    The outputs are two ATM_T structures, containing the correcting mirror
;    shape in one hand (1st output), and the corrected wavefront to be analyzed
;    by a wavefront sensor in the other hand.
;
;    During the simulation the DMC module uses the commands coming from the
;    reconstructor, computes the corresponding mirror shape, subtract it from
;    the incident wavefront and outputs the correcting mirror shape as well as
;    the corrected wavefront.
;
; CATEGORY:
;    main module's routine
;
; CALLING SEQUENCE:
;    error = dmc(inp_atm_t, $ ; input atmosphere to be corrected
;                inp_com_t, $ ; input commands for the correction
;                out_atm_c, $ ; output correcting mirror shape
;                             ; (computed from the commands)
;                out_atm_t, $ ; output corrected atmosphere
;                             ; (i.e. inp_atm_t + out_atm_c)
;                par,       $ ; parameters structure
;                INIT=init, $ ; initialisation data structure
;                TIME=time  ) ; time integration/delay management structure
;
; INPUTS:
;    inp_atm_t: structure of type atm_t.
;               This is the incident wavefront on the mirror.
;    inp_com_t: structure of type com_t.
;               These are the commands sent to the mirror.
;
; INCLUDED OUTPUTS:
;    out_atm_c: structure of type atm_t.
;               This is the atmosphere corresponding to the input commands.
;               (the so-called correcting mirror shape)
;    out_atm_t: structure of type atm_t.
;               This is the reflected-corrected atmosphere.
;
; KEYWORD PARAMETERS:
;    INIT: initialisation data structure.
;    TIME: time managing structure
;
; OUTPUT:
;    error: error code [long scalar].
;
; COMMON BLOCKS:
;    common caos_block, tot_iter, this_iter
;
;    tot_iter   : total number of iteration during the simulation run.
;    this_iter  : current iteration number.
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
;    routine written: february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;
; MODULE MODIFICATION HISTORY:
;    module written : february/march 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : may 2014,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                     debugging of DMI about delay reproduced here below.
;                     (january 2005, Christophe Verinaud)
;                     (error in the shift of time.old_comm - was ok for a delay
;                     of 1 time unit but wrong if delay>1.)
;                   : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
function dmc, inp_atm_t, $      ; incident atmosphere
              inp_com_t, $      ; commands
              out_atm_c, $      ; correcting mirror shape        [BOTTOM BOX]
              out_atm_t, $      ; reflected-corrected atmosphere [TOP    BOX]
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
   error = dmc_init(inp_atm_t,inp_com_t,out_atm_c,out_atm_t,par,INIT=init)

endif else begin
   ; running section
   ;
   ; check over the validity of the commands
   if (inp_com_t.data_status ne !caos_data.not_valid) then begin
      IF (inp_com_t.flag NE 0) THEN BEGIN
         print, 'DMC ERROR:'
         print, ' The command input must be valid.'
         return, !caos_error.module_error
      ENDIF
   endif

   ; the no-time-delay case
   if (par.time_delay eq 0) then begin

      error = dmc_prog(inp_atm_t,inp_com_t,out_atm_c,out_atm_t,par,INIT=init)

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

      error = dmc_prog(inp_atm_t,inp_com_t,out_atm_c,out_atm_t,par,INIT=init)

   endelse

endelse
 
; back to calling program
return, error
end