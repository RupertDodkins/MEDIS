; $Id: mk_vector.pro,v 1.3 2003/06/10 18:29:26 riccardi Exp $

;+
;    MK_VECTOR
;
;    Result = MK_VECTOR(Sampling, Min, Max)
;
;    Returns a vector with Sampling elements from Min to Max.
;
;    KEYWORDS
;        
;        DOUBLE:     force double precision values
;
;        LOGARITMIC: if set, element of the vector are equispatiated on
;                    a logaritmic scale
;-
function mk_vector, sampling, min, max, double=double, logaritmic=logaritmic

	if (sampling eq 1) then return, min

	if (keyword_set(logaritmic)) then $
		if (keyword_set(double)) then $
			return, 10d0^(dindgen(sampling)/(sampling-1)*(alog10(max) $
				-alog10(min))+alog10(min)) $
		else $
			return, 10.0^(findgen(sampling)/(sampling-1)*(alog10(max) $
				-alog10(min))+alog10(min)) $
	else $
		if (keyword_set(double)) then $
			return, dindgen(sampling)/(sampling-1)*(max-min)+min $
		else $
			return, findgen(sampling)/(sampling-1)*(max-min)+min
end

