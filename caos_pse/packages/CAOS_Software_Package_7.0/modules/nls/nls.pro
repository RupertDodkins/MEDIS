; $Id: nls.pro,v 7.0 2016/04/29 marcel.carbillet $
;+
; NAME:
;    nls
;
; ROUTINE'S PURPOSE:
;    nls manages the simulation for the Na-Layer Spot (NLS) module,
;    that is:
;       1-call the module's initialisation routine nls_init at the first
;         iteration of the simulation project,
;       2-call the module's program routine nls_prog otherwise.
;
; MODULE'S PURPOSE:
;    NLS simulates the sodium layer spot formation.
;
;    Calculate the laser spot shape using discretisation of the
;    sodium layer. Give also in output the coordinates within the
;    main telescope axis.
;
;    This module defines the Na layer. Three parameters are needed in input:
;    the mean altitude of the sodium layer, its width and the number of
;    sub-layers you want to consider. In this version the Na density is
;    supposed to be a gaussian with a FHWM equal to 0.7849*width/2. The
;    nominal peak density has been normalised using published data (cf
;    table1, C.S. Gardner, proc. IEEE, vol 77, no 3, march 1989). For each
;    sub-layer, the density itself [m^-2] is determined by calculating the
;    area under the gaussian density profile.
;    The output (Na-spot) is a 3D object, the laser image being
;    calculated in each sub-layer (using the input laser shape, the phase
;    screen, a defocused term and the density). When seen by the imager
;    modules (IMG, SHS) after downward propagation, the spot coordinates
;    (in each sub-layer) are used to shift spot images in order to sum them
;    and obtain the seen spot image.
;
; CATEGORY:
;    main module's routine
;
; CALLING SEQUENCE:
;    error = nls(inp_wfp_t, $
;                out_src_t, $
;                par,       $
;                INIT=init  )
;
; INPUTS:
;    inp_wfp_t: Structure containing the phase screen after    
;               the upward propagation (sum of differents 
;               phase screens) and all parameters concerning 
;               the laser (auxiliary telescope coordinates,
;               laser map, source position in the sky, 
;               focalisation altitude) 
;
; INPUT PARAMETERS:
;    par: the user defined input parameters for the NLS
;
; KEYWORD PARAMETERS:
;    INIT: initialisation data structure.
;
; OUTPUTS:
;    error: error code [long scalar]
;
; INCLUDED OUTPUTS:
;    out_src_t: Structure containing the 3D map of the laser
;               and all the parameters needed for the spot propagation.
;
; COMMON BLOCKS:
;    none.
;
; SIDE EFFECTS:
;    None.
;
; RESTRICTIONS:
;    Saturation effects are not considered.
;
;    NLS parameters are supposed constant during the simulation. 
;
;    Be careful! The choice of the number of sub-layers is important. If you 
;    consider large phase screens and big telescopes, you will create big
;    arrays for each sub-layer, so don't consider too many sub-layers
;    otherwise computation time will increase rapidly.
;
;    On the contrary, don't consider a too small number of sub-layers
;    especially if the distance between the two telescopes (emitter and
;    receptor telescopes) is large, otherwise the discretisation will not be
;    sufficient and the output image is will be wrong (the shift of the spot
;    image will be large, so you will obtain a serie of small spots aligned
;    with each others).
;
; NON-IDL ROUTINES:
;    nls_density    : gives the integrated density of the sodium layer 
;                     for each sub-layer
;    nls_defocus.pro: calculates at an altitude z the defocus to add 
;                     to the focused image.
;    nls_map.pro:     calculates the 3D spot in the sodium sub-layers. 
;    nls_coord.pro:   calculates the coordinates of the 3D spot.
;    n_phot:          calculates the number of background photons in a 
;                     chosen bandwidth (this is a general library
;                     function that can be found in lib).
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: july 1998,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it],
;                     Elise  Viard     (ESO) [eviard@eso.org].
;    modifications  : november 1998,
;                     Elise Viard (ESO) [eviard@eso.org]:
;                    -added possibility to have an input file
;                   : january 1999,
;                     Elise Viard (ESO) [eviard@eso.org]:
;                    -modifications for version 1.0.
;                   : march 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -debugging: one of the status case was missing.
;                   : december 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -enhanced and adapted to version 2.0 (CAOS).
;                   : may 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -help corrected.
;                   : september 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it],
;                     Simone Esposito  (OAA) [esposito@arcetri.astro.it],
;                     Bruno  Femenia   (OAA) [bfemenia@arcetri.astro.it]:
;                    -the 3D spot is also computed during the init phase now
;                     (was needed by the CEN module for reference calculation)
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
;                     Elise Viard (ESO) [eviard@eso.org]:
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -modifications for version 1.0.
;                   : version 2.0,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -enhanced and adapted to version 2.0 (CAOS).
;                   : for version 4.0,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -no more use of the common variable "calibration" and
;                     the tag "calib" (structure "info") for version 4.0 of
;                     the whole CAOS Software System.
;                   : for version 7.0,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;-
;
function nls, inp_wfp_t, $
              out_src_t, $
              par,       $
              INIT=init

; CAOS global common block
common caos_block, tot_iter, this_iter

; error code initialisation
error = !caos_error.ok

; module's actions
if (this_iter eq 0) then begin
   ; initialisation section
   error = nls_init(inp_wfp_t, out_src_t, par, INIT=init)
endif

; run section
error = nls_prog(inp_wfp_t, out_src_t, par, INIT=init)

; back to calling program.
return, error
END 