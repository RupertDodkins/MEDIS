; $Id: qromlog.pro,v 1.3 2003/06/10 18:29:27 riccardi Exp $

function qromlog_func, z
	common qromlog_block, func_name
	x = exp(z)
	return, x*call_function(func_name, x)
end

;+
;
; QROMLOG
;
; res = QROMLOG(func_name, a, b)
;
; same keywords as QROMO. If MIDEXP is set, only the parameter "a" is accepted ("b" is
; supposed to be infinity).
;
; a and b must be strictly positive and b>a
;
; the function computes the integral
;
; \b               \b                   \log(b)
; | f(x)*dx    as   | x*f(x)*d(log(x)) = | exp(z)*f(exp(z))*dz
; \a                \a                   \log(a)
;
; Mar 2002: written by A. Riccardi (Osservatorio Astrofisico di Arcetri)
;           riccardi@arcetri.astro.it
;-

function qromlog, func_name, a, b, _EXTRA=extra_keywords
	common qromlog_block, fn

	fn=func_name
	if a le 0 then message, "Integral limits must be strictly positive"
	za = alog(a)
	if n_params() gt 2 then begin
		zb = alog(b)
		return, qromo('qromlog_func', za, zb, _EXTRA=extra_keywords)
	endif else begin
		return, qromo('qromlog_func', za, _EXTRA=extra_keywords)
	endelse
end

