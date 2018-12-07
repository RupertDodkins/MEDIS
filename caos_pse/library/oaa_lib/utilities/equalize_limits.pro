; $Id: equalize_limits.pro,v 1.4 2003/06/10 18:29:26 riccardi Exp $


;+
; EQUALIZE_LIMITS
;
;  Computes the range including most of the values of the input array or vector.
;  It is usefull to display images with spikes to filter out.
; 
;  The function returns a range eq_range=[r1,r2] of image values for which:
;  the number of image values with values less then r1 is lower then LOW_THESHOLD
;  the number of image values with values less then r2 is lower then HIGH_THESHOLD
;
;  eq_range = equalize_limits(image[, LOW_THRESHOLD=value][, HIGH_THRESHOLD=value] $
;                             [, BINSIZE=value])
;
;  default values:
;  LOW_THRESHOLD=0.01
;  HIGH_THRESHOLD=0.99
;  BINSIZE=(max_image_value-min_image_value)/1000
;
; MODIFICATION HISTORY
;
; Written by: A. Riccardi, Osservatorio di Astrofisico di Arcetri, ITALY
;             riccardi@arcetri.astro.it
;-  
function equalize_limits, ima, LOW_THRESHOLD=low_t, HIGH_THRESHOLD=high_t, BINSIZE=binsize


if n_elements(low_t) eq 0 then low_t=0.01
if n_elements(high_t) eq 0 then high_t=0.99

n=1000
minv = min(ima, MAX=maxv)

if minv ne maxv then begin

	if n_elements(binsize) eq 0 then binsize = (maxv-minv)/float(n)

	p = double(histogram(ima, OMAX=maxv, OMIN=minv, BINSIZE=binsize))
	for i=1,n-1 do p[i]=p[i-1]+p[i]
	p = p/p[n-1]
	idx = where((p ge low_t) and (p le high_t), count)

	low_limit = minv+binsize*min(idx)
	high_limit = minv+binsize*(max(idx)+1)
endif else begin
	low_limit = minv
	high_limit = maxv
endelse

return, [low_limit, high_limit]

end


