;$Id: conv2hex.pro,v 1.2 2004/07/13 09:53:24 riccardi Exp $
;
;+
; CONV2HEX
;
; converts data in strings containing their hexadecimal representation
;
; str = conv2hex(data)
;
; str has the same dimentions as data. Dcomplex, objref, pointers and
; structures are not handled.
;
; HISTORY
;   31 May 2004, written by A. Riccardi
;-

function conv2hex, var

nbits = type2nbits(var, TYPE=type)
dim = size(var, /DIM)
case nbits of
    8: begin
        the_var = (dim[0] eq 0) ? byte(var,0)    : byte(var,0,dim)
        fstr = "(Z2.2)"
    end

    16: begin
        the_var = (dim[0] eq 0) ? uint(var,0)    : uint(var,0,dim)
        fstr = "(Z4.4)"
    end

    32: begin
        the_var = (dim[0] eq 0) ? ulong(var,0)   : ulong(var,0,dim)
        fstr = "(Z8.8)"
    end

    64: begin
        the_var = (dim[0] eq 0) ? ulong64(var,0) : ulong64(var,0,dim)
        fstr = "(Z16.16)"
    end

    else: message, "unsupported data type for convertion"
endcase

if dim[0] eq 0 then begin
    return, string(the_var, FORMAT=fstr)
endif else begin
    return, reform([string(the_var, FORMAT=fstr)], dim, /OVER)
endelse
end


