; $Id: dmc_prog.pro,v 7.0 2016/04/29 marcel.carbillet@unice.fr $
;+
; NAME:
;    dmc_prog
;
; PURPOSE:
;    dmc_prog represents the program routine for the Deformable Mirror
;    Conjugated (DMC) module.
;    (see dmc.pro's header --or file caos_help.html-- for details about the
;    module itself).
;
; CATEGORY:
;    module's program routine
;
; CALLING SEQUENCE:
;    error = dmc_prog(inp_atm_t, $
;                     inp_com_t, $
;                     out_atm_c, $
;                     out_atm_t, $
;                     par,       $
;                     INIT=init)
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.:
;    see module help for a detailed description.
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
FUNCTION dmc_prog, inp_atm_t, $
                   inp_com_t, $
                   out_atm_c, $
                   out_atm_t, $
                   par,       $
                   INIT=init

; CAOS global common block
common caos_block, tot_iter, this_iter

; initialization of the error code
error = !caos_error.ok

; retrieve the output information
info = dmc_info()

;
ds1 = inp_com_t.data_status
ds2 = inp_atm_t.data_status

if ds2 eq !caos_data.not_valid then $
   message, 'the input atmosphere structure cannot be not_valid.'

if ds2 eq !caos_data.wait then $
   message, 'the input atmosphere structure cannot be wait.'

if ds2 eq !caos_data.valid then begin

   case 1B of

   (ds1 eq !caos_data.not_valid): begin
      out_atm_c = inp_atm_t
      out_atm_c.screen = out_atm_c.screen * 0.
      out_atm_c.data_status = !caos_data.valid
      out_atm_t = inp_atm_t
      out_atm_t.data_status = !caos_data.valid
      return, error
   end

   (ds1 eq !caos_data.wait): begin
      out_atm_c.data_status = !caos_data.wait
      out_atm_t.screen      = inp_atm_t.screen + out_atm_c.screen
      out_atm_t.data_status = !caos_data.valid
      return, error
   end

   ds1 eq !caos_data.valid: begin

      out_atm_c.screen = 0.
      ndef = min([init.nm, (size(inp_com_t.command))[1]])
      for i=0,ndef-1 do begin
         out_atm_c.screen = temporary(out_atm_c.screen)               $
                          + (inp_com_t.command[i]*init.mirdef[*,*,i]) $
                          < (par.stroke*1E-6) > (-par.stroke*1E-6)
         ; the mirror shape is the sum of the commands
         ; multiplied by the respective mirror deformations
         ; (as long as they are lower than the maximum stroke).
      endfor

      out_atm_c.screen = -temporary(out_atm_c.screen)
      out_atm_c.data_status = !caos_data.valid

      out_atm_t.screen[*,*,0:init.n_layers-1] = inp_atm_t.screen[*,*,*]
      out_atm_t.screen[*,*,init.n_layers:init.n_layers+init.n_dm-1] = $
         out_atm_c.screen[*,*,*]
      out_atm_t.data_status = !caos_data.valid

      return, error

   end

   else: begin
      message, 'the input command structure has an invalid data status'
   end

   endcase

endif

message, 'the input atmosphere structure has an invalid data status'

return, error
end