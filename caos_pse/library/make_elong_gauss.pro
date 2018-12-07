; Marcel Carbillet (OAA), march 1999, <marcel@arcetri.astro.it>.
;
; I/O: dim     = image dimension  (integer) [px]
;      waist_x = gaussian x-waist (float)   [px]
;      waist_y = gaussian y-waist (float)   [px]
;      map     = resulting rescalable elongated gaussian map (float)

function make_elong_gauss, dim,     $
                           waist_x, $
                           waist_y

x_axis = fltarr(dim, dim)
dummy  = rebin(findgen(dim/2),        dim/2,dim) & x_axis[0,0]    =dummy
dummy  = rebin(dim/2-1-findgen(dim/2),dim/2,dim) & x_axis[dim/2,0]=dummy
y_axis = rotate(x_axis, 1)

x_axis = shift(x_axis, dim/2, dim/2)
y_axis = shift(y_axis, dim/2, dim/2)

map = exp(-(x_axis/waist_x)^2-(y_axis/waist_y)^2)
map = map/total(map)

return, map
end
