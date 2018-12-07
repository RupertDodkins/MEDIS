; $Id: make_xy.pro,v 1.2 2003/06/10 18:29:26 riccardi Exp $
; 
; A. Riccardi, Dipartimento di Astronomia di Firenze (Italy). 
; Please, send me a message if you modify this code. 


function is_power_of_2, n
	temp = long(n)
	while ((temp mod 2B) eq 0B) do temp = temp/2B
	return, temp eq 1B
end

pro square_xy, x, y  
	; tempx has the same type and dimension of x
	tempx = 0B*x+1B
	x=x#(0B*y+1B)  
	y=tempx#y  
end  
 

pro xy_to_polar, x, y
;
; substitute x,y -> r,theta
;
	r=sqrt(x*x+y*y)
	y=atan(y,x)
	x=r
	return
end

pro make_xy, sampling, ratio, x, y, POLAR=is_polar, DOUBLE=is_double, VECTOR=is_vector, ZERO_SAMPLED=use_zero, QUARTER=quarter, FFT=fft
;+ 
; NAME: 
;       MAKE_XY 
; 
; PURPOSE: 
;       This procedure generates zero-centered domains in
;       cartesian plane or axis, tipically for pupil sampling
;       and FFT usage.
; 
; CATEGORY: 
;       Optics. 
; 
; CALLING SEQUENCE: 
; 
;       MAKE_XY, Sampling, Ratio, X [, Y] 
; 
; INPUTS: 
;       Sampling:   integer scalar. Number of sampling points per dimension of
;                   the domain. Sampling>=2 and must be even.
;
;       Ratio:  floating scalar. Extension of sampled domain:
;                   -Ratio <= x [,y] <= +Ratio
;               Ratio < Sampling
;
;       X:      variable. Not used as input.
; 
; OPTIONAL INPUTS: 
;       Y:      variable. Not used as input. Specify this variable if you
;               want the y coordinates in the 2-dimension domain case
;				(see VECTOR keyword).
;        
; KEYWORD PARAMETERS: 
;       DOUBLE: set it to have double type output. 
; 
;       POLAR:  set it to have domain sampling in polar coordinates. If
;               VECTOR keyword is set, POLAR setting is not considered.
;
;       VECTOR: if set, 1-dimensional domain is sampled and you needn't
;               specify Y variable as input.
;
;       ZERO_SAMPLED:   if set, origin of the domain is sampled.
;
;		QUARTER:	if set, only 1st quadrant is returned. The array (vector)
;					returned has Sampling/2 X Sampling/2 (Sampling/2) elements.
;		
;		FFT:	if set, order the output values for FFT purposes.
;				For example, vector -5,-3,-1,+1,+3,+5 is returned as
;				+1,+3,+5,-5,-3,-1.
; 
; OUTPUTS: 
;       X:  floating vector or squared matrix. Returns X values of sampled
;           points. Radial values if POLAR is set.
; 
; OPTIONAL OUTPUTS: 
;       Y:  floating squared matrix. Returns Y values of sampled points.
;           Azimuthal angle values if POLAR is set. If VECTOR is set and
;           Y is specified as input, it is left unchanged.
;
;       HOW IS SAMPLED THE DOMAIN:
;
;           -ZERO_SAMPLING is not set-
;           the edge of the domain is not sampled and the sampling is
;           symmetrical respect to origin.
;
;               Ex: Sampling=4, Ratio=1.
;                   -1   -0.5    0    0.5    1    Domain (Ex. X axis)
;                    |     |     |     |     |
;                       *     *     *     *       Sampling points
;
;
;           -ZERO_SAMPLING is set-
;           the lower edge is sampled and the sampling is not symmetrical
;           respct to the origin.
;
;               Ex: Sampling=4, Ratio=1.
;                   -1   -0.5    0    0.5    1    Domain (Ex. X axis)
;                    |     |     |     |     |
;                    *     *     *     *          Sampling points
;
;			If FFT keyword is set, output values are ordered for
;			FFT purposes:
;
;           Ex: 2-dimensional domain: N = Sampling
;           X or Y(0:N/2-1, 0:N/2-1)   1st quadrant (including origin
;                                      if ZERO_SAMPLEDis set)
;           X or Y(N/2:N, 0:N/2-1)     2nd quadrant
;           X or Y(N/2:N, N/2:N)       3rd quadrant
;           X or Y(0:N/2-1, N/2:N)     2nd quadrant
; 
; EXAMPLE: 
;       Compute the squared absolute value of FFT of function
;       (x+2*y)*Pupil(x^2+y^2) and display the result.
;       Pupil(r)=1. if r<=1., 0. otherwise.
;
;       MAKE_XY, 256, 1., X, Y
;       Pupil = X*X+Y*Y LE 1.
;       TV_SCL, ABS(FFT((X+2*Y)*Pupil))^2
; 
; MODIFICATION HISTORY: 
;       Written by:     A. Riccardi; April, 1995. 
;- 
	if ((not is_even(sampling)) or (sampling le 0)) then begin
		print, 'make_xy -- sampling must be positive and even'
		return
	endif
 
	if (ratio ge sampling) then begin
		print, 'make_xy -- sampling must be gt ratio'
		return
	endif
 
	s2 = sampling/2
	if keyword_set(is_double) then $
		if (keyword_set(quarter)) then $
			x = dindgen(s2) $
		else $
			x = dindgen(sampling) $
	else $
		if (keyword_set(quarter)) then $
			x = findgen(s2) $
		else $
			x = findgen(sampling)
	
	if (not keyword_set(use_zero)) then x = x+.5

	if (not keyword_set(quarter)) then x = temporary(x)-s2
	if (keyword_set(fft)) then x = shift(temporary(x), s2)
	x=temporary(x)/s2*ratio

	if (not keyword_set(is_vector)) then begin
		y=x
		square_xy, x, y
		if keyword_set(is_polar) then xy_to_polar, x, y
	endif
	
	return 
end 

