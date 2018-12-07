; $Id: kolm_mcovar.pro,v 1.2 2003/06/10 18:29:23 riccardi Exp $ 
; 
; A. Riccardi, Dipartimento di Astronomia di Firenze (Italy). 
; riccardi@arcetri.astro.it
; Please, send me a message if you modify this code. 


;+ 
; NAME: 
;       KOLM_MCOVAR 
; 
; PURPOSE: 
;       This function computes OPD covariance matrix of Zernike components of
;       wavefront perturbations due to Kolmogorov turbulence. 
; 
; CALLING SEQUENCE: 
;       Result = KOLM_MCOVAR(Max_index) 
; 
; INPUTS: 
;       Max_index:  integer saclar. Maximum index of Zernike polynomial used.
;                   Max_index >= 2.
; 
; KEYWORD PARAMETERS: 
;       DOUBLE: if set, the result is double type. Float otherwise.
; 
; OUTPUTS: 
;       Squared symmetric matrix with Max_index-1 elements per dimension.
;       It is the covariance matrix for componets of Zernike polynomial with
;       index from 2 to Max_index (see KOLM_COVAR).
;
;           Result(i-2,j-2) = <a(i) * a(j)>     where 2<=i,j<=Max_index
;
;       OPD covariance matrix is in (wavelength)^2*(D/r0)^(5/3) units,
;       where D is the pupil diameter and r0 the Fried parameter.
;		Return 0 if an error occurred.
; 
; RESTRICTIONS: 
;       Covariances with Zernike index i=1 or j=1 is not computed
;       because piston (j=i=1) Kolmogoroffian variance diverges.
;       That's why Max_index >= 2.
; 
; PROCEDURE: 
;       See: KOLM_COVAR
; 
; EXAMPLE: 
;       Computes Covariance matrix for first 15 Zernike inexes and print
;       variance due to Zernike sferical aberration:
;
;       C = KOLM_MCOVAR(15)
;       PRINT, C(11-2, 11-2)
; 
; MODIFICATION HISTORY: 
;       Written by:     A. Riccardi; April, 1995. 
;-

function kolm_mcovar, max_index, DOUBLE=is_double

	; Excludes piston Zernike polynomial
    n_elem = max_index-1
    if n_elem lt 1 then return, 0
    if keyword_set(is_double) then $
        result = dblarr(n_elem,n_elem,/nozero) $
    else $
        result = fltarr(n_elem,n_elem,/nozero)
	; this loop can be optimized. The same value is calculated more
	; then onece
    for i=0,n_elem-1 do $
        for j=i,n_elem-1 do begin
            result(j,i) = kolm_covar(j+2,i+2,double=is_double)
            result(i,j) = result(j,i)
        endfor

    return, result
end
