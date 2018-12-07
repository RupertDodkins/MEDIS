; $Id: image_ar.pro,v 1.3 2003/06/10 18:29:26 riccardi Exp $

function image_ar,yxar,input
;+
;resample an image sampled with a different step in y and x axis to the same step.
;usage : resampled_image=image_ar(aspect_ratio,image)
;			aspect_ratio is the image aspect ratio
;-
sz=size(input)
if sz[0] ne 2 then begin
	MESSAGE,"input must be 2-D"
endif
nx=sz[1]
ny=sz[2]
y=findgen(fix(ny*yxar))/yxar
return, interpolate(input,findgen(nx),y,/grid)
end
