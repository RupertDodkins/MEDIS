;$Id: conv2bin.pro,v 1.3 2004/08/13 18:05:22 labot Exp $
;
;+
; CONV2BIN
;
; converts data in strings containing their binary representation
;
; str = conv2bin(data)
;
; str has the same dimentions as data. Dcomplex, objref, pointers and
; structures are not handled.
;
; HISTORY
;   31 May 2004, written by A. Riccardi (AR)
;   10 Aug 2004, AR
;     bug with no scalar input fixed.
;-

function conv2bin, var

nbits = type2nbits(var)
dim = size(var, /DIM)
case nbits of
    16: the_var = (dim[0] eq 0) ? uint(var,0)    : uint(var,0,dim)
    32: the_var = (dim[0] eq 0) ? ulong(var,0)   : ulong(var,0,dim)
    64: the_var = (dim[0] eq 0) ? ulong64(var,0) : ulong64(var,0,dim)
    else: message, "unsupported data type for convertion"
endcase

offset=(byte('0'))[0]
str = (dim[0] eq 0) ? "" : strarr(dim)
for i=0,nbits-1 do begin
    the_mod = byte(the_var mod 2)
    the_var = ishft(temporary(the_var), -1)
    if (dim[0] eq 0) then str = string(the_mod+offset)+str $
    else str = string(reform(the_mod+offset,[1,dim]))+str
endfor
return, str

end


