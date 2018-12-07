; $Id: stf_theo.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    stf_theo
;
; PURPOSE:
;    This routine computes the theoretical (von Karman: model = 'vKarma'
;    or Kolmogorov: model = 'Kolmog') structure function for a given range
;    of values between 0 and "length = scale*dim" [m], where "scale" is the
;    scale [m/px] and "dim" is the numerical dimension [px].
;
; SUB-ROUTINES:
;    vk_structure: function that compute the von Karman structure function
;                  for one value of the position xpos. This is done using the
;                  built-in IDL function qromo.
;    integrand   : function that gives the integrand for qromo.
;
; CATEGORY:
;    Analysis tool
;
; CALLING SEQUENCE:
;    stf_theo, model, scale, dim, r0in, L0in, vk_st
;
; NEEDED INPUTS:
;    model = the theoretical to consider.
;    scale = the scale in [m/px].
;    dim   = the numerical dimension over wich the structure function
;            calculation is computed (usually no more than N/2, where N
;            is the numerical dimension of the simulated phase screens, when
;            comparison with the theoretical model is needed).
;    r0in  = the Fried parameter [m].
;    L0in  = the wave-front outer scale [m].
;
; OUTPUT:
;    vk_st = the theoretical structure function.
;
; COMMON BLOCK:
;    data : that contains the Fried parameter "r0" and the wave-front
;           outer scale "L0" (common to "st_theo", "vk_structure" and
;           "integrand").
;    data2: that contains the position differencs for which the structure fct
;           is calculated (common only to "vk_structure" and "integrand").
;
; SUB-ROUTINES:
;    vk_structure: function that computes one point of the structure function,
;                  using qromo for the von Karman model.
;    integrand   : function that gives the integrand for qromo.
;
; PROGRAM MODIFICATION HISTORY:
;    program written: july 1998,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it],
;                     Simone Esposito  (OAA) [esposito@arcetri.astro.it].
;    modifications  : december 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;                    -help reorganized.
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;-
;
;;;;;;;;;;;;;;;;;;;;;;
function integrand, fx

; gives the integrand for qromo, called from "vk_structure".
; => for the von Karman model only.

common stf_theo_block,  r0, L0
common stf_theo_block2, xpos

spectrum = 0.0228*r0^(-5/3.)*(1/L0^2+fx^2)^(-11/6.)
                               ; von Karman spectrum
arg = 2 * !pi * fx * xpos      ; arg. of the bessel fct.
fun = fx * spectrum * (1 - beselj(arg,0))
                               ; integrand expression

return, fun                    ; back to integration fct.
end

;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
function vk_structure, xposin

; computes one point of the structure function using qromo.
; for the von Karman model only.

common stf_theo_block,  r0, L0
common stf_theo_block2, xpos

xpos    = xposin                ; the position [m]

vk_strf = 4*!pi*qromo('integrand', 0., /MIDEXP, EPS=1E-3)
                                ; integration

return, vk_strf                 ; back to main procedure
end

;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pro stf_theo, model, scale, dim, r0in, L0in, vk_st

common stf_theo_block, r0, L0

r0    = r0in                    ; Fried parameter [m]
L0    = L0in                    ; wavefront outer-scale [m]
vk_st = fltarr(dim)             ; structure function's init.

if model eq 1 then for i = 0, dim-1 do $
   vk_st[i] = vk_structure(i*scale)    $
else for i = 0, dim-1 do               $
   vk_st[i] = 6.88 * (i*scale/r0)^(5/3.)
                                ; structure fct. computation
return                          ; back to calling program
end