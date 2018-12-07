; $Id: shift_and_add.pro,v 1.3 2002/12/11 18:39:09 riccardi Exp $
;+
;
; SHIFT_AND_ADD
;
; this function returns the shift-and-add result of the input image cube
;
; saa_image = shift_and_add(image_cube, BACKGROUND=bg, /AVERAGE, IDX_HISTORY=idx_hist)
;
; image_cube:  input, real 3-dim array. image_cube[N,M,L]. L images of
;              size NxM
;
; BACKGROUNG:  optional input, real NxM array. Background to remove from
;              each image before processing it.
; AVERAGE:     If it is set, shift_and_add/L is returned instead of
;              shift_and_add
;
; IDX_HISTORY: optional output. named variable. The list of coordinates of
;              the peak value is returned in this variable
;
; HISTORY:
;   05 Dic 2002. Written by A. Riccardi. INAF-OAA, Italy
;                riccardi@arcetri.astro.it
;   06 Dic 2002. AR. IDX_HISTORY keyword added.
;-

function shift_and_add, image_cube, BACKGROUND=bg, AVERAGE=do_ave, IDX_HISTORY=idx_hist
	if test_type(image_cube, /REAL, DIM=s) then $
		message, "image_cube must be an array of numbers"
	if s[0] ne 3 then $
		message, "image_cube must be a 3-dimensional array"

	if n_elements(bg) eq 0 then begin
		do_remove_bg = 0B
	endif else begin
		do_remove_bg = 1B
		if test_type(bg, /REAL, DIM=dim_bg) then $
			message, "BACKGROUND must be an array of numbers"
		if dim_bg[0] ne 2 then $
			message, "BACKGROUND must be a 2-dimensional array"
		if dim_bg[1] ne s[1] or dim_bg[2] ne s[2] then $
			message, "BACKGROUND size doesn't match the image_cube[*,*,0] size"
	endelse

	if arg_present(idx_hist) then begin
		do_collect_idx = 1B
		idx_hist = lonarr(2,s[3])
	endif

	s=size(image_cube)
	saa=dblarr(s[1],s[2])
	x0=s[1]/2
	y0=s[2]/2
	for i=0,s[3]-1 do begin
		if do_remove_bg then begin
			aa=image_cube[*,*,i]-bg
			dummy=amax(aa, idx)
			saa=temporary(saa)+shift(aa, x0-idx[0], y0-idx[1])
		endif else begin
			dummy=amax(image_cube[*,*,i], idx)
			saa=temporary(saa)+shift(image_cube[*,*,i], x0-idx[0], y0-idx[1])
		endelse
		if do_collect_idx then idx_hist[*,i]=idx
	endfor
	if keyword_set(do_ave) then saa=temporary(saa)/s[3]
	return, saa
end
