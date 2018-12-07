; $Id: make_orto_modes.pro,v 1.1 2006/03/20 12:57:48 labot Exp $
;
; S.Esposito, Dipartimento di Astronomia di Firenze (Italy).
; Please, send me a message if you modify this code.

;+
; NAME:
;       MAKE_ORTO_MODES
;
; PURPOSE:
;       This function returns a orthogonal base matrix from the input matrix.   
;
;
; CATEGORY:
;       Linear Algebra.
;
; CALLING SEQUENCE:
;
;       RESULT = MAKE_ORTO_MODES(INP_MATR)
;
; INPUTS:
;       INP_MATR: the influence  matrix,M,used to compute the new base orthogonal, B, matrix through
;                 the transformation B=M##Q, and  imposed the orthogonal property transpose(B)##B=I.
;
;
; OUTPUTS:
;       The orthogonal base matrix, B.
;
; EXAMPLE:
; MODIFICATION HISTORY:
;       Written by:     S. Esposito.
;       9 March 2006, modified by D.Zanotti(DZ)
;       Deleted the automatic transposition of the matrix when an error of input occurred.
;       Updated some line codes.
;-

function make_orto_modes, inp_matr
 
 eps = machar()
 size_inp=size(inp_matr)
 if size_inp[0] ne 2 then message, 'Error in input data, the input array must have two dimension.'

 if size_inp[1] gt size_inp[2] then message, 'Input matrix is give in wrong row-column order.'

 simm_matr = transpose(inp_matr) ## inp_matr
 cholesky, simm_matr ;;; sovrascrive la decomposizione su simm_matr
 elle = simm_matr
 svdc, elle, w,u,v, /DOUBLE

 dd = where(w gt eps.eps)
 wp= dblarr(n_elements(w))
 wp[dd] = 1/w[dd]
 sv = diagonal_matrix(wp)

 inv_elle = v ## sv ## transpose(u)
 out_matr = inp_matr ## (transpose(inv_elle))

 return, out_matr

end
