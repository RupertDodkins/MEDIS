; $Id: nls_coord.pro,v 7.0 2016/04/29 marcel.carbillet $
;+
; NAME:
;    nls_coord
;
; PURPOSE:
;    function for NLS module, calculation of the coordinate of 
;    the spot in each sub-layer of the sodium layer.
;
; CATEGORY:
;    NLS library routine
;
; CALLING SEQUENCE:
;    error =  nls_coord(coor,       $
;                       dist_tel,   $
;                       ang_tel,    $
;                       offaxis_GS, $
;                       angle_GS,   $
;                       alt_GS,     $
;                       n_sub,      $
;                       width,      $
;                       alt_foc     )
;
; INPUTS:
;    coor      :...
;    dist_tel  :...
;    ang_tel   :...
;    offaxis_GS:...
;    angle_GS  :...
;    alt_GS    :...
;    n_sub     :...
;    width     :...
;    alt_foc   :...
;
; OUTPUTS:
;    error: error code [long scalar].
;
; OUTPUTS included in call:
;    coor: array containing spherical and cartesian coordinates   
;          of the spot in each sub-layer of the sodium layer.
;
; EXAMPLE:
;    ...
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: october 1998,
;                     Elise  Viard     (ESO) [eviard@eso.org],
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : february 1999,
;                     Elise     Viard      (ESO) [eviard@eso.org],
;                     Francoise Delplancke (ESO) [fdelplan@eso.org]:
;                    -a few modifications for version 1.0 + documentation.
;                   : december 1999,
;                     Marcel Carbillet [marcel@arcetri.astro.it]:
;                    -adapted to version 2.0 (CAOS).
;                   : april 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
FUNCTION nls_coord, coor, dist_tel, ang_tel, offaxis_GS, angle_GS, $
                    alt_GS, n_sub, width, alt_foc

error = !caos_error.ok

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Definition of the Sodium layer: ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delta_z = width/(n_sub-1D0)
; distance between two successive sub-layer in the Na layer [m]

alt_layers = (dindgen(n_sub)*delta_z-width/2D0+alt_GS)
; altitude of each sub-layer in the Na layer [m]


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Definition of the useful angles and distances in spherical coordinates :
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mu = !Dpi + (ang_tel - angle_GS)
; in the Auxiliary Telescope System Referentiel(AT RS):
; angle between the Main tel. (MT) and the laser spot (LS)

h = alt_layers / cos(offaxis_GS)
; distance between the AT and the LS (in the 3D geometry)
f = alt_layers * tan(offaxis_GS)
; distance on the ground between the AT and the LS

V = where((dist_tel-f*cos(mu)) EQ 0.,count)
IF (count EQ n_sub) THEN  BEGIN
   dzeta = dblarr(n_sub)
ENDIF ELSE dzeta = atan(f*sin(mu),(dist_tel-f*cos(mu)))
; position angle between the main telescope and the spot laser 
IF (total(dist_tel-f*cos(mu))/n_elements(dist_tel-f*cos(mu)) LT 0.) THEN $
   dzeta = dzeta+!Dpi

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Determination of the LS coordinates in the MT SR: ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

r = (dist_tel-f*cos(mu))/cos(dzeta)  
; distance between the main telescope and the spot laser (on the ground)

angle_pos = dzeta + ang_tel
; position angle of the laser spot in the MT SR

IF (min(alt_layers) NE 0) THEN gamma_pos = atan(r/alt_layers) $
                          ELSE gamma_pos = 0D0
; off axis angle of the laser spot in the MT SR

x = alt_layers* tan(gamma_pos) * cos(dzeta + ang_tel)
y = alt_layers* tan(gamma_pos) * sin(dzeta + ang_tel)
; Cartesian coordinates of the spot in the MT SR

coor = transpose([ [angle_pos], [gamma_pos], [alt_layers], [x], [y] ])

return, error
end