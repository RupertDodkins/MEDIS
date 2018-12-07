PRO prep_shrink, size_ima, size_CCD, add, weight_lim

add =  lonarr(size_CCD^2, (ceil(size_ima/size_CCD)+2)^2)
weight_lim =  fltarr(2,size_CCD+1)
weight_lim[0,*] =  findgen(size_CCD+1) * size_ima/size_CCD - 0.5
weight_lim[1,*] =  (round(weight_lim[0,*]) > 0.) - weight_lim[0,*] + 0.5 

FOR i= 0, (fix(size_CCD)^2 -1) DO BEGIN

   xinf =  round( weight_lim[0,i MOD size_CCD] ) >  0.
   xsup =  round( weight_lim[0,(i MOD size_CCD)+1] ) >  0.
   yinf =  round( weight_lim[0,floor(i/size_CCD)] ) >  0.
   ysup =  round( weight_lim[0,floor(i/size_CCD)+1] ) >  0.
   ntot =  (xsup-xinf+1) * (ysup-yinf+1)
   temp =  fltarr(ntot)
   FOR j=1,(ysup-yinf-1) DO $
      temp[(j-1)*(xsup-xinf-1)] =  $
         xinf + 1 + findgen(xsup-xinf-1) + (yinf+j) * size_ima
   add[i,0:ntot-1] =  temp[*]

ENDFOR 

END

