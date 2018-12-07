;+
; SVP
;
; computes the saturation vapour pressure over water in Pa.
; It is valid in the range 0-100C, it is but used beyond this
; range.
;
; svp = svp(t [, /KELVIN])
;
; t:     float scalar or vector. Temperature
;
; KEYWORDS:
;   KELVIN: if it is set, the input temperature is in Kelvin.
;           Default is Celtius degrees.
;
; HISTORY
;   2002: written by G. Brusa, CAAO Steward Obs., USA
;         gbrusa@as.arizona.edu
;-
function svp,t_inp,ICE=ice,KELVIN=kelvin
;t in Celsius
;Wexler's coefficients for saturation water pressure over water
; valid in the range 0-100 C but used beyond this range
if not keyword_set(kelvin) then t=t_inp+273.15 else t=t_inp
g=[-2.9912729e3, -6.0170128e3, 1.887643854e1, -2.8354721e-2, 1.7838301e-5, -8.4150417e-10, 4.4412543e-13, 2.858487]
k=[-5.8653696e3, 2.2241033e1, 1.3749042e-2, -3.4031775e-5,2.6967687e-8,6.918651e-1]
if keyword_set(ice) then return,exp(k##[[1./t],[replicate(1.0,n_elements(t))],[t],[t^2],[t^3],[alog(t)]]) $
	 else return,exp(g##[[1./t^2],[1./t],[replicate(1.0,n_elements(t))],[t],[t^2],[t^3],[t^4],[alog(t)]])
end