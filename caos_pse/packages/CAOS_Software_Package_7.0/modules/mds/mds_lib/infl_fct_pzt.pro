; $Id: infl_fct_pzt.pro,v 7.0 2016/04/29 marcel.carbillet $
;+
; NAME:
;    infl_fct_pzt.pro
;
; PURPOSE:
;    ...
;
; CATEGORY:
;    module's library routine
;
; CALLING SEQUENCE:
;    infl_fct = infl_fct_pzt(mir_geom, dpup, pupil)
;
; INPUTS:
;    mir_geom: mirror geometry parameters
;    dpup    : number of points under the pupil
;    pupil   : pupil itself
;
; OPTIONAL INPUTS:
;    none.
;      
; OUTPUTS:
;    infl_fct: a 3-D array containing the influence functions of each
;              active actuator on (a square arraycontaining) the pupil
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
; EXAMPLE:
;    ...
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: october 1998,
;                     Francoise Delplancke (ESO) [fdelplan@eso.org].
;    modifications  : october 1999,
;                     Francoise Delplancke (ESO) [fdelplan@eso.org]:
;                    -the gain (V to micron) factor is transferred to
;                     this influence function generator (more physical)
;                     from the dmi_calib and dmi_prog.
;                   : october 1999,
;                     Francoise Delplancke (ESO) [fdelplan@eso.org],
;                     Elise     Viard      (ESO) [eviard@eso.org]:
;                    -factor 2 is removed because the model of the influence 
;                     functions is supposed to give directly the total
;                     influence after (normal) reflection.
;                   : january--february 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 2.0 (CAOS).
;                    -the entire structure PAR is no more passed to this
;                     function (just the only 2 relevant parameters: theta
;                     and gain).
;                    : february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -variables theta and gain finally eliminated.
;                    -tag "off" of mir_geom eliminated (always 0).
;                    -routine moved to module MDS (instead of DMI).
;                   : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
FUNCTION infl_fct_pzt, mir_geom, dpup, pupil

; PZT model parameters
;
rad_eff = 1.46
ir = mir_geom.d_act * rad_eff ; radius up to which the actuator has an effect
c  = 3.8
p1 = 4
p2 = 2.4

; routine itself
;
x = findgen(mir_geom.size) # replicate(1, mir_geom.size)
y = transpose(x)

def = fltarr(mir_geom.size, mir_geom.size)
; deformation on the mirror due to each active actuator

infl_fct = fltarr(dpup, dpup, mir_geom.nact)
; phase difference induced on the incident phase screen due to the mirror

interp_x = findgen(mir_geom.size)
interp_y = findgen(mir_geom.size)
; positions at which the def array has to be interpolated to give the
; influence functions projected on the pupil

for i=0,mir_geom.nact-1 do begin

   tmpx = abs((x-mir_geom.coord[i,0])/ir) > 1e-8 < 2.
   tmpy = abs((y-mir_geom.coord[i,1])/ir) > 1e-8 < 2.
   def  = (1. - tmpx^p1 + c*alog(tmpx)*tmpx^p2) $
         *(1. - tmpy^p1 + c*alog(tmpy)*tmpy^p2) $
         *(tmpx le 1.)*(tmpy le 1.)
   ; influence functions in the mirror referential in microns
   tempo=interpolate(def,interp_x,interp_y,/cubic,/grid)
   ; influence functions projected on the wavefront plane
   ; converted in amount of micron variation for the reflected wavefront
   infl_fct[*,*,i] = temporary(tempo[mir_geom.size/2-dpup/2:   $
                                     mir_geom.size/2+dpup/2-1, $
                                     mir_geom.size/2-dpup/2:   $
                                     mir_geom.size/2+dpup/2-1])$
                    *pupil
   ; influence functions limited to the pupil and multiplied by it

endfor 

return, infl_fct
end