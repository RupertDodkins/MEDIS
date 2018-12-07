; $Id: zer_stuff.pro,v 7.0 2016/04/29 marcel.carbillet $
;
function zernumero, zn

j=0
for n=0,200 do begin
  for m=0,n do begin
    if (n-m) mod 2 eq 0 then begin   ; n-m even
      j=j+1
      if j eq zn then return,[n,m]
      if m ne 0 then begin
        j=j+1
        if j eq zn then return,[n,m]
      endif
    endif
  endfor
endfor

end

def=fltarr(dim,dim,nn)

def(*,*,0)=0.3*zernike(1)*pup

for k=1,nn-1 do begin
   nm = zernumero(k+1) & nm = nm(0) > 1
   print,k,nm
   def(*,*,k)=0.3*(zernike(k+1))*pup/float(nm)
endfor

; !?























