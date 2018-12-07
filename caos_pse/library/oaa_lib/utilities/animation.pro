; $Id: animation.pro,v 1.4 2003/03/04 17:41:17 riccardi Exp $
;+
; ANIMATION
;
; show an animation of the frames stored in the input array.
;
; animation, cube[, /VERB][, SHOWF=velue][, SSHOWF=velue][, MINI=value][, MAXI=value] $
;                [, PIXELS=velue][, DEC=value]
;
; cube:   3-dim real array[xdim,ydim,nframes]
;
; SHOWF:  integer, scalar. Number of frames to show in the anmations
; SSHOWF: integer, scalar. Starting frame to show
; MINI:   real scalar. Minimum value used to scale the colors
; MAXI:   real scalar. Maximum value used to scale the colors
; PIXELS: integer, scalar. Zoom factor for the frame display
; DEC:    integer, scalar. Decimation of the frames in cube to diaplay
;
; by G. Brusa, Osservatorio Astrofisico di Arcetri (OAA)
;-
pro animation,cella,verb=verb,showf=showf,sshowf=sshowf,pixels=pixels,mini=mini,maxi=maxi,dec=dec
;
;animate
;
sz=size(cella)
nfr=sz(3)
npix_x=sz(1)
npix_y=sz(2)

if keyword_set(verb) then begin
	print,strtrim(string(nfr),2),' frames'
	print,'quanti frames ed a partire da quale vuoi vedere con quanti pixels?'
	read,showf,sshowf,pixels
	print,'min max'
	read,mini,maxi
	print,'dec'
	read,dec
endif else begin
	if n_elements(showf) eq 0 then showf=nfr
	if n_elements(sshowf) eq 0 then sshowf=0
	if n_elements(pixels) eq 0 then pixels=1
	if n_elements(mini) eq 0 then mini=min(cella)
	if n_elements(maxi) eq 0 then maxi=max(cella)
	if n_elements(dec) eq 0 then dec=0
endelse

if(showf eq 0) then goto,fine_show

;xinteranimate,set=[pixels*npix_x,pixels*npix_y,showf/(dec+1),1]
window_save=!d.window
xinteranimate,set=[pixels*npix_x,pixels*npix_y,showf/(dec+1)];,/SHOWLOAD
for i=0,showf/(dec+1)-1 do begin
	xinteranimate,image=rebin(bytscl(cella(*,*,i*(dec+1)+sshowf),min=mini,max=maxi,top=!d.table_size),pixels*npix_x,pixels*npix_y,/sample),frame=i
endfor

xinteranimate
wset,window_save
fine_show:
return
end
