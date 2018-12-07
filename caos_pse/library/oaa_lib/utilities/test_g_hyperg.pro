; $Id: test_g_hyperg.pro,v 1.2 2003/06/10 18:29:27 riccardi Exp $ 
; 
; A. Riccardi, Dipartimento di Astronomia di Firenze (Italy). 
; riccardi@arcetri.astro.it
; Please, send me a message if you modify this code. 


function product, vect
	n=n_elements(vect)
	result=1.
	for i=0,n-1 do $
		result = result*vect(i)

	return, result
end




function g_hyperg, alpha_par, beta_par, z, eps=eps
;+ 
; NAME: 
;       G_HYPERG
; 
; PURPOSE: 
;       Evaluates generalized hypergeometric function. 
; 
; CATEGORY: 
;       Special function. 
; 
; CALLING SEQUENCE: 
;
;       Result = G_HYPERG(Alpha, Beta, Z) 
; 
; INPUTS:
;       Alpha: 	real or double vector.
;
;		Beta:	real or double vector.
;
;		Z:		float, double or complex. Evaluating point.
;        
; KEYWORD PARAMETERS: 
;       eps:	float. Fractional precision requested. If it isn't set
;				then eps=1.e-6 is assumed.
; 
; OUTPUTS:
;       This function returns:
;
;		Sum(n=0 to N)((Alpha)n/(Beta)n*z^n/n!)
;
;		where:
;		(Alpha)n = (Alpha(0))n*...*(Alpha(P-1))n
;		(a)n = a*(a+1)*...*(a+n-1)
;		P=n_elements(Alpha)
;		(same as Beta)
;
;		N max value of n in the sum. Truncation of the series.
;		N is stimated from eps
; 
; RESTRICTIONS: 
;       P=n_elements(Alpha)
;		Q=n_elements(Beta)
;		Generalized hipergeometric series converges always if P<=Q,
;		conerges for abs(Z)<1. if P=Q+1 and diverges for all z not equal
;		to zero id P>Q+1.
;		If P=Q+1, s=Re(total(Alpha)-total(Beta)) then the series converges
;		for all abs(Z)=1 if s<0; it converges for all abs(Z)=1 and Z not eq 1
;		if 0<=s<1 and diverges if s>=1.
; 
; EXAMPLE: 
;       <???>
; 
; MODIFICATION HISTORY: 
;       Written by:     A. Riccardi; July, 1995. 
;- 

	p = n_elements(alpha_par)-1
	q = n_elements(beta_par)-1

	if (n_elements(eps) eq 0) then eps=1.e-6

	if (p gt q+1) then $
		print, 'g_hyperg --- p > q+1, the series not converges' $
	else $
		if (p eq q+1) then $
			if (max(abs(z)) gt 1.) then $
				print, 'g_hyperg --- p = q+1 and abs(z)>1. , the series not converges'
				;
				; mancano i test per abs(z) eq 1.
				;

	term=1.
	; first element of the series
	result=term

	talpha = replicate(alpha_par(0)*0+1., (p > q)+1)
	tbeta  = talpha
	talpha(0:p) = rotate(alpha_par(sort(alpha_par)), 2)
	tbeta(0:q) = rotate(beta_par(sort(beta_par)), 2)
	n=1

	repeat begin
		term = term * product(talpha/tbeta)/n*z
		result = result + term
		;print, term
		talpha(0:p) = talpha(0:p)+1.
		tbeta(0:q)  = tbeta(0:q)+1.
		n=n+1

		e_rel = term/result

		print, term, result
		if ((n mod 10) eq 0) then stop
	endrep until ((max(e_rel) lt eps) and (min(e_rel) ge -eps))
	;stop
	return, result
end

