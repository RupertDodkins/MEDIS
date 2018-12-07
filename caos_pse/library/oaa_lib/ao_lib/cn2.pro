; $Id: cn2.pro,v 1.3 2003/06/10 18:29:23 riccardi Exp $

;+
;    CN2
;
;    Result = CN2(Z)
;
;    return structure constant value (in m^(-2/3)) at height z (in m) from
;    the pupil of imaging system.
;-
function cn2, z
	common cn2_block, cn2_settings
	return, call_function(cn2_settings.name, z, cn2_settings)
end

