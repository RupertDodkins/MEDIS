; $Id: cn2_setting.pro,v 1.4 2003/06/10 18:29:23 riccardi Exp $

function hv27, z, cn2_settings
	zs=z+cn2_settings.altitude+cn2_settings.elevation ; height from sea-level
	zg=z+cn2_settings.elevation                       ; height from ground-level
	; HV-27 from Sandler (integrate from 3000m
	; to obtain the same results in the paper)
	return, cn2_settings.scale_f*2.7*(2.2d-23*(zs/1d3)^10 *exp(-zs/1d3) $
	                     +1.0d-16*exp(-zs/1.5d3))
end

function hvbl, z, cn2_settings
	zs=z+cn2_settings.altitude+cn2_settings.elevation ; height from sea-level
	zg=z+cn2_settings.elevation                       ; height from ground-level
	; Beckers: boundary layer contributing 50% at the sea-level. The boundary
	; layer follows the ground atitude with the same strength as at the sea-level
	return, cn2_settings.scale_f*((2.2d-23*(zs/1d3)^10*exp(-zs/1d3) $
	                          +1d-16*exp(-zs/1.5d3)) $
	                         +(2.33d-15 + 5.38d-17*(zg/1d3)^(-2d0/3d0)) $
	                         *exp(-zg/80d0))
end

function mhv, z, cn2_settings
	zs=z+cn2_settings.altitude+cn2_settings.elevation ; height from sea-level
	zg=z+cn2_settings.elevation                       ; height from ground-level
	; MHV from Parenti & Sasiela
	return, cn2_settings.scale_f*(8.61d-24*(zs/1d3)^10*exp(-zs/1d3) $
	                         +3.02d-17*exp(-zs/1.5d3) $
	                         +1.90d-15*exp(-zs/100d0))
end


;+
;    CN2_SETTING
;
;    CN2_SETTING, Which_profile
;
;        Which_profile: string, scalar. String containing the funcion
;                       name returning the Cn^2 profile. Three functions
;                       are pre-defined:
;                       "hv27" - Hufnagel-Valley 27 from Sandler et al., JOSAA,11,925(1994)
;                       "hvbl" - adapted from Beckers, ARAA,31,13(1993)
;                       "mhv"  - Modified Hufnagel-Valley from Parenti and Sasiela,
;                                JOSA,11,288(1994)
;                       See below for definition of a user-defined function
;
;    KEYWORDS:
;
;        ALTITUDE:      float, scalar. Site height above sea-level.
;                       If not defined, it is set to 0.0.
;
;        ELEVATION:     float, scalar. Height above ground-level of
;                       pupil of imaging system. Only for turbulence
;                       profiles with surface layers. If not defined,
;                       it is set to 0.0.
;
;        R0:            float, scalar. If defined, the profile is
;                       rescaled to give R0 as Fried Prameter at
;                       wavelength specified by WAVELENGTH keyword.
;
;        WAVELENGTH:    float, scalar. Wavelegth in meters (see R0).
;                       If undefined it is set to 0.55e-6m (V band).
;
;        NORMALIZE:     if set rescale turbulence profile to give a
;                       normalized turbulence profile (integral=1).
;
;        VERBOSE:       if set print turbulence profile infos.
;
; USER-DEFINED Cn^2 PROFILE FUNCTION
;
; function FUNC, z, cn2_settings
;                        ; zsl: height from the sea-level
;    zsl = z+cn2_settings.altitude+cn2_settings.elevation
;                        ; zg: height from the ground
;    zg = z+cn2_settings.elevation
;    cn2=....            ; usually a function of zsl (free atmosphere),
;                        ; zg (boundary layer) and z (dome seeing)
;    return, cn2_settings.scale_f*cn2 ; multiply to scale_f to allow r0 scaling
; end
;
; where z is a vector of height values from the pupil of the optical system in [m]
; and cn2 contains the the structure constant Cn^2 in [m^(-2/3)] at the corresponding
; heights. The structure cn2_settings is defined as follows:
;   cn2_settings.name:       string containing the name of the function of the active Cn^2 profile
;   cn2_settings.scale_f:    float. Scaling factor to match the requested r0
;   cn2_settings.altitude:   float. Height of the ground with respect to the sea level
;   cn2_settings.elevation:  float. Elevation of the pupil with respect to the ground level.
;                            It is useful when a boundary layer is defined.
;   cn2_settings.max_height: float. Maximum height from the sea level of the profile. Above it
;                            the Cn^2 profile is considered to be 0.
; Those fields are to be considered as read-only. The user cannot modified the cn2_setting structure
; inside the function. The structure is initialized by the cn2_setting function.
;
;-
pro cn2_setting, which_profile, normalize=normalize, verbose=verbose $
                 , wavelength=wl, elevation=elev, altitude=alt, r0=r0 $
                 , max_height=max_h

; r0 in metri a 0.55 micron
; alt altezza del sito dal livello del mare in m

common cn2_block, cn2_settings

cn2_settings = $
{ $
	name:       which_profile, $
	scale_f:    1d0, $
	altitude:   0d0, $ ; [m]
	elevation:  0d0, $ ; [m]
	max_height: 40d3 $ ; [m]
}


if (n_elements(elev) ne 0) then $
  cn2_settings.elevation=elev

if (n_elements(max_h) ne 0) then $
  cn2_settings.max_height = max_h

if (n_elements(alt) ne 0) then $
  cn2_settings.altitude=alt

if (n_elements(wl) eq 0) then $
  wl=0.55d-6

; scale_f is 1.0, now
if ((n_elements(r0) ne 0) or keyword_set(normalize))  then begin
    c11=nr_qromo('cn2', 0d0, cn2_settings.max_height)

    if (keyword_set(normalize)) then begin
        cn2_settings.scale_f=1d0/c11
        if (keyword_set(verbose)) then begin
            print, 'Profile function:', cn2_settings.name
            print, 'Scale factor [m^-2/3]:', cn2_settings.scale_f
            print, 'Altitude (from sea-level)[m]:', cn2_settings.altitude
            print, 'Elevation(from ground-l.)[m]:', cn2_settings.elevation
        endif
    endif else begin
        k2=(2d0*!pi/wl)^2
        rho=1d0/(r0^(5d0/3d0)*0.423d0*k2)

        cn2_settings.scale_f = rho/c11
    endelse
endif

if((not keyword_set(normalize)) and keyword_set(verbose)) then begin
    print, 'Profile function:', cn2_settings.name
    print, 'Scale factor [m^-2/3]:', cn2_settings.scale_f
    print, 'Altitude (from sea-level)[m]:', cn2_settings.altitude
    print, 'Elevation(from ground-l.)[m]:', cn2_settings.elevation
    print, 'At wavelength [m]:', wl
    print, '    r_0                    [m]:', fried_par(wl)
    print, '    Isoplanatic angle [arcsec]:', iso_angle(wl)*180d0/!DPI*3600d0
endif

end

