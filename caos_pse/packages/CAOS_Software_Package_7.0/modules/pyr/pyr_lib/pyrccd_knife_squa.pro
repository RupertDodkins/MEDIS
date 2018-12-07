; $Id pyrccd_knife_squa.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;   pyrccd_knife_squa.pro
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
; TRANSMISSION MASK + SQUARE MODULATION ALGORITHM 
function pyrccd_knife_squa,size,dim,wave,l,px,m,pup,fov,pyrcc,iii

print,size(pup)
pupc=complexarr(size,size)
psf_sampling = size/dim
xx = (findgen(dim)-(dim-1)/2.)/dim*2.
xxx= rebin(xx, dim, dim)
yyy= transpose(xxx)

pas=l/(px/8)
; DIAPHRAGM MASK

if fov le size then mask_fov = makepupil(size,fov,0.,xc=(size-1)/2,yc=(size-1)/2) else $
mask_fov=1.
; TILT ADDED TO CENTER IMAGE ON TOP OF PYR (over 4 middle points)

tilt =  -1.*(zern(2,xxx,yyy) + zern(3,xxx,yyy))*2.*!pi/(8*psf_sampling)

pupc(size/2-dim/2:size/2+dim/2-1,size/2-dim/2:size/2+dim/2-1)=$
exp(complex(0.*pup,(wave+tilt)*pup))*pup

; ELECTRIC FIELD IN IMAGE PLANE

imc=shift(fft(shift(pupc,size/2,size/2),-1),size/2,size/2)

; pyrcc : images of pupils on the CCD after pyramid

pyrcc=dblarr(size,size,4)
; NO MODULATION: computation of 4 quadrants

if l eq 0 then begin

for k=0,3 do begin


pyrcc(*,*,k)=shift(abs(fft(shift(m(*,*,k)*imc*mask_fov,size/2,size/2),-1))^2.,size/2,size/2)

endfor

iii=abs(imc)^2.

endif else begin
; WITH MODULATION: computation of 4 quadrant, DISPLACEMENT ALONG
; MODULATION PATH WITH SHIFT OF INTEGER NB OF PIXEL

iii=dblarr(size,size)

print,'Vertical'

for j=-l,l,pas do begin

print,j

imcs=shift(imc,-l,j)

iii=iii+abs(imcs)^2

; integration during modulation
for k=0,3 do begin

pyrcc(*,*,k)=pyrcc(*,*,k)+shift(abs(fft(shift(m(*,*,k)*imcs*mask_fov,size/2,size/2),-1))^2.,size/2,size/2)

endfor


imcs=shift(imc,l,j)

iii=iii+abs(imcs)^2

for k=0,3 do begin

pyrcc(*,*,k)=pyrcc(*,*,k)+shift(abs(fft(shift(m(*,*,k)*imcs*mask_fov,size/2,size/2),-1))^2.,size/2,size/2)



endfor



endfor

print,'horizontal'

for i=-l+pas,l-pas,pas do begin

print,i

imcs=shift(imc,i,-l)

iii=iii+abs(imcs)^2

for k=0,3 do begin


pyrcc(*,*,k)=pyrcc(*,*,k)+shift(abs(fft(shift(m(*,*,k)*imcs*mask_fov,size/2,size/2),-1))^2.,size/2,size/2)


endfor



imcs=shift(imc,i,l)

iii=iii+abs(imcs)^2

for k=0,3 do begin


pyrcc(*,*,k)=pyrcc(*,*,k)+shift(abs(fft(shift(m(*,*,k)*imcs*mask_fov,size/2,size/2),-1))^2.,size/2,size/2)


endfor



endfor


;****************************************************************************
endelse

end