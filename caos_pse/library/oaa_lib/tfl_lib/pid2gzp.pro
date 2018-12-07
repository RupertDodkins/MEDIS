; $Id: pid2gzp.pro,v 1.4 2003/06/10 18:29:24 riccardi Exp $

;+
; PID2GZP
;
; convert a filter parametrized as a PID into a gain-zero-pole
;
;
;          1         A                  (s+z[0])*...*(s+z[nz-1])
; kp + ki*--- + kd*-----*s  ==>  gain * ------------------------
;          s       (s+A)                (s+p[0])*...*(p+z[np-1])
;
; pid2gzp, kp, ki, kd, A, gain, z, p, N_ZEROS=nz, N_POLES=np
;
; For a tipical PID:   A >> kp/kd >> ki/kp
;
; MODIFICATON HISTORY
;
;    Written by: A. Riccardi, Osservatorio Astrofisico di Arcetri, ITALY
;                riccardi@arcetri.astro.it
;-

pro pid2gzp, kp, ki, kd, A, gain, z, p, N_ZEROS=nz, N_POLES=np

if test_type(kp, /REAL, n_el=n) then $
  message, 'The proportional coeff (kp) must be real'
if n ne 1 then $
  message, 'The proportional coeff (kp) must be a scalar'

if test_type(ki, /REAL, n_el=n) then $
  message, 'The integrator coeff (ki) must be real'
if n ne 1 then $
  message, 'The integrator coeff (ki) must be a scalar'

if test_type(kd, /REAL, n_el=n) then $
  message, 'The derivative coeff (kd) must be real'
if n ne 1 then $
  message, 'The derivative coeff (kd) must be a scalar'

if test_type(A, /REAL, n_el=n) then $
  message, 'The low-pass freq. (A) must be real'
if n ne 1 then $
  message, 'The low-pass freq. (A) must be a scalar'
if A le 0.0 and kd ne 0.0 then $
  message, 'The low-pass freq. (A) must be strictly positive'

type = (size((A*kp*ki*kd)[0]))[1]
eps = (machar(DOUBLE=type eq 5)).eps
if type eq 5 then c_one = complex(1.0) else c_one = dcomplex(1.0)


if ki eq 0.0 then begin
    ;; ki eq 0.0
    if kd eq 0.0 then begin
        ;;ki eq 0.0 and kd eq 0.0
        gain = kp
        if n_elements(z) gt 0 then dummy = temporary(z)
        if n_elements(p) gt 0 then dummy = temporary(p)
        nz = 0
        np = 0
    endif else begin
        ;; ki eq 0.0 and kd ne 0.0
        if kp eq 0.0 then begin
            ;; ki eq 0.0 and kd ne 0.0 and kp eq 0.0
            gain = kd*A
            z = [0.0]
            p = [A]
            nz = 1
            np = 1
        endif else begin
            ;; ki eq 0.0 and kd ne 0.0 and kp ne 0.0
            gain = kp + kd * A
            z = [A / (1.0 + kd*A/kp)]
            p = [A]
            nz = 1
            np = 1
        endelse
    endelse
endif else begin
    ;; ki ne 0.0
    if kd eq 0.0 then begin
        ;; ki ne 0.0 and kd eq 0.0
        if kp eq 0.0 then begin
            ;; ki ne 0.0 and kd eq 0.0 and kp eq 0.0
            gain = ki
            if n_elements(z) gt 0 then dummy = temporary(z)
            p = [0.0]
            nz = 0
            np = 1
        endif else begin
            ;; ki ne 0.0 and kd eq 0.0 and kp ne 0.0
            gain = kp
            z = [ki/kp]
            p = [0.0]
            nz = 1
            np = 1
        endelse
    endif else begin
        ;; ki ne 0.0 and kd ne 0.0 and any kp
        gain = kp + kd*A
        dummy = kp + kd*A
        c = ki*A/dummy
        b = (kp*A + ki)/dummy
        delta = b^2 - 4.0*c
        if delta lt 0.0 then delta = complex(1.0,0.0)*delta
        ;; the zero def. in signal processing is opposite in sign
        ;; with respect to the usual algebric definition of zeros of
        ;; a polynomial. That's way the minus sign in the following:
        z = -0.5*(-b+[1, -1]*sqrt(delta))
        p = [0.0, A]
        nz = 2
        np = 2
    endelse
endelse
        
end

