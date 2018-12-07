;+
; NAME:
;   XSHOW
;
; PURPOSE:
;   Wrapper to IMAGE_SHOW with zoom capabilities.
;   Display min and max values of the input vector
;   Left-click and drag to zoom
;   Middle-click to unzoom
;   Rigth-click to popup contect menu:
;       -  save in jpg format
;       -  show info window
;       -  quit
;
; CATEGORY:
;   General graphics.
;
; CALLING SEQUENCE:
;
; xshow, input, x_vec, y_vec, /LABEL, ZOOM_SCALE=zoom_scale, XSIZE=xsize, 
;      YSIZE=ysize, KEYWORDS  with the KEYWORDS of IMAGE_SHOW 
;
; INPUTS:
;   input:  If x_vec and y_vec are not present, "input" is the two-dimensional array
;           to display. If x_vec and y_vec are present, "input" is a vector of values
;           of the map to dispaly in the corresponding irregular grid defined by x_vec
;           and y_vec.
;
;   x_vec, y_vec  cannot be used when "input" is a two-dimensional array. If they are
;           defined, they have to be vectors with the same size as "input". In the last
;           case TRIGRID is used to obtain a regular gridded two-dimensional array
;           to display.
; KEYWORDS:
;   ZOOM_SCALE: if set, change the limit of the lookup table according to the zoom view. 
;               Otherwise constants limits are used. See MAX(MIN)_VALUE in IMAGE_SHOW
;
;   LABEL: If set display a status bar with selected pixel (coords and value) and 
;          with minmax of input (coords and value)
;   
;   XSIZE: Set width of the window
;
;   YSIZE: Set height of the window
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
; MODIFICATION HISTORY:
;   22 May 2005  written by Lorenzo Busoni (LB)
;   23 May 2005  A. Riccardi (AR), multiple instances bug fixed
;   24 May 2005  LB, window resize handling and zoombox display added 
;   25 May 2005  LB, color table is stored in the parameter structure
;                    info window added
;                    XSIZE,YSIZE added
;   26 May 2005  LB, save_jpg and small zooms bugs fixed
;-

;***********************************************
; xshow_draw_kill
; this one is called when the widget_draw is killed
; e.g. by a wdelete
;***********************************************
;pro xshow_draw_kill, drawid
;compile_opt idl2, hidden
;if (WIDGET_INFO(drawid, /VALID_ID) eq 0) then return
;print, 'byebye', drawid
;WIDGET_CONTROL, drawid, GET_UVALUE=par
;WIDGET_CONTROL, par.top, /DESTROY
;end

;***********************************************
; save_jpg_event
;
;***********************************************
pro save_jpg_event, ev
compile_opt idl2, hidden

WIDGET_CONTROL, ev.top, GET_UVALUE=par

filters  = ['*.jpg;*.jpeg']
filename = DIALOG_PICKFILE(DEFAULT_EXTENSION='jpg', FILTER=filters, $ 
	    FILE=par.filejpg, /OVERWRITE_PROMPT, /WRITE)
if (filename ne '') then begin
    par.filejpg=filename   
    WSET, par.win.num
    background=!p.background
    color=!p.color
	geometry = WIDGET_INFO(par.draw, /GEOMETRY )
	WINDOW, /FREE, /PIXMAP, XSIZE = geometry.xsize, YSIZE = geometry.ysize
	pixmap_id = !D.WINDOW
    WSET, pixmap_id
    !p.background='ffffffff'xul
    !p.color = 0
    update_display, par, WINID=pixmap_id
    write_jpeg, filename, tvrd(TRUE=1), TRUE=1, QUALITY=90
    WDELETE, pixmap_id
    WSET, par.win.num
    !p.background=background
    !p.color=color
endif

end

;***********************************************
; show_info_event
;
;***********************************************
pro show_info_event, ev
compile_opt idl2, hidden

WIDGET_CONTROL, ev.top, GET_UVALUE=par

result = MOMENT(par.frmOrg.data, SDEV=stdev, /double)

txt = [ $
    STRING(FORMAT= '(%"Size (%d,%d)")',par.frmOrg.W,par.frmOrg.H) ,$
    STRING(FORMAT= '(%"Min (%0.4g,%0.4g): %g")',par.min.X,par.min.Y,par.min.value) ,$
    STRING(FORMAT= '(%"Max (%0.4g,%0.4g): %g")',par.max.X,par.max.Y,par.max.value) ,$
    STRING(FORMAT= '(%"Total    : %g")',total(par.frmOrg.data)) ,$
    STRING(FORMAT= '(%"Average  : %g")',result[0]) ,$
    STRING(FORMAT= '(%"Std dev  : %g")',stdev, /double)  $
    ]
DEVICE, GET_WINDOW_POSITION=offset
ShowInfo, TITLE='Image Properties', INFO=txt, $ ;GROUP=ev.top
    HEIGHT=8, WIDTH=50, $
    XOFF=offset[0]+.5*par.winPos.W, YOFF=offset[1]-.5*par.winPos.H
end

;***********************************************
; done_event
;
;***********************************************
pro done_event, ev
compile_opt idl2, hidden
WIDGET_CONTROL, ev.top, /DESTROY
end

;**********************************************
; plot_zoombox
;**********************************************
PRO plot_zoombox, par
compile_opt idl2, hidden

; Sort the vertices of the zoom box. Don't know the direction the user zoomed in the data.
s = long([ par.mousedev.last.X, par.lastClick.dev.X]) 
s = TEMPORARY( s[SORT(s)] )
x0 = s[0]
x1 = s[1]
  
s = long([ par.mousedev.last.Y, par.lastClick.dev.Y]) 
s = TEMPORARY( s[SORT(s)] )
y0 = s[0]
y1 = s[1]

; Erase only the box by copying the plot data under the zoombox (which is only one pixel wide)
; from the pixmap. This is much quicker than copying the  entire contents of the zoombox.
DEVICE, COPY = [ x0, y0, x1 - x0 + 1, 1, x0, y0, par.pixmap_id ]
DEVICE, COPY = [ x0, y1, x1 - x0 + 1, 1, x0, y1, par.pixmap_id ]
DEVICE, COPY = [ x0, y0, 1, y1 - y0 + 1, x0, y0, par.pixmap_id ]
DEVICE, COPY = [ x1, y0, 1, y1 - y0 + 1, x1, y0, par.pixmap_id ]

; Plot new box
PLOTS,	long([ par.lastClick.dev.X, par.lastClick.dev.X,  par.mousedev.X, $
		par.mousedev.X, par.lastClick.dev.X ] ), $
	long([ par.lastClick.dev.Y, par.mousedev.Y, par.mousedev.Y, $
		par.lastClick.dev.Y,  par.lastClick.dev.Y ] ), $
        /DEVICE, COLOR = !P.COLOR, LINESTYLE = 1
end

;*********************************************
; update_display
;***********************************************
pro update_display, par, WINID=winid
compile_opt idl2, hidden

; zoomed frame left, right, bottom and top in user units
axl=float(par.axis.L) + float(par.zoom.L)/par.frmOrg.W*(par.axis.R-par.axis.L)
axr=float(par.axis.L) + float(par.zoom.R+1)/par.frmOrg.W*(par.axis.R-par.axis.L)
axb=float(par.axis.B) + float(par.zoom.B)/par.frmOrg.H*(par.axis.T-par.axis.B)
axt=float(par.axis.B) + float(par.zoom.T+1)/par.frmOrg.H*(par.axis.T-par.axis.B)

if (n_elements(winid) eq 0) then winid=par.win.num
; select window
wset, winid
; save actual color table and set local color table
tvlct, R, G, B, /GET
tvlct, par.ct.R, par.ct.G, par.ct.B
; show image
if par.zoom_scale ne 0B then begin
    image_show, $
    par.frmOrg.data[par.zoom.L:par.zoom.R, par.zoom.B:par.zoom.T],$
    POSIZ=pos, $
    XAXIS=[axl, axr],YAXIS=[axb, axt], $
    _EXTRA=par.extra
endif else begin
    image_show, $
    par.frmOrg.data[par.zoom.L:par.zoom.R, par.zoom.B:par.zoom.T],$
    POSIZ=pos, MAX_VALUE=par.lookup.Max, MIN_VALUE=par.lookup.Min, $
    XAXIS=[axl, axr],YAXIS=[axb, axt], $
    _EXTRA=par.extra
endelse

; restore colortable
tvlct, R, G, B
;; select window -1: workaround to wdelete bug:
;; a call to wdel with an xshow opened results in an empty small widget
;wset, -1

; save winPos again in case position has changed
par.winPos.X=pos[0]
par.winPos.Y=pos[1]
par.winPos.W=pos[2]-pos[0]
par.winPos.H=pos[3]-pos[1]

end
;***********************************************
; update_label
;***********************************************
pro update_label, par
compile_opt idl2, hidden

if par.label eq 0B then return

lblmouse  = WIDGET_INFO (par.top, FIND_BY_UNAME='lblmouse')
lblmax    = WIDGET_INFO (par.top, FIND_BY_UNAME='lblmax')
WIDGET_CONTROL, lblmouse, SET_VALUE= STRING( FORMAT=$
	'(%"(%g,%g): %g")', $
	float(par.axis.L) + float(par.mouse.X)/par.frmOrg.W*(par.axis.R-par.axis.L), $
	float(par.axis.B) + float(par.mouse.Y)/par.frmOrg.H*(par.axis.T-par.axis.B), $
	(par.frmOrg.data)[par.mouse.X, par.mouse.Y])

end

;************************************************
; xshow_resize_event
; handle resize_window events
;************************************************
pro xshow_resize_event, ev
compile_opt idl2, hidden

WIDGET_CONTROL, ev.top, GET_UVALUE=par

WIDGET_CONTROL, par.draw, $
                XSIZE = ev.X, $
                YSIZE = ev.Y

update_display, par
update_label, par

WIDGET_CONTROL, ev.top, SET_UVALUE=par
end



;************************************************
; xshow_draw_event
; handle mouse_event on widget_draw
;************************************************
pro xshow_draw_event, ev
compile_opt idl2, hidden

; restore parameters par
WIDGET_CONTROL, ev.top, GET_UVALUE=par

; draw fires a WIDGET_DRAW when mouse is moved over the image
if(tag_names(ev, /structure_name) eq 'WIDGET_DRAW') then begin
    ; save mouse position and update label
    par.mousedev.last.X = par.mousedev.X
    par.mousedev.last.Y = par.mousedev.Y
    par.mousedev.X = ((par.winPos.X > ev.X) < (par.winPos.X+par.winPos.W)) 
    par.mousedev.Y = ((par.winPos.Y > ev.Y) < (par.winPos.Y+par.winPos.H)) 
    par.mouse.X = long( (par.mousedev.X-par.winPos.X)/par.winPos.W $
			*(par.zoom.R-par.zoom.L+1)+par.zoom.L )
    par.mouse.Y = long( (par.mousedev.Y-par.winPos.Y)/par.winPos.H $
			*(par.zoom.T-par.zoom.B+1)+par.zoom.B )
    update_label, par
    ; if we are zooming plot zoombox 
    if par.zooming eq 1B then plot_zoombox, par
   
    ; button events 
    if ev.press eq 1 then begin ; left button click
        ; save last click position
        par.lastClick.dev.X = par.mousedev.X
        par.lastClick.dev.Y = par.mousedev.Y
        par.lastClick.X     = par.mouse.X
        par.lastClick.Y     = par.mouse.Y
        par.zooming         = 1B ; we start zooming
        geometry = WIDGET_INFO(par.draw, /GEOMETRY )
        ; Create the pixmap and save the pixmap ID
        WINDOW, /FREE, /PIXMAP, XSIZE = geometry.xsize, YSIZE = geometry.ysize
        par.pixmap_id = !D.WINDOW
        ;Make the pixmap the active window
        WSET, par.pixmap_id
        ; Copy pixels from the window identified by WIN_ID to current window (pixmap)
        DEVICE, COPY = [ 0, 0, geometry.xsize, geometry.ysize, 0, 0, par.win.num]
        ; Make the screen window active again
        WSET, par.win.num
    endif
    if ev.release eq 1 then begin ; left button release
        par.zooming     = 0B ; we are no more zooming:  delete pixmap
        WDELETE, par.pixmap_id
        if par.mouse.X ne par.lastClick.X and par.mouse.Y ne par.lastClick.Y then begin
            ; save zoomed frame coordinates in pixel units
            par.zoom.L = min([par.lastClick.X, par.mouse.X])
            par.zoom.B = min([par.lastClick.Y, par.mouse.Y])
            par.zoom.R = max([par.lastClick.X, par.mouse.X])
            par.zoom.T = max([par.lastClick.Y, par.mouse.Y])
        endif
        update_display, par
        update_label, par
    endif    	
    if ev.release eq 2 then begin ; central button release
        ; unzoom
        par.zoom.L=0L
        par.zoom.B=0L
        par.zoom.R=par.frmOrg.W-1	
        par.zoom.T=par.frmOrg.H-1	
        update_display, par
        update_label, par
    endif
    if ev.release eq 4 then begin ; right button release
        cntxtBas=WIDGET_INFO(ev.top, FIND_BY_UNAME='contextMenu')
        WIDGET_DISPLAYCONTEXTMENU, ev.id, ev.X, ev.Y, cntxtBas
    endif
endif

WIDGET_CONTROL, ev.top, SET_UVALUE=par
end


;**********************************************************************************
; xshow 
; main routine
;**********************************************************************************
pro xshow , inputo, x_vec, y_vec, LABEL=label, ZOOM_SCALE=zoom_scale, $
    XSIZE=xsize, YSIZE=ysize, $
    NX=nx, NY=ny, $
    MAX_VALUE = max_value, MIN_VALUE = min_value ,$
    XAXIS=xaxis , YAXIS=yaxis , _EXTRA=extra
compile_opt idl2

if(n_elements(xsize) eq 0) then xsize=580
if(n_elements(ysize) eq 0) then ysize=400


base    = WIDGET_BASE(TITLE="Xshow",/COLUMN, UVALUE='base',/TLB_SIZE_EVENTS)
draw    = WIDGET_DRAW (base,/MOTION_EVENTS,/BUTTON_EVENTS, RETAIN=2, $
    ;KILL_NOTIFY = 'xshow_draw_kill', $
	EVENT_PRO = 'xshow_draw_event', XSIZE=xsize, YSIZE=ysize)

; Initialize labels (if required)
if keyword_set(label) then begin
    status  = WIDGET_BASE(base,/ROW, SPACE=20) ;, /GRID_LAYOUT)
    lblmouse = WIDGET_LABEL(status, value='Ready', UNAME='lblmouse', $
	    /ALIGN_LEFT, /DYNAMIC_RESIZE)
    lblmax   = WIDGET_LABEL(status, value='', UNAME='lblmax', $
	    /ALIGN_RIGHT, /DYNAMIC_RESIZE)
endif else label=0B

; Initialize the buttons of the context menu.
cntxtBas  = WIDGET_BASE  (base, /CONTEXT_MENU, UNAME='contextMenu')
cntxtJpg  = WIDGET_BUTTON(cntxtBas, VALUE = 'Save as...', EVENT_PRO = 'save_jpg_event')
cntxtInfo = WIDGET_BUTTON(cntxtBas, VALUE = 'Info', EVENT_PRO = 'show_info_event')
cntxtDone = WIDGET_BUTTON(cntxtBas, VALUE = 'Done', /SEPARATOR, EVENT_PRO = 'done_event')

WIDGET_CONTROL, base, /REALIZE
WIDGET_CONTROL, draw, GET_VALUE=winnum
XMANAGER, 'xshow', base, $
	/no_block, $
	EVENT_HANDLER = 'xshow_resize_event' ; Routine to handle events not generated
                                                ;   in the draw window

npar = n_params()
if npar ne 1 and npar ne 3 then message, "Wrong number of parameters"
input = reform(inputo)
if npar eq 1 then begin
    frameDim = size(input, /DIM)
    frame = input
    if (n_elements(xaxis) ne 2) then xaxis=[0, frameDim[0]]
    if (n_elements(yaxis) ne 2) then yaxis=[0, frameDim[1]]
endif else begin 
    ; check parameters
    n_el = n_elements(input)
    sz = size(x_vec)
    dtype=sz[sz[0]+1]
    if dtype lt 1 or (dtype gt 5 and dtype lt 12) then message, 'x_vec data type no valid'
    sz = size(y_vec)
    dtype=sz[sz[0]+1]
    if dtype lt 1 or (dtype gt 5 and dtype lt 12) then message, 'y_vec data type no valid'
    if n_elements(x_vec) ne n_el or n_elements(y_vec) ne n_el then $
    	message, "input, x_vec and y_vec must have the same size"
    ; grid vectors
    TRIANGULATE, x_vec, y_vec, tr, b
    image = TRIGRID(x_vec, y_vec, input, tr, NX=nx, NY=ny, MISSING=min(input))
    frameDim = size(image, /DIM)
    frame = image
    if (n_elements(xaxis) ne 2) then xaxis=[min(x_vec), max(x_vec)]
    if (n_elements(yaxis) ne 2) then yaxis=[min(y_vec), max(x_vec)]
endelse

; a first image_show to save pos 
image_show, frame, POSIZ=pos,  _EXTRA=extra

if (n_elements(max_value) eq 0) then max_value=max(input)
if (n_elements(min_value) eq 0) then min_value=min(input)
if (n_elements(zoom_scale) eq 0) then zoom_scale=0B
if (n_elements(extra) eq 0) then extra=''
; max, min and coords
maximum = max(frame,maxidx)
minimum = min(frame,minidx)
maxX    = float(maxidx mod frameDim[0])*(xaxis[1]-xaxis[0])/frameDim[0]+float(xaxis[0])
maxY    = float(maxidx  /  frameDim[1])*(yaxis[1]-yaxis[0])/frameDim[1]+float(yaxis[0])
minX    = float(minidx mod frameDim[0])*(xaxis[1]-xaxis[0])/frameDim[0]+float(xaxis[0])
minY    = float(minidx  /  frameDim[1])*(yaxis[1]-yaxis[0])/frameDim[1]+float(yaxis[0])

;get current colortable
tvlct, red,green,blue, /GET
 
; herein and everywhere:
; L = left side of a window
; R = right  
; T = top
; B = bottom
; W = width
; H = height
par={ $
     top: base, $
     draw: draw, $ ; widget_draw id
     label: label, $ ; keyword set label
     npar: npar, $
     ct: {R:red, G:green, B:blue}, $
     zoom_scale: zoom_scale, $
     zooming: 0B, $ ; 1B during zoom drag to plot the zoombox
     filejpg: 'xshow.jpg', $ 
     lookup: {Max: max_value, Min: min_value}, $
     extra: extra, $
     ; axis values in user units
     axis: {L: xaxis[0], R: xaxis[1], B: yaxis[0], T: yaxis[1]}, $
     ; frame position and size in the main window reference
     winPos: {X: pos[0], Y: pos[1], W: pos[2]-pos[0], H: pos[3]-pos[1]} , $ 
     ; mouse position in frame reference 
     mouse:  {X: 0L, Y: 0L}, $
     ; mouse position in device reference
     mousedev: { X: 0L, Y: 0L, last: {X: 0L, Y: 0L}}, $
     ; original frame. W and H are the dimensions of the frame in pixel
     frmOrg: {data: frame, W:frameDim[0], H:frameDim[1] }, $
     ; zoom frame boundaries in unzoomed frame reference
     zoom: {L:0L, B:0L, R: frameDim[0]-1, T: frameDim[1]-1}, $
     ; last click position is used to compute zoom frame size. dev is in the device reference
     lastClick: {X:0L, Y:0L , dev: {X:0L, Y:0L}}, $
     ; minimum value and coords in frame reference
     min: {value: minimum, X:minX, Y:minY}, $
     ; maximum value and coords in frame reference
     max: {value: maximum, X:maxX, Y:maxY},  $
     ; a pixmap is used to display the zoombox
     pixmap_id: -1, $
     ; window properties: number associated to the draw widget
     win: {num: winnum} $ 
    }

; store par data in the main base uvalue
WIDGET_CONTROL, base, SET_UVALUE=par
; store par data also in draw uvalue (for notify_kill events)
;WIDGET_CONTROL, draw, SET_UVALUE=par

; display
update_display, par
update_label, par

; store par data in the main base uvalue
WIDGET_CONTROL, base, SET_UVALUE=par


end

