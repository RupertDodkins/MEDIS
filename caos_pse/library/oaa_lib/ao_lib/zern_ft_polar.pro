; $Id: zern_ft_polar.pro,v 1.2 2003/06/10 18:29:24 riccardi Exp $
;
; A. Riccardi, Dipartimento di Astronomia di Firenze (Italy).
; e-mail address: riccardi@arcetri.astro.it
; Please, send me a message if you modify this code.


function zern_ft_polar, j, k, phi
;+
; NAME:
;       ZERN_FT_POLAR
;
; PURPOSE:
;       ZERN_FT_POLAR returns the value of j-th Zernike polynomial
;       fourier transform in a frequency of polar coordinates k,phi.
;       (We use Noll formulation of Zernike polynomials)
;
; CATEGORY:
;       Special polynomial
;
; CALLING SEQUENCE:
;
;       Result = ZERN_FT_POLAR(J, K, Phi)
;
; INPUTS:
;       J:      index of the polynomial, integer J >= 1
;       K:      frequency to evaluate (polar coord.)
;       Phi:
;
; OUTPUTS:
;       ZERN_FT_POLAR returns the value of j-th Zernike polynomial
;       fourier tranform in the frequency of polar coordinates k, phi.
;       On error return 0.
;
; EXAMPLE:
;       Evaluate Zernike x coma fourier transform in kappa, phi. Enter:
;
;            Result = ZERN_FT_POLAR(8, kappa, phi)
;
; MODIFICATION HISTORY:
;       Written by:     A. Riccardi; March, 1995.
;-
	if j lt 1 then begin
		print, 'zern_ft_polar -- must have j>=0'
		return, 0.
	endif

	; test if double data type
	if ((size(k(0)))(1) eq 5) then pi=!dpi else pi=!pi

	;calculate radial degree n and azimuthal frequency m  
	zern_degree, j, n, m  

	; *** RIGA DA OTTIMIZZARE
	k1 = k > 1e-4
	result = (-1)^((n-m)/2)*sqrt(n+1)/pi*beselj(2*pi*k1, n+1)/k1  
	if m eq 0 then return, result else begin
		result = sqrt(2)*complex(0,1)^m*result
		if is_even(j) then return, result*cos(m*phi) else $
		return, result*sin(m*phi)
	endelse
end
 
