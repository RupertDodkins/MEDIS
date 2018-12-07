; $Id: tfl_init.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;       tfl_init
;
; PURPOSE:
;       tfl_init executes the initialization for the Time FiLtering
;       (TFL) module
;       0- check the formal validity of the input/output structure
;       1- initialize the output structure(s) out_yyy_t and out_zzz_t
;
;       (see tfl.pro's header --or file caos_help.html-- for details
;        about the module itself).
;
; CATEGORY:
;       module's initialisation program
;
; CALLING SEQUENCE:
;       error = tfl_init(inp_com_t, $ ; com_t input structure
;                        out_com_t, $ ; com_t output structure
;                        par,       $ ; parameters structure
;                        INIT=init  $ ; initialisation structure
;                        )
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.:
;       see module help for a detailed description.
;
; MODIFICATION HISTORY:
;    program written: march 1999,
;                     Armando Riccardi (OAA) [riccardi@arcetri.astro.it].
;    modifications  : june 1999, v.1.0.1, Armando Riccardi:
;                    -stable implementation of the modal filtering.
;                   : october 1999, Francoise Delplancke [fdelplan@eso.org]
;                     and Elise Viard [eviard@eso.org] (ESO):
;                    -adapted to the new version (1.0.2) of module REC.
;                   : Dec 1999,
;                     B. Femenia   (OAA) [bfemenia@arcetri.astro.it]
;                    -adapted to new version CAOS (v 2.0).
;                   : january/february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -!caos_error.tfl.* variables eliminated for
;                     compliance with the CAOS Software System, version 4.0.
;                    -"mod_type"->"mod_name"
;                    -no more use of common variable "calibration".
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;-
;
function tfl_init, inp_com_t,  $
                   out_com_t, $
                   par,      $
                   INIT=init

; CAOS global common block
;-------------------------
COMMON caos_block, tot_iter, this_iter

;================
; STANDARD CHECKS
;================

error = !caos_error.ok       ; initialization of the error code: no error as default
info  = tfl_info()           ; Retrieve the Input & Output info.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Compute and test the requested number of tfl arguments
n_par = 1                       ; the parameter structure is always
                                ; present within the arguments

if info.inp_type ne '' then begin
   inp_type = str_sep(info.inp_type,",")
   n_inp    = n_elements(inp_type)
endif else n_inp = 0

if info.out_type ne '' then begin
   out_type = str_sep(info.out_type,",")
   n_out    = n_elements(out_type)
endif else n_out = 0

n_par = n_par + n_inp + n_out

; test the number of passed parameters
if n_params() ne n_par then message, 'wrong number of parameters'

;; test the parameter structure
;; par can be a vector for this module.
if test_type(par, /STRUCTURE) then $
  message, 'TFL: par must be a structure'
if strlowcase(tag_names(par[0], /STRUCTURE_NAME)) ne info.mod_name then $
   message, 'par must be a parameter structure for the module TFL'

if n_inp gt 0 then begin
    ;; test if any optional input exists
    inp_opt = info.inp_opt
endif
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; test the input arguments
;;
dummy = test_type(inp_com_t, TYPE=type)
if type eq 0 then begin         ; undefined variable
   ;; Patch until the worksheet will initialize the
   ;; linked-to-nothing input to a structure as the
   ;; following:
   inp_com_t = $
      {        $
      data_type  : inp_type[0],        $
      data_status: !caos_data.not_valid $
      }
   ;; In future releases the allowed input will be only
   ;; structures.
endif

if test_type(inp_com_t, /STRUC, N_EL=n, TYPE=type) then $
   message, 'inp_com_t: wrong input definition.'

if n ne 1 then message, 'inp_com_t cannot be a vector of structures'

;; test the data type
if inp_com_t.data_type ne inp_type[0] then                $
   message, 'wrong input data type: '+inp_com_t.data_type $
           +' ('+inp_type[0]+' expected).'

if inp_com_t.data_status eq !caos_data.not_valid and not inp_opt[0] then $
      message, 'undefined input is not allowed'
;;
;; End input tests
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; retrieve the input and output information

if info.out_type ne '' then begin
    out_type = str_sep(info.out_type,",")
    n_out    = n_elements(out_type)
endif else n_out = 0

;; test that the number of degree of freedom to be filtered matches
;; the number of elements of par (if n_elements(par) ne 1)
n_par = n_elements(par)
n_dof = n_elements(inp_com_t.command)
;; if n_par eq 1 then the same filter is applied for all the d.o.f.
if (n_par ne 1) and (n_par ne n_dof) then begin
    message, "The no. of degree of freedom to filter (" $
      + strtrim(n_dof) + ") must be the same as the filters (" $
      + strtrim(n_par) + ").", CONT = (not !caos_debug)
    return, !caos_error.module_error
endif

;; All the elements of the par vector must have the same
;; value for the tag negative_fb
if total(par.negative_fb ne par[0].negative_fb) gt 0 then begin
    message, "All the filters associated to each degree of freedom " $
      + 'must have the same value for the "negative feedback" tag', $
      CONT = (not !caos_debug)
    return, !caos_error.module_error
end

;; computes the digital filter from the GZP parametrization
;; of the analog filter model

max_n_coeff = par[0].max_n_coeff

in_coeff = dblarr(max_n_coeff, n_par)
out_coeff= dblarr(max_n_coeff, n_par)

max_n_in_coeff  = 0 ;; max number of recursive filter coeffs for inp. data
max_n_out_coeff = 0 ;; max number of recursive filter coeffs for out. data

for k=0,n_par-1 do begin
    n_s_zero = par[k].n_s_zero
    n_s_pole = par[k].n_s_pole

    if n_s_zero eq 0 then begin
        s_num = [par[k].s_const]
    endif else begin
        s_num = par[k].s_const*zero2coeff(par[k].s_zero[0:n_s_zero-1])
    endelse

    if n_s_pole eq 0 then begin
        s_den = [1d0]
    endif else begin
        s_den = zero2coeff(par[k].s_pole[0:n_s_pole-1])
    endelse


    ;; NORMALIZATION: sampling time T=1
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    s_num = s_num * (2d0*!DPI)^(n_s_zero-n_s_pole)
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ;; test for real coefficients
    if not test_type(s_num, /COMPLEX, /DCOMPLEX, TYPE=tp) then begin
        if total(imaginary(s_num) ne 0.0) ne 0 then begin
            message, "Unexpected complex coeffs for the digital filter", $
              CONT = (not !CAOS_DEBUG)
            return, !CAOS_ERROR.unexpected
        endif else begin
            if tp eq 6 then s_num = float(s_num) else s_num = double(s_num)
        endelse
    endif

    if not test_type(s_den, /COMPLEX, /DCOMPLEX, TYPE=tp) then begin
        if total(imaginary(s_den) ne 0.0) ne 0 then begin
            message, "Unexpected complex coeffs for the digital filter", $
              CONT = (not !CAOS_DEBUG)
            return, !CAOS_ERROR.unexpected
        endif else begin
            if tp eq 6 then s_den = float(s_den) else s_den = double(s_den)
        endelse

    endif


    ;; s/w_samp = 1/Pi*(1-z^-1)/(1+z^-1) : tustin (bilinear) transform
    tustin, s_num, s_den, 0.5d0/!DPI, z_num, z_den

    n_z_num = n_elements(z_num)
    n_z_den = n_elements(z_den)

    max_n_in_coeff  = max([max_n_in_coeff, n_z_num])
    max_n_out_coeff = max([max_n_out_coeff, n_z_den-1])

    z0 = z_den[0]               ; It must be ne 0.0 for a causal filter
    if z0 ne 1d0 then begin     ; normalize the coeffs if needed
        z_den = z_den/z0
        z_num = z_num/z0
    endif

    in_coeff[0,k] = z_num       ; insert z_num vector in k-th row of in_coeff
    if n_z_den gt 1 then begin  ; coeffs for the old outputs
        out_coeff[0,k] = z_den[1:n_z_den-1]
    endif

endfor

use_old_out = max_n_out_coeff gt 0
;; eliminate the common zeros on the trail of coeff vectors
in_coeff =  in_coeff[0:max_n_in_coeff-1, *]
if use_old_out then begin
    out_coeff = out_coeff[0:max_n_out_coeff-1, *]
endif else begin
    out_coeff = out_coeff[0]    ; dummy out_coeff
endelse

if (n_par eq 1) and (n_dof ne 1) then begin
    ;; replicate the same filter for all the d.o.f.
    in_coeff = rebin(in_coeff, max_n_in_coeff, n_dof)
    if use_old_out then begin
        out_coeff = rebin(out_coeff, max_n_out_coeff, n_dof)
    endif
endif

;; time history buffer allocation
if par[0].double then begin
    buf_in  = dblarr(n_z_num, n_dof)       ;; input data buffer
    buf_out = dblarr((n_z_den-1)>1, n_dof) ;; output data buffer
endif else begin
    buf_in = fltarr(n_z_num, n_dof)
    buf_out = fltarr((n_z_den-1)>1, n_dof)
    in_coeff = float(in_coeff)
    out_coeff = float(out_coeff)
endelse

if par[0].negative_fb then sign = -1.0 else sign = 1.0

;; checks in the case modal commands are passed
if inp_com_t.flag eq 1 then begin
    ;; modal command are passed to tfl; the output of tfl will be
    ;; actuator commands (flag=0)
    if test_type(inp_com_t.mod2com, /REAL, DIM=dim) then begin
        message, "The mode->actuator matrix must be real", $
          CONT=(not !CAOS_DEBUG)
        return, !CAOS_ERROR.unexpected
    endif
    if dim[0] ne 2 then begin
        message, "The mode->actuator matrix must be a 2D array", $
          CONT=(not !CAOS_DEBUG)
        return, !CAOS_ERROR.unexpected
    endif
    if (dim[1] ne n_elements(inp_com_t.command)) then BEGIN
       stop
        message, "The mode->actuator matrix does't match the # of modes", $
          CONT = (not !CAOS_DEBUG)
        return, !CAOS_ERROR.unexpected
    endif
    the_pass_mat = (inp_com_t.mod2com)
endif else begin
    the_pass_mat = 0B
endelse

;; definition of the initialization
;; structure

init = { $
         flag       : inp_com_t.flag,     $ ; 0=act. 1=mode commands (-1=wf)
         pass_mat   : the_pass_mat,       $ ; mode -> command matrix
         buf_in     : buf_in,             $ ; buffer of the input command
         buf_out    : buf_out,            $ ; buffer of the output command
         in_coeff   : in_coeff,           $ ; coeff matrix for the input
         out_coeff  : out_coeff,          $ ; coeff matrix for the output
         use_old_out: use_old_out,        $ ; 1B if old output data are needed
         n_comm     : n_dof,              $ ; number of d.o.f to time filter
         sign       : sign                $ ; sign of the feedback (+/-1)
       }


;; checks in the case modal commands are passed
if init.flag eq 1 then begin
    out_command = init.pass_mat ## inp_com_t.command
    out_flag    = 0             ; actuator commands
endif else begin
    ;; actuator command (flag=0) or wf command (flag=-1) are passed to
    ;; tfl.
    out_command = inp_com_t.command
    out_flag    = inp_com_t.flag
endelse

;; the output structures
out_com_t = $
  {         $
    data_type  : out_type[0],       $
    data_status: !caos_data.valid,   $
    command    : out_command,       $ ; filtered command vector
    flag       : out_flag,          $ ; -1=wf, 0=act. commands, 1=mode coeff.
    mod2com    : inp_com_t.mod2com, $ ; mode->act. command matrix
    mode_idx   : 0                  $ ; index list of modes in command
  }

return, error
end