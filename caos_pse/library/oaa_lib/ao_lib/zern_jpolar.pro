; $Id: zern_jpolar.pro,v 1.2 2003/06/10 18:29:24 riccardi Exp $
;
; A. Riccardi, Dipartimento di Astronomia di Firenze (Italy).
; e-mail address: riccardi@arcetri.astro.it
; Please, send me a message if you modify this code.


;+
; NAME:
;       ZERN_JPOLAR
;
; PURPOSE:
;       ZERN_JPOLAR returns the value of j-th Zernike polynomial
;       in a point of polar coordinates r,theta.
;       (We use Noll formulation of Zernike polynomials)
;
; CATEGORY:
;       Special polynomial
;
; CALLING SEQUENCE:
;
;       Result = ZERN_JPOLAR(J, R, Theta)
;
; INPUTS:
;       J:      index of the polynomial, integer J >= 1
;       R:      point to evaluate (polar coord.)
;       Theta:
;
; OUTPUTS:
;       ZERN_POLAR returns the value of j-th Zernike polynomial
;       in the point of polar coordinates r, theta.
;       If r>1 then return 0. On error return 0.
;
; EXAMPLE:
;       Evaluate Zernike x coma in rho, theta. Enter:
;
;            Result = ZERN_JPOLAR(8, rho, theta)
;
; MODIFICATION HISTORY:
;       Written by:     A. Riccardi; March, 1995.
;-
function zern_jpolar, j, r, theta

	if j lt 1 then begin
		print, 'zern_jpolar -- must have j>=0'
		return, 0.
	endif

	;calculate radial degree n and azimuthal frequency m
	zern_degree, j, n, m  
  
	result = sqrt(n+1.+r(0)*0.)*zern_jradial(n, m, r)

	if m eq 0 then $
		return, result $
	else $
		if is_even(j) then $
			return, sqrt(r(0)*0.+2.)*result*cos(m*theta) $
		else $
			return, sqrt(r(0)*0.+2.)*result*sin(m*theta)
end
