; $Id: tv1.pro,v 1.3 2003/06/10 18:29:27 riccardi Exp $

pro TV1, ima, p1, p2, p3, TRUE=true, _EXTRA=extra_keywords

if n_elements(true) ne 0 then begin
	case n_params() of
		2: tv, ima, p1, TRUE=true, _EXTRA=extra_keywords
		3: tv, ima, p1, p2, TRUE=true, _EXTRA=extra_keywords
		4: tv, ima, p1, p2, p3, TRUE=true, _EXTRA=extra_keywords
		else: tv, ima, TRUE=true, _EXTRA=extra_keywords
	endcase
endif else begin
	if float(!version.release) lt 5.3 then begin
		can_use_colormap = 1
	endif else begin
		dev_name = !D.name
		if dev_name eq 'WIN' or dev_name eq 'X' or dev_name eq 'MAC' then begin
			can_use_colormap = colormap_applicable()
		endif else begin
			can_use_colormap = 1
		endelse
	endelse

	if can_use_colormap then begin
		case n_params() of
			2: tv, ima, p1, _EXTRA=extra_keywords
			3: tv, ima, p1, p2, _EXTRA=extra_keywords
			4: tv, ima, p1, p2, p3, _EXTRA=extra_keywords
			else: tv, ima, _EXTRA=extra_keywords
		endcase
	endif else begin
		tvlct, r, g, b, /GET
		case n_params() of
			2: tv, [[[R[ima]]],[[G[ima]]],[[B[ima]]]], p1, TRUE=3, _EXTRA=extra_keywords
			3: tv, [[[R[ima]]],[[G[ima]]],[[B[ima]]]], p1, p2, TRUE=3, _EXTRA=extra_keywords
			4: tv, [[[R[ima]]],[[G[ima]]],[[B[ima]]]], p1, p2, p3, TRUE=3, _EXTRA=extra_keywords
			else: tv, [[[R[ima]]],[[G[ima]]],[[B[ima]]]], TRUE=3, _EXTRA=extra_keywords
		endcase
	endelse
endelse
end
