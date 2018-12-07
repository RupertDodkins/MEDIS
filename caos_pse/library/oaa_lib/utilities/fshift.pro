; Fractional shifting

Function fshift, img, dx, dy

dx=double(dx)
dy=double(dy)

simg = size(img, /dim)

xx = rebin(dindgen(simg[0]), simg[0], simg[1])
yy = rebin(transpose(dindgen(simg[1])), simg[0], simg[1])

if round(dx) eq dx and round(dy) eq dy then $
   return, shift(img, dx, dy) else $
   return, interpolate(shift(img, round(dx), round(dy)), xx-dx+round(dx), yy-dy+round(dy))
end
