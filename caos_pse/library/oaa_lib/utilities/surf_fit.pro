; $Id: surf_fit.pro,v 1.4 2006/12/01 13:44:30 labot Exp $

function get_u_zern, x, y, idx_list

;on_error, 2

n2 = n_elements(idx_list)
m = n_elements(x)

u = dblarr(n2, m, /nozero)
rho = sqrt(x^2+y^2)
theta = atan(y, x)
for i=0,n2-1 do begin
	u(i, *) = zern_jpolar(idx_list[i], rho, theta)
endfor

return,u

end




function get_u_poly, x, y, idx_list

poly_ord = ceil(0.5*(sqrt(1 + 8*idx_list)-3))
y_pow = idx_list - (poly_ord*(poly_ord+1)/2 + 1)
x_pow = poly_ord - y_pow

n2 = n_elements(idx_list)
m = n_elements(x)

u = dblarr(n2, m, /nozero)

for i=0,n2-1 do begin
	u(i,*) = x^x_pow[i]*y^y_pow[i]
endfor

return, u
end


function surf_fit, x, y, z, idx_list, COEFF=coeff, ZOUT=zout, UPLUS=uplus, $
				ZERN=zern, UOUT=uout, UMAT=u, ONLY_COEFF=only_coeff
;+
; NAME:
;	SURF_FIT
;
; PURPOSE:
;	This function determines a polynomial fit to a surface.
;
; CATEGORY:
;	Curve and surface fitting.
;
; CALLING SEQUENCE:
;	Result = SURF_FIT(x, y, z, idx_list, COEFF=coeff, ZOUT=zout, UPLUS=uplus, $
;                ZERN=zern, UOUT=uout, UMAT=u, ONLY_COEFF=only_coeff)
;
; INPUTS:
; 	x:
;   y:
;   z:
;   idx_list:
;	
; OUTPUT:
;	This function returns a fitted array.
;
; KEYWORDS:
;   ZERN:
;   COEFF:
;   ZOUT:
;   UPLUS:
;   UOUT:
;   UMAT:
;   ONLY_COEFF:
;
; PROCEDURE:
; 	Fit a 2D array Z as a polynomial function of x and y.
; 	The function fitted is:
;  	    F(x,y) = Sum over i and j of kx(j,i) * x^i * y^j
; 	where kx is returned as a keyword and i+j le degree.
;
; MODIFICATION HISTORY:
;	July, 1993, DMS		Initial creation
;
;-

;on_error, 2
if test_type(x, /real, n_el=nx) then message, "The x vector must be numeric"
if test_type(y, /real, n_el=ny) then message, "The y vector must be numeric"
if test_type(z, /real, n_el=nz) then message, "The z vector must be numeric"
if nx ne ny then message, "x and y vectors must have the same no. of elements"
if ny ne nz then message, "y and z vectors must have the same no. of elements"
np=nx	;number of points to use in the fitting

if test_type(idx_list, /int, /long, n_el=n_coeff) then message, "The idx_list vector must be int"
if total(idx_list lt 1) gt 0 then message, "idx_list must be greater then zero"
if n_elements(idx_list(UNIQ(idx_list, SORT(idx_list)))) ne n_coeff then $
	message, "idx_list contains repeated elements"

if test_type(u, /real, /undef, dim=s, type=type) then message, "u matrix must be numeric"
u_is_def = type ne 0
if u_is_def ne 0 then begin
	if s[0] ne 2 then message, "u matrix must be 2-D"
	if s[2] ne np then message, "u matrix must have the same number of columns as the x elements"
	if s[1] ne n_coeff then message, "u matrix must have the same number of row as the idx_list elements"
endif

if test_type(uplus, /real, /undef, dim=s, type=type) then message, "u matrix must be numeric"
uplus_is_def = type ne 0
if uplus_is_def then begin
	if s[0] ne 2 then message, "uplus matrix must be 2-D"
	if s[1] ne np then message, "uplus matrix must have the same number of columns as the x elements"
	if s[2] ne n_coeff then message, "uplus matrix must have the same number of row as the idx_list elements"
endif


if test_type(zout, /real, /undef, dim=s_zout, type=type) then message, "zout must be numeric"
zout_is_def = type ne 0
if zout_is_def then begin
	if s_zout[0] ne 2 then message, "zout must be a 2-D matrix"
	if s_zout[1] ne 2 then message, "zout must be a 2 x n elements"
endif

if test_type(uout, /real, /undef, dim=s_uout, type=type) then message, "uout must be numeric"
uout_is_def = type ne 0
if uout_is_def then begin
	if s_uout[0] ne 2 then message, "uout must be a 2-D matrix"
	if s_uout[1] ne n_coeff then message, "uout matrix must have the same number of row as the idx_list elements"
endif

if (not u_is_def) and uplus_is_def  and (not zout_is_def) and (not uout_is_def) then $
	message, "The UMAT matrix must be passed with the present combination of keywords."

case 1B of
	keyword_set(zern): begin
		routine_name = "get_u_zern"
		dummy = where(x^2+y^2 gt 1.0, count)
		if count ne 0 then $
			print, "Warning: the domain should be limited to a circle of unit radius ", count
	end
	else: begin
		routine_name = "get_u_poly"
	end
endcase

if not uplus_is_def then begin
	u = call_function(routine_name, x, y, idx_list)
	uplus = invert(transpose(u) ## u) ## transpose(u)
endif

if not keyword_set(only_coeff) then begin
	if not uout_is_def and zout_is_def then begin
		uout = call_function(routine_name, zout[0,*], zout[1,*], idx_list)
		uout_is_def = 1B
	endif
endif

coeff = uplus ## reform(z, 1, np)

if not keyword_set(only_coeff) then begin
	if uout_is_def then begin
		fit = uout ## coeff
	endif else begin
		fit = u ## coeff
	endelse
endif

if not keyword_set(only_coeff) then begin
	coeff = reform(temporary(coeff))
	return, fit
endif else return,-1

end


