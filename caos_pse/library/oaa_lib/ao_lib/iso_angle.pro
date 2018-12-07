; $Id: iso_angle.pro,v 1.3 2003/06/10 18:29:23 riccardi Exp $

;+
;    ISO_ANGLE
;
;    Return = ISO_ANGLE(Wl)
;
;    return isoplanatic angle (in rad) for turbulence profile CN2 at
;    wavelenth Wl (in m).
;-
function iso_angle, wl
	common cn2_momentum_block, order
	common cn2_block, cn2_settings

	order=5d0/3d0

	return, (2.91d0*(2d0*!dpi/wl)^2* $
		qromlog('cn2_momentum', 1d-3, cn2_settings.max_height))^(-3d0/5d0)
end

