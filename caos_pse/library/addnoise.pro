; $Id: addnoise.pro,v 5.4 2012/08/03 Andrea La Camera $
;+
; NAME:
;    addnoise
;
; PURPOSE:
;    this lib-routine computes the various contributions of noise
;    in an astronomical image.
;
; CATEGORY:
;    library routines
;
; CALLING SEQUENCE:
;    noisy_image = addnoise(input_image,           $
;                           PHOT_NOISE=phot_noise, $
;                           SIGMA_DARK=sigma_dark, $
;                           DELTA_T=delta_t,       $
;                           EXODARK=exodark,       $
;                           GAIN_L3CCD=gain_l3ccd, $
;                           FFOFFSET=ffoffset,     $
;                           SIGMA_RON=sigma_ron,   $
;                           POSITIVE=positive,     $
;                           OUT_TYPE=out_type      )
;
; INPUTS:
;    input_image  = npx*npy 2D array [INTEGER or LONG or FLOAT or DOUBLE]
;
; OPTIONAL INPUTS:
;    none.
;
; KEYWORD PARAMETERS:
;    PHOT_NOISE= "Add" photon noise to the image ?
;    SIGMA_DARK= Dark-current noise rms [e-/s].
;    DELTA_T   = Time-exposure [s].
;    EXODARK   = Exotic dark-current noise (EMCCD case) [e-].
;    GAIN_L3CCD= EMCCD gain.
;    FFOFFSET  = Flat-field calibration residual rms. 
;    SIGMA_RON = RON rms [e-].
;    POSITIVE  = Force possible negative values of the img to zero after RON adding ?
;    OUT_TYPE  = Output type conversion (IDL type code) {1to15}
;                (BYTE=1, INT=2, LONG=3, FLOAT=4 [default], DOUBLE=5, etc.)
;
; OUTPUTS:
;    noisy_image = the resulting noisy image [LONG]
;
; OPTIONAL OUTPUTS:
;    none.
;
; COMMON BLOCKS:
;    noise_seed_block, seed_pn, seed_ron, seed_dark, seed_l3ccd, seed_xd, seed_ff
;
; SIDE EFFECTS:
;    none.
;
; RESTRICTIONS:
;    none.
;
; PROCEDURE:
;    none.
;
; EXAMPLES:
;    ...
;    common noise_seed_block, seed_pn, seed_ron, seed_dark, seed_l3ccd, seed_xd, seed_ff
;    seed_pn=1L & seed_ron=2L & seed_dark=3L & seed_l3ccd=4L & seed_xd=5L & seed_ff=6L
;    ...
;    noisy = addnoise(image, /PHOT_NOISE,                 $ ; photon noise
;                     SIGMA_DARK=1., DELTA_T=10.,         $ ; dark-current noise
;                     EXODARK=0.1, GAIN_L3CCD=1.012^591., $ ; EMCCD noises
;                     FFOFFSET=1E-3,                      $ ; flat-field calib. residual
;                     SIGMA_RON=10., POSITIVE=0           $ ; RON & subsequent positization
;                     OUT_TYPE=3                          ) ; output data type
;    ...
;
; RESTRICTIONS:
;    none
;
; MODIFICATION HISTORY:
;    program written: may 2007,
;                     Diyana Ab Kadir (LUAN) [diyana.abkadir@unice.fr],
;                     Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr].
;    modifications  : june 2008,
;                     Marcel Carbillet (Fizeau) [marcel.carbillet@unice.fr]:
;                    -briefly adapted for public distribution.
;                   : march 2011,
;                     Marcel Carbillet (Fizeau) [marcel.carbillet@unice.fr],
;                     Andrea La Camera (DISI) [lacamera@disi.unige.it]:
;                    -photon noise debugged + now optional,
;                    -EMCCD case completed (exotic dark component added),
;                    -flat-field calibration residuals added,
;                    -RON completed (clipping negative values now optional),
;                    -noisy image can be converted to an arbitrary IDL data type,
;                    -whole code enhanced.
;                  : August 2012,
;                    Andrea La Camera (DIBRIS) [andrea.lacamera@unige.it]:
;                   -Gaussian noise procedure debugged (removed "floor" conversion)
;                   -noisy image can be converted to INT,LONG,FLOAT,or DOUBLE.
;                    ROUND function is applied before converting integers.
;                    Other types generate an error/warning.
;
;-
;
function addnoise, image,                 $ ; original image (noise-free but with background added)
                   PHOT_NOISE=phot_noise, $ ; add photon noise to the input image ?
                   SIGMA_DARK=sigma_dark, $ ; dark-current noise rms (typically 0.1--1 e-/s ?)
                   DELTA_T=delta_t,       $ ; time exposure [s] - for dark noise calculation only
                   EXODARK=exodark,       $ ; exotic dark noise rms (EMCCD only, no time dependence)
                                            ; (typically 0.1 e-)
                   GAIN_L3CCD=gain_l3ccd, $ ; EMCCD (aka LLLCCD or L3CCD) gain
                                            ; (where gain = multiplication factor^nb of registry)
                                            ; (typically 1.012^591~1152.59)
                   FFOFFSET=ffoffset,     $ ; flat-field calibration relative residuals rms
                                            ; (typically 1E-3)
                   SIGMA_RON=sigma_ron,   $ ; RON rms (typically 5--10 e-)
                   POSITIVE=positive,     $ ; force possible negative values to zero after RON adding ?
                   OUT_TYPE=out_type        ; output type conversion (IDL type code) {1to15}
                                            ; (BYTE=1, INT=2, LONG=3, FLOAT=4 [default], DOUBLE=5, etc.)

common noise_seed_block, seed_pn, seed_ron, seed_dark, seed_l3ccd, seed_xd, seed_ff

npx = (size(image))[1] & npy = (size(image))[2]
noisy_image = image

;; Photon noise (Poisson)
if keyword_set(PHOT_NOISE) then begin
   idx=where((image GT 0.) AND (image LT 1E8),c)
                                            ; For values higher than 1E8, should one
   if (c NE 0) then for i=0l,c-1l do $      ; really has to worry about photon noise ?
      noisy_image[idx[i]]=randomn(seed_pn,POISSON=image[idx[i]],/DOUBLE)
endif

;; Additive dark-current noise (Poisson)
if keyword_set(SIGMA_DARK) then begin
   if not(keyword_set(DELTA_T)) then begin
      message, "dark-current noise calculation does need a time exposure value!!"
   endif else noisy_image+=randomn(seed_dark,npx,npy,POISSON=sigma_dark*delta_t,/DOUBLE)
endif

;; EMCCD noises
; Additive exotic (time-exposure-independent) dark-current noise (Poisson) 
if keyword_set(EXODARK) then noisy_image+=randomn(seed_xd,npx,npy,POISSON=exodark,/DOUBLE)

; Additive main EMCCD noise (Gamma)
if keyword_set(GAIN_L3CCD) then begin
   idx=where(image GT 0, c)
   if (c NE 0) then for i=0l,c-1l do $
      noisy_image[idx[i]]+=gain_l3ccd*randomn(seed_l3ccd,GAMMA=image[idx[i]],/DOUBLE)
;   noisy_image=long(temporary(noisy_image))
endif

;; Flat-field calibration residuals
if keyword_set(FFOFFSET) then begin
   ffres=randomn(seed_ff,npx,npy)*ffoffset+1.
   idx = where(ffres LE 0., c)
   if (c NE 0) then ffres[idx]=1.           ; Put possible<=0 ff values to 1.
   noisy_image*=ffres 
endif

;; Additive read-out noise (Gaussian)
if keyword_set(SIGMA_RON) then $
   noisy_image+=randomn(seed_ron,npx,npy,/NORMAL,/DOUBLE)*sigma_ron
   
; Force to zero negative values
if keyword_set(POSITIVE) then begin
   idx=where(noisy_image LT 0, c)
   if (c GT 0) then noisy_image[idx]=0.
endif

; Type conversion of the output
if keyword_set(OUT_TYPE) then begin
   if (out_type LE 0) OR (out_type GT 15) then begin
       message, 'OUT_TYPE must be in IDL type code {1to15}'
   endif
endif else out_type=4
   

case out_type of 
2: begin
   noisy_image_out=FIX(ROUND(noisy_image))
   message, "INT type may generate an overflow in your data.", /INFO
   end
3: noisy_image_out=LONG(ROUND(noisy_image))
4: noisy_image_out=float(noisy_image)
5: noisy_image_out=double(noisy_image)
else: begin
   message, 'Selected OUT_TYPE not yet implemented, '+$
            'the output has been converted to the default type [FLOAT]', /INFO
   noisy_image_out=float(noisy_image)
   end
endcase

return, noisy_image_out
end
