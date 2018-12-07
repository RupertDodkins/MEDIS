;$Id: type2nbits.pro,v 1.1 2004/05/31 18:51:12 riccardi Exp $
;
;+
; TYPE2NBITS
;
; the function returns the number of bits per elements of input data.
;
; n_bits = type2nbits(data, [TYPE=type])
;
; KEYWORDS
;
;  TYPE:   optional named variable. On output contains the IDL code of the
;          data type of input.
;
; HISTORY
;   31 May 2004, written by A. Riccardi
;-

function type2nbits, var, TYPE=type

type = size(var, /TYPE)
case type of
    0:  bits=0  ;undefined
    1:  bits=8  ;byte
    2:  bits=16 ;int
    3:  bits=32 ;long
    4:  bits=32 ;float
    5:  bits=64 ;double
    6:  bits=64 ;complex
    7:  bits=-1 ;string
    8:  bits=-1 ;structure
    9:  bits=128;dcomplex
    10: bits=-1 ;pointer
    11: bits=-1 ;obj reference
    12: bits=16 ;uint
    13: bits=32 ;ulong
    14: bits=64 ;long64
    15: bits=64 ;ulong64
endcase
return, bits
end