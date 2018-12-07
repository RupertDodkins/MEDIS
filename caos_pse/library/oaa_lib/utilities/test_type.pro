; $Id: test_type.pro,v 1.2 2002/12/06 14:38:37 riccardi Exp $
;
;+
; NAME:
;       test_type
;
; PURPOSE:
;       test_type returns 1B if the type of the parameter var
;       is NOT equal to one of the types specified in the keywords.
;       Otherwise it returns 0B.
;
; CATEGORY:
;       Utility
;
; CALLING SEQUENCE:
;       err = test_type(var)
;
; INPUTS:
;       var:          variable to test.
;
; OPTIONAL INPUTS:
;       None.
;
; KEYWORD PARAMETERS:
;       BYTE:         if set test for a byte
;       INT:          if set test for an integer
;       LONG:         if set test for a longword integer
;       FLOAT:        if set test for a single precision floating point
;       DOUBLE:       if set test for a double precision floating point
;       COMPLEX:      if set test for a single precision complex
;       DCOMPLEX:     if set test for a double precision complex
;       STRING:       if set test for a string
;       STRUCTURE:    if set test for a structure
;       POINTER:      if set test for a pointer
;       OBJ_REF:      if set test for an object reference
;       UINT          if set test for an unsigned integer
;       ULONG         if set test for an unsigned longword integer
;       L64           if set test for a 64-bit integer
;       UL64          if set test for an unsigned 64-bit integer
;       UNDEFINED:    if set test for undefined
;
;       NOFLOATING:   if set tests for integer numbers, overriding
;                       the BYTE, INT, LONG, UINT, ULONG, L64 and UL64 keywords.
;       REAL:         if set tests for real numbers, overriding the BYTE, INT,
;                       LONG, UINT, ULONG, L64, UL64, FLOAT and DOUBLE keywords.
;       NOREAL:       if set tests for complex numbers, overriding
;                       the COMPLEX and DCOMPLEX keywords.
;       NUMERIC:      if set tests for any numeric data, overriding the BYTE,
;                       INT, LONG, UINT, ULONG, L64, UL64, FLOAT, DOUBLE,
;                       COMPLEX, DCOMPLEX, REAL, NOREAL, NOFLOATING keywords.
;       DIM_SIZE:     a named variable to receive a long array.
;                       Firt element: number of dimensions. Following
;                       elements: the number of elements for each dimension.
;                       The number of dimensions is 0 if var is a scalar,
;                       or is undefined.
;       N_ELEMENTS:   a named variable to receive a long scalar.
;                       The total number of elements.
;       TYPE:         a named variable to receive a long scalar.
;                       The type of the input (see SIZE)
;
; OUTPUTS:
;       err:          byte scalar. 0B if var match one of the
;                     requested types, 1B otherwise
;
; OPTIONAL OUTPUTS:
;       See keywords
;
; COMMON BLOCKS:
;       None.
;
; SIDE EFFECTS:
;       None.
;
; RESTRICTIONS:
;       None.
;
;
; PROCEDURE:
;       Use the SIZE function.
;
; EXAMPLE:
;       if test_type(var, /LONG, N_ELEMENTS=n_var) then $
;         message, "The variable is not a long"
;       if n_var ne 1 then $
;         message, "The variable must be a scalar"
;
; MODIFICATION HISTORY:
;       May 1998. Written by A. Riccardi (AR). INAF-OAA, Italy
;                 riccardi@arcetri.astro.it
;       Dic 2002. UINT, ULONG, L64 and UL64 keywords added.
;                 An error message added if an unknown data type code
;                 is found.
;-
function test_type, var, BYTE=byte, INT=int, LONG=long, FLOAT=float, $
                    DOUBLE=double, COMPLEX=complex, DCOMPLEX=dcomplex, $
                    STRING=string, STRUCTURE=structure, POINTER=pointer, $
                    OBJ_REF=obj_ref, UINT=uint, ULONG=ulong, L64=l64, UL64=ul64, $
                    UNDEFINED=undefined, DIM_SIZE=dim_size, $
                    N_ELEMENTS=n_elem, NOFLOATING=nofloat, REAL=real, $
                    NOREAL=noreal, NUMERIC=numeric, TYPE=var_type

dim_size = size(var)
var_type = dim_size[dim_size[0]+1]
n_elem = dim_size[dim_size[0]+2]
dim_size = dim_size[0:dim_size[0]]

if keyword_set(numeric) then begin
    real = 1B
    noreal = 1B
endif
if keyword_set(real) then begin
    nofloat = 1B
    float = 1B
    double = 1B
endif
if keyword_set(noreal) then begin
    complex = 1B
    dcomplex = 1B
endif
if keyword_set(nofloat) then begin
    byte = 1B
    int  = 1B
    long = 1B
    uint = 1B
    ulong= 1B
    l64  = 1B
    ul64 = 1B
endif

case var_type of

    0:  if keyword_set(undefined) then return, 0B
    1:  if keyword_set(byte) then return, 0B
    2:  if keyword_set(int) then return, 0B
    3:  if keyword_set(long) then return, 0B
    4:  if keyword_set(float) then return, 0B
    5:  if keyword_set(double) then return, 0B
    6:  if keyword_set(complex) then return, 0B
    7:  if keyword_set(string) then return, 0B
    8:  if keyword_set(structure) then return, 0B
    9:  if keyword_set(dcomplex) then return, 0B
    10: if keyword_set(pointer) then return, 0B
    11: if keyword_set(obj_ref) then return, 0B
    12: if keyword_set(uint) then return, 0B
    13: if keyword_set(ulong) then return, 0B
    14: if keyword_set(l64) then return, 0B
    15: if keyword_set(ul64) then return, 0B
    else: message, "Not supported data type"

endcase

return, 1B

end
