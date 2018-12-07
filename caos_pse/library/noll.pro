function noll, mode, D, r0
;+
; computes the Noll residual variance [rad^2], noll.
; => wf rms [m] = sqrt(noll)*lambda/(2*!PI),
; where lambda = wavelenght [m] for which r0 is defined.
; => Strehl (for wavelenght for which r0 is defined, lambda) = exp{-noll}.
; => Strehl (for another wavelenght, lambda_i) = exp{-noll*(lambda/lambda_i)^2}.
;
; use: noll = noll(mode, D, r0)
; where:
; mode = Zernike (starting from piston=mode #0) untill which the
; ideal correction is made,
; D = diameter of the telescope [m],
; r0 = Fried parameter [m],
; noll = residual variance [rad^2].
;
; Marcel Carbillet (Lagrange, UNS/CNRS/OCA) [marcel.carbillet@unice.fr]
; for CAOS Library 5.4, 22 March 2012.
;-

if mode eq  0 then noll = 1.0299 ; piston (Z1)
if mode eq  1 then noll = .582   ; Zernike tip (Z2)
if mode eq  2 then noll = .134   ; Zernike tilt (Z3)
if mode eq  3 then noll = .111   ; Defocus (Z4)
if mode eq  4 then noll = .0880  ; Astismatism 1 (Z5)
if mode eq  5 then noll = .0648  ; Astigmatism 2 (Z6)
if mode eq  6 then noll = .0587  ; Coma 1 (Z7)
if mode eq  7 then noll = .0525  ; Coma 2 (Z8)
if mode eq  8 then noll = .0463  ; Z9
if mode eq  9 then noll = .0401  ; Z10
if mode eq 10 then noll = .0377  ; 3rd order spherical (Z11)
if mode eq 11 then noll = .0352  ; Z12
if mode eq 12 then noll = .0328  ; Z13
if mode eq 13 then noll = .0304  ; Z14
if mode eq 14 then noll = .0279  ; Z15
if mode eq 15 then noll = .0267  ; Z16
if mode eq 16 then noll = .0255  ; Z17
if mode eq 17 then noll = .0243  ; Z18
if mode eq 18 then noll = .0232  ; Z19
if mode eq 19 then noll = .022   ; Z20
if mode eq 20 then noll = .0208  ; Z21
if mode gt 20 then noll = .2944*(mode+1.)^(-sqrt(3)/2.)

return, noll*(D/r0)^(5./3)
end