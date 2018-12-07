; $Id: photon_qe.pro,v 1.1.1.1 2003/03/07 10:46:32 marcel Exp $
; +
; NAME:
;   photon_qe 
;
; PURPOSE:
;    Computation of the detected number of photons from object and from
;    background.
;
; INPUTS:
;    flag       = flag for NGS (0) or LGS-monochromatic (1) cases
;    lambda_b   = source mean wavelength bands
;    width_b    = width of the source wavelength bands
;    lambda     = mean wavelength of the CCD sensitivity band
;    width      = camera sensitivity bandwidth
;    nb_phot    = number of photons incident per second on the telescope
;                 by the source in each of the defined bands (lambda_b)
;    background = number of photons/s/sampling point/arcsec^2
;                 due to the sky background in each band
;    qe         = quantum efficiency of the camera at each of the mean source
;                 band wavelength
; OUTPUTS:
;    phot_det   = number of photons that can be detected by the camera over its 
;                 bandwidth, per second, coming from the source, on the tel.
;    back_det   = idem coming from the sky background (per arcsec^2)
;
; SIDE EFFECTS: 
;    lambda_b, width_b, nb_phot and background are vectors.
;    The N-1 first elements define the continuous spectrum bands characteristics
;    The last elements corresponds to the LGS-monochromatic band
;
; MODIFICATION HISTORY:
;    program written: 1998/1999,
;                     Francoise Delplancke (ESO) [fdelplan@eso.org].
;    modifications  : november 1999--april 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -enhanced and adapted to version 2.0 (CAOS).
;-
;
FUNCTION photon_qe, flag,       $
                    lambda_b,   $
                    width_b,    $
                    lambda,     $
                    width,      $
                    nb_phot,    $
                    background, $
                    qe,         $
                    phot_det,   $
                    back_det

n_l = n_elements(lambda_b)

IF flag THEN BEGIN         ; LGS case (monochromatic narrow band)
                           ;=====================================
                           ; to compute the source nb of detected photons use
                           ; only the info. of the last element of each vector
                           ; (which is, by definition, the monochromatic band 
 
   IF (lambda_b[n_l-1]-width_b[n_l-1]/2.) GE (lambda+width/2.) OR $
      (lambda_b[n_l-1]+width_b[n_l-1]/2.) LE (lambda-width/2.) $
   THEN BEGIN
      print, 'SHS ERROR : '
      print, 'sensor optical bandpass not adapted to the LGS'
         ; the camera sensitivity bandwidth does not cover the source spectrum
      return, !caos_error.shs.bad_wl_band
   ENDIF

   phot_det =  nb_phot[n_l-1] * qe[0] / width_b[n_l-1] $
               * (  min([lambda+width/2.,lambda_b[n_l-1]+width_b[n_l-1]/2.]) $
                  - max([lambda-width/2.,lambda_b[n_l-1]-width_b[n_l-1]/2.]) )

   ; the background is defined on the broad bands
   ; use then only the n_l-1 first elements of the vectors

   lambda_b   =  lambda_b[0:n_l-2]
   width_b    =  width_b[0:n_l-2]
   background =  background[0:n_l-2]

   bands = where( ( (lambda_b-width_b/2.) GE (lambda-width/2.) ) AND $
                  ( (lambda_b+width_b/2.) LE (lambda+width/2.) ), $
                  count)
      ; bands which are completely covered by the WFS bandwidth

   IF count EQ 0 THEN BEGIN
      ; no bands are completely covered
      t_band =  where( ( ( (lambda-width/2.) GE (lambda_b-width_b/2.) ) AND  $
                         ( (lambda-width/2.) LT (lambda_b+width_b/2.) ) ) OR $
                       ( ( (lambda+width/2.) GE (lambda_b-width_b/2.) ) AND  $
                         ( (lambda+width/2.) LT (lambda_b+width_b/2.) ) ),   $
                       t_count )
      CASE t_count OF
      0: BEGIN
         ; in principle the program cannot pass by here !!
         print, 'SHS ERROR :'
         print, 'Unexpected problem. Call conceptor for debugging !!'
         stop
         return, !caos_error.unexpected
      END
      1: BEGIN
         ; the camera bandwidth is completely included in one source band
         back_det =  background[t_band[0]] * qe[t_band[0]] $
                     * width / width_b[t_band[0]]
         return, !caos_error.ok
      END
      2: BEGIN
         ; the camera bandwidth is "a cheval" on 2 source bands
         back_det =  background[t_band[0]] * qe[t_band[0]] $
                     * ( lambda_b[t_band[0]]+width_b[t_band[0]]/2. $
                         - (lambda-width/2.) ) $
                     / width_b[t_band[0]] $
                   + background[t_band[1]] * qe[t_band[1]] $
                     * ( (lambda+width/2.) $
                         - (lambda_b[t_band[1]]-width_b[t_band[1]]/2.) ) $
                     / width_b[t_band[1]]
         return, !caos_error.ok
      END
      ENDCASE 
   ENDIF

   n_bands =  (size(bands))[1]

   back_det =  total(background[bands] * qe[bands])         
       ; bands totally covered => photons completely integrated

   back_det =  back_det + $
               background[(bands[0]-1) > 0] * qe[(bands[0]-1) > 0] $
               * ( lambda_b[(bands[0]-1) > 0]+width_b[(bands[0]-1) > 0]/2. $
                   - (lambda-width/2.) ) $ 
               / width_b[(bands[0]-1) > 0]
       ; first band (partially covered)

   IF bands(n_bands-1) NE ((size(nb_phot))[1]-1) THEN $
   back_det =  back_det + $
               background[bands[n_bands-1]+1] * qe[bands[n_bands-1]+1] $
               * ( lambda+width/2. $
                   - ( lambda_b[bands[n_bands-1]+1] - $
                       width_b[bands[n_bands-1]+1]/2. ) ) $
               / width_b[bands[n_bands-1]+1]
       ; last band (partially covered)


ENDIF ELSE BEGIN 

   ; NGS/nat.object case with continuous spectrum
   ;=============================================

   ; the nb_phot and background are defined on the broad bands
   ; use then only the n_l-1 first elements of the vectors

   IF (lambda-width/2.) GT (lambda_b[n_l-2]+width_b[n_l-2]/2.) OR $
      (lambda+width/2.) LT (lambda_b[0]-width_b[0]/2.) THEN BEGIN
      print, 'SHS ERROR : '
      print, 'the sensor bandpass is not adapted to the source'
         ; the camera wavelength sensitivity band does not cover any 
         ; source wavelength band
      return, !caos_error.shs.bad_wl_band
   ENDIF 

   lambda_b   =  lambda_b[0:n_l-2]
   width_b    =  width_b[0:n_l-2]
   nb_phot    =  nb_phot[0:n_l-2]
   background =  background[0:n_l-2]

   bands = where( ( (lambda_b-width_b/2.) GE (lambda-width/2.) ) AND $
                  ( (lambda_b+width_b/2.) LE (lambda+width/2.) ), $
                  count)
      ; bands which are completely covered by the WFS bandwidth

   IF count EQ 0 THEN BEGIN
      ; no bands are completely covered
      t_band =  where( ( ( (lambda-width/2.) GE (lambda_b-width_b/2.) ) AND  $
                         ( (lambda-width/2.) LT (lambda_b+width_b/2.) ) ) OR $
                       ( ( (lambda+width/2.) GE (lambda_b-width_b/2.) ) AND  $
                         ( (lambda+width/2.) LT (lambda_b+width_b/2.) ) ),   $
                       t_count )
      CASE t_count OF
      0: BEGIN
         ; in principle the program cannot pass by here !!
         print, 'SHS ERROR :'
         print, 'Unexpected problem. Call conceptor for debugging !!'
stop
         return, !caos_error.shs.unexpected
      END
      1: BEGIN
         ; the camera bandwidth is completely included in one source band
         phot_det =  nb_phot[t_band[0]] * qe[t_band[0]] $
                     * width / width_b[t_band[0]]
         back_det =  background[t_band[0]] * qe[t_band[0]] $
                     * width / width_b[t_band[0]]
         return, !caos_error.ok
      END
      2: BEGIN
         ; the camera bandwidth is "a cheval" on 2 source bands
         phot_det =  nb_phot[t_band[0]] * qe[t_band[0]] $
                     * ( lambda_b[t_band[0]]+width_b[t_band[0]]/2. $
                         - (lambda-width/2.) ) $
                     / width_b[t_band[0]] $
                   + nb_phot[t_band[1]] * qe[t_band[1]] $
                     * ( (lambda+width/2.) $
                         - (lambda_b[t_band[1]]-width_b[t_band[1]]/2.) ) $
                     / width_b[t_band[1]]
         back_det =  background[t_band[0]] * qe[t_band[0]] $
                     * ( lambda_b[t_band[0]]+width_b[t_band[0]]/2. $
                         - (lambda-width/2.) ) $
                     / width_b[t_band[0]] $
                   + background[t_band[1]] * qe[t_band[1]] $
                     * ( (lambda+width/2.) $
                         - (lambda_b[t_band[1]]-width_b[t_band[1]]/2.) ) $
                     / width_b[t_band[1]]
         return, !caos_error.ok
      END
      ENDCASE 
   ENDIF

   n_bands =  (size(bands))[1]

   phot_det =  total(nb_phot[bands] * qe[bands])         
       ; bands totally covered => photons completely integrated

   phot_det =  phot_det + $
               nb_phot[(bands[0]-1) > 0] * qe[(bands[0]-1) > 0] $
               * ( lambda_b[(bands[0]-1) > 0]+width_b[(bands[0]-1) > 0]/2. $
                   - (lambda-width/2.) ) $ 
               / width_b[(bands[0]-1) > 0]
       ; first band (partially covered)

   IF bands(n_bands-1) NE ((size(nb_phot))[1]-1) THEN $
   phot_det =  phot_det + $
               nb_phot[bands[n_bands-1]+1] * qe[bands[n_bands-1]+1] $
               * ( lambda+width/2. $
                   - ( lambda_b[bands[n_bands-1]+1] - $
                       width_b[bands[n_bands-1]+1]/2. ) ) $
               / width_b[bands[n_bands-1]+1]
       ; last band (partially covered)

   back_det =  total(background[bands] * qe[bands])         
       ; bands totally covered => photons completely integrated

   back_det =  back_det + $
               background[(bands[0]-1) > 0] * qe[(bands[0]-1) > 0] $
               * ( lambda_b[(bands[0]-1) > 0]+width_b[(bands[0]-1) > 0]/2. $
                   - (lambda-width/2.) ) $ 
               / width_b[(bands[0]-1) > 0]
       ; first band (partially covered)

   IF bands(n_bands-1) NE ((size(nb_phot))[1]-1) THEN $
   back_det =  back_det + $
               background[bands[n_bands-1]+1] * qe[bands[n_bands-1]+1] $
               * ( lambda+width/2. $
                   - ( lambda_b[bands[n_bands-1]+1] - $
                       width_b[bands[n_bands-1]+1]/2. ) ) $
               / width_b[bands[n_bands-1]+1]
       ; last band (partially covered)

ENDELSE 

; back to calling program
return, !caos_error.ok
end 
