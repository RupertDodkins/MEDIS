; $Id: epsilon.pro,v 1.2 2003/06/10 18:29:25 riccardi Exp $ 
; 
; A. Riccardi, Dipartimento di Astronomia di Firenze (Italy). 
; Please, send me a message if you modify this code. 

function epsilon, DOUBLE=make_double
;+ 
; NAME: 
;       EPSILON 
; 
; PURPOSE: 
;       This function returns the machine precision.
; 
; CATEGORY: 
;       Utilities. 
; 
; CALLING SEQUENCE: 
;
;       Result = EPSILON() 
; 
; KEYWORD PARAMETERS: 
;       DOUBLE: If set calculates double type machine precision. Float
;               otherwise.
; 
; OUTPUTS: 
;       This function returns the machine precision: the smallest floating
;       point eps that: 1. + eps ne 1. (1.d + eps ne 1.d if DOUBLE is set).
; 
; EXAMPLE: 
;       Test if matrix C have zero elements using a tollerance.
;
;           Eps = EPSILON()
;           Toll = MAX(ABS(C)) * Eps
;           IF (WHERE((C LT Toll) AND (C GT -Toll)))(0) ne -1 THEN $
;               PRINT, 'C have zero-stimated elements'
;
; 
; MODIFICATION HISTORY: 
;       Written by:     A. Riccardi; April, 1995
;- 
    if (keyword_set(make_double)) then $ 
		eps = 1.d $
    else $
		eps = 1.

    while ((eps + 1.) ne 1.) do eps = eps/2.

    return, 2.*eps
end
