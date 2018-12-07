; $Id: gpr_prog.pro,v 7.0 2016/04/21 marcel.carbillet $
;+
; NAME:
;    gpr_prog
;
; PURPOSE:
;    gpr_prog executes the simulation for the Geometrical PRopagation (GPR)
;    module (see gpr.pro's header --or file caos_help.html-- for details about
;    the module itself).
;
; CATEGORY:
;    module's program routine
;
; CALLING SEQUENCE:
;    error = gpr_prog(src_t, atm_t, wfp_t, par, INIT=init)
;
; INPUTS/OUTPUT/KEYWORDS/ETC.:
;       see module help for a detailed description.
;
; ROUTINE MODIFICATION HISTORY:
;    program written: october 1998,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it],
;                     Elise  Viard     (ESO) [eviard@eso.org].
;    modifications  : january 1999,
;                     Elise Viard (ESO) [eviard@eso.org]:
;                    -modifications made...
;                   : february 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -propagation modified in order to consider stripes in
;                     addition of square screens.
;                    -"reform" bug of compatibility with point-like sources
;                     corrected.
;                    -a few other modifications for version 1.0.
;                   : march 1999,
;                     Bruno  Femenia   (OAA) [bfemenia@arcetri.astro.it],
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -debugged: the map was not calculated nor passed to the
;                     next module(s).
;                   : april 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -wf average on the pupil is not put to zero anymore.
;                    -second error message on ds2 corrected.
;                    -pupil was not well centered anymore after modification
;                     for stripes stuff: fixed.
;                    -ROT is no more used if the star is on-axis (no need
;                     of shift - and then no need of possible interpolation)
;                     AND the heigth ratio is 1 (no need of px magnification).
;                   : june 1999,
;                     Francoise Delplancke (ESO) [fdelplan@eso.org]:
;                    -adapted to Rayleigh scattering (src_t.constant is a
;                     structure now).
;                   : september 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -ROT is no more used if the shift due to the off-axis of
;                     the star and/or the position of the telescope is of an
;                     integer number of pixels (with a limit of 1/1000 pixel)
;                     AND height ratio = 1 (warning are printed now).
;                    -"floor" => "round"
;                    -help corrected.
;                   : december 1999-april 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -enhanced and adapted to version 2.0 (CAOS).
;                   : december 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -the case where a LGS is lower than the atm. layer(s)
;                     is now implemented ( => flat "turbulent" layer).
;                   : february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -no more use of the common variable "calibration".
;                   : may 2011,
;                     Marcel Carbillet (Fizeau) [marcel.carbillet@unice.fr]:
;                    -debugging: center of rotation for function ROT was badly
;                     defined ((np-1)/2 instead of ((np-1)/2.). [Note that
;                     there is no real rotation, ROT is used because of its
;                     interpolation and magnification features].
;                   : september 2015,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -GPR warnings about cubic interpolation printed only once
;                     (at this_iter=1).
;
;-
;
function gpr_prog, src_t, atm_t, wfp_t, par, INIT=init
 
; CAOS global common block
common caos_block, tot_iter, this_iter

; error code initialization
error = !caos_error.ok

; program itself
if (src_t.dist_z gt 0.)                                                        $
or (src_t.dist_z lt 0. and init.alreadydone eq 0B)                             $
or (src_t.dist_z lt 0. and init.alreadydone eq 1B and src_t.constant[0] eq 0B) $
then begin

   screen = fltarr(init.np, init.np)

   x_GS = init.r_GS[0,*] & y_GS = init.r_GS[1,*]
   if ((size(x_GS))[0] ne 0) then x_GS = reform(x_GS)
   if ((size(y_GS))[0] ne 0) then y_GS = reform(y_GS)

   xx = round(x_GS) & yy = round(y_GS) ; source x- and y-position [px]
   
   FOR i=0,init.n_layers-1 do BEGIN

      if (size(atm_t.screen))[0] eq 2 then $
         dummy = atm_t.screen else dummy = atm_t.screen[*,*,i]

      if (init.dim_x ne init.dim_y) and                                 $
      ( (atm_t.dir[i] eq 90./!RADEG) or (atm_t.dir[i] eq 270./!RADEG) ) $
      then begin
         dummy = transpose(temporary(dummy))
         dim_x = init.dim_y
         dim_y = init.dim_x
      endif else begin
         dim_x = init.dim_x
         dim_y = init.dim_y
      endelse

      if (init.ratio[i] gt 1. AND finite(init.ratio[i])) then begin

         dummy = rot(shift(temporary(dummy),-xx[i],-yy[i]) $
                    , 0., init.ratio[i]                    $
                    , (dim_x-1)/2.+x_GS[i]-xx[i]           $
                    , (dim_y-1)/2.+y_GS[i]-yy[i]           $
                    , CUBIC=-.5)         ; apply ROT function for pixel
                                         ; magnification (and possible wf
                                         ; shift) only if necessary.

         if this_iter eq 1L then begin
            print, "GPR warning:=============================================+"
            print, "| a cubic interpolation will be applied in order to take |"
            print, "| into account cone effect in the propagation process... |"
            print, "|                 (pixel magnification)                  |"
            print, "+========================================================+"
         endif

      endif else if (abs(x_GS[i]-xx[i]) gt 0.001) or       $
                    (abs(y_GS[i]-yy[i]) gt 0.001) then begin

         dummy = rot(shift(temporary(dummy),-xx[i],-yy[i]) $
                    , 0., init.ratio[i]                    $
                    , (dim_x-1)/2.+x_GS[i]-xx[i]           $
                    , (dim_y-1)/2.+y_GS[i]-yy[i]           $
                    , CUBIC=-.5)         ; apply ROT function for wf shift
                                         ; interpolation only if it is the
                                         ; case.

         if this_iter eq 1L then begin
            print, "GPR warning:=============================================+"
            print, "| a cubic interpolation will be applied in order to take |"
            print, "| into account the relative positions of the source and  |"
            print, "| the observing telescope...                             |"
            print, "+========================================================+"
         endif

      ENDIF ELSE IF (init.ratio[i] le 0. or init.ratio[i] eq !VALUES.F_INFINITY) THEN BEGIN
                                            ; flat "turbulent" layer if LGS
         dummy[*,*] = 0.                    ; at a lower or equal altitude than
                                            ; atmospheric layer
      ENDIF ELSE IF (init.ratio[i] EQ 1.) THEN BEGIN 

         dummy = shift(temporary(dummy),-xx[i],-yy[i])
                                            ; else apply simple shift.
      ENDIF ELSE message, "GPR error: altitudes ratio NaN !!!!"

      ;; pupil wf is now centered on atm. layer (shifts for telescope and
      ;; observed object positions already done before).
      ;;<=| if (atm_t.dir[i] lt 90./!RADEG or atm_t.dir[i] gt 270./!RADEG) $
      ;;  | then begin
      ;;  |    x0 = dim_x-init.np
      ;;  |    x1 = dim_x-1
      ;;  | endif else begin
      ;;  |    x0 = 0
      ;;  |    x1 = init.np-1
      ;;  | endelse
      ;;  |
      ;;  | if (atm_t.dir[i]*!RADEG gt 0. and atm_t.dir[i]*!RADEG lt 180.) $
      ;;  | then begin
      ;;  |    y0 = dim_y-init.np
      ;;  |    y1 = dim_y-1
      ;;  | endif else begin
      ;;  |    y0 = 0
      ;;  |    y1 = init.np-1
      ;;  | endelse
      ;;=>
      x0 = (dim_x-init.np)/2
      x1 = (dim_x+init.np)/2-1
      y0 = (dim_y-init.np)/2
      y1 = (dim_y+init.np)/2-1

      ;; wf average on the pupil is not put to zero anymore
      ;;<=| pupil = makepupil_rec(dim_x, dim_y, init.np, par.eps, $
      ;;  |                       XC=(dim_x-1)/2., YC=(dim_y-1)/2.)
      ;;  |                                           ; telescope pupil on wf
      ;;  | coord_pup = where(pupil eq 1., count_pup)
      ;;  | zero = total((dummy)[coord_pup])/count_pup
      ;;  | screen = screen + (dummy-zero)[x0:x1, y0:y1]
      ;;=>
      screen = screen + dummy[x0:x1, y0:y1]

   ENDFOR

   init.alreadydone = 1B

   if (src_t.dist_z le 0.) then begin

       np = (size(wfp_t.pupil))[1]
       expand, src_t.map, np, np, map_e
       map = map_e*wfp_t.pupil
       wfp_t.map = map/total(map)

   endif else begin

      wfp_t.map = src_t.map

   endelse

   wfp_t.screen = screen

endif

; gpr output structure update:
wfp_t.data_status = !caos_data.valid   

return, error                   ; back to calling program
end