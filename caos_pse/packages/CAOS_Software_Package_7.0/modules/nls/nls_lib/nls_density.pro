; $Id: nls_density.pro,v 7.0 2016/04/29 marcel.carbillet $
;
;+
; NAME:
;    nls_density
;
; PURPOSE:
;    Function for NLS module, calculation of the sodium layer profile.
;
; CATEGORY:
;    NLS library routine
;
; CALLING SEQUENCE:
;    error = nls_density(density, $
;                        n_sub,   $
;                        width,   $
;                        off_axis )
;
; INPUTS:
;    n_sub   :...
;    width   :...
;    off_axis:... 
;                  
; OUTPUTS:
;    error: error code [long scalar].
;
; OUTPUTS included in call:
;    density: integrated density value for each sodium sub-layer. 
;
; EXAMPLE:
;    ...
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: october 1998,
;                     Elise  Viard     (ESO) [eviard@eso.org],
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : december 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 2.0 (CAOS).
;                   : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
FUNCTION nls_density, density, $
                      n_sub,   $
                      width,   $
                      off_axis

error   = !caos_error.ok

delta_z = width/(n_sub-1)         ; width of each sub-layer [m]
z       = (findgen(n_sub)*delta_z-width/2)/cos(off_axis)

sigma   = (width/2.)/3.

norm    = 5e9 * exp(-((1e-2/2+z)^2/(2. * sigma^2))) ; normalisation 
                                  ; of the density: the nominal peak 
                                  ; density is 5000 cm^-3 (cf table1,
                                  ; C.S. Gardner, proc. IEEE, vol 77,
                                  ; no 3, march 1889)
 
density1 = norm * exp( - ((z+delta_z/2)/sigma)^2 /2 )
density2 = norm * exp( - ((z-delta_z/2)/sigma)^2 /2 )

density  = (density1 + density2)/2 *delta_z ; the concentration [m^-2] is 
                                  ; determined by calculating the area
                                  ; under the gaussian density profile
return, error
end