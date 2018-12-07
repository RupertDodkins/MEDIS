; $Id: wind_psd.pro,v 1.2 2002/12/11 18:25:11 riccardi Exp $
;+
; WIND_PSD
;
; Kaimal Longitudinal Wind Turbulence: power spectral density (PSD) of wind
; speed fluctuations. The used formulation is valid for a few tens of meters
; from the ground (logarithmic profile of the stationary wind speed with
; respect to z)
;
; v_psd = wind_psd(f [, z [, v10]] [,ROUGHNESS=z0] [,STATIONARY_SPEED=v])
;
; f:      real-number scalar or vector. (input) Temporal frequency vector
;         in [Hz]
; z:      real-number, scalar. (optional input) Height from the ground [m].
;         Default value is 10.0m.
; v10:    real-number, scalar. (optional input) Stationary wind speed at 10m
;         from the ground [m/s]. Default value 10.0m/s.
; z0:     real-number, scalar. (optional input) roughness constant [m], 0.01-0.1m
;         for open grassland, 0.3-1.0m for forest and suburban areas.
;         Default value: 0.3m
;
; v_psd:  real-number, same size of f. (output) Wind speed PSD [N/m^2]
;
; STATIONARY_SPEED: named variable. (optional output) sationary wind speed at
;                   height z. [m/s]
;
; HISTORY
;
;  11 Dec 2002, written by A. Riccardi, INAF-OAA
;               riccardi@arcetri.astro.it
;-
function wind_psd, f, z, v10, ROUGHNESS=z0, STATIONARY_SPEED=v

k=0.4d0                         ; Von Karman constant
z10=10d0                        ; reference height
if n_elements(z0) eq 0 then z0=0.3d0
if n_elements(z) eq 0 then z=10d0
if n_elements(v10) eq 0 then v10=10d0

; stationary wind speed
v = v10*alog(z/z0)/alog(z10/z0)

; friction velocity
vf = k*v10/alog(z10/z0)

return, 200d0*(z*vf^2/v)/(1d0+50d0*f*z/v)^(5d0/3d0)
end
