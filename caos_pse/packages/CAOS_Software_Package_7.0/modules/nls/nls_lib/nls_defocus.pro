; $Id: nls_defocus.pro,v 7.0 2016/04/29 marcel.carbillet $
;
;+
; NAME:
;    nls_defocus
;
; PURPOSE:
;    Function for NLS module, calculation of the defocus cube.
;
; CATEGORY:
;    NLS library routine
;
; CALLING SEQUENCE:
;    error = nls_defocus(defocus, $
;                        n_sub,   $
;                        dim,     $
;                        scale,   $
;                        pupil,   $
;                        alt_foc, $
;                        alt_Na,  $
;                        width,   $
;                        lambda   )
;
; INPUTS:
;    n_sub  :...
;    dim    :...
;    scale  :...
;    pupil  :...
;    alt_foc:...
;    alt_Na :...
;    width  :...
;    lambda :...
;
; OUTPUTS:
;    error: error code [long scalar].
;
; OUTPUTS included in call:
;    defocus: 3D map containing defocused map at different altitudes 
;             in the sodium layer.
;
; EXAMPLE:
;    ...
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: october 1998,
;                     Elise  Viard     (ESO) [eviard@eso.org],
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : march 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -lambda is now a vector, so i've introduced a dummy
;                     variable that takes the Na-band value of it.
;                   : december 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 2.0 (CAOS).
;                   : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;-
;
FUNCTION nls_defocus, defocus, $
                      n_sub,   $
                      dim,     $
                      scale,   $
                      pupil,   $
                      alt_foc, $
                      alt_Na,  $
                      width,   $
                      lambda

error = !caos_error.ok

delta_z = width/(n_sub-1)           ; distance between two successive sub-layer 
                                    ; in the Na layer [m].
defocus = dblarr(dim, dim, n_sub)
rr      = shift(dist(dim)*sqrt(2.)*scale, dim/2, dim/2) * pupil

dummy= lambda[n_elements(lambda)-1] ; choose the Na-band wavelength
FOR i = 0, n_sub-1 DO                                    $
   defocus[*,*,i] = - (                                  $
                      !Dpi *                             $
                      (alt_foc-width/2-alt_Na+i*delta_z) $
                      /dummy/alt_Na^2                    $
                      ) * rr^2      ; defocus calculation for each sub-layer of 
                                    ; the Na layer.

return, error
END 