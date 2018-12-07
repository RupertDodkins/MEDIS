; $Id: sha_test.pro,v 7.0 2016/04/21 marcel.carbillet$
; sha_test: programme for the ATM module
; july 1998: written (Marcel Carbillet, OAA)
; (see psg and sha_test_gui helps)

;;; integrand: sub-routine of sha_test ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

function integrand, freq

; gives the integrand for qromo

common sha_test_block, L0in, len

spectrum = (1/L0in^2 + freq^2)^(-11/6.)
                                     ; von Karman/Kolmogorov spectrum
struc = freq*spectrum*(1-beselj(!pi*freq*len,0))
                                     ; integrand expression
return, struc                        ; back to integration fct.
end

;;; sha_test: main routine ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pro sha_test, alpha, beta, nsha, length, L0=L0

; computes the ratio alpha[n] between theoretical structure function
; and simulated one for a given FFT screen length, where n
; is the number of will-be-added sub-harmonics.
; in case of von Karman model (L0 finite), it computes also the ratio
; beta[n] between theoretical power and simulated one.

common sha_test_block, L0in, len

if not(keyword_set(L0)) then L0 = !VALUES.F_INFINITY
L0in = L0                            ; wavefront outer-scale [m],
                                     ; this imply also a PSD model:
                                     ; L0=Infinity => Kolmogorov,
                                     ; L0=finite number => von Karman.
alpha = fltarr(nsha+1)               ; str.fct ratio[nsha+1] array
beta  = fltarr(nsha+1)               ; power ratio[n] array

;;; compute alpha[n]:

len   = length                       ; screen length
bound = 1./len                       ; lower FFT screen frequency

struc_FFT = qromo('integrand', bound, /MIDEXP)
                                     ; FFT screen struc. fct
if (L0 ne !VALUES.F_INFINITY) then $
   struc_theo = qromo('integrand', 0, bound) + struc_FFT else $
   struc_theo = 7.565*len^(5/3.)     ; theoretical struc. fct

alpha[0] = struc_FFT/struc_theo      ; FFT screen struc. fct ratio

for n = 1, nsha do begin             ; cycle over number of sha

   alpha[n] = qromo('integrand', bound/3., bound)/struc_theo
   alpha[n] = alpha[n-1] + alpha[n]  ; FFT+SHA screen struc. fct ratio
   if (alpha[n]-alpha[n-1] le .001) then goto, stop_loop
   bound = bound/3.                  ; next lower SHA frequency

endfor                               ; end of cycle over sha

stop_loop: for nn = n+1, nsha do alpha[nn] = alpha[n]
                                     ; FFT+SHA screen struc. fct ratio
                                     ; (saturation)
alpha = round(1000*alpha)/1000.      ; actual precision is not better
                                     ; than 0.1%

;;; compute beta[n]:

if (L0 ne !VALUES.F_INFINITY) then for n = 0, nsha do $
   beta[n] = (1 + (L0/3.^n/length)^2)^(-5/6.)
                                     ; FFT+SHA screen power ratio
beta = round(1000*beta)/1000.        ; actual precision is not better
                                     ; than 0.1%
return                               ; back to calling program
end
