pro sn_mainloop_mux, filename
window, 0, xs=400, ys=400
window, 1, xs=400, ys=400
window, 2, xs=400, ys=400
window, 3, xs=400, ys=400
loadct, 13

common ec_common, dm, nact, dm_piston

@efc_read_inputs
sign=+1;flatten for arbitrary polarization

;-- generate ASF at mean wavelength, writing out phase at occulter's exit pupil
lam = mean(lam_array)
print, nact
dm = fltarr(nact, nact)

;Noise sources
hmag = 2
dit = 1.471
ndit = 1
nexpo = 1

;Aperture
os = 7
aperture = shift(dist(n*os),n*os/2,n*os/2)
aperture = aperture le ceil(os * 1.0/pupil_ratio)
aperture = rebin(float(aperture),n,n)
norm_flux = 1d;total(aperture) 
print, norm_flux

;Mask for dark hole area
mask = fltarr(n,n)
mask[n/2+round(inner_radius/pupil_ratio):n/2+round(outer_radius/pupil_ratio),n/2-round(outer_radius/pupil_ratio):n/2+round(outer_radius/pupil_ratio)]=1d
mask_detect = smooth(mask,2.0/pupil_ratio)

;Define speckle nulling params
n_ph = 4; number of phase steps
ph = findgen(n_ph)/(n_ph) * 2 * !dpi
probe_int = 1e-3
n_iter = 40
n_speckle = 30
gain=0.6
n_calib=ceil(outer_radius / cos(45.0/180*!dpi))
res_scan=fltarr(n_ph, n_speckle)
speckle_phot_calib=fltarr(n_calib+1)
print, n_calib

;-- calibration step
v={use_errors:1, use_lodm:0, use_hodm:1, use_coro:1, use_ADC:0, write_arrays:1, use_atm:0, pupil_ratio:pupil_ratio}
prop_run, prescription, asf, lam, n, passval=v
ref_field = addnoise_pharo(abs(asf)^2 / max_psf, hmag, dit, ndit, nexpo)
xx = (findgen(nact)-nact/2) / nact # replicate(1.0,nact)
yy = transpose(xx)
dm0=dm

for kk=inner_radius, n_calib do begin
dm=dm0
kx = kk * cos(45.0/180*!dpi)
ky = kk * sin(45.0/180*!dpi)
;Compute amplitude
amp = 2 * lam * 1e-6 / (2*!dpi) * sqrt(probe_int);probe_int specklex = xx * kx * 2 * !pi 
y = yy * ky * 2 * !pi
h = cos(x+y) 
dm = dm + h * amp; probe_int speckle for calibration purposes 
v={use_errors:1,use_lodm:0,use_hodm:1,use_coro:1, use_ADC:0, write_arrays:1, use_atm:0, pupil_ratio:pupil_ratio}
prop_run, prescription, asf, lam, n, passval=v
calib_field = ( addnoise_pharo((abs(asf)^2) / max_psf, hmag, dit, ndit, nexpo) - ref_field )
;Detect speckle
speckle_level = max(calib_field, speckle_ind)
ind = array_indices(calib_field, speckle_ind)
speckle_phot_calib[kk] = total(shift(aperture, ind[0]-n/2,ind[1]-n/2) * calib_field) / norm_flux
print, speckle_phot_calib[kk]
img = calib_field
wset,1
tvscl, congrid(img[n/2-round(outer_radius/pupil_ratio):n/2+round(outer_radius/pupil_ratio),n/2-round(outer_radius/pupil_ratio):n/2+round(outer_radius/pupil_ratio)],400,400)
endfor

dm = fltarr(nact, nact)
v={use_errors:1,use_lodm:0,use_hodm:1,use_coro:1, use_ADC:0, write_arrays:1, use_atm:0, pupil_ratio:pupil_ratio}
prop_run, prescription, asf, lam, n, passval=v
ref_field = addnoise_pharo((abs(asf)^2) / max_psf, hmag, dit, ndit, nexpo)


;Aberrated field init
v={use_errors:1,use_lodm:0,use_hodm:1,use_coro:1, use_ADC:0, write_arrays:1, use_atm:0, pupil_ratio:pupil_ratio}
prop_run, prescription, asf, lam, n, passval=v
init_field = mask * ( addnoise_pharo((abs(asf)^2) / max_psf,hmag,dit, ndit, nexpo)); define dark hole area

    print, '##################################################################'
    print, '##################################################################'
    print, '##################################################################'
    print, '##################################################################'
    print, '##################################################################'
    print, '##################################################################'
    print, 'Median contrast', median(init_field(where(mask ne 0)))
    print, '##################################################################'
    print, '##################################################################'
    print, '##################################################################'
    print, '##################################################################'
    print, '##################################################################'
    print, '##################################################################'

kx=fltarr(n_speckle)
ky=fltarr(n_speckle)
amp=fltarr(n_speckle)
res_ph=fltarr(n_speckle)
ind_sp=fltarr(2,n_speckle)


for it = 0, n_iter-1 do begin
    maskb = 1.0 ;- aperture  
    ;Detect speckle
    for sp = 0, n_speckle-1 do begin
        speckle_level = max(init_field*maskb, speckle_ind)
        ind = array_indices(init_field, speckle_ind)
        ind_sp[0,sp]=ind[0]
        ind_sp[1,sp]=ind[1]
        speckle_phot = total(shift(aperture, ind[0]-n/2,ind[1]-n/2) * init_field) / norm_flux
        maskb = maskb * (1.0 - shift(aperture, ind[0]-n/2,ind[1]-n/2)  )
        ;Compute spatial frequency
        kx[sp] = (ind[0] - n/2) * pupil_ratio; kx ky is the frequency (cycles per aperture -> lb/D in the focal plane)
        ky[sp] = (ind[1] - n/2) * pupil_ratio
        kk_s=round( sqrt(kx[sp]^2d + ky[sp]^2d ) )
        ;print, kk_s
        ;Compute amplitude
        amp[sp] = 2 * lam * 1e-6 / (2*!dpi) * sqrt(speckle_phot * probe_int / speckle_phot_calib[kk_s])  
    endfor
   
    ;Scan for phase
    for i = 0,n_ph-1 do begin
    dm0 = dm  
        for sp = 0, n_speckle-1 do begin  
        x[*,*] = xx * kx[sp] * 2 * !pi 
        y[*,*] = yy * ky[sp] * 2 * !pi 
        h = cos((x[*,*]+y[*,*]) + ph[i]) 
        dm = dm + h * amp[sp]
        wset,0
        tvscl, congrid(dm,400,400)
        endfor  
    ;stop
    v={use_errors:1,use_lodm:0,use_hodm:1,use_coro:1, use_ADC:0, write_arrays:1, use_atm:0, pupil_ratio:pupil_ratio}
    prop_run, prescription, asf, lam, n, passval=v
    res_field = mask * (addnoise_pharo((abs(asf)^2) / max_psf,hmag,dit, ndit, nexpo))
         for sp = 0, n_speckle-1 do begin  
         res_scan[i,sp]=total(shift(aperture, ind_sp[0,sp]-n/2,ind_sp[1,sp]-n/2) * res_field) / norm_flux
         endfor
    
    wset,1
    img = mask*res_field
    tvscl, congrid(img[n/2-round(outer_radius/pupil_ratio):n/2+round(outer_radius/pupil_ratio),n/2-round(outer_radius/pupil_ratio):n/2+round(outer_radius/pupil_ratio)],400,400)
    dm=dm0
    endfor
    for sp = 0, n_speckle-1 do begin
        x[*,*] = xx * kx[sp] * 2 * !pi 
        y[*,*] = yy * ky[sp] * 2 * !pi   
        res_ph[sp] = atan((res_scan[0,sp]-res_scan[2,sp]), (res_scan[1,sp]-res_scan[3,sp]))
        if res_ph[sp] lt 0 then res_ph[sp] = res_ph[sp] + !dpi
        ;print, res_ph[sp]
        dummy = min(abs(res_ph[sp]-ph), ind_test)
        if n_elements(where(res_scan[*,sp] gt res_scan[ind_test,sp])) ge 2 then begin
        h = cos((x+y) + res_ph[sp]) 
        endif else begin    
        h = cos((x+y) + res_ph[sp] - !dpi)
        endelse
    dm = dm + h * gain * amp[sp]
    endfor
    v={use_errors:1,use_lodm:0,use_hodm:1,use_coro:1, use_ADC:0, write_arrays:1, use_atm:0, pupil_ratio:pupil_ratio}
    prop_run, prescription, asf, lam, n, passval=v
    init_field = mask * ( addnoise_pharo((abs(asf)^2) / max_psf, hmag, dit, ndit, nexpo)); define dark hole area
    wset,3
    img = mask * init_field
    print, '##################################################################'
    print, '##################################################################'
    print, '##################################################################'
    print, '##################################################################'
    print, '##################################################################'
    print, '##################################################################'
    print, 'Median contrast', median(img(where(mask ne 0)))
    print, '##################################################################'
    print, '##################################################################'
    print, '##################################################################'
    print, '##################################################################'
    print, '##################################################################'
    print, '##################################################################'   
    tvscl, congrid(img[n/2-round(outer_radius/pupil_ratio):n/2+round(outer_radius/pupil_ratio),n/2-round(outer_radius/pupil_ratio):n/2+round(outer_radius/pupil_ratio)],400,400)   
endfor

writefits, 'final_image.fits', abs(asf)^2 / max_psf

stop

return
end
