; $Id: nls_prog.pro,v 7.0 2016/04/29 marcel.carbillet $
;+
; NAME:
;    nls_prog
;
; PURPOSE:
;    nls_prog is the program routine for the  Na-Layer Spot (NLS) module.
;
; CATEGORY:
;    module's program routine
;
; CALLING SEQUENCE:
;    error = nls_prog(inp_wfp_t, $
;                     out_src_t, $
;                     par,       $
;                     INIT=init  )
;
; INPUTS/OUTPUTS/ETC.:
;    see nls.pro's header.
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: july 1998,
;                     Elise Viard (ESO) [eviard@eso.org].
;    modifications  : january 1999,
;                     Elise Viard (ESO) [eviard@eso.org]:
;                    -a few modifications for version 1.0.
;                   : march 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -debugging.
;                    -output no more re-defined (done in nls_init).
;                    -adapted map scale computation to the fact that
;                     the wavelength is now a vector.
;                   : march 1999,
;                     Bruno  Femenia   (OAA) [bfemenia@arcetri.astro.it],
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -debugged: map was set to zero after first iteration
;                     for constant sources.
;                   : june 1999,
;                     Francoise Delplancke (ESO) [fdelplan@eso.org]:
;                    -adapted to Rayleigh scattering.
;                   : december 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -enhanced and adapted to version 2.0 (CAOS).
;                   : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
function nls_prog, inp_wfp_t, $
                   out_src_t, $
                   par,       $
                   INIT=init

error = !caos_error.ok

if inp_wfp_t.data_status eq !caos_data.wait THEN $
   message, 'The input cannot be wait.'

; program itself

alreadydone = init.alreadydone

IF (inp_wfp_t.constant[0] ne 1 or alreadydone ne 1) THEN BEGIN

   error = nls_map(map3D, init.dim, init.n_sub, inp_wfp_t.screen, $
                   inp_wfp_t.map, init.defocus, init.Na_prof)
                                ; LGS cube within aux. tel. coord. system
   np = (size(map3D))[1] 
   n_bands = n_elements(inp_wfp_t.lambda)
   map_scale = 1/inp_wfp_t.scale_atm*(inp_wfp_t.lambda[n_bands-1])/np
   
   
   error = nls_coord(coord, inp_wfp_t.dist, inp_wfp_t.angle, $
                     inp_wfp_t.off_axis, inp_wfp_t.pos_ang,  $
                     init.alt, init.n_sub, init.width,       $
                     inp_wfp_t.dist_z )

   IF (inp_wfp_t.constant[0] EQ 1) THEN init.alreadydone = 1

   out_src_t.map      = map3D         ; lgs 3D-map
   out_src_t.scale_xy = map_scale     ; scale as seen from the ground [rd/px]
   out_src_t.coord    = coord         ; coordinates of the differents maps
                                      ; of the spot relative to the MAIN 
                                      ; telescope [rad,rad,m,m,m]
ENDIF

; NLS output structure update
out_src_t.data_status = !caos_data.valid

; back to calling program
return, error
END 