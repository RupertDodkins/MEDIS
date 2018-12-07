; $Id: von_covar.pro,v 1.2 2003/06/10 18:29:24 riccardi Exp $ 
; 
; A. Riccardi, Dipartimento di Astronomia di Firenze (Italy). 
; riccardi@arcetri.astro.it
; Please, send me a message if you modify this code. 

function von_covar, j1, j2, L0n, double=is_double, eps=eps
;+ 
; NAME: 
;       VON_COVAR 
; 
; PURPOSE: 
;       This function computes covariance of zernike components of
;       wave front perturbations due to Von-Karmann turbolence.
; 
; CATEGORY: 
;       Optics. 
; 
; CALLING SEQUENCE: 
; 
;       Result = VON_COVAR(J1, J2, L0) 
; 
; INPUTS: 
;       J1:     integer scalar. Inedex of Zernike polynomial. J1 >= 1
;       J2:     integer scalar. Inedex of Zernike polynomial. J2 >= 1
;		L0:		float or double. Outer-scale value in pupil diameter
;				units.
; 
; KEYWORD PARAMETERS: 
;       DOUBLE: if set, forces double type covariance. Float therwise.
;		EPS:	float or double scalar. relative precision of computation.
;				If undefined EPS=1.e-7.
; 
; OUTPUTS: 
;       This function returns covariance <a(J1)*a(J2)> where a(J1) and
;       a(J2) are J1-th and J2-th Zernike components of wave front 
;       perturbations due to Von-Karman turbolence. Covariance is
;       in (wave-length)^2*(D/r0)^(5/3) units, where D is the pupil
;       diameter and r0 the Fried parameter (r0 for Kolmogoroffian
;		turbolence).
;       To have covariance of phase perurbations, use:
;
;           4*pi^2*VON_COVAR(J1, J2) = <2*pi*a(J1) * 2*pi*aj(J2)>,
;
;       it is in (D/r0)^(5/3) units.
; 
; PROCEDURE: 
;       See:
;           Winker D. M., 1991, JOSA, 8, 1569.
;           Takato N. and Yamaguchi I., 1995, JOSA, 12, 958
; 
; EXAMPLE: 
;       Computes the average spatial variance of phase perturbation on a 
;       circular pupil of diameter 1.5m dues to first 15 Zernike aberrations.
;       Suppose r0 = 15cm, L0=40m
;
;       scale = (150./15.)^(5./3.)
;		L0norm= (40./1.5)
;       var = 0.
;       FOR i=2,15 DO var = var + VON_COVAR(i,i,L0norm)
;       var = 4 * !PI * var * scale
;       Strhel_Ratio = EXP(-var)
;
; MODIFICATION HISTORY: 
;       Written by:     A. Riccardi; July, 1995. 
;- 

    zern_degree, j1, n1, m1
    zern_degree, j2, n2, m2

    
    if ((m1 ne m2) or ((not is_even(j1+j2)) and (m1 ne 0))) then $
        if keyword_set(is_double) then $
            return, 0.d $
        else $
            return, 0.

	if (n_elements(eps) eq 0) then $
		eps = 1.e-7
		
	n1pn2 = (n1+n2)/2.
	n1mn2 = (n1-n2)/2.
	
    if keyword_set(is_double) then begin
        ; the costant is divided for 2*pi to convert rad in waves
        
		x0 = !dpi/L0n
		
        result = (24.d/5.d*gamma(6.d/5.d))^(5.d/6.d)*(gamma(11.d/6.d))^2/!dpi^(5.d/2.d)
        result = result*(-1)^((n1+n2-2*m1)/2)*sqrt((n1+1.d)*(n2+1.d))
        result = result/sin(!dpi*(n1pn2+1.d/6.d))
        
        temp1  = sqrt(!dpi)/2.d^(n1+n2+3)*gamma(n1pn2+1.d)/gamma(n1pn2+1.d/6.d)
        temp1  = temp1/gamma(11.d/6.d)/gamma(n1+2.d)/gamma(n2+2.d)*x0^(n1+n2-5.d/3.d)

        alpha  = [n1pn2+3.d/2.d, n1pn2+2.d, n1pn2+1.d]
        beta   = [n1pn2+1.d/6.d,n1+2.d, n2+2.d, n1+n2+3.d]
        
        temp1  = temp1*g_hyperg(alpha, beta, x0^2, eps=eps)

        temp2  = -gamma(7.d/3.d)*gamma(17.d/6.d)/2.d
        temp2  = temp2/gamma(11.d/(6.d)-n1pn2)/gamma(17.d/(6.d)-n1mn2)/gamma(17.d/(6.d)+n1mn2)
        temp2  = temp2/gamma(n1pn2+23.d/6.d)

        alpha  = [11.d/6.d, 7.d/3.d, 17.d/6.d]
        beta   = [11.d/(6.d)-n1pn2, 17.d/(6.d)-n1mn2, 17.d/(6.d)+n1mn2, 23.d/(6.d)+n1pn2]
        
        temp2  = temp2*g_hyperg(alpha, beta, x0^2, eps=eps)
    endif else begin
        
		x0 = !pi/L0n
		
        result = (24./5.*gamma(6./5.))^(5./6.)*(gamma(11./6.))^2/!pi^(5./2.)
        result = result*(-1)^((n1+n2-2*m1)/2)*sqrt((n1+1.)*(n2+1.))
        result = result/sin(!pi*(n1pn2+1./6.))
        
        temp1  = sqrt(!pi)/2.^(n1+n2+3)*gamma(n1pn2+1.)/gamma(n1pn2+1./6.)
        temp1  = temp1/gamma(11./6.)/gamma(n1+2.)/gamma(n2+2.)*x0^(n1+n2-5./3.)

        alpha  = [n1pn2+3./2., n1pn2+2., n1pn2+1.]
        beta   = [n1pn2+1./6.,n1+2., n2+2., n1+n2+3.]
        
        temp1  = temp1*g_hyperg(alpha, beta, x0^2, eps=eps)

        temp2  = -gamma(7./3.)*gamma(17./6.)/2.
        temp2  = temp2/gamma(11./6.-n1pn2)/gamma(17./6.-n1mn2)/gamma(17./6.+n1mn2)
        temp2  = temp2/gamma(n1pn2+23./6.)

        alpha  = [11./6., 7./3., 17./6.]
        beta   = [11./6.-n1pn2,17./6.-n1mn2, 17./6.+n1mn2, 23./6.+n1pn2]
        
        temp2  = temp2*g_hyperg(alpha, beta, x0^2, eps=eps)
    endelse
    return, result*(temp1+temp2)
end


