; $Id: hold_on_tf.pro,v 1.4 2003/06/10 18:29:24 riccardi Exp $

;+
; 
; NAME
;
;   HOLD_ON_TF
;
;
;   tf = hold_on_tf(s, T)
;
; Return the (Laplace) Tranfer Function associated to the Hold-on
; (DAC) effect for a digital signal with period T.
; s vector of complex frequency [rad/s] (s = sigma + i*omega)
; T period [s]
;
;            1 - exp(-s*T)      sinh(s*T/2)
;   TF(s) = ---------------- = ----------- * T*exp(-s*T/2)
;                  s               s*T/2
;
; MODIFICATON HISTORY
;
;    Written by: A. Riccardi, Osservatorio Astrofisico di Arcetri, ITALY
;                riccardi@arcetri.astro.it
;-

function hold_on_tf, s, T

iu = complex(0.0, 1.0)
idx = where(s ne 0.0, count)

sT2 = s*T/2.0

tf = exp(-sT2) * T

if count ne 0 then begin
    tf[idx] = (0.5*(exp(sT2)-exp(-sT2))[idx]/sT2[idx])*tf[idx]
endif

return, tf
end

