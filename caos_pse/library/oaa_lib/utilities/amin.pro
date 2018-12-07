; $Id: amin.pro,v 1.4 2003/06/10 18:29:25 riccardi Exp $
;+
; AMIN
;
; same as min, but it returns the N-dimensional subscript
; in Min_Subscript, where N is the number of dimensions of
; the input array
;
; MODIFICATON HISTORY
;
;    Written by: A. Riccardi, Osservatorio Astrofisico di Arcetri, ITALY
;                riccardi@arcetri.astro.it
;-
function amin, array, idx_vec, MAX=maxv, NAN=nan

	if n_params() le 1 then begin
		minv = min(array, MAX=maxv, NAN=nan)
	endif else begin
		minv = min(array, idx, MAX=maxv, NAN=nan)
		idx_vec = idx_array(idx, array)
		return, minv
	endelse
end
