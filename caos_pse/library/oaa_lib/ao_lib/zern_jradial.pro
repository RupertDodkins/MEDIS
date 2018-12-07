; $Id: zern_jradial.pro,v 1.2 2003/06/10 18:29:24 riccardi Exp $           
;           
; A. Riccardi, Dipartimento di Astronomia di Firenze (Italy).         
; e-mail address: riccardi@arcetri.astro.it           
; Please, send me a message if you modify this code.    
    
    
;+
; NAME:
;       ZERN_JRADIAL
;
; PURPOSE:
;       ZERN_JRADIAL returns the value of the radial portion R(N,M,Rho)
;		of the Zernike polynomial of radial degree N and azimuthal
;		frequency M in a vector R of radial points.
;		The radial Zernike polynomial is defined in the range (0,1)
;		and is computed as:
;
;			R(N,M,Rho) = Rho^M * P_[(N-M)/2](0,M,2*Rho^2-1)
;
;		where P_k(a,b,x) is the Jacobi Polynomial of degree k (see
;		JACOBI_POL)
;
; CALLING SEQUENCE:
;       Result = ZERNKE_JRADIAL(N, M, Rho [, Jpol1, JPol2])
;
; INPUTS:
;       N:      scalar of type integer or long. N >= 0.
;       M:      scalar of type integer or long. 0 <= M <= N and M-N even.
;       Rho:    n_elements vector of type float or double.
;
; OPTIONAL INPUTS:
;		JPol1:	n_elements vector of type float or double.
;				Jacobi polinomial P_[(N-M)/2-1](0,M,2*Rho^2-1).
;				Not used as input if (N-M)/2 <= 1.
;		JPol2:	n_elements vector of type float or double.
;				Jacobi polinomial P_[(N-M)/2-2](0,M,2*Rho^2-1).
;				with k=(N-M)/2-2. Not used if (N-M)/2-2 <= 1.
;				Not used as input if (N-M)/2 <= 1.
;
;		If JPol1 and JPol2 are given the calculation is faster
;		for (N-M)/2 >= 2.
;
; OPTIONAL OUTPUTS:
;		JPol1:  n-element vector of type float or double.
;				Jacobi polinomial P_[(N-M)/2](0,M,2*Rho^2-1).
;				Not used as input if N <= 1.
;		JPol2:  n-element vector of type float or double.
;				Jacobi polinomial P_[(N-M)/2-1](0,M,2*Rho^2-1).
;               Not used as output if N = 0.
;
; REFERENCES:
;       Magnus, Oberhettinger, Soni "Formulas and Theorems
;           for the Special Function of Mathematical Physics", 1966,
;           Sec. 5.2.
;		Born, Wolf, "Optics"
;		Noll 1976, JOSA, 66, 207.
;
; MODIFICATION HISTORY:
;       Written by:     A. Riccardi; October, 1997.
;-

function zern_jradial, n, m, r, jpol1, jpol2

	; return to the caller on error
	on_error, 2

	; check for the right number of passed parameters
	n_par = n_params()
	if n_par lt 3 then $
		message, "wrong number of passed parameters."

	; check for size and type of parameters
	type_n = size(n)
	type_m = size(m)
	type_r = size(r)

	if type_n(type_n(0)+1) eq 0 then $
		message, "N is undefined."
	if type_m(type_m(0)+1) eq 0 then $
		message, "M is undefined."
	if type_r(type_r(0)+1) eq 0 then $
		message, "Rho is undefined."

	if type_n(0) ne 0 then $
		message, "N must be a scalar"
	if type_m(0) ne 0 then $
		message, "M must be a scalar"
	
	if (type_n(type_n(0)+1) ne 2) and (type_n(type_n(0)+1) ne 3) then $
		message, "N must be an integer of a long."

	if n lt 0 then $
		message, "N must be greater or equal then zero.

	if (type_m(type_m(0)+1) ne 2) and (type_m(type_m(0)+1) ne 3) then $
		message, "M must be an integer of a long."

	if (m lt 0) or (m gt n) or ((m-n) mod 2) then $
		message, "Must be 0<=M<=N and N-M even."

	nmm2 = (n-m)/2
	one = r(0)*0.0+1.0

    if (m eq 0) then $
		return, jacobi_pol(nmm2, 0.0, one*m, 2.0*r^2-1.0, jpol1, jpol2) $
	else $
		return, r^m*jacobi_pol(nmm2, 0.0, one*m, 2.0*r^2-1.0, jpol1, jpol2)
end
