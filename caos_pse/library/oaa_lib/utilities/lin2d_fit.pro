; $Id: lin2d_fit.pro,v 1.4 2006/12/01 13:45:43 labot Exp $

;+
; NAME:
;     LIN2D_FIT
;
;
; PURPOSE:
;     The procedure fits a 2-dim (or 1-dim as a particular case)
;     linear operator A described by the following relationship:
;
;     y = A ## x
;
;     where A is a real LxN (L>=1,N>=2) matrix and x and y are real NxM and LxM
;     matrices respectively.
;     The M>N corresponds to a proper fitting case.
;     x is assumed without error and the columns of y are assumed to have
;     the same variance-covariance matrix C (LxL) and no covariance
;     between the columns themselves.
;     The elements of C are related to covariances of y, by:
;
;     <y[i,j]*y[k,l]> = C[j,l]*I[i,k]
;
;     where I is the MxM identity matrix and i,k are the column
;     indexes and j,l the row indexes of y following the IDL conventions.
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
;     x:     real NxM matrix. N is the number of columns of A.
;              M is the number of measured sets. Each set is stored
;              in a column of x.
;
;     y:     real LxM matrix. L is the number of rows of A.
;              M is again the number of measured sets. Each set is
;              stored in a column of y.
;
;
; KEYWORD PARAMETERS:
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
;                    elements of A (LxN):
;
;                    <A[i,j]*A[k,l]> = C[i,k]*F[j,l]
;
;    YFIT:         named variable. Contains the vector A ## x, where
;                    A is the fitted matrix.
;
;
; OUTPUTS:
;    A:            named variable. Real LxN matrix. It contains the result
;                    of the fitting.
;
;
; MODIFICATION HISTORY:
;
;       Thu Aug 20 18:04:57 1998, Osservatorio Astrofisico di Arcetri,
;                                 Adaptive Optics Group.
;       Feb 03 2000, A.Riccardi. The possibility to fit non-square
;                                matrices A is added.
;
;-

pro lin2d_fit, x, y, A, COVAR_Y=covar_y, CHISQ=chisq, DOUBLE=double $
  , SIGMA=sigma $
  , SINGULAR=singular, COVAR_FACTOR=covar_factor, YFIT=yfit

if test_type(x, /REAL, DIM_SIZE=dimx) then begin
    message, "x must be a real matrix."
endif
if dimx[0] ne 2 then begin
    message, "x must be a 2-D matrix"
endif
if dimx[2] eq 1 then begin
    message, "x must have more then one row"
endif


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
N=dimx[2]                       ; number of rows of x
M=dimx[1]                       ; number of columns of x and y
                                ; the fitted matrix has L rows and N columns

if n_elements(covar_y) ne 0 then begin
    if test_type(covar_y, /REAL, DIM_SIZE=dim) then begin
        message, "C must be a real matrix"
    endif
    if L eq 1 then begin
        if (dim[0] ne 0) and (total(dim ne [1,1]) ne 0) then begin
            message, "COVAR_Y must be a scalar in this case."
        endif
        if covar_y[0] lt 0 then begin
            message, "COVAR_Y must be greater then zero"
        endif
        lch = reform(covar_y, 1, 1)
        ilch = 1.0/lch
    endif else begin
        if total(dim ne [2,L,L]) ne 0 then begin
            ns = strtrim(N,2)
            ns = ns+"x"+ns
            message, "COVAR_Y must be a square matrix. ("+ns+" in this case)"
        endif
        if total(extract_diagonal(covar_y) lt 0) ne 0 then begin
            message, "diagonal of COVAR_Y must be greater then zero"
        endif
        lch = covar_y
        cholesky, lch
        ilch = invert(lch,status)
        if status ne 0 then begin
            message, "The matrix COVAR_Y is near to be singular" 
        endif
    endelse
endif else begin
    covar_y = reform(identity(L), L, L)
    ilch = covar_y
    lch = ilch
endelse
y_red = ilch ## y               ;y reduced in the metrics of the covariance

; force double to true if x or y is double
if not test_type(x[0,0]*y_red[0,0],/DOUBLE) then begin
    double = 1B
endif

svdc, transpose(x), w, u, v, DOUBLE=double

nw = n_elements(w)

eps = epsilon(DOUBLE=double)
idx = where(abs(w) lt eps*max(abs(w)), singular)
if singular eq n_elements(w) then begin
    message, "Rank of x matrix is zero!"
endif
; force the singular values of x near zero to be zero
if singular ne 0 then begin
    w[idx] = 0
endif

if keyword_set(double) then begin
    A_red = dblarr(N,L)
    wp = dblarr(nw,nw)
endif else begin
    A_red = fltarr(N,L)
    wp = fltarr(nw,nw)
endelse

; solve for the colums of transpose(A_red=ilch ## A)
; i.e. solve the system transpose(x)##transpose(A_red)=transpose(y_red)
for c=0,L-1 do begin
    bb=reform(y_red[*,c])
    A_red[*,c] = svsol(u,w,v,bb)
endfor
A = lch ## A_red

idx = where(abs(w) gt 0)
; computes the square of the pseudo-inverse of w
wp[idx,idx] = 1.0/w[idx]^2

; computes the matrix F
covar_factor = V ## wp ## transpose(V)

; computes the standard deviation of the elements of A
var_y = extract_diagonal(covar_y)
sigma = sqrt(transpose(var_y) ## extract_diagonal(covar_factor))

; computes the best fit
yfit = A ## x

; computes the chi square of the fit
chisq = total((ilch ## (y - yfit))^2)

end
