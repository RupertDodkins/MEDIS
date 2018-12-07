; $Id: cholesky.pro,v 1.2 2003/06/10 18:29:23 riccardi Exp $
;
; A. Riccardi, Dipartimento di Astronomia di Firenze (Italy).
; Please, send me a message if you modify this code.

;+
; NAME:
;       CHOLESKY
;
; PURPOSE:
;       This procedure makes the cholesky decomposition of
;       a positive defined simetric matrix.
;
;
; CATEGORY:
;       Linear Algebra.
;
; CALLING SEQUENCE:
;
;       CHOLESKY, L
;
; INPUTS:
;       L:      squared matrix. Matrix to decompose. It is supposed simmetric
;               (transpose(L) = L), so only diagonal and upper triangle is
;				accessed as input.
;               See input of CHOLDC procedure.
;
; KEYWORDS:
;       DOUBLE: if set forces the computation in double precision
;
; OUTPUTS:
;       Matrix. This procedure overwrite on L the lower triangular Cholesky
;		factor of the input matrix, so that L ## TRANSPOSE(L) is the original
;		simmetric matrix.
;
; EXAMPLE:
;       Cholesky decompsition of a 2 dimensional simmetric matrix:
;
;       C = [[1.2, 0.3], [0.3, -2.3]]
;       L = CHOLESKY(C)
;       PRINT, C - (L ## TRANSPOSE(L))
;
; MODIFICATION HISTORY:
;       Written by:     A. Riccardi; April, 1995
;-

pro cholesky, cholesky_factor, DOUBLE=double_prec

	if test_type(cholesky_factor,/REAL,DIM_SIZE=dim) then begin
			message, 'Wrong input type'
	endif
	if dim[0] ne 2 then  $
			message,'Wrong input format, input must be a square matrix'
	if dim[1] ne dim[2] then $
			message,'Wrong input format, input must be a square matrix'

    choldc, cholesky_factor, cholesky_diagonal, DOUBLE=double_prec
    n=n_elements(cholesky_diagonal)
	if n eq 1 then message,' Cholesky decomposition failed'

    for j=0,n-2 do begin
        cholesky_factor(j+1:*,j)=0.0
    endfor
    set_diagonal, cholesky_factor, cholesky_diagonal
end

