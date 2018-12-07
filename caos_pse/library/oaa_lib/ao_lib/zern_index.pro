; $Id: zern_index.pro,v 1.2 2003/06/10 18:29:24 riccardi Exp $           
;           
; A. Riccardi, Dipartimento di Astronomia di Firenze (Italy).         
; e-mail address: riccardi@arcetri.astro.it           
; Please, send me a message if you modify this code.    
    
    
function zern_index, n, m
;+ 
; NAME: 
;       ZERN_INDEX 
; 
; PURPOSE: 
;       ZERN_INDEX calculates the index of a zernike polynomial
;       from radial degree N and azimuthal frequency M. If M is not
;       zero there are two possible index value, even and odd, with
;       index_1=j and index_2=j+1. In this case (M is not 0)
;       Zernike_index returns the minor value (j).
; 
; CATEGORY: 
;       Special polynomial. 
; 
; CALLING SEQUENCE: 
;
;       Result = ZERN_INDEX(N, M) 
; 
; INPUTS: 
;       N:  radial degree. Integer, N>=0.
;       M:  azimuthal frequency. Integer, 0<=M<=N and N-M even 
; 
; MODIFICATION HISTORY: 
;       Written by:     A. Riccardi; April, 1995.
;-
    if ((n lt m) or (n lt 0) or (m lt 0)) then begin
        print, 'zern_index -- n>=0 and 0<=m<=n'
        return, 0
    endif

    if (not is_even(n-m)) then begin
        print, 'zern-index -- n-m must be even'
        return, 0
    endif

    if (m eq 0) then return, (long(n)+1)*n/2+1 $
    else return, (long(n)+1)*n/2+m
end
