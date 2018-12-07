; $Id pyrccd_knife_circ.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;   pyrccd_knife_circ.pro
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
;   modifications  : may 2016,
;                    Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                   -adapted to Soft. Pack. CAOS 7.0.
;-
; TRANSMISSION MASK + CIRCULAR MODULATION ALGORITHM 
function pyrccd_knife_circ,size,dim,wave,l,px,m,pup,fov,pyrcc,iii

print,size(pup)
pupc=complexarr(size,size)
pupct=complexarr(size,size)
pyrcc=dblarr(size,size,4)
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

; NO MODULATION: computation of 4 quadrants (each one individually)
if l eq 0 then begin

for k=0,3 do begin

pyrcc(*,*,k)=shift(abs(fft(shift(m(*,*,k)*imc,size/2,size/2),-1))^2.,size/2,size/2)

endfor
iii=abs(imc)^2.

endif else begin
; WITH MODULATION: computation of 4 quadrants (each one individually)
iii=dblarr(size,size)


n_count = px

for j=0,n_count-1 do begin

print,j,n_count


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
for k=0,3 do begin

pyrcc(*,*,k)=pyrcc(*,*,k)+shift(abs(fft(shift(m(*,*,k)*imcs,size/2,size/2),-1))^2.,size/2,size/2)

endfor

endfor

endelse

end