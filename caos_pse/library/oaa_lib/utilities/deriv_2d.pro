; $Id: deriv_2d.pro,v 1.4 2003/06/10 18:29:25 riccardi Exp $

;+
; DERIV_2D
; 
; INPUT:
; x:	x-vector. N-elements.
; y:	y-vector. M-elements
; func:	NxM-elements matrix to derive
;
; OUTPUT:
; de_x:	x-derivative matrix
; de_y: y-derivative matrix
;
; MODIFICATION HISTORY:
;   Written by: A. Riccardi, Osservatorio Astrofisico di Arcetri, ITALY
;-

pro deriv_2d, x, y, func, de_x, de_y

	de_x = func
	de_y = func

	for i=0,n_elements(func(0,*))-1 do begin
    	de_x(*,i) = deriv(x, func(*,i))
	endfor

	for i=0,n_elements(func(*,0))-1 do begin
    	de_y(i,*) = deriv(y, func(i,*))
	endfor

end

