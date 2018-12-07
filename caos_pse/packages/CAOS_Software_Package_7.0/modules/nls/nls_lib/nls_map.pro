; $Id: nls_map.pro,v 7.0 2016/04/29 marcel.carbillet $
;+
; NAME:
;    nls_map
;
; PURPOSE:
;    Function for NLS module, calculation of the spot data cube.
;    Calculation of the intensity map at differents altitudes
;    output: the LSG 3D-map within the projector telescope coordinates system.
;
; CATEGORY:
;    NLS library routine
;
; CALLING SEQUENCE:
;    error = nls_map(map3D,  $
;                    dim,    $
;                    n_sub,  $
;                    screen, $
;                    map2D,  $
;                    defoc,  $
;                    Na_prof )
;
; INPUTS:
;    dim    :...
;    n_sub  :...
;    screen :...
;    map2D  :...
;    defoc  : defocus array calculated in nls_defocus.pro
;    Na_prof:
;
; OUTPUTS:
;    error: error code [long scalar].
;
; OUTPUTS included in call:
;    map3D: 3D array containing intensity map at different 
;           altitudes in the sodium layer (within the projector 
;           telescope coordinates system).
;
; EXAMPLE:
;    ...
;
; MODIFICATION HISTORY:
;   program written: october 1998,
;                    Elise  Viard     (ESO) [eviard@eso.org],
;                    Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;   modifications  : december 1999,
;                    Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                   -adapted to version 2.0 (CAOS).
;                  : april 2000,
;                    Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                   -debugged: screen is a wavefront, but was treated as a
;                    phase screen => error of 2*!pi/lambda.
;                  : april 2016,
;                    Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                   -adapted to Soft. Pack. CAOS 7.0.
;
;-
;
FUNCTION nls_map, map3D,  $
                  dim,    $
                  n_sub,  $
                  screen, $
                  map2D,  $
                  defoc,  $
                  Na_prof

error = !caos_error.ok

np = (size(map2D))[1] & db_np = 2*np & map3D = fltarr(2*np,2*np,n_sub)
db_map2D = fltarr(db_np,db_np) & db_defoc = db_map2D & db_screen = db_map2D

np1 = np/2 & np2 = 3*np/2-1
db_map2D[np1:np2,np1:np2] = map2D & db_screen[np1:np2,np1:np2] = screen

for i = 0, n_sub-1 do begin 

   db_defoc[np1:np2,np1:np2] = defoc[*,*,i]
   phase = (air_ref_idx(589E-9)/air_ref_idx(500E-9))*2.*!PI/589E-9*db_screen $
         + db_defoc
   tfmap = shift(float((abs(fft(db_map2D*exp(complex(0,1)*phase))))^2),np,np)
   dummy = total(tfmap) & map3D[*,*,i] = tfmap/dummy*Na_prof[i] 

endfor

return, error
end