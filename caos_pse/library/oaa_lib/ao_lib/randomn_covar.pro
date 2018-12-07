; $Id: randomn_covar.pro,v 1.2 2003/06/10 18:29:24 riccardi Exp $ 
; 
; A. Riccardi, Dipartimento di Astronomia di Firenze (Italy). 
; Please, send me a message if you modify this code. 

;+
; NAME: 
;       RANDOMN_COVAR
; 
; PURPOSE: 
;       This function returns a sample of zero mean jointly
;       gaussian random variables by the Cholesky decomposition
;       of their covariance matrix.
;
; 
; CATEGORY: 
;       Statistics. 
; 
; CALLING SEQUENCE: 
;
;       Result = RANDOMN_COVAR(L,R) 
; 
; INPUTS: 
;       L:      squared matrix. Cholesky factor of covariance
;               matrix from CHOLESKY function. The covariance
;               matrix C is:
;                   C = transpose(L)#L
;
; OPTIONAL INPUTS:
;       R:      integer or long scalar. Number of realizations.
;               If not defined one realization is returned.
; 
; KEYWORD PARAMETERS: 
;       SEED:   long type variable. Random generation seed.
;               See RANDOMU function.
; 
; OUTPUTS: 
;       Vector. This function returns a sample of zero mean jointly
;       gaussian random variables with statistics from L.
;       If L is double type matrix, double vector is
;       returned. Otherwise float.
;
;               Return = L ## RANDOMN(seed,r,n)
;
;       where n is the dimension of L.
; 
; OPTIONAL OUTPUTS: 
;       If SEED variable is specified, it is updated. See RANDOMU function.
; 
; TROUBLES: 
;       Even if double type L is used, RANDOMN returns
;       a float type vector that is converted to double type one. 
; 
; EXAMPLE: 
;       Create a plot of probability density function of the sum
;       of two jointly gaussian variables with M mean and C covariance.
;
;       C = [[1.2, 0.3], [0.3, 2.3]]
;       M = [12.1, 25.7]
;       L = CHOLESKY(C)
;       seed = 1L
;       A = fltarr(500, /NOZERO)
;       FOR i=0,499 DO A(i) = TOTAL(RANDOMN_COVAR(L, SEED=seed) + M)
;       HISTOGRAM(A)
; 
; MODIFICATION HISTORY: 
;       Written by:     A. Riccardi; April, 1995
;-

function randomn_covar, cholesky_factor, r, SEED=seed, SPARSE=sparse

	if n_params() eq 1 then r=1
	if keyword_set(sparse) then begin
		; cholesky_factor has been saved as a sparse matrix
		; using SPRSIN with the COLUMN keyword set.
		n = cholesky_factor.ija(0)-2
		randm = fltarr(r,n)
		for i=0,r-1 do begin
			randm[i,*] = sprsax(cholesky_factor, randomn(seed, n))
		endfor
		if r eq 1 then begin
			return, reform(randm)
		endif else return, randm
	endif
    n = n_elements(cholesky_factor(*,0))
	if r eq 1 then begin
    	return, cholesky_factor##randomn(seed,  n)
	endif else begin
	    return, cholesky_factor##randomn(seed, r, n)
	endelse
end

