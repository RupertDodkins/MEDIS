; $Id: positivization.pro, v 1.3 2012/03/22 andrea la camera$
;+
; NAME:
;   positivization
;
; PURPOSE:
;   This routine performs the POSITIVIZATION of the input array
;
; CATEGORY:
;
; CALLING SEQUENCE:
;   result = positivization(array, ZERO=zero)
;
; INPUTS: 
;   array - the input array
;
; OPTIONAL INPUTS:
;   none.
;           
; KEYWORD PARAMETERS:
;   ZERO  - positivization can operate both on negative values (set ZERO=0) and on
;           non-positive values (set ZERO=1, or use keyword /ZERO)
;
; OUTPUT:
;   result - The "positivized" array
;
; OPTIONAL OUTPUTS:
;   none.
;
; COMMON BLOCKS:
;   none.
;
; SIDE EFFECTS:
;   none.
;
; RESTRICTIONS:
;   none.
;
; CALLED NON-IDL FUNCTIONS:
;   none.
;
; EXAMPLE:
;   none.
;
; WRITTEN BY:
;         : month year ??
;           Gabriele Desidera' (DISI) [desidera@disi.unige.it]
;
; MODIFICATION HISTORY:
;         : August 2011,
;           Andrea La Camera (DISI) [lacamera@disi.unige.it]:
;          -added the header in the file with information on it.
;          -added a print/warning if >5% of the pixels are going to be changed.
;         : March 2012, 
;           Andrea La Camera (DISI) [lacamera@disi.unige.it]:
;          -eliminated input of dimensions (information is retrieved from array)
;          -extension to 1D and 3D cases (3D case is considered to be an array 
;          of several 2D images)
;          -general debugging 
;                  
;-


function positivization, x, ZERO=zero

on_error,2

ndim=size(x, /N_DIM)

out=x
if keyword_set(zero) then begin
   pos=where(double(out) le 0., count) ;treat non-positive pixels  (≤ 0)
endif else begin
   pos=where(double(out) lt 0., count) ;treat only negative pixels (< 0)
endelse

case ndim of 
1: begin ;1D CASE
     NN = (size(out))[1]
     if count gt 0 then begin
       out[pos]=0.
       for i=0L,count-1 do begin   ;check pixel by pixel
          posx=(pos[i] mod NN)
          xini=posx
          xfin=posx
          ;select small sub-array (containing the pixel)
          if xini gt 0 then xini=xini-1
          if xfin lt NN-1 then xfin=xfin+1
          ;select a region around current pixel
          temp=double(out[xini:xfin]) 
          pos1=where(temp gt 0.,count1)
          while (count1 eq 0) do begin  ; expand the region if all pixels are 0
             if xini gt 0 then xini=xini-1
             if xfin lt NN-1 then xfin=xfin+1
             temp=double(out[xini:xfin]) ;select the new region   
             pos1=where(temp gt 0.,count1)       ;check again
          endwhile
          ;replace 0 with the median value of the region
          out[posx]=median(temp[pos1])       
       endfor
       if (float(count) GE (float(NN)*0.05)) then begin
          num=round(float(count)*100./(float(NN)))
          message, "Warning! Too many pixels (about "+$
                   strtrim(num,1)+"%) have been changed...",/INFO
       endif
    endif   
end ; END OF 1D CASE
2: begin
    NN=(size(out))[1]
    MM=(size(out))[2]
    if count gt 0 then begin
       out[pos]=0.
       for i=0L,count-1 do begin   ;check pixel by pixel
          posx=(pos[i] mod NN)
          posy=(pos[i] / NN)
          xini=posx
          xfin=posx
          yini=posy
          yfin=posy
          ;select small sub-array (containing the pixel)
          if xini gt 0 then xini=xini-1
          if xfin lt NN-1 then xfin=xfin+1
          if yini gt 0 then yini=yini-1
          if yfin lt MM-1 then yfin=yfin+1  
          ;select a 3x3 region around current pixel
          temp=double(out[xini:xfin,yini:yfin]) 
          pos1=where(temp gt 0.,count1)
          while (count1 eq 0) do begin  ; expand the region if all pixels are 0
             if xini gt 0 then xini=xini-1
             if xfin lt NN-1 then xfin=xfin+1
             if yini gt 0 then yini=yini-1
             if yfin lt MM-1 then yfin=yfin+1  
             temp=double(out[xini:xfin,yini:yfin]) ;select the new region   
             pos1=where(temp gt 0.,count1)       ;check again
          endwhile
          ;replace 0 with the median value of the region
          out[posx,posy]=median(temp[pos1])       
       endfor
       if (float(count) GE (float(NN)*float(MM)*0.05)) then begin
          num=round(float(count)*100./(float(NN)*float(MM)))
          message, "Warning! Too many pixels (about "+$
                   strtrim(num,1)+"%) have been changed...",/INFO
       endif
    endif
end ;END OF 2D CASE
3: begin ;3D CASE
   P = (size(out))[3]
   for j=0, P-1 do begin
      dummy = out[*,*,j]
      if keyword_set(zero) then begin
         dummy=positivization(dummy, /ZERO)
      endif else begin
         dummy=positivization(dummy)
      endelse
      out[*,*,j] = dummy
   endfor
   end ;END OF 3D CASE
else: message, "WRONG INPUT ARRAY: only 1D/2D/3D arrays are supported..."
endcase
   
return,out

end
