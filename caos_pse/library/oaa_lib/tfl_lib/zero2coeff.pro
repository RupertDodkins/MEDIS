; $Id: zero2coeff.pro,v 1.4 2003/06/10 18:29:25 riccardi Exp $

function zero2coeff, zeros
;+
;
; ZERO2COEFF
;
;  c = zero2coeff(z)
;
;  returns the coeffs of the polynomial:
;
;    (x+z[0])*(x+z[1])* ... *(x+z[n-1])
;
;  where n>0. z can be a real or a complex vector.
;
;  The coeffs are ordered from the lowest to the highest power of x
;
; MODIFICATON HISTORY
;
;    Written by: A. Riccardi, Osservatorio Astrofisico di Arcetri, ITALY
;                riccardi@arcetri.astro.it
;-

if test_type(zeros, /NUMERIC, N_EL=n_el) then $
  message, 'the input must be numeric'

coeff = [zeros[0], 1B]
for i=1,n_el-1 do $
  coeff = poly_mult([zeros[i], 1B], coeff)

return, coeff
end
