;+
; QP_EIGENPROBELM
;
; eigenval = qp_eigenproblem(M, C, K, right_eigenvec, left_eigenvec, inv_A, STATUS=status)
;
; computes complex eigenvalues and complex right and left eigenvectors
; of a quadratic pencil (visco-elastic system with damping non simultaneously
; diagonaliziable with mass and stiffness matrixes).
; Eigenvector are ordered by columns.
;
; Quadratic pencil:
;
; M##d^2x/dt^2 + C##dx/dt + K##x = 0
;
; setting:
;
; q=[[x],[dx/dt]]
;
; the system can be rewritten as:
;
; dq/dt+R##q=0
;
; where:
;
; A = [[C_mat, M_mat], $
;      [M_mat, zeros]]
;
; B = [[-K_mat, zeros], $
;      [ zeros, M_mat]]
;
; R = inverse(A)##B
;
; the function returns:
;
; eigenval: eigenvlues of R
; right_eigenvec: right eigenvectors of R:
;                 R##right_eigenvec=r_eigenvec##diagonal_matrix(eigenval)
; left_eigenvec:  left eigenvectors of R:
;                 transpose(left_eigenvec)##R=diagonal_matrix(eigenval)##transpose(left_eigenvec)
; inv_A:          inverse(A)
;
; HISTORY
;   July 2003: written by A. Riccardi, INAF-Osservatorio di Arcetri, ITALY
;              riccardi@arcetri.astro.it
;   Jun 2006: AR, more help written.
;+

function qp_eigenproblem, M_mat, C_mat, K_mat, r_mode, l_mode, inv_A, STATUS=flag

	n_dof=(size(M_mat))[1]

	la_svd, M_mat, w, u, v, /DOUBLE, STATUS=flag
	;print, "definition of mass matrix:", max(w)/min(w)

	wp = diagonal_matrix(1d0/w)
	inv_M_mat = transpose(v)##wp##u
	zeros = dblarr(n_dof, n_dof)
	id = double(identity(n_dof))

	A_mat = [[C_mat, M_mat], $
	         [M_mat, zeros]]

	B_mat = [[-K_mat, zeros], $
	         [ zeros, M_mat]]

	inv_A = invert(A_mat)
	;la_svd, A_mat, w, u, v, /DOUBLE, STATUS=flag
	;inv_A = v ## diagonal_matrix(1d0/w) ## transpose(u)

	R = inv_A ## B_mat

	s_res = la_eigenproblem(R, /DOUBLE, EIGENVEC=r_mode, LEFT_EIGENVEC=l_mode, STATUS=flag)
	l_mode = transpose(conj(l_mode))
;	l_mode = transpose(l_mode)
	r_mode = transpose(r_mode)

	return, s_res
end


