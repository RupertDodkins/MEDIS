; january 2010: Marcel Carbillet (Fizeau) [marcel.carbillet@unice.fr]
;
function psf2gauss2fwhm, corr, ideal

; compute the FWHM interms of lambda/D from the PSF via Gaussian fit
; corr : AO-corrected PSF
; ideal: ideal PSF

np = long((size(corr))[1])
if np^2 ne n_elements(corr) then message, "image is not a squared one !!"
if n_elements(corr) ne n_elements(ideal) then message, "images are of different sizes !!"
if np/2 ne np/2. then message, "images are made of an even linear nb of px !!"

dummy = gauss2dfit(ideal, sig_id)
dummy = gauss2dfit(corr , sig_ao)

fwhm = (sig_ao[2]+sig_ao[3])/(sig_id[2]+sig_id[3])

return, fwhm
end