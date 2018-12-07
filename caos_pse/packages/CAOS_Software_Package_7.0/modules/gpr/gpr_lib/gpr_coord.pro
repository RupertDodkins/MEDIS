; $Id: gpr_coord.pro,v 7.0 marcel.carbillet $
;+
; NAME:
;    gpr_coord
;
; PURPOSE:
;    Function for GPR module, calculation of the coordinate of 
;    the spot in each turbulent layer.
;
; CATEGORY:
;    module's library program
;
; CALLING SEQUENCE:
;    err = gpr_coord(r_GS, dist_tel, ang_tel, offaxis_GS, angle_GS,$
;                    alt_layers)
;
; INPUTS:
;    dist_tel, ang_tel, offaxis_GS, angle_GS, alt_layers
;
; OUTPUTS:
;    err: long scalar (see !caos_error var in caos_init.pro).
;
; INCLUDED OUTPUTS:
;    r_GS: array containing cartesian coordinates of the spot in 
;          each turbulent layer.
;
; EXAMPLE:
;    See within gpr_prog.pro.
;
; MODIFICATION HISTORY:
;    program written: october 1998,
;                     Elise  Viard     (ESO) [eviard@eso.org],
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : march 1999,
;                     Bruno  Femenia   (OAA) [bfemenia@arcetri.astro.it],
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -ATAN debugged.
;                   : december 1999,
;                     Marcel Carbillet [marcel@arcetri.astro.it]:
;                    -adapted to version 2.0 (CAOS).
;                   : may 2011,
;                     Marcel Carbillet [marcel.carbillet@unice.fr]:
;                    -approximations sinmu and cosmu (if <1E-8 then 0)
;                     added to avoid useless very small values of r_GS
;                     (and then interpolations within gpr_prog).
;                   : may 2014,
;                     Marcel Carbillet [marcel.carbillet@unice.fr]:
;                    -no more error handling inside routine (and r_GS as
;                     result).
;                    -double precision computations.
;                    -approximations sinmu and cosmu now more restrictive
;                     (if <1E-6 then 0, instead of 1E-8), and performed
;                     on abs(sinmu), abs(cosmu), abs(1-sinmu), abs(1-cosmu),
;                     abs(1+sinmu), and (1+cosmu).
;                   : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
function gpr_coord, dist_tel, ang_tel, offaxis_GS, angle_GS, alt_layers

dist_tel   = double(dist_tel)
ang_tel    = double(ang_tel)
offaxis_GS = double(offaxis_GS)
angle_GS   = double(angle_GS)
alt_layers = double(alt_layers)

mu = !DPi+ang_tel-angle_GS
h  = alt_layers/cos(offaxis_GS)
f  = alt_layers*tan(offaxis_GS)

n_lay = double(n_elements(alt_layers))

dummy = where((dist_tel-f*cos(mu)) EQ 0, count)

IF (count EQ n_lay) THEN dzeta = dblarr(n_lay) $
ELSE BEGIN
   sinmu = sin(mu)
   if abs(sinmu) lt 1E-6 then sinmu=0D0
   if abs(1-sinmu) lt 1E-6 then sinmu=1D0
   if abs(1+sinmu) lt 1E-6 then sinmu=-1D0
   cosmu = cos(mu)
   if abs(cosmu) lt 1E-6 then cosmu=0D0
   if abs(1-cosmu) lt 1E-6 then cosmu=1D0
   if abs(1+cosmu) lt 1E-6 then cosmu=-1D0
   dzeta = atan(f*sinmu,(dist_tel-f*cosmu))
ENDELSE
                                           ; position angle between the main 
                                           ; telescope  and the spot laser 
r = (dist_tel-f*cos(mu)) / cos(dzeta)      ; distance between the main
                                           ; telescope  and the spot laser 
x_GS = r*cos(dzeta+ang_tel)                ; coordinates of the spot
y_GS = r*sin(dzeta+ang_tel)
r_GS = transpose([[x_GS], [y_GS]])

return, r_GS
end