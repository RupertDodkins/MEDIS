function fftshift, image, xs, ys, nonorm=nonorm, sqr=sqr

s=size(image)

if s(0) eq 2 then begin            ;<<< case 2D
  if N_PARAMS() ne 3 then $
    message,'2d array -> x and y shifts required'
;  if (s(1) ne s(2)) then message,'Array should be square'
  x=fltarr(s(1),s(2)) & for i=0,s(1)-1 do x(i,*)=float(i)-s(1)/2
  y=fltarr(s(1),s(2)) & for i=0,s(2)-1 do y(*,i)=float(i)-s(2)/2
  tilt=-(64.)*0.098174773*(xs*x/s(1)+ys*y/s(2))  
; << facteur de normalisation
  ct=shift(cos(tilt),s(1)/2,s(2)/2) & st=shift(sin(tilt),s(1)/2,s(2)/2)

  imf=fft(image,-1)
  ex=fft(complex(float(imf)*ct-imaginary(imf)*st,$
                 float(imf)*st+imaginary(imf)*ct),1)
  if keyword_set(sqr) then ex = abs(ex) else ex=float(ex)
  if not keyword_set(nonorm) and (total(image)*total(ex) lt 0.) then ex=-ex
endif
if s(0) eq 1 then begin            ;<<< case 1D
  if N_PARAMS() ne 2 then $
    message,'2d array -> x shift required'
  x=findgen(s(1))-s(1)/2
  tilt=-(64./s(1))*0.09817*xs*x
  ct=shift(cos(tilt),s(1)/2) & st=shift(sin(tilt),s(1)/2)
  imf=fft(image,1)
  ex=fft(complex(float(imf)*ct-imaginary(imf)*st,$
                 float(imf)*st+imaginary(imf)*ct),-1)
  if keyword_set(sqr) then ex = abs(ex) else ex=float(ex)
  if not keyword_set(nonorm) and (total(image)*total(ex) lt 0.) then ex=-ex
endif
if s(0) ne 1 and s(0) ne 2 then $
  print,'Can shift only vectors and arrays'

return,ex

end