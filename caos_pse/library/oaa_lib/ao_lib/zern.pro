; $Id: zern.pro,v 1.2 2003/06/10 18:29:24 riccardi Exp $
;
; A. Riccardi, Dipartimento di Astronomia di Firenze (Italy).
; e-mail address: riccardi@arcetri.astro.it
; Please, send me a message if you modify this code.


function zern, j, x, y
;+
; NAME:
;       ZERN
;
; PURPOSE:
;       The ZERN function returns the value of J-th Zernike polynomial
;       in the points of coordinates X,Y. The output is of the same type
;		as the X and Y vectors. The function convert X,Y
;		coordinates in polar coordinates and call ZERN_JPOLAR function.
;
; CALLING SEQUENCE:
;       Result = ZERN(J, X, Y)
;
; INPUTS:
;       J:      scalar of type integer or long. Index of the polynomial,
;				J >= 1.
;       X:      n-element vector of type float or double. X coordinates.
;       Y:		n-element vector of type float or double. Y coordinates.
;
; MODIFICATION HISTORY:
;       Written by:    A. Riccardi; March, 1995.
;-
	return, zern_jpolar(j, sqrt(x*x+y*y), atan(y,x))
end
