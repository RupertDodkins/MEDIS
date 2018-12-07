function psf2fto2strehl, corr, ideal
;+
; output:
;   Strehl ratio computed from the PSF via FTO calculation.
;
; inputs:
; corr : aberrated (e.g. AO-corrected) PSF
; ideal: ideal PSF
;
; original version:
;    Marcel Carbillet (OAA) [marcel@arcetri.astro.it], mid 2001.
; march 2012:
;    Marcel Carbillet (Lagrange, UNS/CNRS/OCA) [marcel.carbillet@unice.fr]:
;    - minor modifications.
; september 2014:
;    Marcel Carbillet (Lagrange, UNS/CNRS/OCA) [marcel.carbillet@unice.fr]:
;    - simplification/debugging.
;-
np = long((size(corr))[1])
if np^2 ne n_elements(corr) then message, "image is not a squared one !!"
if n_elements(corr) ne n_elements(ideal) then message, "images are of different sizes !!"

if np/2 ne np/2. then print, "WARNING: images are made of an even linear nb of px !!"

strehl = total(float(fft(shift(corr ,np/2,np/2))),/DOUBLE) $
       / total(float(fft(shift(ideal,np/2,np/2))),/DOUBLE)

return, strehl
end