;$Id: oa_fft.pro,v 1.1 2007/04/27 13:19:35 marco Exp $$
;+
;   NAME:
;    OA_FFT
;
;   PURPOSE:
;    Select and execute the FFT routine between FFTW package 
;    if installed or the default one.
;
;   USAGE:
;    result = OA_FFT(Input, Keywords)
;
;   INPUT:
;    see FFT IDL documentation.
;
;   OUTPUT:
;    see FFT IDL documentation.
;
;   PACKAGE:
;    OAA_LIB
;   
;   HISTORY:
;    Written by Marco Xompero (MX)
;    marco@arcetri.astro.it
;    27 Apr 2007
;-

Function oa_fft, a, b, IDL=idl, _EXTRA=_EXTRA

    if keyword_set(IDL) then                                            $
        if n_elements(b) eq 0   then return, fft(a, _EXTRA=_EXTRA)      $
                                else return, fft(a, b, _EXTRA=_EXTRA) 
    
    stat = execute('dummy = fftw(fltarr(8))', 0, 1)
    if stat then begin
        if test_type(a,/DOUBLE) then fact = 1./n_elements(a) $ 
                                else fact = 1d/n_elements(a) 
        return, fact*fftw(a, b, _EXTRA=_EXTRA) 
    endif else begin
        if n_elements(b) eq 0   then return, fft(a, _EXTRA=_EXTRA)      $
                                else return, fft(a, b, _EXTRA=_EXTRA) 
    endelse

End
    
    
