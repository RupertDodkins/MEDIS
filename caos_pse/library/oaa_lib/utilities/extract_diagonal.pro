; $Id: extract_diagonal.pro,v 1.4 2003/06/10 18:29:26 riccardi Exp $

;+
; EXTRACT_DIAGONAL
;
; Result = EXTRACT_DIAGONAL(A)
;
; INPUT
; A:	square matrix
;
; OUTPUT
; vector containg the diagonal elements of A matrix
;
; MODIFICATION HISTORY
;
; Written by: A. Riccardi, Osservatorio Astrofisico di Arcetri, ITALY
;-
function extract_diagonal, mat

	on_error, 2
	s_mat = size(mat)

	case s_mat[0] of
		2: begin
			if s_mat(1) eq s_mat(2) then begin
				return, mat(lindgen(s_mat(1))*(s_mat(1)+1))
			endif
		end

		1: begin
			if s_mat(1) eq 1 then begin
				return, mat
			endif
		end

		0: begin
			return, mat
		end

		else: begin
		end
	endcase

	message, "The input matrix must be square"
end

