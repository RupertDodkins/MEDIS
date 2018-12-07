;$Id: pseudo_invert.pro,v 1.2 2006/03/09 13:45:38 riccardi Exp $
;
;+
; PSEUDO_INVERT
;
; returns the pseudo-inverted matrix of a given matrix. The pseudo-inverted matrix is computed
; using singular value decomposition method filtering out the singular values w having:
;  w < max(w)*eps
; If eps is not specified in the keywords, machine precision value is used.
;
; a_plus = PSEUDO_INVERT(a [,/DOUBLE][,EPS=eps][,W_VEC=w_vec][,U_MAT=u][,V_MAT=v] $
;                        [,INV_W=inv_w][,IDX_ZEROS=idx][,COUNT_ZEROS=count][,/VERBOSE])
;
; a = u##diagonal_matrix(w)##transpose(u)
; IDX_ZEROS: indexes of vector w related to singular vectors filtered out (-1 if none)
; COUNT_ZEROS: number of singular vectors filtered out
; INV_W: pseudo-inverted of diagonal(w) (equal to diagonal(1/w) if no vectors filtered out)
; /DOUBLE: force double precision computation
;
; HISTORY:
; 09/03/2006: written by A. Riccardi (AR), riccardi@arcetri.astro.it.
;
;-
function pseudo_invert, a, DOUBLE=double, EPS=eps, W_VEC=w, U_MAT=u, V_MAT=v, INV_W=inv_w $
                      , IDX_ZEROS=idx, COUNT_ZEROS=count, VERBOSE=verbose

la_svd, a, w, u, v, DOUBLE=double

if n_elements(eps) eq 0 then begin
    if size(a, /TNAME) eq "DOUBLE" or keyword_set(double) then begin
        eps = (machar(/DOUBLE)).eps
    endif else begin
        eps = (machar()).eps
    endelse
endif
if keyword_set(verbose) then print, "Singular values: Max=", strtrim(max(w),2) $
                                  , ", Min=", strtrim(min(w),2)
idx = where(w lt max(w)*eps, count)
if count ne 0 then begin
    inv_w = w
    inv_w[idx]=1.0
    inv_w = 1.0/inv_w
    inv_w[idx] = 0.0
endif else begin
    inv_w = 1.0/w
endelse

return, v ## diagonal_matrix(inv_w) ## transpose(u)
end
