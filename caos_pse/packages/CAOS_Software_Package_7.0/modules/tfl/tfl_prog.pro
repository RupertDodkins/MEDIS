; $Id: tfl_prog.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;       tfl_prog
;
; PURPOSE:
;       tfl_prog represents the scientific algorithm for the
;       Time FiLtering (TFL) module.
;
; CATEGORY:
;       scientific program
;
; CALLING SEQUENCE:
;       error = tfl_prog(          $
;                       inp_com_t, $ ; com_t input structure
;                       out_com_t, $ ; com_t output structure
;                       par,       $ ; parameters structure
;                       INIT=init  $ ; initialisation structure
;                       ) 
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.:
;       see module help for a detailed description. 
;
; MODIFICATION HISTORY:
;       program witten: March 1999, A. Riccardi (OAA),
;                       [riccardi@arcetri.astro.it].
;        modifications: June 1999, v.1.0.1, A. Riccardi:
;                      -Stable implementation of the modal filtering.
;                     : October 1999, Francoise Delpkancke:
;                      -adapted to new REC version.
;                     : Nov 1999,
;                      B. Femenia (OAA) [bfemenia@arcetri.astro.it]
;                      -adapted to new version CAOS (v 2.0).
;                     : may 2016,
;                       Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                      -adapted to Soft. Pack. CAOS 7.0.
;-
;
function tfl_prog, inp_com_t, $
                   out_com_t, $
                   par,       $
                   INIT=init

; initialization of the error code: no error as default
error = !caos_error.ok

; string vector of output types
out_type = str_sep((tfl_info()).out_type, ',')

ds1 = inp_com_t.data_status

;; the input is not optional
if ds1 eq !caos_data.not_valid then begin
    message, 'Unexpected input data status: "not_valid".', $
      CONT = (not !CAOS_DEBUG)
    return, !CAOS_ERROR.unexpected
endif

if ds1 eq !caos_data.wait then begin
    out_com_t.data_status = !caos_data.wait
    return, error
end

if ds1 eq !caos_data.valid then begin
    ;; filter the input commands
    
    nc = n_elements(inp_com_t.command)
    if nc ne init.n_comm then begin
        message, "Unexpected size of the command vector (" $
          + strtrim(nc,2) + " instead of " $
          + strtrim(init.n_comm,2) + ").", CONT = (not !CAOS_DEBUG)
        return, !CAOS_ERROR.unexpected
    endif
    
    ;; leaves space for the new input
    ;; command and writes it in the input
    ;; buffer
    case (size(init.buf_in))[0] of
    
        2L: begin
            ;; #coeff > 1 and #command > 1
            init.buf_in = shift(init.buf_in, 1, 0)
        end
        
        1L: begin
            ;; #coeff > 1 and #command = 1
            init.buf_in = shift(init.buf_in, 1)
        end
        
        else: begin
            ;; scalar: #coeff = 1 and #command = 1
            ;; leave unchanged
        end
    endcase
    init.buf_in[0,*] = inp_com_t.command
    
    ;; computes the filtered command
    command = total(init.in_coeff*init.buf_in, 1)
    if init.use_old_out then $
      command = command - total(init.out_coeff*init.buf_out, 1)
    
    ;; store the new output in the output buffer
    if init.use_old_out then begin
        case (size(init.buf_out))[0] of
            
            2L: begin
                ;; array: #coeff >= 1 and #command >= 1
                init.buf_out = shift(init.buf_out, 1, 0)
            end
            
            1L: begin
                ;; vector: #coeff >= 1 (and #command = 1)
                init.buf_out = shift(init.buf_out, 1)
            end
            
            else: begin
                ;; scalar: (#coeff = 1 and #command = 1)
                ;; leave unchanged
            end
        endcase
    endif
    ;; store the output even if init.use_old_out=0B
    ;; it is not used at the moment, but could be used for future
    ;; implementations
    init.buf_out[0,*] = command
    
    ;; checks in the case modal commands are passed
    if init.flag eq 1 then begin
        out_command = init.pass_mat ## temporary(command)
        out_flag    = 0         ; actuator commands
    endif else begin
        ;; actuator command (flag=0) or wf command (flag=-1) are passed to
        ;; tfl.
        out_command = temporary(command)
        out_flag    = inp_com_t.flag
    endelse

    ;; fill the output structure
    if n_elements(out_command) ne n_elements(out_com_t.command) then begin
        message, "Unexpectd number of elements in the output command vector", $
          CONT = (not !CAOS_DEBUG)
        return, !CAOS_ERROR.unexpected
    endif
;;;    out_com_t.command[*] = init.sign * temporary(out_command)
    out_com_t.command = init.sign * temporary(out_command)
    out_com_t.flag = out_flag

    out_com_t.data_status = !caos_data.valid
    
    return, error
endif

;; this is the case in which the 1st input does not match
;; any defined data status
message, 'The inp_com_t input has an unexpected data status.', /CONT
error = !CAOS_ERROR.unexpected

return, error
end
