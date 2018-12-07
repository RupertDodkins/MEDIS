;+
; IDX2RGB
;
;   the function returns the RGB long numbers corresponding to the 
;   indexes of the current color table given by idx
;
; rgbcodes = idx2rgb(idx, /SCALE)
;
;   if SCALE keyword is set, idx is scaled to fit the 0-255 range.
;-
function idx2rgb, idx, SCALE=scale, _EXTRA=_extra
	tvlct, r, g, b, /GET
	if keyword_set(scale) then begin
		ii=bytscl(idx, _EXTRA=_extra)
		return, R[ii]+256L*(G[ii]+256L*B[ii])
	endif else begin
		return, R[idx]+256L*(G[idx]+256L*B[idx])
	endelse
end