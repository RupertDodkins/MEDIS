; $Id: kolm_covar.pro,v 1.2 2003/06/10 18:29:23 riccardi Exp $ 
; 
; A. Riccardi, Dipartimento di Astronomia di Firenze (Italy). 
; riccardi@arcetri.astro.it
; Please, send me a message if you modify this code. 

;+ 
; NAME: 
;       KOLM_COVAR 
; 
; PURPOSE: 
;       This function computes the covariance of Zernike polynomial
;		coefficients of the wavefront perturbations due to 
;		Kolmogorov turbulence.
; 
; 
; CALLING SEQUENCE: 
; 
;       Result = KOLM_COVAR(J1, J2) 
; 
; INPUTS: 
;       J1:     integer scalar. Inedex of Zernike polynomial. J1 >= 2 
;       J2:     integer scalar. Inedex of Zernike polynomial. J2 >= 2 
; 
; KEYWORD PARAMETERS: 
;       DOUBLE: if set, double precision covariance is returned.
;				Otherwise, single precision (float).
; 
; OUTPUTS: 
;       This function returns OPD covariance <a(J1)*a(J2)> where a(J1) and
;       a(J2) are J1-th and J2-th Zernike components of wave front 
;       perturbations due to Kolmogoroffian turbolence. Covariance is
;       in (wavelength)^2*(D/r0)^(5/3) units, where D is the pupil
;       diameter and r0 the Fried parameter.
;       To have covariance of phase perurbations, use:
;
;           4*pi^2*KOLM_COVAR(J1, J2) = <2*pi*a(J1) * 2*pi*aj(J2)>,
;
;       it is in (D/r0)^(5/3) units.
; 
; RESTRICTIONS: 
;       J1, J2 >= 2, because piston variance (J1=J2=1) diverges. 
; 
; BIBLIOGRAFY: 
;           Noll 1976, JOSA, 66, 207.
;           Roddier 1990, Opt. Eng., 29, 1174. 
; 
; EXAMPLE: 
;       Computes the average spatial variance of phase perturbation on a 
;       circular pupil of diameter 1.5m due to first 15 Zernike polynomials.
;       Suppose r0 = 15cm.
;
;       scale = (150./15.)^(5./3.)
;       var = 0.
;       FOR i=2,15 DO var = var + KOLM_COVAR(i,i)
;       var = (2 * !PI)^2 * scale * var
;
; MODIFICATION HISTORY: 
;       Written by:     A. Riccardi; April, 1995. 
;						A. Riccardi; June, 1997. Recursive calculation
;							for the Gamma(n+alpha) (n int and alpha
;							floating point) to avoid overflow
;							in the Gamma Function for large n+alpha.
;- 

function kolm_covar, j1, j2, DOUBLE=is_double

    zern_degree, j1, n1, m1
    zern_degree, j2, n2, m2

    
    if ((m1 ne m2) or ((not is_even(j1+j2)) and (m1 ne 0))) then $
        if keyword_set(is_double) then $
            return, 0D0 $
        else $
            return, 0.0

	; npn and nmn are both integer because m1=m2, so n1 and n2 have the
	; same parity.
	; Moreover, because n1,n2>=1 in this frame, npn>=0
	; and nmn>=0
    npn = (n1 + n2)/2-1
    nmn = abs(n1 - n2)/2

    if keyword_set(is_double) then begin
        ; the costant reported in Roddier 1990 is divided by 2*pi 
		; to convert rad in waves
        result = 0.057494899D*(-1)^((n1+n2-2*m1)/2)*sqrt((n1+1D)*(n2+1D))
		result = result*gamma(1D/6D)/(gamma(17D/6D))^2/gamma(29D/6D)
		c1=1D & c2=1D
		if (npn gt 0) then for i=0,npn-1 do c1=c1/(29D/6D0+i)*(1D/6D0+i)
		if (nmn gt 0) then for i=0,nmn-1 do c2=c2/(17D/6D0+i)*(-11D/6D0+i)
    endif else begin
        result = 0.0574949*(-1)^((n1+n2-2*m1)/2)*sqrt((n1+1.0)*(n2+1.0))
		result = result*gamma(1.0/6.0)/(gamma(17.0/6.0))^2/gamma(29.0/6.0)
		c1=1.0 & c2=1.0
		if (npn gt 0) then for i=0,npn-1 do c1=c1/(29.0/6.0+i)*(1.0/6.0+i)
		if (nmn gt 0) then for i=0,nmn-1 do c2=c2/(17.0/6.0+i)*(-11.0/6.0+i)
    endelse
    return, result*c1*c2*(-1)^nmn
end
