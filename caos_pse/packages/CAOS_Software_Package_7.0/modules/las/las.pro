; $Id: las.pro,v 7.0 2016/04/29 marcel.carbillet $
;+
; NAME:
;    las
;
; ROUTINE'S PURPOSE:
;    las manages the simulation for the LASer definition (LAS) module,
;    that is:
;       1-call the module's initialisation routine las_init at the first
;         iteration of the simulation project,
;       2-call the module's program routine las_prog otherwise.
;
; MODULE'S PURPOSE:
;    LAS executes the simulation of a created laser beam. It creates the
;    gaussian beam of the laser and modelise its focalisation in the sodium
;    layer, and calculates the number of photons emitted.
;    LAS allows the user to define the laser shape. Up to now, it is only
;    possible to have a gaussian laser, in continuous wave.
;    The input power allows us to obtain the number of photons measured in
;    the Shack-Hartmann subapertures.
;    The waist coefficient is defined with the following formula:
;       waist^2 = 2*sigma^2 => waist = sqrt(2)*sigma
;       => waist = FWHM / (2*sqrt(alog(2)))
;    The user will have to choose also the distance of focalisation of the
;    laser.
;    Usually, if we consider the sodium layer, it is about 90km. It is not
;    necessary the same value as the mean sodium layer altitude (focusing the
;    laser is not easy, so errors in focalisation can be taken into account).
;    Finally, the artificial star coordinates must be given.
;
; CATEGORY:
;    main module's routine
;
; CALLING SEQUENCE:
;    error = las(out_src_t, par, INIT=init)
;
; INPUT PARAMETERS:
;    par: the user defined input parameters for the NLS
;
; KEYWORD PARAMETERS:
;    INIT: initialisation data structure.
;
; OUTPUTS:
;    error: error code [long scalar].
;
; INCLUDED OUTPUTS:
;    out_src_t: Structure containing the laser beam map in an 
;               arbitrary scale, the number of photons and the 
;               wavelength considered, the coordinates of the 
;               spot laser in the sky and the altitude of 
;               focalisation.
;
; COMMON BLOCKS:
;    common caos_block, tot_iter, this_iter
;
;    tot_iter   : total number of iteration during the simulation run.
;    this_iter  : current iteration number.
;
; SIDE EFFECTS:
;    none.
;
; RESTRICTIONS:
;    Can only define a gaussian beam !
;
; CALLED NON-IDL FUNCTIONS:
;    none.
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: october 1998,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it],
;                     Elise  Viard     (ESO) [eviard@eso.org].
;    modifications  : january 1999,
;                     Elise Viard (ESO) [eviard@eso.org]:
;                    -a few modifications for version 1.0.
;                   : december 1999--april 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -enhanced and adapted to version 2.0 (CAOS).
;                   : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -use of variable "calibration" eliminited for version 4.0
;                     of the whole CAOS Software System.
;                   : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
; MODULE MODIFICATION HISTORY:
;    module written : beta-version,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it],
;                     Elise  Viard     (ESO) [eviard@eso.org].
;    modifications  : version 1.0,
;                     Elise  Viard     (ESO) [eviard@eso.org],
;                    -a few modifications.
;                   : version 2.0,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -enhanced and adapted to version 2.0 (CAOS).
;                    -useless tag TIME took out
;                    -module's help imported from las_prog and corrected.
;                    -INIT structure and routine las_prog eliminated (useless).
;                   : for version 4.0,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -no more use of the common variable "calibration" and
;                     the tag "calib" (structure "info") for version 4.0 of
;                     the whole CAOS Software System.
;                   : for version 7.0,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
;;;;;;;;;;;;;;;
; module code ;
;;;;;;;;;;;;;;;
;
function las, out_src_t, par

; CAOS global common block
common caos_block, tot_iter, this_iter

; error code initialisation
error = !caos_error.ok

; module's action
if (this_iter eq 0) then error = las_init(out_src_t, par)

; back to calling program
return, error
end