; $Id: d0_par.pro,v 1.2 2002/03/14 11:03:01 riccardi Exp $
;+
; D0_PAR
;
;   This function computes the d0 parameter for a laser
;   focused at height h [m] at the wavelength wl [m].
;   The formula used for d0 is from Tyler.
;   Use cn2_setting procedure before use this function
;   to set the cn2 profile.
;
; d0 = d0_par(h, wl, EPS=epsm, MIN_ALT=min_alt, MAX_ALT=max_alt)
;
; HISTORY
;
; Written by A. Riccardi (AR)
; Osservatorio Astrofisico di Arcetri, ITALY
; riccardi@arcetri.astro.it
; Please, send me a message if you modify this code.
;
; 14 Mar 2002, AR
;  *QROMO is used instead of QROMB for the numerical
;   integration giving d0.
;  *The max height of the cn2 profile definition is
;   now read from the cn2_block common structure.
;-


function fa_weight, h
    common beacon, h_beacon, eps

    a=0.05701166152d0
    b=0.9179724217d0

    x=h/h_beacon
    chi=1-x

    return, a*(1d0+chi^(5d0/3d0))- $
            b*(6d0/11d0* $
                g_hyperg([-11d0/6d0, -5d0/6d0],[2d0],chi^2, EPS=eps)- $
           10d0/11d0* $
                chi*g_hyperg([-11d0/6d0, 1d0/6d0],[3d0],chi^2, EPS=eps)- $
            6d0/11d0*x^(5d0/3d0))
end


function cn2_fa, h

	return, cn2(h)*fa_weight(h)
end


function d0_par, h, wl, EPS=epsm, MIN_ALT=min_alt, MAX_ALT=max_alt

	common beacon, h_beacon, eps
	common cn2_block, cn2_settings

	if (n_elements(epsm) eq 0) then eps=1d-7 else eps=epsm
	if (n_elements(min_alt) eq 0) then min_alt=0d0
	add_upper = 0B
	if (n_elements(max_alt) eq 0) then begin
		add_upper = 1B
		if (h lt cn2_settings.max_height) then max_alt=h $
		else max_alt=cn2_settings.max_height
	endif

	h_beacon=h

	fa_factor = qromo('cn2_fa', min_alt, max_alt, EPS=eps)

	d0 = (2.0*!pi/wl)^(-6.0/5.0)*fa_factor^(-3.0/5.0)

	return, d0

end

