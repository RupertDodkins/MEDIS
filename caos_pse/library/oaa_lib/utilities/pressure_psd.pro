; $Id: pressure_psd.pro,v 1.2 2002/12/11 18:39:09 riccardi Exp $
;+
; PRESSURE_PSD
;
; PSD of Dynamic wind pressure fluctuations. A Kaimal wind turbulrnce model is ; used.
;
; p_psd = pressure_psd(f [,z [,v10]] [,ROUGHNESS=z0] [,AIR_DENSITY=rho]
;                      [,STATIONARY_PRESSURE])
;
; f:      real-number scalar or vector. (input) Temporal frequency vector
;         in [Hz]
; z:      real-number, scalar. (optional input) See z in WIND_PSD function
; v10:    real-number, scalar. (optional input) See v10 in WIND_PSD function.
;
; p_psd:  real-number, same size of f. (output) Dynamic wind pressure [N/m^2]
;
; ROUGHNESS:  real-number, scalar. (optional input) See z0 in WIND_PSD function.
; AIR_DENSITY:real-number, scalar. (optional input) Air density in [Kg/m^3]
; STATIONARY_PRESSURE: Named variable. (optional output) Stationary value of
;                      wind pressure [N/m^2]
; 
; HISTORY
;  11 Dec 2002, written by A. Riccardi, INAF-OAA, Italy
;               riccardi@arcetri.astro.it
;-

function pressure_psd, f, z, v10, ROUGHNESS=z0, AIR_DENSITY=rho $
                       , STATIONARY_PRESSURE=q0

if n_elements(rho) eq 0 then rho=1.23d0

uPSD = wind_psd(f, z, v10, ROUGHNESS=z0, STATIONARY_SPEED=v)
q0 = 0.5d0*rho*v^2
return, (2d0*q0/v)^2*uPSD
end


