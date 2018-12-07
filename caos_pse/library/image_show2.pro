; $Id: image_show2.pro,v 2.0 2004/12/08 marcel.carbillet $
;+
; NAME:
;   IMAGE_SHOW2
;
; PURPOSE:
;   Display an image.
;
; CATEGORY:
;   General graphics.
;
; CALLING SEQUENCE:
;   IMAGE_SHOW2, input $
;   , WINDOW_SCALE = window_scale, ASPECT = aspect, MAX_VALUE = max_value $
;   , MIN_VALUE = min_value, SHOW_BAR = show_bar, INV = inv, POSIZ = posiz$
;   , _EXTRA=plot_keywords, DIG = dig, BAR_TITLE = bar_title
;
; INPUTS:
;   INPUT:  The two-dimensional array to display.
;
; KEYWORD PARAMETERS:
;
;   WINDOW_SCALE: Set this keyword to scale the window size to
;                 the image size.
;                     Otherwise, the image size is scaled to the window size.
;                     This keyword is ignored when outputting to devices with
;                     scalable pixels (e.g., PostScript).
;
;   ASPECT: Set this keyword to retain the image's aspect ratio.
;       Square pixels are assumed.  If WINDOW_SCALE is set, the
;       aspect ratio is automatically retained.
;
;   MAX_VALUE: Set this keyword to change the limit of the lookup table
;
;   MIN_VALUE: Set this keyword to change the limit of the lookup table
;
;   SHOW_BAR: Set this keyword to show the lookup table
;
;       BAR_TITLE: A string containing the title to print on the top
;                  of the color bar (if SHOW_BAR is set)
;
;   INV: Set this keyword to invert the lookup table (can be used to
;            reduce the amount of toner used when printing certain images)
;
;   POSIZ: Returns the device coordinates of the displayed image
;              (can be used to overplot something on the main image)
;
;   DIG: Sets the number of digits used to label the ticks of the
;        lookup table (otherwise set automatically)
;
;   INTERP: Uses an interpolation method as described in the routine poly_2d
;
;
; OUTPUTS:
;   No explicit outputs.
;
; COMMON BLOCKS:
;   None.
;
; SIDE EFFECTS:
;   The currently selected display is affected.
;
; RESTRICTIONS:
;   None.
;
; PROCEDURE:
;   If the device has scalable pixels, then the image is written over
;   the plot window.
;
; MODIFICATION HISTORY:
;   - DMS, May, 1988.
;   - Armando Riccardi, may 1999, enhanced (did not work with windows).
;   - Marcel Carbillet, september 1999 and january 1999, windows again.
;   - Marcel Carbillet, december 2004, routine image_show2m (module DIS,
;   package CAOS) and image_show2 (module DSP, package AIRY) unified
;   and put in .../caos/lib/ (for use from any package).
;
;-
;
pro image_show2, input $
                 , WINDOW_SCALE = window_scale, ASPECT = aspect $
                 , MAX_VALUE = max_value $
                 , MIN_VALUE = min_value, SHOW_BAR = show_bar $
                 , INV = inv, POSIZ = posiz $
                 , DIG = dig, INTERP=interp $
                 , BAR_TITLE = bar_title, CHARSIZE=ch_size, $
                 _EXTRA=plot_keywords

; initial settings
;
on_error,2                      ;Return to caller if an error occurs



image=reform(input)
sz = size(image)                ;Size of image
if sz(0) lt 2 then message, 'Parameter not 2D'
dtype=sz(sz(0)+1)
if dtype lt 1 or dtype gt 5 then message, 'Data type no valid'

mass=max(image) & mini=min(image)
if keyword_set(max_value) then mass=max_value
if keyword_set(min_value) then mini=min_value
xax=findgen(sz(1))/(sz(1)-1)*sz(1)
yax=findgen(sz(2))/(sz(2)-1)*sz(2)
if (keyword_set(inv)) then begin
    show=-image
    show=bytscl(float(show),min=-mini,max=-mass,top=!d.table_size)
endif else begin
    show=image
    show=bytscl(float(show),min=mini,max=mass,top=!d.table_size)
endelse
if n_elements(dig) ne 0 then dig=dig(0)>0
;
; set window used by plot
;
pposition_old=!p.position
pregion_old=!p.region
pmulti_old=!p.multi
if keyword_set(show_bar) then begin
    if total(!p.position) ne 0 then begin
        !p.position=0
    endif
    if  total(!p.multi) ne 0    then begin
        nc=!p.multi(1)          ;number of columns in the multi plot
        nr=!p.multi(2)          ;number of rows in the multi plot
        nfr=nc*nr
        if !p.multi(0) eq 0 then begin
            ifr=0               ;frame index from 0 to nfr-1
        endif else begin
            ifr=nfr-!p.multi(0)
        endelse
        if !p.multi(4) eq 0 then begin
            ir=ifr/nc
            ic=ifr-ir*nc
        endif else begin
            ic=ifr/nc
            ir=ifr-ic*nr
        endelse
        ir=nr-ir-1
        ir=float(ir) & ic=float(ic)
        pregion=[ic/nc, ir/nr, (ic+1)/nc , (ir+1)/nr]
        dpregion=pregion(2:3)-pregion(0:1)
        pimage=[pregion(0:1),pregion(0:1)+dpregion*[.75,1]]
        pbar=[pimage(0:1)+dpregion*[.78,0],pregion(2:3)]
        !p.multi=0
    endif else begin
        pimage=[0,0,.75,1]
        pbar=[.78,0,1,1]
    endelse
endif


if keyword_set(show_bar) then !p.region=pimage
noer=0
if pmulti_old(0) ne 0 and keyword_set(show_bar) then noer=1
if keyword_set(noerase) then noer=1
plot,[min(xax),max(xax)],[min(yax),max(yax)] $
  , /nodata,xstyle=5, ystyle=5, noerase=noer $
  , color=0, CHARSIZE=ch_size, _EXTRA=plot_keywords

px = !x.window * !d.x_vsize ;Get size of window in device units
py = !y.window * !d.y_vsize
swx = px(1)-px(0)       ;Size in x in device units
swy = py(1)-py(0)       ;Size in Y
if swx le 0.0 or swy le 0.0 then message, 'Image can not be displayed'
six = float(sz(1))      ;Image sizes
siy = float(sz(2))
aspi = six / siy        ;Image aspect ratio
aspw = swx / swy        ;Window aspect ratio
f = aspi / aspw         ;Ratio of aspect ratios
plot,[min(xax),max(xax)],[min(yax),max(yax)] $
    , /nodata,xstyle=4, ystyle=4, noerase=1, color=0  $
    , title=title, xtitle=xtitle, ytitle=ytitle $
    , CHARSIZE=ch_size

if (!d.flags and 1) ne 0 then begin ;Scalable pixels?
    if keyword_set(aspect) then begin ;Retain aspect ratio?
                                ;Adjust window size
        if f ge 1.0 then swy = swy / f else swx = swx * f
    endif
    tv,show,px(0),py(0),xsize = swx, ysize = swy, /device
endif else begin                ;Not scalable pixels
    if keyword_set(window_scale) then begin ;Scale window to image?
        tv,show,px(0),py(0) ;Output image
        swx = six       ;Set window size from image
        swy = siy
    endif else begin        ;Scale window
        if keyword_set(aspect) then begin
            if f ge 1.0 then swy = swy / f else swx = swx * f
        endif                   ;aspect
                                ;Have to resample image
        tv,poly_2d(show $
                   ,[[0,0],[six/swx,0]],[[0,siy/swy],[0,0]],keyword_set(interp)$
                   ,swx,swy),px(0),py(0)
    endelse         ;window_scale
endelse                         ;scalable pixels

posiz=[px(0),py(0),px(0)+swx,py(0)+swy]

plot,[min(xax),max(xax)],[min(yax),max(yax)] $
  , /noerase,/nodata,/xst,/yst $
  , pos = [px(0),py(0), px(0)+swx,py(0)+swy],/dev $
  , title=title, xtitle=xtitle, ytitle=ytitle $
  , CHARSIZE=ch_size, _EXTRA=plot_keywords
 
;
; color bar
;
if keyword_set(show_bar) then begin
; checks min a max values
    !p.region=pbar
    if mass eq mini then goto,fine

    res=machar(double=(dtype eq 5))
    exp=ceil(alog10(-alog10(res.xmin)))
    if n_elements(dig) ne 0 then begin
        digits=dig(0)
    endif else begin
        digits=-floor(alog10(res.eps))
    endelse
    mx = !d.table_size      ;Brightest color
    show=reform(bindgen(mx),1,mx)
    sz = size(show)
    if (keyword_set(inv)) then show=-show
    dig_p=digits
    repeat begin
        noplot=0B

        if !VERSION.OS_FAMILY eq "Windows" then dummy = 6 else dummy = 5
        tot_p=dig_p+exp+dummy

        plot,[[0,0],[1,1]],/nodata, xstyle=4, ystyle = 4, /noerase $
          , xmargin=tot_p, CHARSIZE=ch_size
        px = !x.window * !d.x_vsize ;Get size of window in device units
        py = !y.window * !d.y_vsize
        swx = px(1)-px(0)       ;Size in x in device units
        swy = py(1)-py(0)       ;Size in Y
        if ((swx le 0.0 or swy le 0.0) and ((!d.flags and 1) ne 0)) or $
          ((swx le 10.0 or swy le 10.0) and ((!d.flags and 1) eq 0)) $
          then begin
            dig_p=dig_p-1
            noplot=1B
        endif
    endrep until not(noplot) or dig_p lt 0
    if noplot then begin
        print, 'Bar can not be displayed'
        goto, fine
    endif

    if n_elements(bar_title) ne 0 then $
      plot,[[0,0],[1,1]],/nodata, xstyle=4, ystyle = 4, /noerase $
      , xmargin=tot_p , TITLE=bar_title, CHARSIZE=ch_size

    six = float(sz(1))      ;Image sizes
    siy = float(sz(2))
    aspi = six / siy        ;Image aspect ratio
    aspw = swx / swy        ;Window aspect ratio
    f = aspi / aspw             ;Ratio of aspect ratios

    if (!d.flags and 1) ne 0 then begin ;Scalable pixels?
        tv,show,px(0),py(0),xsize = swx, ysize = swy, /device
    endif else begin            ;Not scalable pixels
                                ;Have to resample image
        tv,poly_2d(show $
                   , [[0,0],[six/swx,0]], [[0,siy/swy],[0,0]],0 $
                   , swx,swy), px(0),py(0)
    endelse         ;scalable pixels
    if n_elements(dig) ne 0 then begin
        if dig_p lt dig then print,'Requested # of digits does not fit'
    endif
    val=mini+(mass-mini)*indgen(11)/10
    form='(E'+strtrim(tot_p,2)+'.'+strtrim(dig_p,2)+')'
    vals=string(val,format=form)
    if keyword_set(max_value) then vals(10)=">="+vals(10)
    if keyword_set(min_value) then vals(0)="<="+vals(0)
    axis,yaxis=0,yticks=10,ytickn=vals
endif
fine:
!p.position=pposition_old
!p.region=pregion_old
if  total(pmulti_old) ne 0 and keyword_set(show_bar) then begin
    if pmulti_old(0) eq 0 then begin
        !p.multi=[pmulti_old(1)*pmulti_old(2)-1,pmulti_old(1:4)]
    endif else begin
        !p.multi=[pmulti_old(0)-1,pmulti_old(1:4)]
    endelse
endif
return
end
