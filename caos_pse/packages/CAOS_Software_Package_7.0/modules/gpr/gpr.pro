; $Id: gpr.pro,v 7.0 2016/04/21 marcel.carbillet $
;+
; NAME:
;    gpr
;
; ROUTINE'S PURPOSE:
;    gpr manages the simulation for the Geometrical PRopagation (GPR) module,
;    that is:
;       1-call the module's initialisation routine gpr_init at the first
;         iteration of the simulation project,
;       2-call the module's program routine gpr_prog otherwise.
;
; MODULE'S PURPOSE:
;    GPR executes the geometrical propagation between either a source at
;    infinity (astronomical object) with a given set of angular coordinates
;    or a source at a finite distance (laser guide star), with a
;    given set of angular and spatial coordinates, and a telescope with a
;    given set of spatial coordinates.
;
; CATEGORY:
;    main module's routine
;
; CALLING SEQUENCE:
;    error = gpr(inp_src_t, $
;                inp_atm_t, $
;                out_wfp_t, $
;                par,       $
;                INIT=init  )
;
; OUTPUTS:
;    error: long scalar (error code, see !caos_error var in caos_init.pro).
;
; INPUTS:
;    inp_src_t: the source characteristics
;    inp_atm_t: the atmosphere characteristics
;
; INPUT PARAMETERS:
;    par: the user defined input parameters for the GPR
;
; INCLUDED OUTPUTS:
;    out_wfp_t: Structure containing the phase screen, the
;               telescope parameters (coordinates, diameter,
;               obscuration) and source  parameters. 
;               Source coordinates are needed in all cases as
;               photometry/spectrometry or wavelength.
;               Focalisation distance is used in the LGS cases.
;               Map and its scale are needed in the extended source
;               source cases.
;
; KEYWORD PARAMETERS:
;    INIT : initialisation data structure.
;
; COMMON BLOCKS:
;    none.
;
; SIDE EFFECTS:
;    none.
;
; RESTRICTIONS:
;    The method consist to add rescaled phase screen calculated by FFT
;    or by Zernike generation. 
;
;    In the UPWARD propagation case, the distance between each turbulent 
;    layer (b) is smaller than the distance between the last turbulent 
;    layer and the sodium layer (a). So it can be considered as Fresnel
;    propagation (Only after the LAS module). 
;
;    But in the DOWNWARD propagation case, the distance between each 
;    turbulent layer (b) is equivalent to the distance between the lowest 
;    turbulent layer and the telescope (c). We are only in the Fraunhoffer 
;    propagation case (after the SRC and NLS modules).
;
;
;              ~~~~~~~~~~~~~~~~~~~~~~~~  sodium layer 90km or infinite
;                         ^                 distance in the natural  
;                         |                     guide star case 
;                         |
;                         |
;                         |
;                         |  (a)
;                         |
;                         |
;                         v
;              ***********************    differents turbulent layers
;                         |  (b)
;              &&&&&&&&&&&&&&&&&&&&&&&     between 10 and 30km
;
;              ####################### 
;                         | (c)
;                    |__________|        telescope 0km
;
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: october 1998,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it],
;                     Elise  Viard     (ESO) [eviard@eso.org].
;    modifications  : january 1999,
;                     Elise Viard (ESO) [eviard@eso.org]:
;                    -modifications made...
;                   : february 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -a few modifications for version 1.0.
;                   : march 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -phase stripes (rectangular screens) is now managed.
;                   : december 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 2.0 (CAOS).
;                   : december 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -the init section is now done during the run section as
;                     well in order to easily consider non-constant (wrt time)
;                     sources.
;                   : january 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -use of variable "calibration" eliminited for version 4.0
;                     of the whole CAOS Software System.
;
; MODULE MODIFICATION HISTORY:
;    module written : Marcel Carbillet (OAA) [marcel@arcetri.astro.it],
;                     Elise  Viard     (ESO) [eviard@eso.org].
;    modifications  : for version 1.0,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                     Elise  Viard     (ESO) [eviard@eso.org].
;                    -enhanced and adapted to.
;                   : for version 1.0.2,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -enhanced and debugged.
;                   : for version 2.0,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -enhanced and adapted to version 2.0 (CAOS).
;                   : for version 3.0,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -the init section is now done during the run section as
;                     well in order to easily consider non-constant (wrt time)
;                     sources.
;                    -the case where the LGS is lower than a turbulent layer
;                     is now implemented.
;                   : for version 3.1,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -MCAO case now treated.
;                   : for version 4.0,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -no more use of the common variable "calibration" and
;                     the tag "calib" (structure "info") for version 4.0 of
;                     the whole CAOS Software System.
;
;-
;
function gpr, inp_src_t, $
              inp_atm_t, $
              out_wfp_t, $
              par,       $
              INIT=init

; CAOS global common block
common caos_block, tot_iter, this_iter

; initialization of the error code
error = !caos_error.ok

; module's actions
if (this_iter eq 0) then begin
   ; initialisation section
   error = gpr_init(inp_src_t, $
                    inp_atm_t, $
                    out_wfp_t, $
                    par,       $
                    INIT=init  )
endif else begin
   ; run section
   error = gpr_init(inp_src_t, $
                    inp_atm_t, $
                    out_wfp_t, $
                    par,       $
                    INIT=init  )
   error = gpr_prog(inp_src_t, $
                    inp_atm_t, $
                    out_wfp_t, $
                    par,       $
                    INIT=init  )
endelse

; back to calling program
return, error
end 