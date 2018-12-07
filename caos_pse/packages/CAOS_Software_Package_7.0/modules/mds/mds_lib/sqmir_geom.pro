; $Id: sqmir_geom.pro,v 7.0 2016/04/29 marcel.carbillet $
;
FUNCTION sqmir_geom, nb_act, size, eps

d_act = float(size-1)/(nb_act-1)

; coordinates of the actuators
xa = findgen(nb_act) * d_act - size/2 + 0.5
ya = xa

maxi = max(xa) > (-1.*min(xa))

IF fix(maxi) GT (size/2.) THEN BEGIN 
   newsize = fix(maxi)
   xa = temporary(xa) + (newsize-size)/2
   size = newsize
ENDIF 

; determining which actuators are in and just around the pupil
k = 0
coord = fltarr(nb_act*nb_act,2)
; minimal distance between actuators 
; (radius of the influence zone of the actuators influence fct)

FOR i=0,nb_act-1 DO BEGIN
   FOR j=0,nb_act-1 DO BEGIN
      distance = sqrt((xa[i])^2.+(ya[j])^2.)
      IF ((distance-d_act) LE size/2. AND $
          (distance+d_act) GE eps*size/2.) THEN BEGIN
         coord[k,0] = xa[i] + size/2.-.5
         coord[k,1] = ya[j] + size/2.-.5
         k = k+1
      ENDIF 
   ENDFOR
ENDFOR

nact  = k
coord = coord[0:k-1,*]

geom = {coord:coord, size:size, nact:nact, d_act:d_act}

return, geom
END