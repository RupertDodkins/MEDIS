; $Id: bisection.pro,v 1.4 2003/06/10 18:29:25 riccardi Exp $

;+
; BISECTION
;
; apply the bisection method to find a zero of the function func_name in
; the interval start_interval
;
; res=bisection(start_interval, func_name[, TOL=value])
;
; start_interval: real 2-element vector. Interval containing the zero of the function
; func_name:      string, scalar. Name of the function having the zero in start_interval
; 
; TOL:            real scalar. Tollerance of the solution. Default value=1d-6.
;
; MODIFICATON HISTORY
;
;    Written by: A. Riccardi, Osservatorio Astrofisico di Arcetri, ITALY
;                riccardi@arcetri.astro.it
;- 

function bisection, w, func_name, TOL=eps

	if n_elements(eps) eq 0 then eps=1d-6

	w_inf = min(w, MAX=w_sup)
	f_inf = call_function(func_name, w_inf)
	f_sup = call_function(func_name, w_sup)
	if f_inf*f_sup ge 0 then message, "ERROR"
	dw = (w_sup-w_inf)
	repeat begin
		w_mid = (w_inf+w_sup)/2d0
		f_mid = call_function(func_name, w_mid)
		if f_mid*f_inf gt 0 then begin
			w_inf = w_mid
			f_inf = f_mid
		endif else begin
			w_sup = w_mid
			f_sup = f_mid
		endelse
	endrep until (abs(w_inf-w_sup) lt eps*w_mid) or (abs(f_inf-f_sup) lt eps*f_mid) or f_mid eq 0.0

	return, w_mid
end
