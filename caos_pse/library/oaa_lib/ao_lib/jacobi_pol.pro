; $Id: jacobi_pol.pro,v 1.2 2003/06/10 18:29:23 riccardi Exp $           
;           
; A. Riccardi, Dipartimento di Astronomia di Firenze (Italy).         
; e-mail address: riccardi@arcetri.astro.it           
; Please, send me a message if you modify this code.    
    
    
;+
; NAME:
;       JACOBI_POL
;
; PURPOSE:
;       JACOBI_POL returns the value of the Jacobi Polynomial
;		P_N(A,B,X) of degree N and parameters A and B in a vector X
;		of points. The Jacobi polynomials are
;		orthogonal over the interval (-1,+1) with the weight
;		function w(x)=(1-x)^a * (1+x)^b.
;		The computation of the polynomial P_N(A,B,X) use the
;		recurrence relation:
;
;			P_0(A,B,X) = 1
;			P_1(A,B,X) = (a+b+2)/2*X+(A-B)/2
;
;			for N >= 2:
;			C0 = 2*N*(A+B+N)*(A+B+2*N-2)
;			C1 = (2*N+A+B-2)*(2*N+A+B-1)*(2*N+A+B)*X+
;				 +(A^2-B^2)*(2*N+A+B-1)
;			C2 = 2*(N+A-1)*(2*N+A+B)*(N+B-1)
;
;			C0*P_N(A,B,X) = C1*P_(N-1)(A,B,X)-C2*P_(N-2)(A,B,X)
;
; CALLING SEQUENCE:
;       Result = JACOBI_POL(N, A, B, X [, JPol1, JPol2])
;
; INPUTS:
;       N:      scalar of type integer or long. N >= 0.
;       A:		scalar of type float or double. A > -1. 
;       B:      scalar of type float or double. B > -1.
;       X:      n-element vector of type float or double.
;
; OPTIONAL INPUTS:
;       JPol1:  n-element vector of type float or double.
;				Jacobi polinomial P_(N-1)(A,B,X).
;               Not used as input if N <= 1.
;       JPol2:  n-element vector of type float or double.
;				Jacobi polinomial P_(N-2)(A,B,X).
;               Not used as input if N <= 1.
;
;       If JPol1 and JPol2 are given the calculation is faster
;		for N >= 2.
;
; OPTIONAL OUTPUT:
;       JPol1:  n-element vector of type float or double.
;				Jacobi polinomial P_N(A,B,X).
;       JPol2:  n-element vector of type float or double.
;				Jacobi polinomial P_(N-1)(A,B,X).
;               Not used as output if N = 0.
; REFERENCES:
;		Magnus, Oberhettinger, Soni "Formulas and Theorems
;			for the Special Function of Mathematical Physics", 1966,
;			Sec. 5.2.
;
; EXAMPLE:
;
; MODIFICATION HISTORY:
;       Written by:     A. Riccardi; October, 1997.
;-

function jacobi_pol, n, a, b, x, y, yp

	; return to the caller on error
	on_error, 2

	; check for the right number of passed parameters
	n_par = n_params()
	if n_par lt 4 then $
		message, "wrong number of passed parameters."
	
	; check for size and type of parameters
	type_n = size(n)
	type_a = size(a)
	type_b = size(b)
	type_x = size(x)

	if type_n(type_n(0)+1) eq 0 then $
		message, "N is undefined."
	if type_a(type_a(0)+1) eq 0 then $
		message, "A is undefined."
	if type_b(type_b(0)+1) eq 0 then $
		message, "B is undefined."
	if type_x(type_x(0)+1) eq 0 then $
		message, "X is undefined."

	if type_n(0) ne 0 then $
		message, "N must be a scalar"
	if type_n(0) ne 0 then $
		message, "A must be a scalar"
	if type_n(0) ne 0 then $
		message, "B must be a scalar"

	if (type_n(type_n(0)+1) ne 2) and (type_n(type_n(0)+1) ne 3) then $
		message, "N must be an integer of a long."

	if n lt 0 then $
		message, "N must be greater or equal then zero."

	if (a le -1) or (b le -1) then $
		message, "A and B must be greater then -1."

	; compute Jacobi polynomials for N=1 or N=2
	if n eq 0 then begin
		; generate the array of the results with the same type and
		; size as x
		y = x*0.0+1.0
		return, y
	endif

	ab = a+b

	if n eq 1 then begin
		yp = x*0.0+1.0
		y = (ab+2.0)/2.0*x+(a-b)/2.0
		return, y
	endif
		
	; at this point N>=2.
	; if JPol1 and JPol2 are passed, they are checked.
	type_1 = size(y)
	type_2 = size(yp)

	; test if Jpol1 is undefined
	if (type_1(type_1(0)+1) eq 0) or (type_2(type_2(0)+1) eq 0) then begin
		y=(ab+2.0)/2.0*x+(a-b)/2.0 
		yp=x*0.0+1.0
		n0 = 2
	endif else begin
		nx = type_x(type_x(0)+2)
		if (type_1(type_1(0)+2) ne nx) or (type_2(type_2(0)+2) ne nx) then $
			message, "JPar1 and JPar2 must have the same size of X."
		n0 = n
	endelse

	n0 = n0*(x(0)*0.0 +1.0)		; now n0 has the same type of x

	for i=n0,n do begin
		c0 = 2.0*i+ab
		c1 = 2.0*i*(i+ab)*(c0-2.0)
		c2 = c0*(c0-1.0)*(c0-2.0)
		c3 = (c0-1.0)*(a-b)*ab
		c4 = 2.0*(i+a-1.0)*c0*(i+b-1.0)

		ytemp = temporary(y)
		y = ((c2*x+c3)*ytemp-c4*yp)/c1
		yp = temporary(ytemp)
	endfor

	return, y

end
