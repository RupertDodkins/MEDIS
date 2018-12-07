; $Id: showvolume.pro,v 1.2 2002/03/14 11:49:14 riccardi Exp $

pro showvolume, vol, thresh, low=low

	s = SIZE(vol)
	IF s[0] NE 3 THEN begin
		print, "La matrice in input deve avere dimensione 3"
		return
	endif
	SCALE3, XRANGE=[0, S[1]], YRANGE=[0, S[2]],ZRANGE=[0, S[3]]
	IF N_ELEMENTS(low) EQ 0 THEN low = 0
	SHADE_VOLUME, vol, thresh, v, p, LOW = low

	TV, POLYSHADE(v,p,/T3D)
end
