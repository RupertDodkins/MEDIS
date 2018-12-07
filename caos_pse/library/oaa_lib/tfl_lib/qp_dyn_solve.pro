;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; QP_TF_SOLVE
;;;;;;;;;;;;
function qp_tf_solve, f

common qp_tf_solve_block, dyn_data

n_freq = n_elements(f)
n_dof = n_elements(dyn_data.s_res)/2
n_ft = (size(dyn_data.FC))[1]

iu = dcomplex(0d0, 1d0)
; force f to be an array because rebin needs that
ss = 2*!DPI*iu*f
;ss = 2*!DPI*iu*rebin([f], n_freq, 2*n_dof, /SAMP)

tf_sol = dcomplexarr(n_freq, 2*n_dof, n_ft)
for ift=0,n_ft-1 do begin
	for ir=0,2*n_dof-1 do begin
	    ;rm_reb = crebin(dyn_data.r_mode[ir,*], n_freq, 2*n_dof)
	    lmt_invA = transpose(dyn_data.l_mode[ir,*])##dyn_data.inv_A
	    lmt_rm = (transpose(dyn_data.l_mode[ir,*])##dyn_data.r_mode[ir,*])[0]
;	    tf_sol[*,*,ift] = tf_sol[*,*,ift] $
;	                    +(ss*(lmt_invA##dyn_data.FC[ift,*])[0]+(lmt_invA##dyn_data.FK[ift,*])[0]) $
;	                    /(lmt_rm*(ss-dyn_data.s_res[ir]))*rm_reb
	    tf_sol[*,ir,ift] = $
	                    (ss*(lmt_invA##dyn_data.FC[ift,*])[0]+(lmt_invA##dyn_data.FK[ift,*])[0]) $
	                    /(lmt_rm*(ss-dyn_data.s_res[ir]))
	endfor
endfor

return, tf_sol
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; QP_DYN_SOLVE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;+
; QP_DYN_SOLVE
;
; tf = qp_dyn_solve(freq, s_res, r_mode, l_mode, inv_A, FK_mat, FC_mat)
;
; returns the modal transfer function of the complex modes defined by the equation:
;
; M_mat##d^2x/dt^2 + C_mat##dx/dt + K_mat##x = FK_mat##c + FC_mat##dc/dt
;
; s_res, r_mode, l_mode and inv_A are returned by the qp_eigenproblem function:
;
; s_res = qp_eigenproblem(M_mat, C_mat, K_mat, r_mode, l_mode, inv_A)
;
; the system can be write as (see qp_eigenproblem for inv_A and R definition)
;
; dq/dt-R##q = inv_A##(FK##c+FK##dc/dt)
; where:
; q=[[x],[dx/dt]]
; FK=[[FK_mat],[zeros]]
; FC=[[FC_mat],[zeros]]
;
; q=r_mode##a (a= coeff column vector of decomposition of q over r_modes,
;              see qp_eigenproblem for r_mode definition)
;
; a[i]=transpose(l_mode[i,*])##q/(transpose(l_mode[i,*])##r_mode[i,*]))
;
; in the Laplace (L{f}(s)=Laplace transform of f(t)) space:
;
; (s*I-R)##r_mode##L{a}(s) = inv_A##(FK_mat+s*FC_mat)##L{c}(s)
;
; multipling on the right with transpose(l_mode)
;
; (s-diag(s_res))##diag(h)##L{a} = transpose(r_mode)##inv_A##(FK_mat+s*FC_mat)##L{c}(s)
; where: h[i] = transpose(l_mode[i,*])##r_mode[i,*]
;
; N=n_elements(s_res)=2*n_elements(x)
; M=n_elements(c)
;
; we have NxM transfer functions: tf[s,i,j]=L{a[0,i]}(s)/L{c[0,j]}(s)
;
; qp_dyn_solve returns tf[f,i,j] where s=2*!PI*complex(0,1)
;
; Note: c cannot be expanded in the r_mode basis
;
; HISTORY:
;   Jul 2003: written by A. Riccardi (AR), riccardi@arcetri.astro.it
;   Jun 2006: AR, help written
;-
function qp_dyn_solve, f, s_res, r_mode, l_mode, inv_A, FK_mat, FC_mat

	common qp_tf_solve_block, dyn_data

	sz = size(FK_mat)
	n_ft = sz[1]
	n_dof = sz[2]

	zeros = dblarr(n_ft,n_dof)
	FC = [[FC_mat],$
	      [ zeros]]
	FK = [[FK_mat],$
	      [ zeros]]

	dyn_data = $
	  { $
	  	inv_A: inv_A,  $
	  	FC:    FC,     $
	  	FK:    FK,     $
	  	s_res: s_res,  $
	  	l_mode:l_mode, $
	  	r_mode:r_mode  $
	  }

	return, qp_tf_solve(f)

end

