; $Id: atm.pro,v 7.0 2016/04/21 marcel.carbillet $
;+
; NAME:
;    atm
;
; ROUTINE'S PURPOSE:
;    atm manages the simulation for the ATMosphere building (ATM) module,
;    that is:
;       1-call the module's initialisation routine atm_init at the first
;         iteration of the simulation project
;       2-call the module's program routine atm_prog otherwise.
;
; MODULE'S PURPOSE:
;    ATM generates the turbulent atmosphere. To do so a modelisation of
;    the Cn2 profile is considered. In fact, up to six discrete layers,
;    each affected by a different Cn2 value are simulated. They are also
;    affected by a velocity vector if temporal evolution is required.
;    If temporal evolution is considered, the time-base defined
;    inside ATM will rule all the subsequent simulation branches.
;
;    Each turbulent layer is a phase screen that can be either generated
;    by the module or read from a file where already computed phase screens
;    were saved. In that case, the utility PSG (that can be found in
;    .../pack_lib/) had been previously used for this purpose,
;    and the phase screens can be either squares or stripes. An ad-hoc help
;    of the utility PSG can be found in the header of the program "psg.pro".
;    Note that in this case the physical length of the wavefronts is still a
;    free parameter that can be chosen (as well as the Fried parameter r0).
;
;    A number of non-editable fields are present in the ATM GUI which purpose
;    is to help the user in defining the right parameters for her/his
;    simulation, or simply to know what are the parameters that define the
;    wavefronts used in case the use-already-computed-phase-screens feature
;    is selected. These non-editable fields have a title between parenthesis
;    - i.e. like "(title)" and not "title".
;
;    phase screen generation:
;    ------------------------
;    The two methods used for it are explained here after:
;
;      +-----------------------------------------------------------------+
;      | (1) Fast Fourier transform (FFT) [+ sub-harmonics adding (SHA)] |
;      +-----------------------------------------------------------------+
;
;      In this case the phase screen generation is computed assuming
;      either a von Karman modulus or a Kolmogorov one via FFT, with
;      compensation for the low-frequencies (if required) by means of SHA
;      [Lane et al., 1992].
;
;      Note that the von Karman model differs from the Kolmogorov one because
;      an wavefront outer scale of turbulence L0 van be selected.
;
;      Note also that the low-frequencies compensation to be performed in this
;      routine can be tested before via the routine 'sha_test' (this can be
;      automatically done within the ATM GUI by simply pushing the button
;      "PUSH HERE to test subharmonics accuracy"). 
;
;      The generated FFT phase screens are initially complex arrays, and we
;      use both the real and imaginary parts of each of them as two
;      independent phase screens [Negrete-Regagnon, 1995]. We then have to
;      normalize each of the parts by a factor sqrt(2), for energy reasons.
;
;      If temporal evolution is required, each phase screen is shifted from
;      an iteration to the next one by the amount of pixels calculated both
;      from the velocity vectors associated to the turbulent layer and from
;      the selected time-base. If the number resulting shifting pixels is
;      not an integer, the shift is done by interpolating the phase screens.
;      (A simulation is then faster - and does not suffer from any possible
;      interpolation innacurracy - if both the velocity vectors and the
;      time-base are judiciously chosen.)
;
;      +-----------------------------------------------------------------+
;      | (2) Zernike polynomials (ZP) method: [+ recursive formula (RF)] |
;      +-----------------------------------------------------------------+
;
;      In this case the phase screen generation is performed assuming only a
;      Kolmogorov modulus, and the dimensions of the phase screens are the
;      pupil's ones.
;
;      These wave screens are changed into phase screens (by multiplying them
;      by a factor 2*!pi). Then they have to be scaled for the given value of
;      the ratio between the telescope diameter 'D'  and the Fried parameter
;      'r0' before to be used, by multiplying them by the factor (D/r0)^(5/6).
;
;      References:
;      Lane R. G., Glindeman A. and Dainty J. C., 'Simulation of a Kolmogorov
;         Phase Screen', Waves in Random Media 2, 209--224, 1992.
;      Negrete-Regagnon P., 'Bispectral Imaging in Astronomy', PhD thesis,
;         Imperial College, UK, 1995.
;
;      Modification history of the phase screen generation part:
;      Written by Marcel Carbillet, OAA, 1998, but:
;      * FFT routine:      - originally written by Enrico Marchetti, ESO, 1997.
;                          - modified by Marcel Carbillet, OAA, 1997.
;      * SHA routine:      written by Marcel Carbillet, Simone Esposito
;                          and Armando Riccardi, OAA, 1998.
;      * Zernike routines: written by Armando Riccardi, OAA, 1997.
;
; CATEGORY:
;    main module's routine
;
; CALLING SEQUENCE:
;    error = atm(out_atm_t, par, INIT=init)
;
; OUTPUT:
;    error: long scalar (error code). see !caos_error var in caos_init.pro.
;
; INPUTS:
;    none.
;
; INCLUDED OUTPUTS:
;    out_atm_t: the output structure of ATM, of type "atm_t", containing:
;    -screen : 3-variables array of the ensemble of layers' wavefronts of
;              the turbulent atmosphere [m]
;    -scale  : spatial scale [m/px]
;    -delta_t: base-time [s]
;    -alt    : vector of altitudes of the layers [m]
;    -dir    : vector of direction of the wind [rd].
;
; KEYWORD PARAMETERS:
;    INIT: initialisation data structure
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
;    -For now, temporal evolution is possible ONLY with FFT phase
;    screens, NOT Zernike ones.
;    -No more than 6 turbulent layers are allowed (but this is only a limitation
;     of the GUI -- easy to override!).
;    -If temporal evolution is selected, and if phase stripes (i.e. not
;    square phase screens) are considered, the wind directions MUST BE
;    along the x- or the y-axis.
;    -Pay attention that the possible following GPR module will, a priori, place
;    the collecting telescope in the middle of the phase screens. That means that
;    if, for example, you have an 8m telescope in the middle of a 14m-large phase
;    screen, you will only (14-8)/2=3m available on the left side, and the same at
;    the right side of your telescope pupil, for time evolution of your phase
;    screens wrt wind velocities, base time, etc., before having a complete cycle
;    on your phase screens. This is not a serious problem for pure FFT screens,
;    but the fact that the same portion of phase screen will pass again over the
;    telescope pupil. If subharmonics are considered this can become, on the other
;    hand, a big problem if this limit is overcome, since the last values of the
;    border of the atmospheric layers will be repeated ad libitum.
;    
;
; CALLED NON-IDL FUNCTIONS
;    from .../modules/atm/atm_lib:
;       atm_psg    : sub-routine for phase screen generation.
;       atm_psg_fft: FFT phase screen generation sub-routine.
;       atm_psg_sha: sub-harmonics adding sub-routine.
;       atm_psg_zer: Zernike phase screen generation sub-routine.
;    from .../lib:
;       shiffft    : FFT-based phase screen shift sub-routine.
;
; ROUTINE MODIFICATION HISTORY:
;    program written: july 1998,
;                     Marcel  Carbillet (OAA) [marcel@arcetri.astro.it]  ,
;                     Simone  Esposito  (OAA) [esposito@arcetri.astro.it],
;                     Armando Riccardi  (OAA) [riccardi@arcetri.astro.it].
;    modifications  : february 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -standardization for version 1.0,
;                    -phase screens [rd] => wavefronts [m],
;                    -a few other modifications for version 1.0.
;                   : march 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -phase screens/stripes can be read from a file
;                     instead of being generated (the "use already
;                     computed phase screens" feature).
;                    -some controls of parameters consistency and
;                     more fields of help-for-decision added.
;                   : november 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 2.0 (CAOS).
;                   : january/february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -use of variable "calibration" eliminited for version 4.0
;                     of the whole system CAOS.
;                    -help completed (FFT+SHA vs. limited dimension stuff).
;                   : march 2016,
;                     Ulysse Perruchon-Monge & Adama Sy (Dépt. Physique UNS),
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -turbulence can now be switched off (by using par.turnatmos).
;
;-
;
function atm, out_atm_t, $
              par,       $
              INIT=init

; CAOS global common block
common caos_block, tot_iter, this_iter

; initialization of the error code
error = !caos_error.ok

; module's actions
if (this_iter eq 0) then begin

   ; initialisation section
   error = atm_init(out_atm_t, par, INIT=init)

endif else begin

   ; run section
   if par.turnatmos then error = atm_prog(out_atm_t, par, INIT=init)

   if ((par.lps eq 0) and (par.cal eq 1)) then    $
      if (tot_iter eq 1) then free_lun, init.unit $
      else if (this_iter eq tot_iter) then free_lun, init.unit

endelse

return, error
end