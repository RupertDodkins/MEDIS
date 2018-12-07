; $Id: poly_mult.pro,v 1.5 2003/06/10 18:29:24 riccardi Exp $

function poly_mult, p1, p2, DOUBLE=double

;+
; NAME:
;   POLY_MULT
;
; p = poly_mult(p1, p2 [, DOUBLE=double])
;
; p1, p2 vector of coeff of polynimials:
;           P1(x)=p1[0]+p1[1]*x+p2[2]*x^2+...+p1[n1]*x^n1
;           P2(x)=p2[0]+p2[1]*x+p2[2]*x^2+...+p2[n2]*x^n2
;
; p      vector of the coeffs of the polynomial P1(x)*P2(x)
;
; if n1 < n2 poly_mult(p1,p2) is faster then poly_mult(p2,p1)
;
; MODIFICATON HISTORY
;
;    Written by: A. Riccardi, Osservatorio Astrofisico di Arcetri, ITALY
;                riccardi@arcetri.astro.it
;-

n1 = n_elements(p1)-1
n2 = n_elements(p2)-1

if n1 lt 0 or n2 lt 0 then message, 'Input polynomial coeffs not defined'

n = n1+n2                       ; order of the polynomial p1*p2

if keyword_set(double) then begin
    ;; force the double precision data type
    p = dblarr(n+1)
endif else begin
    ;; conserve the same data type
    p = replicate(p1[0]*p2[0]*0B, n+1)
endelse

for i=0, n1 do p[i] = p[i:*] + p1[i]*p2

return, p
end
