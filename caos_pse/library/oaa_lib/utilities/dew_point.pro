;+
; DEW_POINT
;
; computes the dew and frost point
;
; t_point = dew_point(vp [, /FROST][, /KELVIN])
;
; vp:      float scalar or vector. Vapour pressure in hPa
;          vp = vp*(hr/100.0), where vp is saturation vapour
;          pressure in hPa and hr is relative humidity in
;          percentage (0-100)
; KEYWORDS:
;   FROST: if it is set, the frost point is returned. Default is
;          dew point.
;
;   KELVIN: if it is set, the dew/frost point is returned in
;           kelvin. Defaults is Celtius degrees.
;
; HISTORY
;   2002: written by G. Brusa, CAAO Steward Obs., USA
;         gbrusa@as.arizona.edu
;-
function dew_point,vp,FROST=frost,KELVIN=kelvin
;coefficients for the inverse from the vp calculation
cdew=[2.0798233e2,-2.0156028e1,4.6778925e-1,-9.2288067e-6]
ddew=[1,-1.3319669e-1,5.6577518e-3,-7.5172865e-5]
cfrost=[2.1257969e2,-1.0264612e1,1.4354796e-1,0.0]
dfrost=[1,-8.2871619e-2,2.3540411e-3,-2.4363951e-5]
if keyword_set(kelvin) then off=0.0 else off=-273.15
if keyword_set(frost) then $
	return,cfrost##[[replicate(1.0,n_elements(vp))],[alog(vp)],[alog(vp)^2],[alog(vp)^3]] $
	/(dfrost##[[replicate(1.0,n_elements(vp))],[alog(vp)],[alog(vp)^2],[alog(vp)^3]])+off $
	 else return,cdew##[[replicate(1.0,n_elements(vp))],[alog(vp)],[alog(vp)^2],[alog(vp)^3]] $
	 	/(ddew##[[replicate(1.0,n_elements(vp))],[alog(vp)],[alog(vp)^2],[alog(vp)^3]])+off
end