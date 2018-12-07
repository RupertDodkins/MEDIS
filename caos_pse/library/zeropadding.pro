; $Id: zeropadding last version: 2012/03/22 Andrea La Camera $
;
;+
; NAME:
;       zeropadding
;
; PURPOSE:
;       To enlarge the size of an 1d/2d/3d array by using zero_padding. 
;       Final dimension(s) will be:
;          1d case -> dim1 
;          2d case -> dim1 x dim2 [If dim2 is not provided: dim1 x dim1.]
;          3d case -> dim1 x dim2 [The third dimension will not be changed.] 
;       Please note that dim1 and dim2 must be smaller than the input array size.
;       
; CATEGORY:
;       utility
;
; CALLING SEQUENCE:
;       result = zeropadding(arr, dim1, [dim2, [value=value]])
;
; INPUT:
;       arr          : initial array, can be 1D, 2D or 3D (cube of images)
;       dim1[,dim2]  : output dimension(s) 
;
; OPTIONAL INPUT:
;       value       : value of the extended boundary (default = 0)
;
; OUTPUT:
;       result      : the zero-padded array(s)
;
; ROUTINE MODIFICATION HISTORY:
;       routine written: March 2012,
;                        Andrea La Camera (DISI) [lacamera@disi.unige.it]
;       modifications  : 
;-


function zeropadding, arr, dim1, dim2, value=value
on_error,2

IF KEYWORD_SET(value) THEN ext_value=value ELSE ext_value=0
IF (N_ELEMENTS(dim2) EQ 0)  THEN dim2=dim1

ndim=size(arr, /N_DIM)
case ndim of 
0: begin
   ;CONSTANT --> ERROR!
   message, "Input array is not valid"
   end
1: begin
   ; 1D CASE 
   N=(size(arr))[1]
   out=make_array(dim1,type=(size(arr,/type)), value=ext_value)
   if dim1 LT N then message, "Output size must be greater than input size"
   if N mod 2 EQ 0 then begin ;EVEN CASE
      out[dim1/2-N/2:dim1/2+N/2-1]=arr
   endif else begin ;ODD CASE
      out[dim1/2-N/2:dim1/2+N/2]=arr
   endelse
   end
2: begin
   ; 2D CASE
   N=(size(arr))[1]
   M=(size(arr))[2]
   out=make_array(dim1,dim2,type=(size(arr,/type)), value=ext_value)
   if (dim1 LT N) OR (dim2 LT M) then $
        message, "Output size must be greater than input size"
   if (N mod 2 EQ 0) AND (M mod 2 EQ 0) then begin ;EVEN-EVEN CASE
      out[dim1/2-N/2:dim1/2+N/2-1, dim2/2-M/2:dim2/2+M/2-1]=arr
   endif
   if (N mod 2 EQ 1) AND (M mod 2 EQ 1) then begin ;ODD-ODD CASE
      out[dim1/2-N/2:dim1/2+N/2, dim2/2-M/2:dim2/2+M/2]=arr
   endif
   if (N mod 2 EQ 0) AND (M mod 2 EQ 1) then begin ;EVEN-ODD CASE
      out[dim1/2-N/2:dim1/2+N/2-1, dim2/2-M/2:dim2/2+M/2]=arr
   endif
   if (N mod 2 EQ 1) AND (M mod 2 EQ 0) then begin ;ODD-EVEN CASE
      out[dim1/2-N/2:dim1/2+N/2, dim2/2-M/2:dim2/2+M/2-1]=arr
   endif
   end
   
3: begin
   ; 3D CASE
   N=(size(arr))[1]
   M=(size(arr))[2]
   P=(size(arr))[3]
   out=make_array(dim1,dim2,P,type=(size(arr,/type)), value=ext_value)
   if (dim1 LT N) OR (dim2 LT M) then $
        message, "Output size must be greater than input size"
   if (N mod 2 EQ 0) AND (M mod 2 EQ 0) then begin ;EVEN-EVEN CASE
      for j=0,P-1 do out[dim1/2-N/2:dim1/2+N/2-1, dim2/2-M/2:dim2/2+M/2-1,j]=arr[*,*,j]
   endif
   if (N mod 2 EQ 1) AND (M mod 2 EQ 1) then begin ;ODD-ODD CASE
      for j=0,P-1 do out[dim1/2-N/2:dim1/2+N/2, dim2/2-M/2:dim2/2+M/2,j]=arr[*,*,j]
   endif
   if (N mod 2 EQ 0) AND (M mod 2 EQ 1) then begin ;EVEN-ODD CASE
      for j=0,P-1 do out[dim1/2-N/2:dim1/2+N/2-1, dim2/2-M/2:dim2/2+M/2,j]=arr[*,*,j]
   endif
   if (N mod 2 EQ 1) AND (M mod 2 EQ 0) then begin ;ODD-EVEN CASE
      for j=0,P-1 do out[dim1/2-N/2:dim1/2+N/2, dim2/2-M/2:dim2/2+M/2-1,j]=arr[*,*,j]
   endif
   end
else: message, "Only 1D/2D/3D arrays are supported..."
endcase

return, out
end
