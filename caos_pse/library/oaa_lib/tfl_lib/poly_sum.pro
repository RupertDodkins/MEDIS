; $Id: poly_sum.pro,v 1.4 2003/06/10 18:29:25 riccardi Exp $

function poly_sum, p1, p2
;+
; POLY_SUM
;
; coeff_sum = poly_sum(coeff1, coeff2)
;
; returns the coeffs of the polynomial given by the sum
; of the polynomial of coeffs coeff1 and coeff2
;
; MODIFICATON HISTORY
;
;    Written by: A. Riccardi, Osservatorio Astrofisico di Arcetri, ITALY
;                riccardi@arcetri.astro.it
;-

n1 = n_elements(p1)
n2 = n_elements(p2)

if n1 gt n2 then begin
    p_out = p1
    p_out[0] = p_out[0:n2-1]+p2
endif else begin
    p_out = p2
    p_out[0] = p_out[0:n1-1]+p1
endelse

return, p_out
end
