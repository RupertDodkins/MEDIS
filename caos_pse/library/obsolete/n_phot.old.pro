; $Id: n_phot.pro,v 1.1.1.1 2003/03/07 10:46:19 marcel Exp $
;+
; NAME:
;    n_phot
;
; PURPOSE:
;    this lib-routine computes from a source magnitude the corresponding
;    number of photons for a given band, a given surface and a given time
;    interval. this is returned together with the number of photons from
;    the sky background.
;    the choosen band can be either a Johnson one (from U to M, but also
;    a default Na-band), or a user-defined one (specifying the central
;    wavelength and the bandwidth).
;    the routine can also be used in order to get the tabuled bands, with
;    the corresponding central wavelengths, bandwidths, A0 0-mag. star
;    brightnesses, and sky background default magnitudes. in this case
;    the returned values for the source and the sky background nb of
;    photons is NaN.
;
; CATEGORY:
;    library routines
;
; CALLING SEQUENCE:
;    [nb_of_photons, background] = n_phot(mag,             $
;                                         BAND=band,       $
;                                         SURF=surf,       $
;                                         DELTA_T=delta_t, $
;                                         LAMBDA=lambda,   $
;                                         WIDTH=width      $
;                                         E0=e0            $       
;                                         BACK_MAG=back_mag)
;
; INPUTS:
;    mag  = magnitude [FLOAT]
;
; OPTIONAL INPUTS:
;    none.
;
; KEYWORD PARAMETERS:
;    BAND     = wavelength Johnson band or Na default band [STRING].
;    DELTA_T  = integrating time [s] [FLOAT], default is 1s.
;    SURF     = integrating surface [m^2] [FLOAT], default is 1m^2.
;    LAMBDA   = central wavelenght of the choosen band [m] [FLOAT].
;    WIDTH    = bandwidth of the choosen band [m] [FLOAT].
;    E0       = A0 0-magnitude star brightness in the choosen band,
;               [J/s/m^2/um] [FLOAT].
;    BACK_MAG = sky background default magnitude [FLOAT].
;
; OUTPUTS:
;    nb_of_photons = the computed source number of photons [DOUBLE]
;    background    = the computed sky background nb of photons [DOUBLE]
;
; OPTIONAL OUTPUTS:
;    none.
;
; COMMON BLOCKS:
;    none.
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
;    [1]: compute the number of photons coming from a 5-mag star
;         observed in V-band, with 8m-diameter telescope and an integration
;         time of 12s:
;
;         [nb_of_photons, background] = n_phot(5.,                $
;                                              BAND='V',          $
;                                              SURF=!PI*(8.^2)/4, $
;                                              DELTA_T=12.        )
;
;         returns:
;            nb_of_photons = 5.9521160e+10 photons
;            background    = 63581.948     photons
;
;    [2]: compute the same stuff but with a user-defined sky background
;         of 19.5-mag:
;
;         [nb_of_photons, background] = n_phot(5.,                $
;                                              BAND='V',          $
;                                              SURF=!PI*(8.^2)/4, $
;                                              DELTA_T=12.        $
;                                              BACK_MAG=19.5      )
;         returns:
;            nb_of_photons = 5.9521160e+10 photons
;            background    = 100549.18     photons
;
;    [3]: compute the same stuff but with a user-defined band of
;         central wavelength 0.54um and a narrow bandwidth of 0.01um:
;
;         [nb_of_photons, background] = n_phot(5.,                $
;                                              LAMBDA=5.4E-7,     $
;                                              WIDTH=1E-8,        $
;                                              SURF=!PI*(8.^2)/4, $
;                                              DELTA_T=12.        $
;                                              BACK_MAG=19.5      )
;         returns:
;            nb_of_photons = 6.5661736e+09 photons
;            background    = 11092.246     photons
;
;    [4]: get the sky background default magnitudes table:
;
;         [nb_of_photons, background] = n_phot(0.,                    $
;                                              BACK_MAG=back_mag_table)
;
;         returns:
;            nb_of_photons = NaN
;            background    = NaN
;            back_mag_table= [22.,21.,20.,19.,17.5,16.,14.,12.,10.,6.,23.5]
;
;    [5]: get the bands, central wavelengths, bandwidths, A0 0-mag. star
;         brightnesses, and sky background default magnitudes tables:
;
;         [nb_of_photons, background] = n_phot(0.,                     $
;                                              BAND=band_table,        $
;                                              LAMBDA=lambda_table,    $
;                                              WIDTH=width_table,      $
;                                              E0=e0_table,            $
;                                              BACK_MAG=back_mag_table )
;
;         returns:
;            nb_of_photons = NaN
;            background    = NaN
;            band_table    =
;[   "U",   "B",   "V",   "R",   "I",   "J",   "H",   "K",   "L",   "M",   "Na"]
;            lambda_table  =
;[3.6e-7,4.4e-7,5.5e-7,  7e-7,  9e-7,1.3e-6,1.7e-6,2.2e-6,3.4e-6,  5e-06,5.9e-7]
;            width_table   =
;[6.8e-8,9.8e-8,8.9e-8,2.2e-7,2.4e-7,  3e-7,3.5e-7,  4e-7,5.5e-7,   3e-7,  1e-8]
;            e0_table      =
;[4.4e-8,7.2e-8,3.9e-8,1.8e-8,8.3e-9,3.4e-9, 7e-10, 4e-10, 8e-11,2.2e-11,3.9e-8]
;            back_mag_table=
;[   23.,   22.,   21.,   20.,  19.5,   14.,  13.5,  12.5,    3.,     0.,   23.]
;
; RESTRICTIONS:
;    in the case that user-defined bandwidth (keyword WIDTH) and
;    wavelength (keyword LAMBDA) are set, it cannot extend beyond a
;    routine-defined band. otherwise the results (nb_of_photons and
;    background) are wrong.
;
; MODIFICATION HISTORY:
;    program written: october 1998,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : march 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -help completed.
;                    -background output stuff added.
;
;-
;
function n_phot, mag,             $
                 BAND=band,       $
                 SURF=surf,       $
                 DELTA_T=delta_t, $
                 LAMBDA=lambda,   $
                 WIDTH=width,     $
                 E0=e0,           $
                 BACK_MAG=back_mag

if not(n_elements(surf))    then surf    = 1.
if not(n_elements(delta_t)) then delta_t = 1.

; bands:
band_tab   = $
[ "U",  "B",  "V",  "R",  "I",  "J",  "H",  "K",  "L",  "M", "Na"]
; wavelength [m]:
lambda_tab = 1e-6 * $
[0.36, 0.44, 0.55, 0.70, 0.90, 1.25, 1.65, 2.20, 3.40, 5.00, .589]
; bandwidth [m]:
width_tab  = 1e-6 * $
[.068, .098, .089, .220, .240, .300, .350, .400, .550, .300, .010]
; A0 0-magnitude star brightness [J/s/m^2/um]:
e0_tab     = 1e-10* $
[435., 720., 392., 176., 83.0, 34.0, 7.00, 3.90, 0.81, 0.22, 392.]
; [ref.: P.Lena, Astrophysique : methodes physiques de l'observation,
;        pp.95--96, Coll. Savoirs Actuels, InterEd./CNRS-Ed. (1996)]
; [except Na-band (added)]

; default sky background magnitudes:
back_mag_tab = $
[ 23.,  22.,  21.,  20., 19.5,  14., 13.5, 12.5,   3.,   0.,  23.]

dummy=-1
if (n_elements(band)) then begin
   repeat dummy=dummy+1 until (band_tab[dummy] eq band)
                                          ; band
   if not(n_elements(lambda)) then lambda = lambda_tab[dummy]
                                          ; wavelength [m]
endif else if (n_elements(lambda)) then begin
   repeat dummy=dummy+1 until $
      (abs(lambda_tab[dummy]-lambda) le width_tab[dummy]/2.)
   band = band_tab[dummy]                 ; band
endif else begin                          ; if neither LAMBDA nor BAND
   band     = band_tab                    ;is set then return the bands,
   lambda   = lambda_tab                  ;lambdas, widths, A0 0-mag. star
   width    = width_tab                   ;brightnesses (e0) and default
   e0       = e0_tab                      ;sky background magnitudes.
   back_mag = back_mag_tab
   return, [!VALUES.F_NAN, !VALUES.F_NAN] ; NaN is returned as the nb of
                                          ;photons in this case.
endelse

if not(n_elements(width)) then width = width_tab[dummy]
                                          ; band-width [m]
if not(n_elements(back_mag)) then back_mag = back_mag_tab[dummy]
                                          ; sky background magnitude

e0 = e0_tab[dummy]                        ; A0 star 0-mag. brightness
                                          ;[J/s/m^2/um]
h = 6.626d-34                             ; Planck constant [Js]
c = 3d8                                   ; light velocity [m/s]
nb_of_photons = lambda*delta_t*surf*(width*1e6)*e0/(h*c) * 10^(-mag/2.5)
                                          ; source number of photons
background = lambda*delta_t*surf*(width*1e6)*e0/(h*c) * 10^(-back_mag/2.5)
                                          ; sky background nb of photons

return, [nb_of_photons, background]       ; back to calling program
end
