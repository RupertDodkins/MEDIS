; $Id: dmi_prog.pro,v 7.0 2016/04/29 marcel.carbillet $
;+
; NAME:
;    dmi_prog
;
; PURPOSE:
;    dmi_prog represents the program routine for the Deformable MIrror (DMI)
;    module.
;    (see dmi.pro's header --or file caos_help.html-- for details about the
;    module itself).
;
; CATEGORY:
;    module's program routine
;
; CALLING SEQUENCE:
;    error = dmi_prog(inp_wfp_t, $
;                     inp_com_t, $
;                     out_wfp_c, $
;                     out_wfp_t, $
;                     par,       $
;                     INIT=init)
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.:
;    see module help for a detailed description.
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: october 1998
;                     Francoise Delplancke (ESO) [fdelplan@eso.org].
;    modifications  : february 1999,
;                     Francoise Delplancke (ESO) [fdelplan@eso.org]:
;                    -adapted to the new templates.
;                   : october 1999,
;                     Elise     Viard      (ESO) [eviard@eso.org],
;                     Francoise Delplancke (ESO) [fdelplan@eso.org]:
;                    -the gain (V to micron) factor is transferred to
;                     the influence function generator (more physical).
;                   : december 1999--january 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -debugged, enhanced, and adapted to version 2.0 (CAOS).
;                   : september 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -wait status problem fixed.
;                   : june 2001,
;                     Marcel     Carbillet (OAA) [marcel@arcetri.astro.it],
;                     Christophe Verinaud  (OAA) [verinaud@arcetri.astro.it]:
;                    -delay stuff debugged...
;                   : february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -correction commands are (finally!!) considered as negative
;                     (no more need of TFL for setting it before DMI).
;                    -now generalized to any kind of mirror deformations
;                     (not only PZT influence functions).
;                    -no more use of the common variable "calibration".
;                   : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
FUNCTION dmi_prog, inp_wfp_t, $
                   inp_com_t, $
                   out_wfp_c, $
                   out_wfp_t, $
                   par,       $
                   INIT=init

; CAOS global common block
common caos_block, tot_iter, this_iter

; initialization of the error code
error = !caos_error.ok

; retrieve the output information
info = dmi_info()

;
ds1 = inp_com_t.data_status
ds2 = inp_wfp_t.data_status

if ds2 eq !caos_data.not_valid then $
   message, 'the input wavefront structure cannot be not_valid.'

if ds2 eq !caos_data.wait then $
   message, 'the input wavefront structure cannot be wait.'

if ds2 eq !caos_data.valid then begin

   case 1B of

   (ds1 eq !caos_data.not_valid): begin
      out_wfp_c = inp_wfp_t
      out_wfp_c.screen = out_wfp_c.screen * 0.
      out_wfp_c.data_status = !caos_data.valid
      out_wfp_t = inp_wfp_t
      out_wfp_t.data_status = !caos_data.valid
      return, error
   end

   (ds1 eq !caos_data.wait): begin
      out_wfp_c.data_status = !caos_data.wait
      out_wfp_t.screen      = inp_wfp_t.screen + out_wfp_c.screen
      out_wfp_t.data_status = !caos_data.valid
      return, error
   end

   ds1 eq !caos_data.valid: begin

      ; initialize output wf 
      out_wfp_c.screen = 0.
      ndef = min([init.nm, (size(inp_com_t.command))[1]])
      for i=0,ndef-1 do begin
         out_wfp_c.screen = temporary(out_wfp_c.screen)               $
                          + (inp_com_t.command[i]*init.mirdef[*,*,i]) $
                          < (par.stroke*1E-6) > (-par.stroke*1E-6)
         ; the mirror shape is the sum of the commands
         ; multiplied by the respective influence functions.
         ; (as long as they are lower than the maximum stroke).
      endfor

      out_wfp_c.screen = -temporary(out_wfp_c.screen)
      out_wfp_c.data_status = !caos_data.valid

      out_wfp_t.screen = inp_wfp_t.screen + out_wfp_c.screen
      out_wfp_t.data_status = !caos_data.valid

      return, error

   end

   else: begin
      message, 'the input command structure has an invalid data status'
   end

   endcase

endif

message, 'the input wavefront structure has an invalid data status'

return, error
end