; $Id: fft1.pro,v 1.3 2003/06/10 18:29:26 riccardi Exp $

;+
; FFT1
;
; perform FFT for real data, providing the correct scaling
; and PSD (pixels^2/Hz)
;
; HISTORY:
;    ?? 19??  Written by Guido Brusa, Osservatorio Astrofisico di Arcetri
;             brusa@arcetri.astro.it
;
;
;-

pro fft1, data, dt, FSPEC=fspec, PSPECTRUM=pspectrum, PSD=psd, SPEC=spec $
        , NOPLOT=noplot, PRINT=print

np=n_elements(data)
df=1./dt/np                   ;frequency sampling
pspectrum=fltarr(2,np)
fspec=(findgen(np/2)+1)*df  ;array with sampled frequency
spec=fft(data,-1)

pspectrum(0,*)=abs(spec)
pspectrum(1,*)=atan(imaginary(spec),float(spec))

psd=reform(2*pspectrum(0,1:np/2)^2,np/2)/df

if not keyword_set(noplot) then begin
    window, /free, title='data'
    plot, dt*findgen(n_elements(data)), data, xtitle='Time/sec' $
        , psym=-1, syms=.6
    window, /free, title='spectrum'
    !p.multi=[0,1,2]
    plot_oo, fspec, pspectrum(0,1:n_elements(fspec)-1) $
           , xtitle='Frequency/hz',psym=-2 $
           , syms=.6,ytitle='Amplitude'
    plot_oi, fspec, pspectrum(1,1:n_elements(fspec)-1)/!pi*180 $
           , yr=[-180,180],$
    ystyle=1, ytitle='Phase'
    window, /free, title='PSD'
    !p.multi=[0,0,0]
    plot_oo, fspec, psd, xtitle='Frequency/hz', psym=-2, syms=.6 $
           ,ytitle='Power/Hz'
    window, /free, title='PSD*f'
    !p.multi=[0,0,0]
    !p.region=[0.1,0.1,.9,.9]
    plot, alog10(fspec), psd*fspec, xtitle='log(Frequency/hz)', psym=10 $
        ,syms=.6, ytitle='Power', xsty=9, xr=[alog10(fspec(0)-df/2*(1.1)) $
        , alog10(fspec(np/2-1)+df/2*1.1)]
    plots, [alog10(fspec(0)),alog10(fspec(0)-df/2)] $
         , [psd(0)*fspec(0),psd(0)*fspec(0)], /data
    plots, [alog10(fspec(0)-df/2), alog10(fspec(0)-df/2)] $
         , [psd(0)*fspec(0),0], /data
    xyouts, .5, .8, 'Total power = '+string(format='(E9.2)',total(psd*df)) $
          , /norm
    xyouts, .5, .7, 'zero frequency bin power = ' $
          + string(format='(E9.2)',pspectrum(0,0)^2), /norm
    axis, xaxis=1, /xlog, xtitle='Frequency/Hz', xr=[fspec(0)-df/2*(1.1) $
        , fspec(np/2-1)+df/2*1.1], xsty=1
    !p.region=[0,0,0,0]
endif

if(keyword_set(print)) then begin
    if(print eq 1) then begin
        psinit, /full
        !p.multi=[0,1,5]
        plot, dt*findgen(n_elements(data)), data,xtitle='Time/sec' $
            , psym=-1, syms=.6
        plot_oo, fspec, pspectrum(0,1:n_elements(fspec)-1) $
               , xtitle='Frequency/hz',psym=-2, syms=.6, ytitle='Amplitude'
        plot_oi, fspec, pspectrum(1,1:n_elements(fspec)-1)/!pi*180 $
               , yr=[-180,180], ystyle=1, ytitle='Phase'
        plot_oo, fspec, psd, xtitle='Frequency/hz', psym=-2, syms=.6 $
               , ytitle='Power/Hz'
        plot, alog10(fspec), psd*fspec, xtitle='log(Frequency/hz)' $
            , psym=10, syms=.6, ytitle='Power', xsty=9 $
            , xr=[alog10(fspec(0)-df/2*(1.1)),alog10(fspec(np/2-1)+df/2*1.1)]
        plots, [alog10(fspec(0)),alog10(fspec(0)-df/2)] $
             , [psd(0)*fspec(0),psd(0)*fspec(0)], /data
        plots, [alog10(fspec(0)-df/2),alog10(fspec(0)-df/2)] $
             , [psd(0)*fspec(0),0], /data
        xyouts, .5, .15, 'Total power = ' $
              + string(format='(E9.2)',total(psd*df)), /norm
        xyouts, .5, .1, 'zero frequency bin power = ' $
              + string(format='(E9.2)',pspectrum(0,0)^2), /norm
        axis, xaxis=1, /xlog, xtitle='Frequency/Hz' $
            , xr=[fspec(0)-df/2*(1.1), fspec(np/2-1)+df/2*1.1],xsty=1
        !p.multi=[0,0,0]
        psterm
    endif else begin
        psinit
        !p.multi=[0,0,0]
        !p.region=[0.1,0.1,.9,.9]
        plot, alog10(fspec), psd*fspec, xtitle='log(Frequency/hz)' $
            , psym=10, syms=.6, ytitle='Power', xsty=9 $
            , xr=[alog10(fspec(0)-df/2*(1.1)),alog10(fspec(np/2-1)+df/2*1.1)]
        plots, [alog10(fspec(0)),alog10(fspec(0)-df/2)] $
             , [psd(0)*fspec(0),psd(0)*fspec(0)], /data
        plots, [alog10(fspec(0)-df/2),alog10(fspec(0)-df/2)] $
             , [psd(0)*fspec(0),0], /data
        xyouts, .5, .8, 'Total power = ' $
              + string(format='(E9.2)',total(psd*df)), /norm
        xyouts, .5, .7, 'zero frequency bin power = ' $
              + string(format='(E9.2)',pspectrum(0,0)^2), /norm
        axis, xaxis=1, /xlog, xtitle='Frequency/Hz' $
            , xr=[fspec(0)-df/2*(1.1), fspec(np/2-1)+df/2*1.1], xsty=1
        !p.region=[0,0,0,0]
        psterm
    endelse
endif
return
end
