; $Id: amax.pro,v 1.4 2003/06/10 18:29:25 riccardi Exp $
;+
; AMAX
;
; same as max, but it returns the N-dimensional subscript
; in Max_Subscript, where N is the number of dimensions of
; the input array
;
; MODIFICATON HISTORY
;
;    Written by: A. Riccardi, Osservatorio Astrofisico di Arcetri, ITALY
;                riccardi@arcetri.astro.it
;-
function amax, array, idx_vec, MIN=minv, NAN=nan

	if n_params() le 1 then begin
		maxv = max(array, MIN=minv, NAN=nan)
	endif else begin
		maxv = max(array, idx, MIN=minv, NAN=nan)
		idx_vec = idx_array(idx, array)
		return, maxv
	endelse
end
