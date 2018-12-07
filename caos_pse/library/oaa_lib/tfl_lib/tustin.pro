; $Id: tustin.pro,v 1.3 2003/03/25 11:37:50 riccardi Exp $

pro tustin, num_c, den_c, fs, num_d, den_d, PREWARP=fp, DOUBLE=double
;+
; NAME:
;    TUSTIN
;
; PURPOSE:
;
; The Tustin (bilinear) transform is a mathematical mapping of variables.
; In digital filtering, it is a standard method of mapping the s
; (or analog) plane into the z (or digital) plane. It transforms
; analog filters, designed using classical filter design trchniques,
; into their discrete equivalents.
;
; The bilinear transformation maps the s-plane into the z-plane by:
;
;           Hd(z) = Hc[s=2*fs*(z-1)*(z+1)] ,
;
; where Hc(s) is the analog filter (continous domain), Hd(z) if
; the discrete filter and fs is the frequency of the sampling.
;
; This transformation maps the j*W axis of the
; s=S+j*W plane into the unit circle in the z-plane by:
;
;           w = 2*fs*atan(W/(2*fs)) ,
;
; where z=exp(i*w).
;
; Bilinear can accept an optional keyword PREWARP containing a
; frequency for which the frequency responces before and after mapping
; match exactly. In prewarped mode, the bilinear tranformation maps
; the s-plane into the z-plane with:
;
;           Hd(z) = Hc[s=2*pi*fs/tan(pi*fp/fs)*(z-1)/(z+1)] .
;
; With the prewarping option, bilinear maps the j*W axis around the
; unit circle by:
;
;           w = 2*atan[W*tan(pi*fp/fs)/(2*pi*fp)] .
;
; In prewarp mode, bilinear maches the frequency 2*pi*fp [rad/s] in
; the s-plane to the normalized frequency 2*pi*fp/fs [rad/s] in the z-plane.
;
; CATEGORY:
;    Signal processing
;
;
; CALLING SEQUENCE:
;
;    tustin, num_c, den_c, fs, num_d, den_d [, PREWARP=fp][, DOUBLE=double]
; 
; INPUTS:
;
;    num_c:      real vector. Vector of real coeffs of the numerator
;                of the analog filter tranfer function (ascending
;                powers of s).
;    den_c:      real vector. Vector of real coeffs of the denominator
;                of the analog filter tranfer function (ascending
;                powers of s).
;    fs:         real scalar. Sampling frequency [Hz].
;      
; KEYWORD PARAMETERS:
;
;    PREWARP:    real scalar. Optional. If defined contains the
;                prewarping frequency [Hz]
;    DOUBLE:     if set, force double precision computation.
;
; OUTPUTS:
;
;    num_d:      real vector. Vector of real coeffs of the numerator
;                of the discrete filter (ascending powers of z^-1).
;    den_d:      real vector. Vector of real coeffs of the numerator
;                of the discrete filter (ascending powers of z^-1).
;
; EXAMPLE:
;
;
;
; MODIFICATION HISTORY:
;
;       Oct 1998, written by Armando Riccardi OAA <riccardi@arcetri.astro.it>
;
;-

nn = n_elements(num_c)-1
nd = n_elements(den_c)-1
n  = max([nn, nd])

if keyword_set(double) then begin
    cp = [1d0,  1d0]
    cm = [1d0, -1d0]
    num_d = dblarr(n+1)
    den_d = dblarr(n+1)
    if n_elements(fp) ne 0 then begin
        fs_eff = !DPI*fp/tan(!DPI*fp/fs)
    endif else begin
      fs_eff = fs
  endelse
endif else begin
    zero = 0B*num_c[0]*den_c[0]*fs
    cp = [1e0,  1e0]+zero
    cm = [1e0, -1e0]+zero
    num_d = fltarr(n+1)+zero
    den_d = fltarr(n+1)+zero
    if n_elements(fp) ne 0 then begin
        s = size(zero)
        if s[s[0]] eq 5 then begin
            fs_eff = !DPI*fp/tan(!DPI*fp/fs)
        endif else begin
            fs_eff = !PI*fp/tan(!PI*fp/fs)
        endelse
    endif else begin
        fs_eff = fs
    endelse
endelse
    
for k=0,nn do begin
    pp = poly_pow(cp, nn-k, DOUBLE=double)
    pm = poly_pow(cm, k, DOUBLE=double)
    num_d[0] = num_d + (num_c[k]*(2*fs_eff)^k)*poly_mult(pp,pm)
endfor

for k=0,nd do begin
    pp = poly_pow(cp, nd-k, DOUBLE=double)
    pm = poly_pow(cm, k, DOUBLE=double)
    den_d[0] = den_d + (den_c[k]*(2*fs_eff)^k)*poly_mult(pp,pm)
endfor

if nn gt nd then begin
    den_d[0] = poly_mult(poly_pow(cp, nn-nd), den_d[0:nd])
endif else if nn lt nd then begin
    num_d[0] = poly_mult(poly_pow(cp, nd-nn), num_d[0:nn])
endif

if den_d[0] ne 0 then begin
    num_d = num_d/den_d[0]
    den_d = den_d/den_d[0]
endif

end
