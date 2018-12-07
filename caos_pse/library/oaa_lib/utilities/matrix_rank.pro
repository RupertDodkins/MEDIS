; $Id: matrix_rank.pro,v 1.2 2002/03/14 11:49:13 riccardi Exp $

function matrix_rank, m

on_error, 2

; computes the rank of the matrix m

if test_type(m, /FLOAT, /DOUBLE, DIM_SIZE=dims) then begin
	message, "Wrong input parameter type. The input must be a float or double."
endif

if dims[0] ne 2 then begin
	message, "Wrong input dimension. Input must be a 2-dim array"
endif

svdc, m, w, u, v

is_double = test_type(m, /FLOAT)

dummy=check_math(/PRINT)
ret = machar(DOUBLE=is_double)
dummy=check_math()

eps = double(ret.eps)

w = abs(w)
maxw = max(w)

dummy = where(w gt maxw*eps, rank)

return, rank

end

