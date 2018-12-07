; $Id: slope.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    slope.pro
;
; PURPOSE:
;    This routine calculates the centroid positions of the images 
;    under each active subaperture of the SHWFS sensor.
;
; CATEGORY:
;    CEN's library routine
;
; CALLING SEQUENCE:
;    error = slope(inp_mim_t, rebin_fact, meas)
;
; ROUTINE MODIFICATION HISTORY:
;   routine written: june 2001,
;                    Christophe Verinaud (OAA) [verinaud@arcetri.astro.it].
;   modifications  : october 2002,
;                    Christophe Verinaud (OAA) [verinaud@arcetri.astro.it]:
;                   -normalization alternative added.
;                  : february 2003,
;                    Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                   -"cleaned" for CAOS system 4.0.
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;-
;
FUNCTION slope, inp_mim_t, meas, algo_type

error = !caos_error.ok

if algo_type eq 0B then begin

n_star = 1

if (size(inp_mim_t.image))[0] ne 2 then n_star =  (size(inp_mim_t.image))[3]

meas = fltarr(2*inp_mim_t.nsp)
if n_star gt 1 then meas = fltarr(2*inp_mim_t.nsp,n_star)
size_CCD = (size(inp_mim_t.image))[1]
temp = fltarr(size_CCD/2, size_CCD/2,4)

if n_star eq 1 then begin

temp(*,*,0)=inp_mim_t.image(0:size_CCD/2-1,0:size_CCD/2-1)
temp(*,*,1)=inp_mim_t.image(size_CCD/2:size_CCD-1,0:size_CCD/2-1)
temp(*,*,2)=inp_mim_t.image(size_CCD/2:size_CCD-1,size_CCD/2:size_CCD-1)
temp(*,*,3)=inp_mim_t.image(0:size_CCD/2-1,size_CCD/2:size_CCD-1)

endif
; extraction of the 4 quadrants

if n_star eq 1 then tot=total(inp_mim_t.image)    ; normalisation factor

print,tot

if n_star gt 1 then begin
tot=dblarr(n_star)
for k=0,n_star-1 do tot(k) = total(inp_mim_t.image[*,*,k])
endif

if n_star eq 1 then begin

temp(*,*,0)=inp_mim_t.image(0:size_CCD/2-1,0:size_CCD/2-1)
temp(*,*,1)=inp_mim_t.image(size_CCD/2:size_CCD-1,0:size_CCD/2-1)
temp(*,*,2)=inp_mim_t.image(size_CCD/2:size_CCD-1,size_CCD/2:size_CCD-1)
temp(*,*,3)=inp_mim_t.image(0:size_CCD/2-1,size_CCD/2:size_CCD-1)

; extraction of the 4 quadrants
FOR i=0, inp_mim_t.nsp-1 DO BEGIN           ; loop on the subapertures

a=inp_mim_t.xspos_CCD(i)
b=inp_mim_t.yspos_CCD(i)


  meas(i) = $
  ((temp(a,b,0)-temp(a,b,1)+temp(a,b,3)-temp(a,b,2)))/tot
  
  
  meas(i+inp_mim_t.nsp) = $
  ((temp(a,b,0)-temp(a,b,2)+temp(a,b,1)-temp(a,b,3)))/tot

  
ENDFOR                       ; end of the loop on the subapertures
endif


if n_star gt 1 then begin


FOR k=0,n_star - 1 do begin 
             ; loop on the stars
temp(*,*,0)=inp_mim_t.image(0:size_CCD/2-1,0:size_CCD/2-1,k)
temp(*,*,1)=inp_mim_t.image(size_CCD/2:size_CCD-1,0:size_CCD/2-1,k)
temp(*,*,2)=inp_mim_t.image(size_CCD/2:size_CCD-1,size_CCD/2:size_CCD-1,k)
temp(*,*,3)=inp_mim_t.image(0:size_CCD/2-1,size_CCD/2:size_CCD-1,k)

; extraction of the 4 quadrants
FOR i=0, inp_mim_t.nsp-1 DO BEGIN           ; loop on the subapertures

a=inp_mim_t.xspos_CCD(i)
b=inp_mim_t.yspos_CCD(i)

  meas(i,k) = $
((temp(a,b,0)-temp(a,b,1)+temp(a,b,3)-temp(a,b,2))+1.e-8)/tot(k)
  
  
  meas(i+inp_mim_t.nsp,k) = $
  ((temp(a,b,0)-temp(a,b,2)+temp(a,b,1)-temp(a,b,3)))/tot(k)
  
  
ENDFOR                       ; end of the loop on the subapertures
ENDFOR                       ; end of the loop on the stars

endif
endif


if algo_type eq 1B then begin

n_star = 1

if (size(inp_mim_t.image))[0] ne 2 then n_star =  (size(inp_mim_t.image))[3]

meas = fltarr(2*inp_mim_t.nsp)
if n_star gt 1 then meas = fltarr(2*inp_mim_t.nsp,n_star)
size_CCD = (size(inp_mim_t.image))[1]
temp = fltarr(size_CCD/2, size_CCD/2,4)

if n_star eq 1 then begin

temp(*,*,0)=inp_mim_t.image(0:size_CCD/2-1,0:size_CCD/2-1)
temp(*,*,1)=inp_mim_t.image(size_CCD/2:size_CCD-1,0:size_CCD/2-1)
temp(*,*,2)=inp_mim_t.image(size_CCD/2:size_CCD-1,size_CCD/2:size_CCD-1)
temp(*,*,3)=inp_mim_t.image(0:size_CCD/2-1,size_CCD/2:size_CCD-1)

endif
; extraction of the 4 quadrants

if n_star eq 1 then tot=total(inp_mim_t.image)    ; normalisation factor
if n_star gt 1 then begin
tot=dblarr(n_star)
for k=0,n_star-1 do tot(k) = total(inp_mim_t.image[*,*,k])
endif

if n_star eq 1 then begin

temp(*,*,0)=inp_mim_t.image(0:size_CCD/2-1,0:size_CCD/2-1)
temp(*,*,1)=inp_mim_t.image(size_CCD/2:size_CCD-1,0:size_CCD/2-1)
temp(*,*,2)=inp_mim_t.image(size_CCD/2:size_CCD-1,size_CCD/2:size_CCD-1)
temp(*,*,3)=inp_mim_t.image(0:size_CCD/2-1,size_CCD/2:size_CCD-1)

; extraction of the 4 quadrants
FOR i=0, inp_mim_t.nsp-1 DO BEGIN           ; loop on the subapertures

a=inp_mim_t.xspos_CCD(i)
b=inp_mim_t.yspos_CCD(i)


  meas(i) = $
 ((temp(a,b,0)-temp(a,b,1)+temp(a,b,3)-temp(a,b,2)))/$
 ((temp(a,b,0)+temp(a,b,1)+temp(a,b,3)+temp(a,b,2))+1.e-8)
  
  
  meas(i+inp_mim_t.nsp) = $
    ((temp(a,b,0)-temp(a,b,2)+temp(a,b,1)-temp(a,b,3)))/$
    ((temp(a,b,0)+temp(a,b,2)+temp(a,b,1)+temp(a,b,3))+1.e-8)

  
ENDFOR                       ; end of the loop on the subapertures
endif

if n_star gt 1 then begin


FOR k=0,n_star - 1 do begin 
             ; loop on the stars
temp(*,*,0)=inp_mim_t.image(0:size_CCD/2-1,0:size_CCD/2-1,k)
temp(*,*,1)=inp_mim_t.image(size_CCD/2:size_CCD-1,0:size_CCD/2-1,k)
temp(*,*,2)=inp_mim_t.image(size_CCD/2:size_CCD-1,size_CCD/2:size_CCD-1,k)
temp(*,*,3)=inp_mim_t.image(0:size_CCD/2-1,size_CCD/2:size_CCD-1,k)

; extraction of the 4 quadrants
FOR i=0, inp_mim_t.nsp-1 DO BEGIN           ; loop on the subapertures

a=inp_mim_t.xspos_CCD(i)
b=inp_mim_t.yspos_CCD(i)

  meas(i,k) = $
  ((temp(a,b,0)-temp(a,b,1)+temp(a,b,3)-temp(a,b,2)))/$
  ((temp(a,b,0)+temp(a,b,1)+temp(a,b,3)+temp(a,b,2)))
  
  
  meas(i+inp_mim_t.nsp,k) = $
   ((temp(a,b,0)-temp(a,b,2)+temp(a,b,1)-temp(a,b,3)))/$
   ((temp(a,b,0)+temp(a,b,2)+temp(a,b,1)+temp(a,b,3))+1.e-8)
  
  
ENDFOR                       ; end of the loop on the subapertures
ENDFOR                       ; end of the loop on the stars

endif
endif

return, error
end