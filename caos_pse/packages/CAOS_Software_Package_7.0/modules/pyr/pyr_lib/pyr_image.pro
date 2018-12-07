; $Id pyr_image.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;   pyr_image.pro
;
; PURPOSE:
;   ...
;
; CALLING SEQUENCE:
;   ...
;
; OUTPUT:
;   ...
;
; COMMON BLOCKS:
;   ...
;
; SIDE EFFECTS:
;   ...
;
; RESTRICTIONS:
;   ...
;
; DESCRIPTION:
;   ...
;
; HISTORY:
;   program written: june 2001,
;                    Christophe Verinaud (OAA) [verinaud@arcetri.astro.it].
;   modifications  : january 2005,
;                    Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr]:
;                   -some useless print eliminated.
;                  : may 2016,
;                    Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                   -adapted to Soft. Pack. CAOS 7.0.
;-
;
function pyr_ima_compute, phase_screen, init, par, sensor_image,iii,pup,fov, fftwnd

common caos_block, tot_iter, this_iter

posxk=init.posxk
posyk=init.posyk


; Nb of sampling points per Lambda/D
psf_sampling = init.psf_sampling

n_spot = 1

nsub   = par.nxsub
if par.optcoad eq 0B then sensor_image = dblarr(nsub*n_spot*2, nsub*n_spot*2,par.n_pyr)

dim=(size(phase_screen))[1]
size=dim*psf_sampling       ;(psf_sampling points on psf (lambda over D))

if par.optcoad eq 1B then sensor_image = dblarr(size,size,par.n_pyr); for Layer Oriented only (MAOS pack)

for kk = 0,par.n_pyr -1 do begin ; n-pyr=1 here

l=double(par.modul[kk]*psf_sampling)    ;(l px of shift)

m=init.masque
tpup=total(pup)

tnph=init.starnph[kk]*tpup ;total nb of photons arriving in pupil plane
		           ; some of them are diffracted out of the pupil

tpyr = init.tpyr           ; normalisation factor


; Function calls for PHASE MASK + CIRCULAR MODULATION  algorithm
if (par.algo eq 1B and par.mod_type eq 1B) then begin 

if par.fftwnd eq 1B then error = $
pyrccd_fftwnd_circ(size,dim,phase_screen[*,*,kk],l,init.px,m,pup,fov,iccds,iii)
if par.fftwnd eq 0B then error = $
pyrccd_circ(size,dim,phase_screen[*,*,kk],l,init.px,m,pup,fov,iccds,iii)

endif

; Function calls for TRANSMISSION MASK + CIRCULAR MODULATION  algorithm
if (par.algo eq 0B and par.mod_type eq 1B) then begin 

if par.fftwnd eq 1B then error = $
pyrccd_fftwnd_knife_circ(size,dim,phase_screen[*,*,kk],l,init.px,m,pup,fov,iccds,iii)
if par.fftwnd eq 0B then error = $
pyrccd_knife_circ(size,dim,phase_screen[*,*,kk],l,init.px,m,pup,fov,iccds,iii)

endif

; Function calls for TRANSMISSION MASK + SQUARE MODULATION  algorithm
if (par.algo eq 0B and par.mod_type eq 0B) then begin 

if par.fftwnd eq 1B then error = $
pyrccd_fftwnd_knife_squa(size,dim,phase_screen[*,*,kk],l,init.px,m,pup,fov,iccds,iii)
if par.fftwnd eq 0B then error = $
pyrccd_knife_squa(size,dim,phase_screen[*,*,kk],l,init.px,m,pup,fov,iccds,iii)

endif

; Function calls for PHASE MASK + SQUARE MODULATION  algorithm
if (par.algo eq 1B and par.mod_type eq 0B) then begin 

if par.fftwnd eq 1B then error = $
pyrccd_fftwnd_squa(size,dim,phase_screen[*,*,kk],l,init.px,m,pup,fov,iccds,iii)
if par.fftwnd eq 0B then error = $
pyrccd_squa(size,dim,phase_screen[*,*,kk],l,init.px,m,pup,fov,iccds,iii)

endif


if par.optcoad eq 0B then begin

iccd=dblarr(init.sizen,init.sizen,4)

;COLLECTING THE 4 QUADRANTS AND REBINNING TO CCD PIX:

if par.algo eq 0B then begin ; ********* for transmission mask algorithm

for k = 0,3 do begin
if dim ne init.sizen then begin
iccd(*,*,k)=rebin_CCD(findgen(dim)/dim,findgen(init.sizen)/init.sizen,$
(iccds(size/2-dim/2+1:size/2+dim/2,size/2-dim/2+1:size/2+dim/2,k)))*tnph/tpyr(kk)
endif else $
iccd(*,*,k)=iccds(size/2-dim/2+1:size/2+dim/2,size/2-dim/2+1:size/2+dim/2,k)*tnph/tpyr(kk)
endfor

endif

if par.algo eq 1B then begin ;  ********** for phase mask algorithm

for k=0,3 do begin

if dim ne init.sizen then begin
iccd[*,*,k]=rebin_CCD(findgen(dim)/dim,findgen(init.sizen)/init.sizen,$
(iccds(size/2-dim/2+posxk[k]+1:size/2+dim/2+posxk[k],size/2-dim/2+posyk[k]+1:size/2+dim/2+posyk[k])))*tnph/tpyr[kk]
endif else $
iccd[*,*,k]=iccds[size/2-dim/2+posxk[k]+1:size/2+dim/2+posxk[k],size/2-dim/2+$
posyk[k]+1:size/2+dim/2+posyk[k]]*tnph/tpyr[kk]

endfor

endif


;*****************computation of sensor_image on CCD*************************
 
 	for nn=0,init.nsp-1 do begin



sensor_image(init.xspos_CCD(nn),init.yspos_CCD(nn),kk)=$
              total(iccd(init.xlim(0,nn):init.xlim(1,nn),$
	                  init.ylim(0,nn):init.ylim(1,nn),0)) 
sensor_image(init.xspos_CCD(nn)+nsub*n_spot,init.yspos_CCD(nn),kk)=$
              total(iccd(init.xlim(0,nn):init.xlim(1,nn),$
	                  init.ylim(0,nn):init.ylim(1,nn),1)) 
sensor_image(init.xspos_CCD(nn)+nsub*n_spot,init.yspos_CCD(nn)+nsub*n_spot,kk)=$
              total(iccd(init.xlim(0,nn):init.xlim(1,nn),$
	                  init.ylim(0,nn):init.ylim(1,nn),2)) 
sensor_image(init.xspos_CCD(nn),init.yspos_CCD(nn)+nsub*n_spot,kk)=$
             total(iccd(init.xlim(0,nn):init.xlim(1,nn),$
	                  init.ylim(0,nn):init.ylim(1,nn),3)) 


	endfor
 endif
 
 if par.optcoad eq 1B then sensor_image[*,*,kk] = iccds * tnph/tpyr[kk]
 
 endfor
 
return, !caos_error.ok

END

function pyr_image,wfp, init, par, sensor_image,iii, fftwnd

COMMON caos_block, tot_iter, this_iter

phase_screen = wfp.screen * 2.*!PI/par.lambda
pup=wfp.pupil
; conversion from optical path screen toward phase screen

;****************LGS NOT YET IMPLEMENTED !!!!!!!

;if (size(wfp.map))[0] eq 3 then begin
 ;  error = prepare_lgs(phase_screen, init, par, sensor_image, wfp.constant, wfp.map)
   ; laser guide star obtained by upward propagation
;endif


;size of Field of View after diaphragm in sampling points of image on
;top of pyramid
fov = par.pyr_fov/3600.*!DPI/180.*wfp.scale_atm*(size(wfp.screen))[1]/par.lambda*par.psf_sampling

error = $
   pyr_ima_compute(phase_screen, init, par, sensor_image,iii,pup,fov,fftwnd)

;sensor_image[0,0] = phase_screen
print,'NPHNPH :: ', total(sensor_image) 

return, !caos_error.ok
end