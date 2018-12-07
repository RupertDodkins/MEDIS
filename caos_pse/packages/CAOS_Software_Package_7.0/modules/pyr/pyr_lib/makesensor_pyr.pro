; $Id: makesensor_pyr.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;   makesensor_pyr.pro
;
; PURPOSE:
;   This module creates the geometrical parameters relative to a squared
;   sensor geometry.
;
; CALLING SEQUENCE:
;   sensor_geom = makesensor(nxsub, fvalid, size, pupil, psf_sampling,sep, modul,step)
;
; OUTPUT:
;   sensor_geom : a structure contraining the sensor geometrical parameters
;                 (number of active sub-apertures, linear number of sub-ap.,
;                  number of sampling points per sub-ap., total number of
;                  sampling points, x- and y-positions of the sub-ap.,
;                  array representing the sensor)
;
; COMMON BLOCKS:
;   None
;
; SIDE EFFECTS:
;   Modifies the wavefront sensor size by making it multiple of the
;   sub-aperture linear number.
;
; RESTRICTIONS:
;   none.
;
; DESCRIPTION:
;   It makes a matrix representing the sensor geometry with 0 out of the pupp
;   and, under each sub-aperture, the integer corresponding to its order
;   number, for a squared configuration.
;   Several other parameters are also computed and stored in a structured
;   variable sensor_geom which is returned. They concern :
;      - the x- and y-positions of each sub-aperture
;      - the number and size of sub-apertures
;
; HISTORY:
;   program written: october 2002,
;                    Christophe Verinaud (OAA) [verinaud@arcetri.astro.it],
;                    (from makesensor_sq.pro).
;   modifications  : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;-
;
function makesensor_pyr,par,nxsub, fvalid, size, pupil,psf_sampling,sep,modul,step,fftwnd,D

n_pyr = n_elements(modul) ; here =1
nxp = float(size)/par.nxsub 
; (non integer) number of pupp sampling points per sub aperture

sizen=nxsub*fix(nxp)  
nxp = float(sizen)/nxsub
  
print,'New WFS size : ',sizen,nxp
if size ne sizen then begin
pupp=rebin_CCD(findgen(size)/size,findgen(sizen)/sizen,float(pupil))
endif else pupp = float(pupil)

supsize=psf_sampling*size      ;(psf_sampling points on psf)

; TRANSMISSION MASK corresponding to facets
masque = intarr(supsize,supsize,4)

ma=intarr(supsize/2,supsize/2)
ma(*,*)=1

masque(0:supsize/2-1,0:supsize/2-1,0)=ma
masque(supsize/2:supsize-1,0:supsize/2-1,1)=ma
masque(supsize/2:supsize-1,supsize/2:supsize-1,2)=ma
masque(0:supsize/2-1,supsize/2:supsize-1,3)=ma

; Pyramidic PHASE MASK 

mm = dblarr(supsize,supsize)

for k = size*psf_sampling/2-1,0,-1 do for j=size*psf_sampling/2-1,0,-1 do mm[k,j] = $ 
;32.*!DPI*$
;((j+1-size*psf_sampling/2)+(k+1-size*psf_sampling/2))/(128*psf_sampling/2)/$
;sqrt(2)*2.*1.8*1.00715*sep/1.28125

((j+1-size*psf_sampling/2)+(k+1-size*psf_sampling/2))*sep*!DPI/psf_sampling


mm[size*psf_sampling/2:*,0:size*psf_sampling/2-1] = reverse(mm[0:size*psf_sampling/2-1,0:size*psf_sampling/2-1],1)
mm[*,size/2*psf_sampling:*] = reverse(mm[*,0:size/2*psf_sampling-1],2)
 

if par.algo eq 1B then masque = mm

sens_sub_map = fltarr(ceil(nxp),ceil(nxp), nxsub^2)

; array which will contain the map of each active sub-aperture
; with the same resolution [m/sampling point] as the wavefront screen
; map = 1 inside the sub-aperture
;     = a non-integer at the sides

xa = (sizen-1)/2. + ( findgen(nxsub)-((nxsub-1)/2.) )*nxp
; x positions of the sub-apertures in the sizen^2 array

xlim = lonarr(2, nxsub^2)
ylim = lonarr(2, nxsub^2)

fvalid  = fvalid * round(nxp^2.)
; fraction of the total subaperture surface for which a subaperture
; is considered valid (multiplied by the total number of sampling
; points per sub-aperture). If the coefficient is :
;    1, it will take only the entirely illuminated subapertures
;    0, all subapertures which have at least 1 sampling point
;       illuminated will be taken into account

k     = 0
tempo = intarr(sizen, sizen)

sens_cen_pupil = fltarr(2, nxsub^2)
; double vector which will contain the center positions of the active
; sub-apertures in the sizen^2 array

sensor_s1 = fltarr(sizen, sizen)
; array showing the sensor active sub-aperture for information

; Determining the active sub-apertures
FOR i=0,nxsub-1 DO BEGIN          ; loop on lenslet array lines

  FOR j=0,nxsub-1 DO BEGIN        ; loop on lenslet array columns

    tempo = tempo * 0.

    xlim[0,k] = round(xa[i]+.5-nxp/2.) > 0
    xlim[1,k] = round(xa[i]-.5+nxp/2.) < (sizen-1)
    ylim[0,k] = round(xa[j]+.5-nxp/2.) > 0
    ylim[1,k] = round(xa[j]-.5+nxp/2.) < (sizen-1)

    tempo [ xlim[0,k] : xlim[1,k] , ylim[0,k] : ylim[1,k] ] = 1

    tempo = pupp * temporary(tempo)

    IF total(tempo) GT fvalid THEN BEGIN
    ; compares the number of sampling points of subaperture i,j which are
    ; under the pupp with the threshold fvalid

       sensor_s1 = temporary(sensor_s1) + tempo

       sens_sub_map[0,0,k] = float(tempo[xlim[0,k]:xlim[1,k],ylim[0,k]:ylim[1,k]])
       ; all the sampling points touched by the sub-aperture k
       ; are taken with a weight equal to 1

       ; putting fractionnal intensities on the border pixels
       sens_sub_map[0,*,k] = sens_sub_map[0,*,k] * (0.5+xlim[0,k]-(xa[i]-nxp/2.))
       ; left edge

       sens_sub_map[*,0,k] = sens_sub_map[*,0,k] * (0.5+ylim[0,k]-(xa[j]-nxp/2.))
       ; lower edge

       sens_sub_map[xlim[1,k]-xlim[0,k],*,k] = sens_sub_map[xlim[1,k]-xlim[0,k],*,k] $
                                              *( xa[i]+nxp/2. - xlim[1,k] + 0.5 )
       ; right border

       sens_sub_map[*,ylim[1,k]-ylim[0,k],k] = sens_sub_map[*,ylim[1,k]-ylim[0,k],k] $
                                              *( xa[j]+nxp/2. - ylim[1,k] + 0.5 )
       ; upper border

       sens_cen_pupil[0,k] = xa[i]
       sens_cen_pupil[1,k] = xa[j]

       k = k+1
       ; order number of the next valid subaperture

    ENDIF

  ENDFOR

ENDFOR                             ; end of loop on all lenslets

IF k LT 1 THEN BEGIN
   print, 'Invalid geometry : no active sub-aperture found.'
   print, ''
   return, !caos_error.invalid_geom
ENDIF

nsp =  k
; total number of valid (active) subaperture
sens_sub_map = sens_sub_map[*,*,0:k-1]
; active sub-aperture maps
xlim = xlim[*,0:k-1]
ylim = ylim[*,0:k-1]
sens_cen_pupil = sens_cen_pupil[*,0:k-1]
; active sub-aperture center(x- and y-) coordinates
; in the sizen^2 array

tsp = fltarr(nsp)

FOR i = 0,nsp-1 DO tsp[i]=total(sens_sub_map[*,*,i])
; number of active sampling point per subpupp

tpyr = dblarr(n_pyr)

for kk=0,n_pyr-1 do begin

l=modul(kk)*psf_sampling  ;(l px of shift)
px=step
phase_screen=float(pupil)*0.

fov = par.pyr_fov/3600.*!DPI/180.*D/par.lambda*psf_sampling

; Launching the pyramid algorithm for computing the intensity 
; normalization factor (could be computed directly)

if (par.algo eq 0B and par.mod_type eq 1B) then begin 

if fftwnd eq 0B then error = $
pyrccd_knife_circ(size*psf_sampling,size,phase_screen,l,px,masque,pupil,fov,iccds,iii)
if fftwnd eq 1B then error = $
pyrccd_fftwnd_knife_circ(size*psf_sampling,size,phase_screen,l,px,masque,pupil,fov,iccds,iii)

endif

if (par.algo eq 1B and par.mod_type eq 1B) then begin 

if fftwnd eq 0B  then error = $
pyrccd_circ(size*psf_sampling,size,phase_screen,l,px,masque,pupil,fov,iccds,iii)
if fftwnd eq 1B  then error = $
pyrccd_fftwnd_circ(size*psf_sampling,size,phase_screen,l,px,masque,pupil,fov,iccds,iii)

endif

if (par.algo eq 0B and par.mod_type eq 0B) then begin 

if fftwnd eq 0B  then error = $
pyrccd_knife_squa(size*psf_sampling,size,phase_screen,l,px,masque,pupil,fov,iccds,iii)
if fftwnd eq 1B then error = $
pyrccd_fftwnd_knife_squa(size*psf_sampling,size,phase_screen,l,px,masque,pupil,fov,iccds,iii)

endif

if (par.algo eq 1B and par.mod_type eq 0B) then begin 

if fftwnd eq 0B  then error = $
pyrccd_squa(size*psf_sampling,size,phase_screen,l,px,masque,pupil,fov,iccds,iii)
if fftwnd eq 1B then error = $
pyrccd_fftwnd_squa(size*psf_sampling,size,phase_screen,l,px,masque,pupil,fov,iccds,iii)

endif


tpyr(kk)=total(iccds)

endfor

; Structured variable containing all these parameters
sensor_geom = $
   {          $
   px 	    : px,	      $
   nsp      : nsp,            $ ; number of active sub-apertures [integer]
   nxp      : nxp,            $ ; number of sampling points per sub-ap (linear) [float]
   tsp      : tsp,            $ ; total number of sampling points per active sub-aperture
                                ; [nsp vector of floats]
   sizen    : sizen,          $ ;
   tpyr     : tpyr,           $ ; normalisation factor for intensity
   masque   : masque,         $ ; masque corresponding to pyramid facets
   sensor_s1: sensor_s1,      $ ; sensor active sub-ap image
   cen_pupil: sens_cen_pupil, $ ; active sub-aperture center coordinates in sizen^2 array
                                ; [(2,nsp) matrix of floats]
   sub_map  : sens_sub_map,   $ ; active sub-aperture maps [(ceil(nxp)+1,ceil(nxp)+1,nsp)
                                ; matrix of floats]
   xlim     : xlim,           $ ; the inf and max limits of each sub-ap in sizen^2 array
                                ; [(2,nsp) matrix of long]
   ylim     : ylim            $ ; the inf and max limits of each sub-ap in sizen^2 array
   }                            ; [(2,nsp) matrix of long]

return, sensor_geom             ; returns the sensor geometry structured variable
end