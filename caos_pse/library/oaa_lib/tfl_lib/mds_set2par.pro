pro mds_set2par, settling_time, overshoot, w0, norm_damping, SETTLING_LIMIT=settling_level, EPSILON=eps

;+
; mds_set2par, settiling_time, overshoot, w0, norm_damping, SETTLING_LIMIT=settling_level
;
; example:
; computes the natural frequency w0 [rad/sec] and normalized damping gamma.
;
; EXAMPLE:
; for a mass-damper-spring system with 1ms of settling time and 10% overshoot.
;
; mds_set2par, 0.001, 0.1, w0, gamma
;
; KEYWORDS:
; SETTLING_LIMIT: Threshold relative to the command for the computation of the settling
;                 time. It is 0.1 by default (i.e. +/- 10% wrt command).It must be greater
;                 then or equal to the overshoot
;
; NOTE: the equivalent delay for small w (in transfer function terms) is 2*gamma/w0.
;       It is about 0.5*settling_time with 0.1 overshoot and 0.1 setting level.
;
; HISTORY:
;  May 2006: written by A. Riccardi (AR). INAF-OAA
;-

if n_elements(eps) eq 0 then eps=1e-4
if n_elements(settling_level) eq 0 then settling_level=0.1
if overshoot gt settling_level then message, "Settling level cannot be less then specified overshoot."
theta = (atan(-alog(overshoot)/!DPI))
norm_damping = sin(theta)
wd=sqrt(1-norm_damping^2) ;w0=1
t0=0.0
t1=!DPI/wd
count = 100
while count ne 0 do begin
    tm = (t0+t1)/2
    resp = mds_step_resp(tm, norm_damping, 1.0)
    if resp gt 1-settling_level then t1=tm else t0=tm
    count -= 1
    if abs(t1-t0)/tm lt eps then break
endwhile
if count eq 0 then message, "ERROR, number of iterations exceeded the max value."

w0 = tm/settling_time
end