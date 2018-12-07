; $Id: atm_psg_fft.pro,v 7.0 2016/04/21 marcel.carbillet$
;+
; NAME:
; atm_psg_fft
;
; FFT phase screen generation.
; See atm_psg help.
;
; ROUTINE MODIFICATION HISTORY:
;    program written: february-april 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : february 2009,
;                     Marcel Carbillet (Fizeau) [marcel.carbillet@unice.fr]:
;                    -numerical precautions for Kolmogorov case clarified.
;
;-
;
function atm_psg_fft, dim, length, L0

common psg_seed_block, seed1, seed2

phase = (randomu(seed1,dim,dim)-.5) * 2*!PI  ; rnd uniformly distributed phase
                                             ; (between -PI and +PI)
rr = dist(dim)
if L0 eq !VALUES.F_INFINITY then rr[0,0] = 1.; avoid 1/infinity afterwards
                                             ; for Kolmogorov model
modul = (rr^2+(length/L0)^2)^(-11/12.)       ; vonKarman/Kolmogorov model
if L0 eq !VALUES.F_INFINITY then modul[0,0] = 0.
                                             ; put again modulus[0,0]=0
                                             ; for Kolmogorov model
phase_screen = sqrt(.0228)*dim^(5/6.)*fft(modul*exp(complex(0,1)*phase),/INV)
                                             ; complex FFT phase screen
return, phase_screen                         ; back to calling procedure
end