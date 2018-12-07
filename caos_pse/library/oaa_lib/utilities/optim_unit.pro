; $Id: optim_unit.pro,v 1.2 2002/03/14 11:49:13 riccardi Exp $

function optim_unit, vec, str_unit, str_mult

	ofm = fix(alog10(abs(max(vec))))/3
	nstr = n_elements(str_unit)
	max_t = max(abs(vec))
	ranges = abs(alog10(max_t/str_mult) - 1.0)
	str_idx = (where(ranges eq min(ranges)))[0]

	return, str_idx
end
