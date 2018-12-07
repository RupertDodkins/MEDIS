; $Id: test_lin2d.pro,v 1.3 2003/06/10 18:29:27 riccardi Exp $

N = 36
M = 1000L
seed=1L
S = 100L

A = 2*randomu(seed, N, N)-1
C = 2*randomu(seed, N, N)-1
var = randomu(seed, N)+0.5
xv = 2*randomu(seed, M, N)-1

yv = a ## xv

svdc, C, w, u, v

C = fltarr(N,N)
set_diagonal, C, var

C = V ## C ## transpose(V)
C = C/10.0
l = C
cholesky, l

yn = fltarr(M,N)
AS = fltarr(N,N,S)
for is=0L,S-1 do begin

    for im=0L,M-1 do begin
        yn[im,*] = randomn_covar(l,SEED=seed1)
    endfor

    y=yv+yn

    lin2d_fit, xv, y, A_fit, COVAR_Y=C, CHISQ=chisq, SIGMA=sigma $
      , SINGULAR=sing, COVAR_FACTOR=cf, YFIT=yfit

    AS[*,*,is]=A_fit
    if is mod 10 eq 9 then print,(is+1)
endfor


end
