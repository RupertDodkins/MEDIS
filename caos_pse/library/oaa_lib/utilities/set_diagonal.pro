; $Id: set_diagonal.pro,v 1.3 2003/06/10 18:29:27 riccardi Exp $

;+
; SET_DIAGONAL
;
; SET_DIAGONAL, A, Diag
;
; INPUT
; A:	matrice quadrata nXn
; Diag:	vettore di lunghezza n (diagonale da settare in A)
;
; OUTPUT
; In uscita la matrice A ha per diagonale Diag
;-
pro set_diagonal, mat, diag

	on_error, 2
	s_mat = size(mat)

	case s_mat[0] of
		2: begin
			if s_mat(1) eq s_mat(2) and n_elements(diag) eq s_mat(1) then begin
				mat(lindgen(s_mat(1))*(s_mat(1)+1))=diag
				return
			endif
		end

		1: begin
			if s_mat(1) eq 1 and n_elements(diag) eq 1 then begin
				mat[0] = diag[0]
				return
			endif
		end

		0: begin
			if n_elements(diag) eq 1 then begin
				mat = diag[0]
				return
			endif
		end

		else: begin
		end
	endcase

	message, "Wrong format of input data"
end
