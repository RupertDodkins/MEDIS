; $Id: comp_colors.pro,v 1.4 2003/06/10 18:29:25 riccardi Exp $

;+
;   COMP_COLORS
;
; returns a vector of n RGB (long integer) values of different colors
;
;  colors = comp_colors(n)
;
; MODIFICATON HISTORY
;
;    Written by: A. Riccardi, Osservatorio Astrofisico di Arcetri, ITALY
;                riccardi@arcetri.astro.it
;-
 
function comp_colors, n_colors

hue = 360.0/n_colors*findgen(n_colors)
sat = replicate(1.0, n_colors)
val = replicate(1.0, n_colors)

color_convert, hue, sat, val, r, g, b, /HSV_RGB

return, long([transpose(r), transpose(g), transpose(b), replicate(0B,1,n_colors)], 0, n_colors)

end
