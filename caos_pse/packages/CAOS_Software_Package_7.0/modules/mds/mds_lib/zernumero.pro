; $Id: zernumero.pro,v 7.0 2016/04/29 marcel.carbillet $
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