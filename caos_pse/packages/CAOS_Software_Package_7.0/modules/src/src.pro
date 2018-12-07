; $Id: src.pro,v 7.0 2016/04/21 marcel.carbillet $
;+
; NAME:
;    src
;
; ROUTINE'S PURPOSE:
;    SRC manages the simulation for the Calibration FiBer (SRC) module,
;    that is:
;      1-call the module's initialisation routine src_init at the first
;        iteration of the project
;      2-call the module's program routine src_prog otherwise, managing
;        at the same time the possible time integration/delay.
;
; MODULE'S PURPOSE:
;    src executes the simulation for SouRCe (SRC) module.
;    The source chosen can be either a natural object or a laser guide star,
;    and either a point-like or 2D-object.
;    In this last case (2D-objects), the map can be either a
;    user-defined one or a map calculated by the module, with a
;    uniform disc-like shape or a gaussian one (that can be
;    elongated).
;    The magnitude of the source can be chosen, as well as its
;    spectral type (in case of a natural object) and the values
;    of the background in the different Johnson bands (+ a Na band).
;    The number of photons computation is then done assuming that a
;    natural object is a black body-like one.
;    In the laser guide star case, the given magnitude is an
;    equivalent V-magnitude.
;    Finally, the angular position of the object has to be chosen, as
;    well as its distance from the observing telescope (in case of a
;    laser guide star).
;
; CATEGORY:
;    main module's routine
;
; CALLING SEQUENCE:
;    error = src(out_src_t, par, INIT=init)
;
; OUTPUT:
;    error: long scalar (error code). see !caos_error var in caos_init.pro.
;
; INPUTS:
;    none.
;
; INCLUDED OUTPUTS:
;    out_src_t: structure of type "src_t" containing the characteristics of
;               the selected source, the following fields are contained in
;               this structure:
;               off_axis  : off-axis of source wrt main tel. [rd]
;               pos_ang   : position angle of source wrt main tel. [rd]
;               dist_z    : dist. main tel.-object [m] (inf. if astro. one)
;               map       : source map (if 2d astronomical object)
;               scale_xy  : map scale (if any) [rd/px]
;               coord     : [not used]
;               scale_z   : [not used]
;               n_phot    : number(s) of photons  [/s/m^2] (vs. wavelength)
;               background: sky background(s) [/s/m^2/arcsec^2] (id.)
;               lambda    : wavelength(s) [m]
;               width     : band-width(s) [m]
;
; KEYWORD PARAMETERS:
;    INIT: named variable undefined or containing a scalar when src is
;          called for the first time. As output the named variable will
;          contain a structure of the initialization data. For the following
;          calls of src, the keyword INIT has to be set to the structure
;          returned by the first call.
;
; COMMON BLOCKS:
;    common caos_ao_block, tot_iter, this_iter
;
;    tot_iter   : total number of iteration during the simulation run.
;    this_iter  : current iteration number.
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
; CALLED NON-IDL FUNCTIONS:
;    n_phot  : for number of photons calculus (see in .../lib).
;    spec2mag: to transform a V-magnitude into any other band
;              magnitude (see in .../lib).
;
; ROUTINE MODIFICATION HISTORY:
;    program written: october 1998,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : february 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -a few modifications for version 1.0.
;                   : march 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it],
;                     Simone Esposito  (OAA) [esposito@arcetri.astro.it]:
;                    -added 2D-objects calculation feature.
;                   : Nov 1999,
;                     B. Femenia   (OAA) [bfemenia@arcetri.astro.it]
;                     M. Carbillet (OAA) [marcel@arcetri.astro.it]
;                    -adapted to new version CAOS (v 2.0).
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
; MODULE MODIFICATION HISTORY:
;    module written : Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : for version 4.0,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -no more use of the common variable "calibration" and
;                     the tag "calib" (structure "info") for version 4.0 of
;                     the whole CAOS Software System.
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;-
;
function src, out_src_t, $
              par,       $
              INIT=init

COMMON caos_block, tot_iter, this_iter


error = !caos_error.ok          ; Init error code: no error as default


IF (this_iter EQ 0) THEN BEGIN  ; INITIALIZATION 
                                ;===============
   error= src_init(out_src_t, $
                   par,       $
                   INIT=init  $
                  )

ENDIF ELSE BEGIN                ; NORMAL RUNNING: SRC does not consider
                                ;===============  integration nor delay
   error= src_prog(out_src_t, $
                   par,       $
                   INIT=init  $
                  )
 
ENDELSE 

return, error
END