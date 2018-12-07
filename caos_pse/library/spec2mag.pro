; $Id: spec2mag.pro,v 5.0 2005/01/13 marcel.carbillet@unice.fr $
;+
; NAME:
;       spec2mag
;
; PURPOSE:
;       ...
;
; CATEGORY:
;       Utility
;
; CALLING SEQUENCE:
;       mag_band = spec2mag(spec_type, mag_V, band)
;
; INPUTS:
;       spec_type = spectral type of the object [STRING]
;       mag_V     = V-magnitude [FLOAT]
;       band      = band in which the magnitude is needed [STRING]
;
; OPTIONAL INPUTS:
;       none.
;
; KEYWORD PARAMETERS:
;
; OUTPUT:
;       band_mag = magnitude of the objetc for the desired band.
;
; OPTIONAL OUTPUTS:
;       none.
;
; COMMON BLOCKS:
;       none.
;
; SIDE EFFECTS:
;       none.
;
; RESTRICTIONS:
;       none.
;
; PROCEDURE:
;       none.
;
; EXAMPLE:
;       ...
;
; MODIFICATION HISTORY:
;    program written: october 1998,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : january 2005,
;                     Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr]:
;                    -2.5 (and not 2.512) for the Pogson law...
;
;-
;
function spec2mag, spec_type, mag_V, band, T_EFF=Teff, $
   SPEC_TAB=spec_tab, TEFF_TAB=Teff_tab

; spectral types and corresponding effective temperatures:

O_spec_tab = ["O5", "O7", "O9"]
O_Teff_tab = [38.0, 37.0, 31.9]*1e3

B_spec_tab = ["B0", "B1", "B2", "B3", "B5", "B6", "B7", "B8", "B9"]
B_Teff_tab = [30.0, 24.2, 22.1, 18.8, 16.4, 15.4, 14.5, 13.4, 12.4]*1e3

A_spec_tab = ["A0", "A1", "A2", "A3", "A5", "A7"]
A_Teff_tab = [10.8, 10.2, 9.73, 9.26, 8.62, 8.19]*1e3

F_spec_tab = ["F0", "F2", "F5", "F6", "F7", "F8"]
F_Teff_tab = [7.24, 6.93, 6.54, 6.45, 6.32, 6.20]*1e3

G_spec_tab = ["G0", "G2", "G5", "G8"]
G_Teff_tab = [5.92, 5.78, 5.61, 5.49]*1e3

K_spec_tab = ["K0", "K2", "K3", "K5", "K7"]
K_Teff_tab = [5.24, 4.78, 4.59, 4.41, 4.16]*1e3

M_spec_tab = ["M0", "M1", "M2", "M3", "M4", "M5", "M8"]
M_Teff_tab = [3.92, 3.68, 3.50, 3.36, 3.23, 3.12, 2.66]*1e3

spec_tab = [O_spec_tab, B_spec_tab, A_spec_tab, F_spec_tab $
   , G_spec_tab, K_spec_tab, M_spec_tab]

Teff_tab = [O_Teff_tab, B_Teff_tab, A_Teff_tab, F_Teff_tab $
   , G_Teff_tab, K_Teff_tab, M_Teff_tab]

; [ref.: K.R.Lang, Astrophysical Formulae, 2d Edition,
;        pp.564, Spinger-Verlag (1980)]

; effective temperature of desired spectral type

dummy=-1
repeat dummy=dummy+1 until (spec_tab[dummy] eq spec_type)
Teff = Teff_tab[dummy]

; magnitude in desired band

h = 6.626d-34                             ; Planck constant [Js]
c = 3d8                                   ; light velocity [m/s]
k = 1.38d-23                              ; Boltzmann cst [J/K]

dummy = n_phot(0., BAND='V',  LAMBDA=lambda_V,    E0=e0_V)
dummy = n_phot(0., BAND=band, LAMBDA=lambda_band, E0=e0_band)
                                          ; get lambdas and e0s
                                          ; for both bands
mag_band = mag_V - 2.5 *                        $
   alog10(                                      $
      e0_V/e0_band * (lambda_V/lambda_band)^5 * $
      (exp(h*c/lambda_V/k/Teff)-1) /            $
      (exp(h*c/lambda_band/k/Teff)-1)           $
      )                                   ; compute magnitude in
                                          ;desired band using Pogson
                                          ;and Planck laws, from V-mag.
return, mag_band                          ; back to calling program
end
