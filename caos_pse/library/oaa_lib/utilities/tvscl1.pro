; $Id: tvscl1.pro,v 1.3 2002/12/04 14:54:25 riccardi Exp $
;
;+
;    TVSCL1
;
;-
pro TVSCL1, ima, p1, p2, p3, _EXTRA=extra_keywords

case n_params() of
	2: tv1, bytscl(ima), p1, _EXTRA=extra_keywords
	3: tv1, bytscl(ima), p1, p2, _EXTRA=extra_keywords
	4: tv1, bytscl(ima), p1, p2, p3, _EXTRA=extra_keywords
	else: tv1, bytscl(ima), _EXTRA=extra_keywords
endcase

end
