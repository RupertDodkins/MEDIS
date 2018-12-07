; $Id: imstruc_to_fits.pro,v 7.0, last revision 2016/06/10 Andrea La Camera $


pro imstruc_to_fits, filename, nb_struc, header
  
;transfert the image of one or several airy structures of image type into a fits file
  str = mrdfits(filename, nb_struc,/POINTER_VAR)
  if nb_struc GT 1 then begin 
     image = fltarr((size(str.image))[1],(size(str.image))[2], nb_struc)
     pos=strpos(filename,'_',/reverse_search)
     if (size(str.image))[0] eq 3 then begin
        for n=((size(str.image))[3])-1,0,-1 do begin
           name=strmid(filename,0,pos)+'_'+strcompress(string(n),/remove_all)+'.fits'
           for i=0, nb_struc-1 do begin 
              str = mrdfits(filename, i+1,/POINTER_VAR)
              image[*,*,i] = str.image[*,*,n]
           endfor
           fxaddpar, header, 'psf', 	fix(str.psf),'[WFT] PSF [1/0]'
           fxaddpar, header, 'npixel',str.npixel,'[WFT] Number of pixel'
           fxaddpar, header, 'resolut',str.resolution,'[WFT] Pixel size [arcsec]'
           fxaddpar, header, 'lambda',str.lambda,'[WFT] Filter central wavelength [m]'
           fxaddpar, header, 'width',str.width,'[WFT] Filter width [m]' 
           fxaddpar, header, 'EXPTIME',str.time_integ[0,0],'[WFT] Exposure Time [s]'
           fxaddpar, header, 'time_de', str.time_delay,'[WFT] CAOS field time_delay'
           fxaddpar, header, 'history', 'processed from -->    ' + name, 	''
           writefits, name, image, header
        endfor
     endif else begin
        for i=0, nb_struc-1 do begin 
           str = mrdfits(filename, i+1,/POINTER_VAR)
           image[*,*,i] = str.image
        endfor
        fxaddpar, header, 'psf', fix(str.psf),'[WFT] PSF [1/0]'
        fxaddpar, header, 'npixel', str.npixel,'[WFT] Number of pixel'
        fxaddpar, header, 'resolut', str.resolution,'[WFT] Pixel size [arcsec]'
        fxaddpar, header, 'lambda', str.lambda, '[WFT] Filter central wavelength [m]'
        fxaddpar, header, 'width', str.width, '[WFT] Filter width [m]'
        fxaddpar, header, 'EXPTIME', str.time_integ[0,0], '[WFT] Exposure Time [s] for frame 0'
        fxaddpar, header, 'time_de', str.time_delay, '[WFT] CAOS field time_delay'
        fxaddpar, header, 'history', 'processed from -->    ' + filename, 	''
        writefits, filename, image, header
     endelse
     
  endif else begin 
                                ; one structure case
     if (size(str.image))[0] eq 3 then begin 
                                ; 3-d case 
        image = fltarr((size(str.image))[1],(size(str.image))[2],(size(str.image))[3])
     endif 
     if (size(str.image))[0] eq 2 then begin 
                                ; 2-d case
        image = fltarr((size(str.image))[1],(size(str.image))[2])
     endif
     image = str.image
     fxaddpar, header, 'psf', fix(str.psf),  '[WFT] PSF [1/0]'
     fxaddpar, header, 'npixel', str.npixel,'[WFT] Number of pixel'
     fxaddpar, header, 'resolut', str.resolution, '[WFT] Pixel size [arcsec]'
     fxaddpar, header, 'lambda', str.lambda,  '[WFT] Filter central wavelength [m]'
     fxaddpar, header, 'width', str.width, '[WFT] Filter width [m]'
     keyw=''
     if (size(str.image))[0] eq 3 then begin 
        for i=0,(size(str.image))[3]-1 do begin
           keyw='EXPTIME'+strcompress(string(i),/remove_all)
           fxaddpar, header, keyw, str.time_integ[i,0],'[WFT] Exposure Time [s] for frame '+strcompress(string(i),/remove_all)
        endfor
     endif 
     if (size(str.image))[0] eq 2 then begin 
        fxaddpar, header, 'EXPTIME', str.time_integ[0,0],'[WFT] Exposure Time [s]'
     endif
     fxaddpar, header, 'time_de',str.time_delay,'[WFT] CAOS field time_delay'
     fxaddpar, header, 'history','processed from -->    ' + filename,''
     writefits, filename, image, header
  endelse
  
  
  return
end
