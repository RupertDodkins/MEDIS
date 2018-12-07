; $Id: zern_ft.pro,v 1.2 2003/06/10 18:29:24 riccardi Exp $
;
; A. Riccardi, Dipartimento di Astronomia di Firenze (Italy).
; e-mail address: riccardi@arcetri.astro.it
; Please, send me a message if you modify this code.


function zern_ft, j, fx, fy
;+
; NAME:
;       ZERN_FT
;
; PURPOSE:
;       ZERN_FT returns the value of j-th Zernike polynomial
;       fourier transform in a point of frequency fx,fy.
;       (We use Noll formulation of Zernike polynomials)
;
; CATEGORY:
;       Special polynomial
;
; CALLING SEQUENCE:
;
;       Result = ZERN_FT(J, Fx, Fy)
;
; INPUTS:
;       J:      index of the polynomial, integer J >= 1
;       Fx:     frequency to evaluate
;       Fy:
;
; OUTPUTS:
;       ZERN_FT returns the value of j-th Zernike polynomial
;       fourier transform in the point of requency Fx,Fy.
;       On error return 0.
;
; EXAMPLE:
;       Evaluate Zernike x coma fourier transform in fx,fy. Enter:
;
;           Result = ZERN_FT(8, fx, fy)
;
; MODIFICATION HISTORY:
;       Written by:     A. Riccardi; March, 1995.
;-
	k = sqrt(fx*fx+fy*fy)
	phi = atan(fy,fx)

	return, zern_ft_polar(j, k, phi)
end
