; $Id: plot_amp.pro,v 1.5 2006/09/08 10:59:16 labot Exp $

pro plot_amp, f_vec, complex_tf, _EXTRA=extra_keyw, OVERPLOT=overplot $
              , DB=db,COMPARISON=comparison, AUNITS=aunits, SMOOTH_SIZE=smooth_window
;+
; NAME:
;    PLOT_AMP
;
; PURPOSE:
;
;    Plot_amp plots (or overplots) the amplitude of a complex
;    transfer function. The plot is log-log and the gridding is
;    enabled.
;
; CATEGORY:
;
;    Plotting Routines, Digital Filtering
;
; CALLING SEQUENCE:
;
;    plot_amp, f_vec, complex_tf[, /DB|AUNITS=str][, /OVERPLOT|/COMPARISON]
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
;    DB:          If set, plot the amplitude axis in deciBel (dB)
;                 units.
;
;    AUNITS:      String containing the units of the amplitude axis.
;                 It is not considered if the DB keyword is used.
;    OVERPLOT:    If set, plot_amp overplots instead of plotting.
;
;    COMPARISON:  Keyword used by plot_bode.pro. It is not considered if
;                 the OVERPLOT keyword is used
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
;    plot_amp_block. Just for internal use.
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
;       Nov 1998, written by A. Riccardi <riccardi@arcetri.astro.it>
;                 Osservatorio Astrofisico di Arcetri, ITALY
;
;       G. Brusa, Added COMPARISON and AUNITS keywords
;
;-

common plot_amp_block, amp_xrange, amp_yrange

if n_params() ne 2 then $
	message, "Two parameters must be passed."

if test_type(f_vec, /FLOAT, /DOUBLE, N_EL=n_el) then $
  message, 'f_vec must be single or double precision float.'
idx = where(f_vec le 0.0, count)
if n_el-count lt 2 then $
  message, 'f_vec must have at least 2 elements greater then 0.'

if test_type(complex_tf, /FLOAT, /DOUBLE, /COMPLEX, /DCOMPLEX $
             , N_EL=n_el_tf) then $
  message, 'complex_tf must be real or complex floating point.'
if n_el ne n_el_tf then $
  message, 'complex_tf must have the same no. of elements then f_vec.'

idx = where(f_vec gt 0)

amp_tf=abs(complex_tf)
if n_elements(smooth_window) ne 0 then amp_tf=smooth(amp_tf,smooth_window,/EDGE)

if keyword_set(overplot) then begin
    if keyword_set(db) then begin
        oplot, f_vec[idx], 20*alog10(amp_tf[idx]) $
          , _EXTRA=extra_keyw
    endif else begin
        oplot, f_vec[idx], amp_tf[idx] $
          , _EXTRA=extra_keyw
    endelse
endif else begin
	if keyword_set(comparison) then begin
		plot, f_vec, amp_tf, xrange=10.^(amp_xrange) $
		, yrange=10.^(amp_yrange), /noerase, xsty=5, ysty=5 $
		 , /XLOG, /YLOG, _EXTRA=extra_keyw
	endif else begin
        if keyword_set(db) then begin
            plot, f_vec[idx], 20*alog10(amp_tf[idx]) $
              , xtit='Frequency', ytit='Amplitude [dB]' $
              , xgridstyle=1, ygridstyle=1, ticklen=1.0 $
              , /XLOG, _EXTRA=extra_keyw
        endif else begin
        	ytitle='Amplitude'
        	if n_elements(aunits) ne 0 then ytitle=ytitle+' '+aunits
            plot, f_vec[idx], amp_tf[idx] $
              , xtit='Frequency', ytit=ytitle $
              , xgridstyle=1, ygridstyle=1, ticklen=1.0 $
              , /XLOG, /YLOG, _EXTRA=extra_keyw
        endelse
    endelse
endelse

amp_xrange=!x.crange
amp_yrange=!y.crange

end
