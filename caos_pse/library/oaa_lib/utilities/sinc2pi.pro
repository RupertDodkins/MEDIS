; $Id: sinc.pro,v 1.4 2003/11/18 16:31:02 riccardi Exp $

function sinc, x
;+
;
; sinc(x) = 1 if x eq 0
;         = sin(2*!PI*x)/(2*!PI*x) otherwise
;
; it's the Fourier transform of Pup(x)= 1 if x le 1
;                                       0 otherwise
;
; Aug 2003  A.R. fixed bug when x=[0]
;-
	temp = where(x eq 0, count)

	if count eq 0 then $
		result = sin(2*!PI*x)/(2*!PI*x) $
	else begin
		result = x
		result[temp] = 1
		temp = where(x ne 0, count)
		if count ne 0 then $
			result[temp] = sin(2*!PI*x[temp])/(2*!PI*x[temp])
	endelse

	return, result
end

