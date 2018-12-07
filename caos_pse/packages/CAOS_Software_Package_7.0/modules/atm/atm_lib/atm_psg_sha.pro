; $Id: atm_psg_sha.pro,v 7.0 2016/04/21 marcel.carbillet $
;+
; NAME:
; atm_psg_sha
;
; SHA phase screens generation.
; See atm_psg help.
;
; MODIFICATION HISTORY
;    17 May 1999: M. Carbillet (OAA) [marcel@arcetri.astro.it]
;                 fixed error in the definition of the yy array
;    18 may 1999: A. Riccardi (OAA) [riccardi@arcetri.astro.it]
;                 The piston term of each generated subharmonic
;                 is now removed before adding it to the phase
;                 screen
;-
;
function atm_psg_sha, dim, length, L0, sha

common psg_seed_block, seed1, seed2

; addictional parameters

nsub = 3                                             ; null freq. px is divided
                                                     ; into "nsub*nsub" sub-pxs
null = nsub/2                                        ; null freq. px coord.

; initialize the low-frequencies screen

low_freq_screen = complexarr(dim,dim)                ; low-freq. screen init.

; freq (modulus), fx & fy (coordinates) "nsub*nsub" frequency arrays init.

freq_x   = rebin(findgen(nsub)-1, nsub, nsub)
freq_y   = rotate(freq_x, 1)
freq_mod = shift(dist(nsub), null, null)

; xx and yy "dim*dim" screens

xx = (rebin(findgen(dim),dim,dim))/dim
yy = transpose(xx)

; cycle over order of sub-division (depth) of the null freq. px

depth  = 0                                           ; depth initialization
repeat begin                                         ; cycle over depth
   depth = depth + 1

   phase = (randomu(seed2,nsub,nsub)-.5)             ; random uniformly
                                                     ;distributed phase
   freq_mod = temporary(freq_mod)/nsub
   freq_mod(null,null) = 1.                          ; freq.mod.sub-array
  
   freq_x = temporary(freq_x)/nsub
   freq_y = temporary(freq_y)/nsub                   ; freq.coord.sub-arrays

   modul = (freq_mod^2+(length/L0)^2)^(-11/12.)      ; Kolmog./vonKarman model
   modul(null, null) = 0.                            ; modulus(null freq.) = 0

   for i = 0, nsub-1 do begin                        ; cycle over sub-px
   for j = 0, nsub-1 do begin
       
      sh  = exp(2*!pi*complex(0,1)*(xx*freq_x[i,j]+yy*freq_y[i,j]+phase[i,j]))
      sh0 = complex(total(sh,/DOUBLE)/long(dim)^2)
      
      low_freq_screen = temporary(low_freq_screen) $
                      + 1./float(nsub)^depth * modul[i,j] * (temporary(sh)-sh0)
                                                     ; total sh phase screen
   endfor
   endfor                                            ; end of cycle ov. sub-px

endrep until (depth eq sha)                          ; end of cycle over depth

low_freq_screen = sqrt(.0228)*dim^(5/6.)*temporary(low_freq_screen)

return, low_freq_screen                              ; back to calling proc.
end