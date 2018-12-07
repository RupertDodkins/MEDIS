; $Id: atm_psg.pro,v 7.0 2016/04/21 marcel.carbillet $
;+
; NAME:
;   atm_psg
;
; PURPOSE:
;   This routine generates the phase screen, given the computing method --
;   Fast Fourier Transform Zernike polynomials, the atmospheric model for
;   the modulus of the phase screens, and the other physical and numerical
;   parameters further listed.
;   The two methods are explained here after:
;
;   +-----------------------------------------------------------------+
;   | (1) Fast Fourier transform (FFT) [+ sub-harmonics adding (SHA)] |
;   +-----------------------------------------------------------------+
;
;   In this case the phase screen generation (PSG) is computed assuming
;   either a von Karman modulus or a Kolmogorov one via FFT, with
;   compensation for the low-frequencies (if necessary) by means of SHA
;   [Lane et al., 1992].
;
;   Note that he low-frequencies compensation to be performed in this
;   routine can be tested before via the routine 'sha_test'. 
;
;   The generated FFT phase screens are initially complex arrays, and we
;   use both the real and imaginary parts of each of them as two
;   independent phase screens [Negrete-Regagnon, 1995]. We then have to
;   normalize each of the parts by a factor sqrt(2), for energy reasons.
;
;   The phase screens are scaled to 1 pixel/r0.
;
;   +-----------------------------------------------------------------+
;   | (2) Zernike polynomials (ZP) method: [+ recursive formula (RF)] |
;   +-----------------------------------------------------------------+
;
;   In this case the PSG is performed assuming only a Kolmogorov modulus,
;   and the dimensions of the phase screens are the pupil's ones.
;
;   These wave screens are changed into phase screens (by multiplying them
;   by a factor 2*!pi). Then they have to be scaled for the given value of
;   the ratio between the telescope diameter 'D'  and the Fried parameter
;   'r0' before to be used, by multiplying them by the factor (D/r0)^(5/6).
;
; CATEGORY:
;   Phase Screen Generation (PSG)
;
; CALLING SEQUENCE:
;   error = atm_psg(par, screens)
;
; INPUT:
;   par: parameter file coming from atm_gui.
;
; OUTPUT:
;   screen: the resulting phase screen.
;
; COMMON BLOCK:
;   psg_seed_block:
;
;   +---+ If 'FFT' is selected, it contains the seeds for the two
;   |(1)| phases: one for the FFT screen and one for SHA ones.
;   +---+ In common with 'atm_psg_fft' and 'atm_psg_sha'.
;
;   +---+ If 'Zer' is selected, only one seed (seed1) is used.
;   |(2)| In common with 'randomn_covar'.
;   +---+
;
; SUB-ROUTINES:
;   +---+ atm_psg_fft  = proc. that computes the FFT screen.
;   |(1)|
;   +---+ atm_psg+sha  = proc. that computes the additive sub-harmonics
;                        phase screen.
;
;   +---+ zer_screen  = proc. that computes the ZP phase screen.
;   |(2)|
;   +---+
;
; REFERENCES:
;   Lane R. G., Glindeman A. and Dainty J. C., 'Simulation of a Kolmogorov
;   Phase Screen', Waves in Random Media 2, 209--224, 1992.
;   Negrete-Regagnon P., 'Bispectral Imaging in Astronomy', PhD thesis,
;   Imperial College, UK, 1995.
;
; PROGRAM MODIFICATION HISTORY:
;   Written by Marcel Carbillet, OAA, 1998, but:
;   * FFT routine:      - originally written by Enrico Marchetti, ESO, 1997.
;                       - modified by Marcel Carbillet, OAA, 1997.
;   * SHA routine:      written by Marcel Carbillet, Simone Esposito
;                       and Armando Riccardi, OAA, 1998.
;   * Zernike routines: written by Armando Riccardi, OAA, 1997.
;
;   modifications: november 1999--april 2000,
;                  Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                 -enhanced and adapted to version 2.0 (CAOS).
;                : december 2000,
;                  Bruno Femenia (OAA) [bfemenia@arcetri.astro.it]:
;                 -Zernike part enhanced.
;
;-
;
FUNCTION atm_psg, par, screens, coeff

; parameters

screens = FLTARR(par.dim, par.dim, par.n_layers)
                                    ; screens = n_scre independent phase screens
error  = !caos_error.ok             ; error flag

IF (par.model EQ 0) THEN par.L0 = !VALUES.F_INFINITY

; program

IF (par.method EQ 0) THEN BEGIN     ; 'FFT+SHA' computing method

   FOR j = 0, (par.n_layers+1)/2-1 DO BEGIN
                                    ; cycle over nb of screens

      phase_screen = atm_psg_fft(par.dim, par.length, par.L0)
                                    ; comp. a "dim*dim" cplx FFT ph.screens

      IF (par.sha NE 0) THEN phase_screen = TEMPORARY(phase_screen) $
                             + atm_psg_sha(par.dim, par.length, par.L0, par.sha)
                                    ; compensate it IF necessary

      screens[*,*,2*j] = SQRT(2) * FLOAT(phase_screen)
                                    ; real part of cplx phase screens

      IF (2*j+1 LT par.n_layers) THEN $
         screens[*,*,2*j+1] = SQRT(2)*IMAGINARY(phase_screen)
                                    ; imaginary part of cplx phase screens

   ENDFOR                           ; END OF CYCLE OVER NB OF SCREENS

   coeff = 0                        ; not used in 'FFT+SHA' computing method

ENDIF ELSE BEGIN 

   IF (par.method EQ 1) THEN BEGIN  ; 'Zernike Pol.+RF' computing method

      rad_deg = par.zern_rad_degree
      j_modes = (rad_deg+1)*(rad_deg+2)/2-1
                                    ; -1 because we do NOT consider PISTON !!
      coeff   = FLTARR(j_modes,par.n_layers)

      FOR j = 0, par.n_layers-1 DO BEGIN
                                    ; cycle over nb of screens

         error = atm_psg_zer(par, phase_screen, coeff_zern)
                                    ; compute phase screen

         screens[*,*,j] = phase_screen
         coeff[*,j]     = coeff_zern

      ENDFOR                        ; END OF CYCLE OVER NB OF SCREENS

   ENDIF

ENDELSE

return, error                       ; back to calling program...
END 