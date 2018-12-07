; $Id: poly_pow.pro,v 1.4 2003/06/10 18:29:24 riccardi Exp $

function poly_pow, p, power, DOUBLE=double
;+
; POLY_POW
;
; coeff_out = poly_pow(coeff_in, e [, DOUBLE=double])
;
; returns the coeffs of the polynomial given by the e-th power
; of the polynomial of coeffs coeff_in
;
; MODIFICATON HISTORY
;
;    Written by: A. Riccardi, Osservatorio Astrofisico di Arcetri, ITALY
;                riccardi@arcetri.astro.it
;-

if power eq 0 then begin
    if keyword_set(double) then return, [1d0] else return, [1]+0B*p[0]
endif

p_out = p

for k=2,power do p_out = poly_mult(p, p_out, DOUBLE=double)

return, p_out
end
