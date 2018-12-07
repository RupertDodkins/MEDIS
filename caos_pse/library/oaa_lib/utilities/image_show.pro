; $Id: image_show.pro,v 1.8 2006/06/07 14:36:54 riccardi Exp $

pro image_show, input, x_vec, y_vec, NX=nx, NY=ny, XAXIS=xax, YAXIS=yax $
    , WINDOW_SCALE = window_scale, ASPECT = aspect, MAX_VALUE = max_value $
    , MIN_VALUE = min_value, SHOW_BAR = show_bar, INV = inv, POSIZ = posiz $
    , DIG = dig, INTERP=interp, _EXTRA=plot_keywords, SCALE = scale $
    , BAR_TITLE=ytitle_bar, NOERASE=noerase, NO_GT=no_gt, NO_LT=no_lt $
    , TITLE=title, YTITLE=ytitle, YTICKF_BAR=ytickf_bar, YSTYLE=ystyle $
    , XSTYLE=xstyle, COL_INVERT=col_invert, LOG=log, XBAR=xbar $
    , CONTOUR=do_contour, NLEV = nlev ,PERCENT = percent $
    , EQUALIZE = equalize
;+
; NAME:
;   IMAGE_SHOW
;
; PURPOSE:
;   Display an image.
;
; CATEGORY:
;   General graphics.
;
; CALLING SEQUENCE:
;
; image_show, input, x_vec, y_vec, NX=nx, NY=ny, XAXIS=xax, YAXIS=yax $
;    , WINDOW_SCALE = window_scale, ASPECT = aspect, MAX_VALUE = max_value $
;    , MIN_VALUE = min_value, SHOW_BAR = show_bar, INV = inv, POSIZ = posiz $
;    , DIG = dig, INTERP=interp, _EXTRA=plot_keywords, SCALE = scale $
;    , BAR_TITLE=ytitle_bar, NOERASE=noerase, NO_GT=no_gt, NO_LT=no_lt $
;    , TITLE=title, YTITLE=ytitle, YTICKF_BAR=ytickf_bar, YSTYLE=ystyle $
;    , XSTYLE=xstyle, COL_INVERT=col_invert, LOG=log, XBAR=xbar $
;    , CONTOUR=do_contour, NLEV = nlev ,PERCENT = percent, EQUALIZE=equalize
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
;
; KEYWORD PARAMETERS:
;
;   NX,NY:  Used only when three parameters are passed. Same keywords as TRIGRID.
;
;	XAXIS:	Two elements array containing minimum and maximum x-axis values
;
;	YAXIS:	Two elements array containing minimum and maximum y-axis values
;
;   WINDOW_SCALE:   Set this keyword to scale the window size to the image size.
;       Otherwise, the image size is scaled to the window size.
;       This keyword is ignored when outputting to devices with
;       scalable pixels (e.g., PostScript).
;
;   ASPECT: Set this keyword to requested image's aspect ratio (y/x).
;       1 implies square pixels.  If WINDOW_SCALE is set, the
;       aspect ratio is automatically retained.
;
;   MAX_VALUE: Set this keyword to change the limit of the lookup table
;
;   MIN_VALUE: Set this keyword to change the limit of the lookup table
;
;   SHOW_BAR: Set this keyword to show the color lookup table
;
;   INV: Set this keyword to invert the lookup table (can be used to
;        reduce the amount of toner/ink used when printing certain images)
;
;   POSIZ: Returns the device coordinates of the displayed image
;          (can be used to overplot something on the main image)
;
;   DIG: Sets the number of digits used to label the ticks of the lookup table
;           (otherwise set automatically)
;
;   INTERP: Uses an interpolation method as described in the routine
;           poly_2d
;
;	_EXTRA: Allows to use the general keywords used with the plot routine to
;           insert titles and other features (see help on plot).
;
;   SCALE:  Scales x and y axis (not used on XAXIS or YAXIS values)
;
;	BAR_TITLE: Allows to insert a title over the color bar
;
;   XBAR:    0.0 < xbar < 1.0, normalized starting point of the color bar
;            in the horizontal direction of the plotting window.
;            0.75 by default
;
;   NOERASE: If set, the window or page is not erased before plotting
;
;   YTICKF_BAR: tick format strin of the color bar labels
;
;   COL_INVERT: invert the background and foreground colors
;
;   LOG:    if set, display the array values using logarithmic scale
;
;   CONTOUR:  if set, overplot a contour plot on the array map
;
;   NLEV:   number of levels to use in the contour plot (10 by default)
;
;   PERCENT: if set, contour label are expressed in percent value of
;             the plotting range
;
;   EQUALIZE: if set, the function equalize_limit is called to compute
;             the optimal color cuts. MIN_VALUE and MAX_VALUE keywords
;             override the EQUALIZE setting. In order to restrict the
;             computation of the equalized limits over a subset of data,
;             set this keyword to the corresponding list of elements to use.
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
;   DMS, May, 1988. (image_cont)
;	several times. G. Brusa Zappellini (Osservatorio Astrofisico di Arcetri)
;                  brusa@arcetri.astro.it.
;   Mar 2002. A. Riccardi (OAA) riccardi@arcetri.astro.it
;             Keywords CONTOUR, NLEV, PERCENT added.
;             Computation of the optimal value for DIG if is not not passed.
;   Mar 2002. AR, Implemented the possibility to pass an irregularly gridded set of points.
;   Dic 2002. GBZ, added the XBAR keyword
;   Dic 2002. AR, Error in the computation of the optimal value of dig fixed.
;                 Image x-size is computed as 95% of xbar.
;                 Definition of NX and NY keyword fixed.
;                 New data type (code numbers from 12 to 15, see SIZE function) are
;                 now accepted. The data type check is performed earlier in the code.
;                 Check on the x_vec and y_vec data type added.
;                 keyword EQUALIZE added
;   June 2003. AR, A subset of data can be now used to compute the equalized limits
;                 (see EQUALIZE keyword)
;                 ASPECT keyword implements the possibility to have non-squared
;                 pixels
;   May 2006. AR, fixed computation of number of digits in case minimum value
;             is zero
;-

;
; initial settings
;
    ;on_error,2                 ;Return to caller if an error occurs

	npar = n_params()
	if npar ne 1 and npar ne 3 then message, "Wrong number of parameters"

	sz = size(input)
    dtype=sz(sz(0)+1)
    if dtype lt 1 or (dtype gt 5 and dtype lt 12) then message, 'Data type no valid'

	if npar eq 1 then begin
	    image=reform(input)
	    sz = size(image)                ;Size of image
    	if sz(0) ne 2 then message, 'Parameter not 2D'
    endif else begin
    	n_el = n_elements(input)

		sz = size(x_vec)
	    dtype=sz(sz(0)+1)
	    if dtype lt 1 or (dtype gt 5 and dtype lt 12) then message, 'x_vec data type no valid'
		sz = size(y_vec)
	    dtype=sz(sz(0)+1)
	    if dtype lt 1 or (dtype gt 5 and dtype lt 12) then message, 'y_vec data type no valid'

    	if n_elements(x_vec) ne n_el or n_elements(y_vec) ne n_el then $
    		message, "input, x_vec and y_vec must have the same size"
    	TRIANGULATE, x_vec, y_vec, tr, b
    	image = TRIGRID(x_vec, y_vec, input, tr, NX=nx, NY=ny, MISSING=min(input))
    	sz = size(image)
    endelse

	if keyword_set(do_contour) then contour_image=image
	if n_elements(xbar) eq 0 then xbar=0.75

	if keyword_set(log) then begin
	 	mass_lin=max(image) & mini_lin=min(image)
	 	if min(image) le 0 then message,'Image contains values <=0',/cont
	 	except=!except
        ret=check_math(/print)
        !except=0
		image=alog10(image)
		ret=check_math()
        !except=except
	endif

	n_eq = n_elements(equalize)
	if (n_eq ne 0) and (n_elements(max_value) eq 0 or n_elements(min_value) eq 0) then begin
		if n_eq gt 1 then eq_minmax = equalize_limits(image[equalize]) $
		else if keyword_set(equalize) then eq_minmax = equalize_limits(image)
    endif


	if keyword_set(log) then begin
		if n_elements(max_value) ne 0 then begin
			mass_lin=max_value
			mass=alog10(max_value)
		endif else if keyword_set(equalize) then begin
			mass_lin=10^eq_minmax[1]
			mass=eq_minmax[1]
		endif else begin
			mass=max(image)
		endelse

    	if n_elements(min_value) ne 0 then begin
    		mini_lin=min_value
    		mini=alog10(min_value)
		endif else if keyword_set(equalize) then begin
			mini_lin=10^eq_minmax[0]
			mini=eq_minmax[0]
		endif else begin
			mini=min(image)
		endelse
	endif else begin
		if n_elements(max_value) ne 0 then mass=max_value else $
			if keyword_set(equalize) then mass = eq_minmax[1] else mass=max(image)
    	if n_elements(min_value) ne 0 then mini=min_value else $
			if keyword_set(equalize) then mini = eq_minmax[0] else mini=min(image)
    endelse


    if n_elements(scale) eq 0 then scale=[1.0,1.0]
    if n_elements(xax) eq 0 then xax=findgen(sz(1))/(sz(1)-1)*sz(1)*scale[0]
    if n_elements(yax) eq 0 then yax=findgen(sz(2))/(sz(2)-1)*sz(2)*scale[1]
    if (keyword_set(inv)) then begin
        show=bytscl(float(-image),min=-mass,max=-mini,top=!d.table_size)
    endif else begin
        show=bytscl(float(image),min=mini,max=mass,top=!d.table_size)
    endelse
    if n_elements(dig) ne 0 then dig=dig(0)>0
    if n_elements(ytitle_bar) eq 0 then ytitle_bar=""
    if n_elements(title) eq 0 then title=""
    if n_elements(ytitle) eq 0 then ytitle=""
    if n_elements(xstyle) eq 0 then xstyle=1
    if n_elements(ystyle) eq 0 then ystyle=1

	if keyword_set(COL_INVERT) then begin
		device,decompose=1
		background_old=!p.background
		color_old=!p.color
		!p.background=color_old
		!p.color=background_old
	endif

;
; set window used by plot
;
    pposition_old=!p.position
    pregion_old=!p.region
    pmulti_old=!p.multi

    pflag='nul'
    if keyword_set(show_bar) then begin
    	; 0 < ximage < xbar < 1
		ximage=xbar*0.95
        if !p.position[0] ne !p.position[2] then begin
        	pflag='pos'
        	pposition=!p.position
        	dpposition=pposition[2:3]-pposition[0:1]
		    pimage=[pposition[0:1],pposition[0:1]+dpposition*[ximage,1]]
		    pbar=[pimage[0:1]+dpposition*[xbar,0],pposition[2:3]]
            !p.position=pimage
        endif else begin
        	if !p.region[0] ne !p.region[2] then begin
        		pflag='reg'
        		pregion=!p.region
        		dpregion=pregion[2:3]-pregion[0:1]
		    	pimage=[pregion[0:1],pregion[0:1]+dpregion*[ximage,1]]
		    	pbar=[pimage[0:1]+dpregion*[xbar,0],pregion[2:3]]
            	!p.region=pimage
        	endif else begin
   				if  total(!p.multi) ne 0    then begin
	        		pflag='mul'

		            nc=!p.multi(1) ;number of columns in the multi plot
		            nr=!p.multi(2) ;number of rows in the multi plot
		            nfr=nc*nr
		            if !p.multi(0) eq 0 then begin
		                ifr=0 ;frame index from 0 to nfr-1
		            endif else begin
		                ifr=nfr-!p.multi(0)
		                noerase=1
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
		            pimage=[pregion(0:1),pregion(0:1)+dpregion*[ximage,1]]
		            pbar=[pimage(0:1)+dpregion*[xbar,0],pregion(2:3)]
		            !p.region=pimage
		            !p.multi=0
	        	endif else  begin
	        		pflag='nul'
	           		pimage=[0,0,ximage,1]
            		pbar=[xbar,0,1,1]
				endelse
        	endelse
		endelse
	endif

    plot,[min(xax),max(xax)],[min(yax),max(yax)] $
        , /nodata,xstyle=xstyle and 4, ystyle=ystyle and 4, noerase=noerase $
        , color=!P.BACKGROUND, _EXTRA=plot_keywords, TITLE=title, YTITLE=ytitle


    px = !x.window * !d.x_vsize ;Get size of window in device units
    py = !y.window * !d.y_vsize
    swx = px(1)-px(0)       ;Size in x in device units
    swy = py(1)-py(0)       ;Size in Y
    if keyword_set(show_bar) then swx=swx*ximage
    if swx le 0.0 or swy le 0.0 then begin
    	message, 'Image can not be displayed',/cont
    	goto,fine
	endif
    six = float(sz(1))      ;Image sizes
    siy = float(sz(2))
    aspi = six / siy        ;Image aspect ratio
    if n_elements(aspect) ne 0 then aspi=aspi/aspect
    aspw = swx / swy        ;Window aspect ratio
    f = aspi / aspw         ;Ratio of aspect ratios

    ;plot,[min(xax),max(xax)],[min(yax),max(yax)] $
    ;    , /nodata,xstyle=4, ystyle=4, /noerase, color=0 $
    ;    , title="", xtitle="", ytitle=""

    if (!d.flags and 1) ne 0 then begin ;Scalable pixels?
        if keyword_set(aspect) then begin   ;Retain aspect ratio?
            ;Adjust window size
            if f ge 1.0 then swy = swy / f else swx = swx * f
        endif
        tv1,show,px(0),py(0),xsize = swx, ysize = swy, /device
    endif else begin    ;Not scalable pixels
        if keyword_set(window_scale) then begin ;Scale window to image?
            tv1,show,px(0),py(0) ;Output image
            swx = six       ;Set window size from image
            swy = siy
        endif else begin        ;Scale window
            if keyword_set(aspect) then begin
                if f ge 1.0 then swy = swy / f else swx = swx * f
            endif       ;aspect
            ;Have to resample image
            tv1,poly_2d(show $
            , [[0,0],[six/swx,0]], [[0,siy/swy],[0,0]],keyword_set(interp) $
            , swx,swy), px(0),py(0)
        endelse         ;window_scale
    endelse         ;scalable pixels

    posiz=[px(0),py(0),px(0)+swx,py(0)+swy]

    plot,[min(xax),max(xax)],[min(yax),max(yax)] $
        , /noerase,/nodata,xst=xstyle,yst=ystyle $
        , pos = posiz $
        , /dev, _EXTRA=plot_keywords, TITLE=title $
        , YTITLE=ytitle
 ;
 ; Overplot contours if requested
 ;
	if keyword_set(do_contour) then begin
		if (n_elements(nlev) eq 0) then nlev=10
		mx = !d.n_colors-1		;Brightest color
		colors=fltarr(nlev)
		colors[0:nlev/2-1]=mx & colors[nlev/2:*]=0
		if keyword_set(inv) then colors = mx - colors
		if !d.name eq 'PS' then begin
			colors = mx - colors ;invert line colors for pstscrp
			temp=mass & mass=-mini & mini=-temp
		endif
		xl=findgen(nlev)/(nlev-1)*(mass-mini)+mini
		if keyword_set(log) then begin
			xann=strtrim(string(10^xl,format='(e10.2)'),2)

			contour,contour_image,/noerase,xst=1+4,yst=1+4,$	;Do the contour
	   			pos = posiz,/dev,$
				c_color =  colors,$
				levels=10^xl,c_annotation=xann,/follow, $
				max_value=10^mass, min_value=10^mini, chars=1.2, ZLOG=LOG

		endif else begin
			if (keyword_set(percent)) then begin
				xann=strmid(strtrim(string((findgen(nlev-1)+1)/nlev*100),2),0,2)+'%'
			endif else begin
				xann=strtrim(string(xl,format='(e10.2)'),2)
			endelse

			contour,contour_image,/noerase,xst=1+4,yst=1+4,$	;Do the contour
	   			pos = posiz,/dev,$
				c_color =  colors,$
				levels=xl,c_annotation=xann,/follow, $
				max_value=mass, min_value=mini, chars=1.2, ZLOG=LOG
		endelse
	endif
;
; color bar
;
    if keyword_set(show_bar) then begin
; checks min and max values
		if pflag eq 'pos' then begin
			message,'Bar cannot be displaied: set the variable !p.position to 0',/cont
			goto,fine
		endif
		!p.position=0
		!p.region=pbar
        if mass eq mini then goto,fine
        except=!except
        ret=check_math(/print)
        !except=0
        res=machar(double=(dtype eq 5))
        expo=ceil(alog10(-alog10(res.xmin)))
        ret=check_math()
        !except=except
        if n_elements(dig) ne 0 then begin
            digits=dig(0)
;        endif else digits=-floor(alog10(res.eps))
        endif else begin
        	max_digits=-floor(alog10(res.eps))
        	if mini eq 0 then digits=1 else digits=(ceil(alog10(abs(mini)/(mass-mini)))+1)<max_digits>1
        endelse

        mx = !d.table_size      ;Brightest color
        show=reform(bindgen(mx),1,mx)
        sz = size(show)
        if (keyword_set(inv)) then show=-show
        dig_p=digits
        extra_dig=6             ;IDL under Windows uses 6 extra characters for the E format and not 5!
        if n_elements(ytickf_bar) ne 0 then begin
        	noplot=0B
        	tot_p=strlen(string(0.0,format=ytickf_bar))
            plot,[[0,0],[1,1]],/nodata, xstyle=4, ystyle = 4, /noerase $
                , xmargin= tot_p,TITLE=ytitle_bar, _EXTRA=plot_keywords, color=!P.BACKGROUND, YTICKF=ytickf_bar
            px = !x.window * !d.x_vsize ;Get size of window in device units
            py = !y.window * !d.y_vsize
            swx = px(1)-px(0)       ;Size in x in device units
            swy = py(1)-py(0)       ;Size in Y
            if ((swx le 0.0 or swy le 0.0) and ((!d.flags and 1) ne 0)) or $
               ((swx le 10.0 or swy le 10.0) and ((!d.flags and 1) eq 0)) $
               then noplot=1B

        endif else begin
	        repeat begin
	            noplot=0B
	            tot_p=dig_p+expo+extra_dig
	            plot,[[0,0],[1,1]],/nodata, xstyle=4, ystyle = 4, /noerase $
	                , xmargin=tot_p, TITLE=ytitle_bar, _EXTRA=plot_keywords, color=!P.BACKGROUND
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
	    endelse
        if noplot then begin
            print, 'Bar can not be displayed'
            goto, fine
        endif

        six = float(sz(1))      ;Image sizes
        siy = float(sz(2))
        aspi = six / siy        ;Image aspect ratio
        aspw = swx / swy        ;Window aspect ratio
        f = aspi / aspw         ;Ratio of aspect ratios

        if (!d.flags and 1) ne 0 then begin ;Scalable pixels?
            tv1,show,px(0),py(0),xsize = swx, ysize = swy, /device
        endif else begin    ;Not scalable pixels
                ;Have to resample image
                tv1,poly_2d(show $
                , [[0,0],[six/swx,0]], [[0,siy/swy],[0,0]],0 $
                , swx,swy), px(0),py(0)
        endelse         ;scalable pixels
        if n_elements(dig) ne 0 then begin
            if dig_p lt dig then print,'Requested # of digits does not fit'
        endif
        val=mini+(mass-mini)*indgen(11)/10
        if n_elements(ytickf_bar) ne 0 then begin
        form=ytickf_bar
        endif else form='(E'+strtrim(tot_p,2)+'.'+strtrim(dig_p,2)+')'
        vals=string(val,format=form)
        if (keyword_set(max_value) and not keyword_set(no_gt)) then vals(10)=">"+vals(10)
        if (keyword_set(min_value) and not keyword_set(no_lt)) then vals(0)="<"+vals(0)
		if keyword_set(log) then begin
			plot,[0,0],[mini_lin,mass_lin],/nodata, xstyle=1+4, ystyle=1+4, /noerase $
				, xmargin=tot_p, TITLE=ytitle_bar, _EXTRA=plot_keywords,/ylog
			axis,yaxis=0,_EXTRA=plot_keywords, ystyle=1,yticklen=0.2
        endif else begin
	        plot,[0,0],[1,1],/nodata, xstyle=1+4, ystyle=1+4, /noerase $
	                , xmargin=tot_p, TITLE=ytitle_bar, _EXTRA=plot_keywords
	        axis,yaxis=0,yticks=10,ytickn=vals, _EXTRA=plot_keywords
        endelse
    endif
    if keyword_set(COL_INVERT) then begin
		!p.background=background_old
		!p.color=color_old
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



    end
