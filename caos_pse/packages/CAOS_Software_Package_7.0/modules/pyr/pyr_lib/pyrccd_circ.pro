; $Id pyrccd_circ.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;   pyrccd_circ.pro
;
; PURPOSE:
;   ...
;
; CALLING SEQUENCE:
;   ...
;
; OUTPUT:
;   ...
;
; COMMON BLOCKS:
;   ...
;
; SIDE EFFECTS:
;   ...
;
; RESTRICTIONS:
;   ...
;
; DESCRIPTION:
;   ...
;
; HISTORY:
;   program written: june 2001,
;                    Christophe Verinaud (OAA) [verinaud@arcetri.astro.it].
;   modifications  : october 2004,
;                    Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr]:
;                   -px-->px[0] line 43 because of a stupid new IDL6+ bug !
;                   -some useless print eliminated.
;                  : may 2016,
;                    Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                   -adapted to Soft. Pack. CAOS 7.0.
;-
;
; PHASE MASK + CIRCULAR MODULATION ALGORITHM 
function pyrccd_circ,size,dim,wave,l,px,m,pup,fov,pyrcc,iii

pupc=complexarr(size,size)
pupct=complexarr(size,size)
pyrc=dblarr(size,size)
psf_sampling = size/dim
xx = (findgen(dim)-(dim-1)/2.)/dim*2.
xxx= rebin(xx, dim, dim)
yyy= transpose(xxx)

; DIAPHRAGM MASK
if fov le size then mask_fov = makepupil(size,fov,0.,xc=(size-1)/2,yc=(size-1)/2) else $
mask_fov=1.

; TILT ADDED TO CENTER IMAGE ON TOP OF PYR (over 4 middle points)
tilt =  -1.*(zern(2,xxx,yyy) + zern(3,xxx,yyy))*2.*!pi/(8*psf_sampling)
pupc(size/2-dim/2:size/2+dim/2-1,size/2-dim/2:size/2+dim/2-1)=$
exp(complex(0.*pup,(wave+tilt)*pup))*pup

; ELECTRIC FIELD IN IMAGE PLANE
imc=shift((fft(shift(pupc,size/2,size/2),-1)),size/2,size/2)*mask_fov

; NO MODULATION: computation of 4 quadrants
if l eq 0 then begin

pyrc=shift(abs(fft(shift(exp(complex(0.,-1.*m))*imc,size/2,size/2),-1))^2.,size/2,size/2)
iii=abs(imc)^2.

endif else begin
; WITH MODULATION: computation of 4 quadrant

iii=dblarr(size,size);PSF on top of pyramid (modulated)

n_count = px[0] ; nb of points to simulate the modulation

for j=0,n_count-1 do begin

alpha = 2.*!DPI/n_count

a1 = cos(alpha*j) 
a2 = sin(alpha*j)

; TILT ADDED FOR DISPLACING THE SPOT OVER PYRAMID ON MODULATION PATH
tiltt = l*(!DPI/2.)*(a1*zern(2,xxx,yyy) + a2*zern(3,xxx,yyy))/psf_sampling
pupct[size/2-dim/2:size/2+dim/2-1,size/2-dim/2:size/2+dim/2-1]=$
pupc[size/2-dim/2:size/2+dim/2-1,size/2-dim/2:size/2+dim/2-1]*$
exp(complex(0.*pup,tiltt*pup))*pup

; ELECTRIC FIELD IN IMAGE PLANE
imcs=shift((fft(shift(pupct,size/2,size/2),-1)),size/2,size/2)*mask_fov
iii=iii+abs(imcs)^2.

; 4 Quadrants
pyrc=pyrc+shift(abs(fft(shift(exp(complex(0.,-1.*m))*imcs,size/2,size/2),-1))^2.,size/2,size/2)

endfor

endelse

pyrcc = pyrc

end