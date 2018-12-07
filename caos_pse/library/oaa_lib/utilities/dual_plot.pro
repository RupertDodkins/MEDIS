; $Id: dual_plot.pro,v 1.4 2003/06/10 18:29:25 riccardi Exp $

pro dual_plot,x1,y1,x2,y2,_EXTRA=extra_data,XMARGIN=xm,Y2COLOR=y2_color $
             ,Y2LOG=y2log, YLOG=ylog, X2TOP=x2top, YMARGIN=ym, XLOG=xlog $
             ,X2LOG=x2log, TITLE=title, XTITLE=xtit, YTITLE=ytit, X2TITLE=x2tit $
             ,Y2TITLE=y2tit, THICK=thick, ALTHICK=thick2
;+
; it draws a plot with different left and right y-scales. If X2TOP is set, then
; different bottom and top x scales are plotted.
;-
if n_elements(title) eq 0 then tit="" else tit=title
if keyword_set(x2top) then begin
	a1=min(x1, MAX=a2) & xr1=[a1,a2]
	a1=min(x2, MAX=a2) & xr2=[a1,a2]
	if strlen(tit) ne 0 then begin
		fact_margin=1.3
		tit=tit+"!C!C"
	endif else begin
		fact_margin=1.0
	endelse
	if n_elements(ym) eq 0 then ym=[!Y.MARGIN[0],fact_margin*!Y.MARGIN[0]]
	xst=8
endif else begin
	a1=min(x1, MAX=a2) & a3=min(x2, MAX=a4)
	a1=min([a1,a2,a3,a4],MAX=a5)
	xr1 = [a1,a5] & xr2=xr1
	x2log=keyword_set(xlog)
	xst=0
endelse
yr1=minmax(y1)
yr2=minmax(y2)
if n_elements(xm) eq 0 then xm=[!X.MARGIN[0],!X.MARGIN[0]]
plot,x1,y1,YSTY=1+2+8+16, XSTY=1+2+xst+16, XR=xr1, YR=yr1, XMARGIN=xm, YMARGIN=ym, _EXTRA=extra_data $
    , YLOG=ylog, XLOG=xlog, XTIT=xtit, YTIT=ytit, TIT=tit, THICK=thick
plot,x2,y2,ysty=1+2+4+16, XSTY=1+2+4+16,/noerase, XMARGIN=xm, YMARGIN=ym, XR=xr2, COLOR=y2_color $
    ,YLOG=y2log, XLOG=x2log, _EXTRA=extra_data, YR=yr2, THICK=thick2
if keyword_set(x2top) then $
	axis,xaxis=1, xsty=1+2+8+16, XMARGIN=xm, YMARGIN=ym, _EXTRA=extra_data,XLOG=x2log, XR=xr2 $
    	,XTIT=x2tit
axis,yaxis=1, ysty=1+2+8+16, XMARGIN=xm, YMARGIN=ym, _EXTRA=extra_data,YLOG=y2log, YR=yr2 $
    ,YTIT=y2tit

end

