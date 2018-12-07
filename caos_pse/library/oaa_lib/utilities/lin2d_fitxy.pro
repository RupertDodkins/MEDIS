; $Id: lin2d_fitxy.pro,v 1.3 2003/06/10 18:29:26 riccardi Exp $

;+
; NAME:
;     LIN2D_FITXY
;
;
; PURPOSE:
;     The procedure fits a 2-dim linear operator A described by the
;     following relationship:
;
;     y = A ## x
;
;     where A is a real LxN matrix and x and y are real NxM and LxM matrices
;     respectively. M is the number of measurements. N>1 and L>=1.
;     The M>N corresponds to a proper fitting case.
;     the columns of x and y are assumed to have the same
;     variance-covariance matrix Cx and Cy repsectively for and no covariance
;     between the columnes themselves.
;     The elements of Cx and Cy are related to covariances of x and y, by:
;
;     <x[i,j]*x[k,l]> = Cx[j,l]*I[i,k]
;     <y[i,j]*y[k,l]> = Cy[j,l]*I[i,k]
;
;     where I is the NxN identity matrix in the case of Cx and LxL in the case of Cy.
;
; CATEGORY:
;     Fitting Routines
;
;
; CALLING SEQUENCE:
;     lin2d_fit, x, y, A
;
;
; INPUTS:
;     x:     real NxM matrix. N is the dimension of the domain of A.
;              M is the number of measured sets
;
;     y:     real LxM matrix. L is the dimension of the image space of A.
;            M is the same as before.
;
;
; KEYWORD PARAMETERS:
;    COVAR_X:      real NxN symmetric matrix. Covariance of each
;                    column of x.
;
;    COVAR_Y:      real LxL symmetric matrix. Covariance of each
;                    column of y.
;
;    CHISQ:        named variable. Provides the sum of the squared errors.
;
;    DOUBLE:       set this keyword to force double precision calculation.
;
;    SIGMA:        named variable. Returns the standard deviation of
;                    the elements of A.
;
;    SINGULAR:     named variable. Contains the number of singular
;                    values equal to zero.
;
;    COVAR_FACTOR: named variable. Contains the NxN matrix F that can
;                    be used to compute the covariances for the
;                    elements of A:
;
;                    <A[i,j]*A[k,l]> = C[i,k]*F[j,l]
;
;    YFIT:         named variable. Contains the vector A ## x, where
;                    A is the fitted matrix.
;
;    EPS:          float or double scalar. Minimum relative pecision requested
;                    in the computation of the elements of the fitted matrix.
;                    If undefined 1e-3 is assumed.
;
; OUTPUTS:
;    A:            named variable. Real NxN matrix. It contains the result
;                    of the fitting.
;
;
; MODIFICATION HISTORY:
;
;       Thu Aug 20 18:04:57 1998, Osservatorio Astrofisico di Arcetri,
;                                 Adaptive Optics Group.
;
;-
pro lin2d_fitxy, x, y, A, COVAR_X=covar_x, COVAR_Y=covar_y, CHISQ=chisq $
                 , DOUBLE=double, SIGMA=sigma $
                 , SINGULAR=singular, COVAR_FACTOR=covar_factor $
                 , YFIT=yfit, EPS=eps, MAX_ITER=max_iter, CONVERGED=conv

;on_error, 2

if test_type(x, /REAL, DIM_SIZE=dimx) then begin
    message, "x must be a real matrix."
endif
if dimx[0] ne 2 then begin
    message, "x must be a 2-D matrix"
endif
if dimx[2] eq 1 then begin
    message, "x must have more then one row"
endif

N = dimx[2]                     ; number of rows of x

if n_elements(covar_x) ne 0 then begin
    if test_type(covar_x, /REAL, DIM_SIZE=dim) then begin
        message, "COVAR_X must be a real matrix"
    endif
    if total(dim ne [2,N,N]) ne 0 then begin
        ns = strtrim(N,2)
        ns = ns+"x"+ns
        message, "COVAR_X must be a square matrix. ("+ns+" in this case)"
    endif
    if total(extract_diagonal(covar_x) lt 0) ne 0 then begin
        message, "diagonal of COVAR_X must be greater then zero"
    endif
endif else begin
    lin2d_fit, x, y, A, COVAR_Y=covar_y, CHISQ=chisq $
      , DOUBLE=double, SIGMA=sigma $
      , SINGULAR=singular, COVAR_FACTOR=covar_factor $
      , YFIT=yfit
    conv=1B
    return
endelse

if test_type(y, /REAL, DIM_SIZE=dimy) then begin
    message, "y must be a real matrix."
endif
if dimy[0] gt 2 or dimy[0] eq 0 then begin
    message, "y must be a vector or a 2-D matrix"
endif
if dimx[1] ne dimy[1] then begin
    message, "x and y must have the same number of columns"
endif

if dimy[0] eq 1 then L=1 else L=dimy[2] ; number of rows of y


if n_elements(covar_y) ne 0 then begin
    if test_type(covar_y, /REAL, DIM_SIZE=dim) then begin
        message, "COVAR_Y must be a real matrix"
    endif
    if total(dim ne [2,L,L]) ne 0 then begin
        ns = strtrim(L,2)
        ns = ns+"x"+ns
        message, "COVAR_Y must be a square matrix. ("+ns+" in this case)"
    endif
    if total(extract_diagonal(covar_y) lt 0) ne 0 then begin
        message, "diagonal of COVAR_Y must be greater then zero"
    endif
    covar_y_is_def=1B
endif else begin
    covar_y = covar_x[0]*fltarr(L,L)
    set_diagonal, covar_y, replicate(1.0,L)
    covar_y_is_def=0B
endelse

if n_elements(eps) eq 0 then begin
    eps=1e-3
endif else begin
    if test_type(eps, /REAL, N_EL=n_el) then begin
        message,"EPS must be real"
    endif
    if n_el ne 1 then message,"EPS must be a scalar"
    if eps le 0 then message,"EPS must be greater then 0"
endelse

if n_elements(max_iter) eq 0 then begin
    max_iter=10
endif else begin
    if test_type(max_iter, /INT, /LONG, N_EL=n_el) then begin
        message,"MAX_ITER must be integer"
    endif
    if n_el ne 1 then message,"MAX_ITER must be a scalar"
    if max_iter gt 0 then message,"MAX_ITER must be greater then 0"
endelse


lin2d_fit, x, y, A, COVAR_Y=covar_y, CHISQ=chisq, DOUBLE=double, SIGMA=sigma $
  , SINGULAR=singular, COVAR_FACTOR=covar_factor, YFIT=yfit

conv = 1B
for i=1,max_iter do begin
    covar = A ## covar_x ## transpose(A)
    if covar_y_is_def then covar=covar+covar_y

    lin2d_fit, x, y, new_A, COVAR_Y=covar, CHISQ=chisq, DOUBLE=double $
      , SIGMA=sigma $
      , SINGULAR=singular, COVAR_FACTOR=covar_factor, YFIT=yfit
    if total(abs(new_A-A) lt abs(eps*A)) eq long(L)*N then begin
        A = new_A
        return
    endif
    A = new_A
endfor

conv = 0B
message, /INFO, "Warning: Iteration method hasn't converged!"

end
