; $Id: xyploterr.pro,v 1.1.1.1 2002/03/12 11:53:47 riccardi Exp $

PRO XYPLOTERR, X, Y, ERRX, ERRY, OVERPLOT=overplot, _EXTRA=plot_keywords, $
						XRANGE =xrange, YRANGE = yrange
;
;+
; NAME:
;	XYPLOTERR
;
; PURPOSE:
;	Overplot data points with accompanying error bars for x and y.
;
; CATEGORY:
;	Plotting, 2-dimensional.
;
; CALLING SEQUENCE:
;	OPLOTERR,  X,  Y , ErrX, ErrY, PSYM=Psym
;
; INPUTS:
;	Y:	The array of Y values.
;
;	Err:	The array of error bar values.
;
; OPTIONAL INPUT PARAMETERS:
;	X:	An optional array of X values.  The procedure checks whether
;		or not the third parameter passed is a vector to decide if X
;		was passed.
;
;		If X is not passed, then INDGEN(Y) is assumed for the X values.
;
;	PSYM:	The plotting symbol to use (default = +7).
;
; COMMON BLOCKS:
;	None.
;
; SIDE EFFECTS:
;	None.
;
; RESTRICTIONS:
;	Arrays cannot be of type string.  There must be enough points to
;	plot.
;
; PROCEDURE:
;	A plot of X versus Y with error bars drawn from Y - ERR to Y + ERR
;	is written to the output device over any plot already there.
;
; MODIFICATION HISTORY:
;	William Thompson	Applied Research Corporation
;	July, 1986		8201 Corporate Drive
;				Landover, MD  20785
;       kdb, March, 1997  - Fixed a problem if 1 element arrays where used.
;-
;

	;
	;  Interpret the input parameters.
	;
	ON_ERROR,2              ; Return to caller if an error occurs
	NP = N_PARAMS(0)
	IF NP LT 4 THEN $
	  message, 'Must be called with 4 parameters: X,  Y , ERRX, ERRY'
	;
	;  Plot data and the error bars.
	;
	N = N_ELEMENTS(X) < N_ELEMENTS(Y) < N_ELEMENTS(ERRX) < N_ELEMENTS(ERRY)
	IF N LT 1 THEN message, 'No points to plot.' $
	ELSE IF N EQ 1 THEN BEGIN		;Double XX and YY arrays to allow
		XX = X[0]*[1,1]	;	plotting of single point.
		YY = Y[0]+[1,1]
		XERR = ERRX[0]*[1,1]
		YERR = ERRY[0]*[1,1]
	END ELSE BEGIN
		XX = X[0:N-1]
		YY = Y[0:N-1]
		XERR = ERRX[0:N-1]
		YERR = ERRY[0:N-1]
	ENDELSE
	if keyword_set(overplot) then begin
		OPLOT,XX,YY, _EXTRA=plot_keywords 				;Plot data points.
	endif else begin
		if n_elements(xrange) eq 0 then xrange=[min(XX-XERR),max(XX+XERR)]
		if n_elements(yrange) eq 0 then yrange=[min(YY-YERR),max(YY+YERR)]

		PLOT,XX,YY, XRANGE=xrange,$
						YRANGE=yrange,_EXTRA=plot_keywords
	endelse

	FOR I = 0,N-1 DO BEGIN			;Plot error bars.
		XXX = [XX[I],XX[I]]
		YYY = [YY[I]-YERR[I],YY[I]+YERR[I]]
		OPLOT,XXX,YYY, linestyle=0
		XXX = [XX[I]-XERR[I],XX[I]+XERR[I]]
		YYY = [YY[I],YY[I]]
		OPLOT,XXX,YYY, linestyle=0
	END
;
END

