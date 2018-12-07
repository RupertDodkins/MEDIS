; $Id: cfb_init.pro,v 7.0 2016/04/27 marcel.carbillet $
;+ 
; NAME: 
;    cfb_init 
; 
; PURPOSE: 
;    cfb_init executes the initialization for the Calibration FiBer
;    (CFB) module, that is:
;
;       0- check the formal validity of the output structure.
;       1- initialize the output structure(s) out_wfp_t.
;
;    (see cfb.pro's header --or file caos_help.html-- for details
;    about the module itself).
; 
; CATEGORY: 
;    module's initialisation routine 
; 
; CALLING SEQUENCE: 
;    error = cfb_init(out_wfp_t,  $ ; wfp_t output structure
;                     par      ,  $ ; parameters structure
;                     INIT=init   $ ; initialisation data structure
;                     ) 
; 
; INPUTS/OUTPUTS/KEYWORDS/ETC.: 
;       see cfb.pro's help for a detailed description. 
; 
; ROUTINE MODIFICATION HISTORY: 
;       program written: Nov 1999, 
;                        Bruno Femenia (OAA) [bfemenia@arcetri.astro.it]
;                      : january 2003,
;                        Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                       -"mod_type"->"mod_name"
;                        (for version 4.0 of the whole Software System CAOS).
;                       -output tag "tel_alt" eliminated (was relevant only to
;                        obsolete module SHS).
;                      : april 2016,
;                        Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                       -adapted to Soft. Pack. CAOS 7.0.
;
;- 
;
FUNCTION cfb_init, out_wfp_t, par, INIT=init
 
; STANDARD CHECKS
;================

error = !caos_error.ok                                      ;Init error code: no error as default
info  = cfb_info()                                          ; Retrieve the Input & Output info.

; test the number of passed parameters corresponds to what there is in info
;--------------------------------------------------------------------------
n_par = 1                                                   ; Parameter structure (GUI) always in args. list

IF info.inp_type NE '' THEN BEGIN
    inp_type = STR_SEP(info.inp_type,",")
    n_inp    = N_ELEMENTS(inp_type)
ENDIF ELSE BEGIN
    n_inp    = 0
ENDELSE

IF info.out_type NE '' THEN BEGIN
    out_type = STR_SEP(info.out_type,",")
    n_out    = N_ELEMENTS(out_type)
ENDIF ELSE BEGIN
    n_out    = 0
ENDELSE

n_par= n_par + n_inp + n_out

IF N_PARAMS() NE n_par THEN MESSAGE, 'wrong number of parameters'

; test the parameter structure
;-----------------------------
IF TEST_TYPE(par, /STRUCTURE, N_ELEMENTS=n) THEN $
   MESSAGE, 'CFB: par must be a structure'             
                                                        
IF n NE 1 THEN MESSAGE, 'CFB: par cannot be a vector of structures'

IF STRLOWCASE(TAG_NAMES(par, /STRUCTURE_NAME)) NE info.mod_name THEN $
   MESSAGE, 'par must be a parameter structure for the module cfb'

; test if any optional input exists
;-----------------------------------
IF n_inp GT 0 THEN BEGIN
    inp_opt = info.inp_opt
ENDIF

; NO INPUT => no test on the input argument !!
;--------------------------------------------

; AT PRESENT: no loading nor restoring of INIT file!!
;----------------------------------------------------

; NO init STRUCTURE REQUIRED !!
;------------------------------

;;==========================================
;; initialization of the OUT_WFP_T structure
;;==========================================

np     = par.wf_nb_pxl
pupil  = MAKEPUPIL(np,np,par.eps,XC=(np-1)/2.,YC=(np-1)/2.) ;Even nb of sampling pts for the pupil
sc_atm = FLOAT(par.diameter)/FLOAT(np)

; number of photons from fiber.
nb_phot= par.n_phot*par.diameter^2*!PI/4.                   ;Number of photons/sec from fiber

; retrieve lambdas, widths.
dummy   = n_phot(0., BAND=band, LAMBDA=lambda, WIDTH=width)
n_bands = n_elements(band)

;generate Gaussian map as fiber image.
sigma  = par.fwhm/2.35483                                   ;Sigma of Gaussian in ['']
map    = FLTARR(np,np)
map_sc = 6*sigma/np*4.848e-6                                ;Map scale [rd/px]: sampling from -3sigma to 3sigma.
axis   = (FINDGEN(np)-np/2+0.5)*map_sc /4.848e-6            ;Axis of FFT image in [rad]
FOR j=0,np-1 DO map[*,j]=  $                                ;GAUSSIAN distribution.
  EXP(-(axis^2+axis[j]^2)/(2.*sigma^2))

map = map/TOTAL(map)                                        ;Unity volume Gaussian. (except for pixel size!!)

out_wfp_t =                               $
  {                                       $
    data_type  : info.out_type[0]       , $
    data_status: !caos_data.valid       , $   
    screen     : FLTARR(np,np)          , $ ; phase screen  [px,px]
    pupil      : pupil                  , $ ; pupil 
    eps        : 0.                     , $ ; obscuration ratio
    scale_atm  : sc_atm                 , $ ; spatial scale [m/px]
    delta_t    : 1.                     , $ ; base time     [s]
    lambda     : lambda                 , $ ; wavelength    [m]
    width      : width                  , $ ; bandwidth     [m]
    n_phot     : FLTARR(n_bands)+nb_phot, $ ; source nb(s) of photons/s [phot/s]
    background : FLTARR(n_bands)        , $ ; sky background(s) [phot/s/arcsec^2]
    map        : map                    , $ ; source map [px,px]
    map_scale  : map_sc                 , $ ; scale [rd/px]
    dist_z     : !values.f_infinity     , $ ; Fiber located at objet focus point of collimator lens.
    off_axis   : 0.                     , $ ; Irrelevant for CFB
    pos_ang    : 0.                     , $ ; Idem.
    coord      : FLTARR(5)              , $ ; Idem.
    scale_z    : 0.                     , $ ; Idem.
    dist       : 0.                     , $ ; Idem.
    angle      : 0.                     , $ ; Idem.
    constant   : 1B                     , $ ; constant (wrt time) source.
    correction : 0B                       $ ; this is not a correcting wf
  }

RETURN, error 
END 