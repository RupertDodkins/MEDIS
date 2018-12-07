; $Id: lllccd_prob.pro,v 1.1 2003/03/24 14:27:55 riccardi Exp $
;+
;
; prob = lllccd_prob(x, n, g)
;
; probability function to obtain x extra-electrons in the avalange when
; n photo-electrons are detected, with gain g. g=m^r where r is the
; number of amplification registers and m is the multiplication factor of
; each register (m>=1.0, m=1.01 tipically).
;
; n must be integer. if n>170 or (n-1)*log(x/g)
;
; EXAMPLE:
;
; probability P(0<=x<1) with n=1 and g=1.01^519
;
; P=lllccd_prob(0.5, 1, 1.01^519)
;
; MODIFICATION HISTORY:
;
; 22 March 2003: written by A. Riccardi, INAF-OAA, Italy
;                riccardi@arcetri.astro.it
;-
function lllccd_prob, x, n, g

	n1=n-1
	gd=double(g)
	xg=double(x)/gd
	; Gosper modification of the Stirling's approximation
	; see: http://mathworld.wolfram.com/StirlingsApproximation.html
	ln_fact=n1*alog(double(n1))-n1+0.5d0*alog(!DPI*(2d0*n1+1d0/3d0))

	; From gamma distribution: mean=n*g, variance=n*g^2, skewness=2/sqrt(n), kurtosis=6/n
	; see: http://mathworld.wolfram.com/GammaDistribution.html
	if ln_fact < 705 then begin
		return, (xg)^n1*exp(-xg)/factorial(n1)/gd
	endif else begin
		return, exp(n1*alog(xg)-xg-alog(gd)-ln_fact)
	endelse
end
