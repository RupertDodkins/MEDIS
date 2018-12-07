; $Id add_noise.pro,v 2.0 2000/01/01 marcel.carbillet$
; +
; NAME:
;    add_noise
;
; MODIFICATION HISTORY:
;    program written: june 1999,
;                     Francoise Delplancke (ESO) [fdelplan@eso.org].
;    modifications  : october 1999,
;                     Bruno Femenia (OAA) [bfemenia@arcetri.astro.it],
;                     and Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -bug "init.size_CCD<=>init.size_cam" fixed.
;                   : november 1999, Marcel Carbillet (OAA):
;                    -adapted to version 2.0 (CAOS).
; -
;
FUNCTION add_noise, image,             $
                    init,              $
                    seedwfs1=seedwfs1, $
                    seedwfs2=seedwfs2

IF init.noise THEN BEGIN 

   image =  temporary(image) + init.dark
      ; adds the dark noise
   image =  poidev ( temporary(image) , seed=seedwfs1) $
                + floor( randomn(seedwfs2, init.size_CCD, init.size_CCD) $
                         * sqrt(init.rnoise) )
      ; makes the Poisson distributed photon noise (gives a rounded number)
      ; adds the Gaussian random read-out noise of mean=0, rms=shack.ron
      ;      which is also "quantified" (no fractional number of electrons)

ENDIF ELSE BEGIN 
   image =  floor(temporary(image))
      ; quantification of the image
ENDELSE 

IF init.threshold GT 0. THEN $
   image = (temporary(image) - init.threshold) > 0. ELSE  image = temporary(image) > 0.
          ; application of the threshold

return, image

END 
