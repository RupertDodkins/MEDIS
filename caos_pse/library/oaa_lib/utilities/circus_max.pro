; $Id: circus_max.pro,v 1.3 2005/02/08 11:51:31 labot Exp $

; First define the function FUNC:
Function FUNC, P

	common FUNC_XY, xax, yax, data
    r2max = max((xax-p[0])^2+(yax-p[1])^2)
    id = where((xax-p[0])^2+(yax-p[1])^2 eq r2max)
    mval = r2max
;    print, 'Rmax ', sqrt(r2max)
;    print, 'Npixel ', total(data[id])
	return, mval
End



function circus_max, mask, ASPECT_RATIO=ar, DISPLAY=display
;+
; CIRCUS_MAX
;
; This function returns the center and the radius of the smallest
; circle containing all the non-zero points in the 2D array mask.
; Center and radius are returned in pixel coordinates of the x-axis.
;
; ret = circus_max(mask [, ASPECT_RATIO=aspect][, /DISPLAY])
;
; ASPECT_RATIO:  deltaY/deltaX. Set it to the right value if x-pixels
;                and y-pixels have not the same linear scale. Aspect
;                ratio is set to 1 by default.
; DISPLAY:       Set it to display the graphical result of the fitting.
;
; ret = [x0,y0,Radius], where:
;
; Radius is the cirle radius in pixel units of x-axis
; x0 is the x coordinate in pixel units of x-axis
; y0 is the y coordinate in pixel units of y-axis
;
;
; HISTORY
;
; Apr 2004: written by M. Xompero
;
; 14 Apr 2004: A. Riccardi.
;  *Unused CENTER keyword removed.
;  *help fixed
;-
COMMON FUNC_XY, xax, yax, data

data=mask
if n_elements(ar) eq 0 then ar=1.0
xs = (size(mask, /dim))[0]
ys = (size(mask, /dim))[1]
; Define the data points:
id_ris = where(mask ne 0)
ris = inddim(id_ris, size(mask, /dim))
xax = ris[*,0]
yax = ar*ris[*,1]
guessx = mean(xax)
guessy = mean(yax)
; Call the function. Set the fractional tolerance to 1 part in
; 10^5, the initial guess to [0,0], and specify that the minimum
; should be found within a distance of 100 of that point:
r = AMOEBA(1e-5, SCALE=[1e2], P0 = [guessx, guessy], FUNCTION_VALUE=fval)

; Check for convergence:
IF N_ELEMENTS(R) EQ 1 THEN MESSAGE, 'AMOEBA failed to converge'
tt = mk_vector(700, 0.0, 2*!PI)
x0 = r[0]
y0 = r[1]/ar
radius = sqrt(double(fval[0]))
if keyword_set(DISPLAY) then begin
	window, /free, xs = xs, ys = ys
	tvscl, mask
	plots, radius*cos(tt)+x0, radius*sin(tt)/ar+y0, /DEV, COLOR=255L
	plots, x0, y0, PSYM=1, /dev
; Print results:
	PRINT, 'Centre x of the circle:', strcompress(x0, /rem)
	PRINT, 'Centre y of the circle:', strcompress(y0, /rem)
	print, 'Radius of the circle: ', radius
endif
return, [x0, y0, radius]
end