; $Id: display_3d.pro,v 1.1.1.1 2003/03/07 10:46:30 marcel Exp $
; +
; name:
;    display_3d
;
; purpose:
;    display of a 3D-map.
;
; inputs:
;    map      : 3D-map (i.e. map[x, y, z])
;    scale_x  : x-scale [rd/px]
;    scale_y  : y-scale [rd/px]
;    scale_z  : z-scale [m/px]
;
; keywords:
;    THRESHOLD   : threshold as a ratio wrt the maximum of the 3D-map
;                 (default value is 0.05, i.e. 5% of the max intensity value).
;    X_VIEW_ANGLE: x-view-angle [deg] (default value is 22.).
;    Z_VIEW_ANGLE: z-view-angle [deg] (default value is 31.).
;    OFFSET_X    : mean x-offset [rd] (default value is 0.).
;    OFFSET_Y    : mean y-offset [rd] (default value is 0.).
;    OFFSET_Z    : mean z-offset [m]  (default value is 0.).
;    WIN_XSIZE   : window x-size [px] (default value is 512).
;    WIN_YSIZE   : window y-size [px] (default value is 512).
;
; output:
;    error: error code (see caos_init).
;
; program written: march 1999,
;                  Marcel Carbillet (OAA) [marcel@arcetri.astro.it],
;                  Elise Viard      (ESO) [eviard@eso.org].
; modifications  : november 1999,
;                  Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                 -adapted to version 2.0 (CAOS)
; -

function display_3d, map,                       $
                     scale_x,                   $
                     scale_y,                   $
                     scale_z,                   $
                     WIN_XSIZE=win_xsize,       $
                     WIN_YSIZE=win_ysize,       $
                     THRESHOLD=threshold,       $
                     OFFSET_X=offset_x,         $
                     OFFSET_Y=offset_y,         $
                     OFFSET_Z=offset_z,         $
                     X_VIEW_ANGLE=x_view_angle, $
                     Z_VIEW_ANGLE=z_view_angle, $
                     CHARSIZE=charsize

error = !caos_error.ok

erase

if not(n_elements(win_xsize))    then win_xsize    = 512
if not(n_elements(win_ysize))    then win_ysize    = 512
if not(n_elements(threshold))    then threshold    = .05
if not(n_elements(x_view_angle)) then x_view_angle = 22.
if not(n_elements(z_view_angle)) then z_view_angle = 31.
if not(n_elements(offset_x))     then offset_x     = 0.
if not(n_elements(offset_y))     then offset_y     = 0.
if not(n_elements(offset_z))     then offset_z     = 0.

sz = SIZE(map)

xx = indgen(sz[1]) & yy = indgen(sz[2]) & zz = indgen(sz[3])

xrange = [min(xx), max(xx)]
yrange = [min(yy), max(yy)]
zrange = [min(zz), max(zz)]

dis_device = !D.NAME
set_plot, 'Z'

device, set_resolution=[win_xsize, win_ysize]

; 3D=>2D transformation definition
surface, map[*,*,(SIZE(map))[3]/2], $
         xx,                        $
         yy,                        $
         /SAVE,                     $
         /NODATA,                   $
         XRANGE=xrange,             $
         YRANGE=yrange,             $
         ZRANGE=zrange,             $
         AX    =x_view_angle,       $
         AZ    =z_view_angle,       $
         XSTYLE=5,                  $
         YSTYLE=5,                  $
         ZSTYLE=5

; x-axis definition
axis, XRANGE=                                                     $
         ((!X.CRANGE-(sz[1]-1)/2.)*scale_x+offset_x)*!RADEG*3600, $
      XAXIS=0,                                                    $
      /XSTYLE,                                                    $
      /T3D,                                                       $
      XTITLE='x-position [arcsec]',                               $
      CHARSIZE=2.

; y-axis definition
axis, YRANGE=                                                     $
         ((!Y.CRANGE-(sz[2]-1)/2.)*scale_y+offset_y)*!RADEG*3600, $
      YAXIS=0,                                                    $
      /YSTYLE,                                                    $
      /T3D,                                                       $
      YTITLE='y-position [arcsec]',                               $
      CHARSIZE=2.

; z-axis definition
axis, ZRANGE=                                             $
         ((!Z.CRANGE-(sz[3]-1)/2.)*scale_z+offset_z)/1E3, $
      ZAXIS=2,                                            $
      /ZSTYLE,                                            $
      /T3D,                                               $
      ZTITLE='altitude [km]',                             $
      CHARSIZE=2.

; definition
shade_volume, map,                $
              threshold*max(map), $
              vertex,             $
              poly,               $
              /LOW

dummy = polyshade(vertex,    $
                  poly,      $
                  /T3D       )

dummy = tvrd()
set_plot, dis_device
tvscl, dummy

return, error
end
