; $Id: fried_par.pro,v 1.3 2003/06/10 18:29:23 riccardi Exp $

;+
;    FRIED_PAR
;
;    Result = FRIED_PARAM(Wl)
;
;    returns Fried Parameter r_O (in m) at wavelength Wl (in m).
;    It uses CN2(Z) turbulence profile.
;-
function fried_par, wl, seeing=seeing

	common cn2_block, cn2_settings

	r0=(0.423d0*(2d0*!pi/wl)^2*qromlog('cn2', 1d-3, cn2_settings.max_height))^(-3d0/5d0)
	seeing=205265d0*(wl/r0)

	return, r0
end

