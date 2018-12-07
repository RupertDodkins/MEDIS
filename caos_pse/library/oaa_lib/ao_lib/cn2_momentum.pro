; $Id: cn2_momentum.pro,v 1.3 2003/06/10 18:29:23 riccardi Exp $

;+
;    CN2_MOMENTUM
;
;    Result = CN2_MOMENTUM(Z)
;
;    return CN2(Z)*Z^(Order)
;
;    where Order is set by COMMON BLOCK:
;        common cn2_momentum, order
;-
function cn2_momentum, z

	common cn2_momentum_block, order
	return, cn2(z)*z^order
end

