function makeDEFZernike, radial_order, dim, EPS=eps
; +
;
; use: DEF = makeDEFZernike(radial_order, dim, EPS=eps)
; makes a base of Zernike modes DEF of dim*dim px, centered on the
; px [(dim-1)/2,(dim-1)/2] a priori, and from radial order 1 (tip
; & tilt) and untill and including whole radial order radial_order.
; keyword EPS permits to consider also an obstruction ratio
; (0<EPS<1).
; makes use of the OAA Library routines zern.pro and zernumero.pro.
; makes use of the CAOS Library routine makepupil.pro.
; Marcel Carbillet (Lagrange - UNS/CNRS/OCA)
; [marcel.carbillet@unice.fr], March 2012.
; modifications:
; - May 2014, marcel.carbillet@unice.fr: adapted from original
; version with special pupil (for sake of comparison w/ PAOLA(C)).
;
; -

nmodes= ((radial_order+1L)*(radial_order+2L))/2-1L
xx    = (findgen(dim)-dim/2)/(dim/2-1L)
xxx   = rebin(xx, dim, dim)
yyy   = transpose(xxx)
DEF   = fltarr(dim, dim, nmodes)
if keyword_set(EPS) then eps=EPS else eps=0.
pupil = makepupil(dim, dim, eps, XC=(dim-1)/2., YC=(dim-1)/2.)
for i=0L, nmodes-1 do DEF[*,*,i] = zern(i+2L, xxx, yyy) * pupil * 1./(zernumero(i+2L))[0]

return, DEF   ; DEF[*,*,0]=tip, DEF[*,*,1] = tilt, etc.
end