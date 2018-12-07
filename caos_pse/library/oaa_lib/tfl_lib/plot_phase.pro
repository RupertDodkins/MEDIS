; $Id: plot_phase.pro,v 1.7 2006/09/08 11:00:25 labot Exp $

pro plot_phase, f_vec, complex_tf, _EXTRA=extra_keyw, OVERPLOT=overplot $
                , NO_UNWRAP=no_unwrap, RADIANTS=rad, COMPARISON=comparison $
                , YRANGE=pyrange, XRANGE=xrange, FREQ_UNITS=freq_units, SMOOTH_SIZE=smooth_window
;+
; NAME:
;    PLOT_PHASE
;
; PURPOSE:
;
;    Plot_phase plots (or overplots) the phase of a complex
;    transfer function. The plot is log in the freq. axis and the
;    gridding is enabled. The procedure unwrap the phase by default.
;
; CATEGORY:
;
;    Plotting Routines, Digital Filtering
;
; CALLING SEQUENCE:
;
;    plot_phase, f_vec, complex_tf [, /RAD][, FREQ_UNITS=str][, /OVERPLOT|/COMPARISON]
;              [, /NO_UNWRAP]
;
; INPUTS:
;
;    f_vec:       real vector. Vector of frequencyes. Frequencies less
;                 or equal to zero are not considered.
;    complex_tf:  complex vector. Transfer function. The number of
;                 elements of complex_tf must be the same as f_vec.
;
; OPTIONAL INPUTS:
;
;    None.
;
; KEYWORD PARAMETERS:
;
;    RADIANTS:    If set, the phase is plotted in radiants (degree by
;                 default).
;
;    FREQ_UNITS:  string. Units of the frequency vector. Default value: "Hz".
;
;    NO_UNWRAP:   If set, the phase unwrapping is disabled.
;
;    OVERPLOT:    If set, plot_phase overplots instead of plotting.
;
;    COMPARISON:  Used by plot_bode.pro. Not considered if OVERPLOT is set.
;
;    All the keywords allowed in plot (or overplot if OVERPLOT is set)
;    can be added to the calling sequence.
;
; OUTPUTS:
;
;    None.
;
; OPTIONAL OUTPUTS:
;
;    None.
;
; COMMON BLOCKS:
;
;    plot_phase_block. Just for internal use.
;
; SIDE EFFECTS:
;
;
;
; RESTRICTIONS:
;
;
;
; PROCEDURE:
;
;
;
; EXAMPLE:
;
;
;
; MODIFICATION HISTORY:
;
;       Nov 1998, written by A. Riccardi (AR)
;       Osservarorio Astrofisico di Arcetri (OAA), ITALY
;       <riccardi@arcetri.astro.it>
;
;       G. Brusa, OAA
;       Added overplot and comparison features
;
;       Mar 2002, AR
;       Fix of the label of the angle axis when radiants are displayed.
;       RADIANTS keyword added, DEG keyword suppressed
;       From now degree unit is the default
;
;       Apr 2002, AR
;       FREQ_UNITS keyword added
;
;       July 2003, AR
;       unwrapping phase code moved to unwrap_phase indipendent procedure
;-

common plot_phase_block, phase_xrange, phase_yrange

if n_params() ne 2 then $
  message, "Two parameters must be passed."

if test_type(f_vec, /FLOAT, /DOUBLE, N_EL=n_el) then $
  message, 'f_vec must be single or double precision float.'
idx = where(f_vec le 0.0, count)
if n_el-count lt 2 then $
  message, 'f_vec must have at least 2 elements greater then 0.'

if test_type(complex_tf, /COMPLEX, /DCOMPLEX $
             , N_EL=n_el_tf) then $
  message, 'complex_tf must be complex floating point.'
if n_el ne n_el_tf then $
  message, 'complex_tf must have the same no. of elements then f_vec.'

idx = where(f_vec gt 0)
pass = imaginary(alog(complex_tf[idx]))

if not keyword_set(no_unwrap) then unwrap_phase, pass

if keyword_set(rad) then begin
    ytit = 'Phase [rad]'
endif else begin
    pass = pass*180.0/!PI
    ytit = 'Phase [deg]'
endelse

if n_elements(smooth_window) ne 0 then pass = smooth(pass, smooth_window, /EDGE)

if keyword_set(overplot) then begin
    oplot, f_vec[idx], pass, _EXTRA=extra_keyw
endif else begin
	if keyword_set(comparison) then begin
		plot, f_vec, pass, xrange=10.^(phase_xrange) $
			, yrange=phase_yrange,/noerase, xstyle=5, ystyle=5 $
			, /XLOG, _EXTRA=extra_keyw
	endif else begin
		if n_elements(freq_units) ne 0 then $
			xtitle="Frequency ["+freq_units+"]" $
		else $
			xtitle="Frequency [Hz]"
		if n_elements(pyrange) ne 0 then begin
			yticks=fix((pyrange(1)-pyrange(0)))/90
			ytickv=90*(fix(pyrange(0))/90+indgen(yticks+1))
			yminor=9
			if not keyword_set(xrange) then xrange=minmax(f_vec)
			plot, f_vec, pass, /XLOG $
	     		, xtit='Frequency [Hz]',ytit=ytit $
	     		, xgridstyle=1, ygridstyle=1, ticklen=1.0$
				, _EXTRA=extra_keyw, yrange=pyrange , xrange=xrange $
				, yticks=yticks , ytickv=ytickv, yminor=yminor
		endif else begin
			if keyword_set(xrange) then begin
				yrange=minmax(pass(where(f_vec gt xrange(0) and $
						f_vec lt xrange(1))))
			endif else begin
				yrange=[min(pass), max(pass)]
			endelse
			if not keyword_set(xrange) then xrange=[min(f_vec),max(f_vec)]
			yticks=fix((yrange(1)-yrange(0)))/90
			ytickv=90*(fix(yrange(0))/90+indgen(yticks+1))
			yminor=9
			plot, f_vec, pass, /XLOG $
	     		, xtit='Frequency [Hz]',ytit=ytit $
	     		, xgridstyle=1, ygridstyle=1, ticklen=1.0$
				, _EXTRA=extra_keyw, xrange=xrange $
				, yticks=yticks , ytickv=ytickv, yminor=yminor
		endelse
	endelse
endelse
phase_xrange=!x.crange
phase_yrange=!y.crange
end

