; $Id: zern_order.pro,v 1.2 2003/06/10 18:29:24 riccardi Exp $ 
; 
; A. Riccardi, Dipartimento di Astronomia di Firenze (Italy). 
; riccardi@arcetri.astro.it
; Please, send me a message if you modify this code. 


function zern_order, nmax
;+
;   Result = ZERN_ORDER(Nmax)
;
;   returns a vector of Zernike polynomial indexes from 2 to
;   ZERNIKE_INXDEX(Nmax,Nmax) ordered by azimuthal frequency
;   (see Roddier 90, Opt. Eng., 29, 1174). Nmax must be >=1
;-
    if (Nmax lt 1) then begin
        print, 'Order_index -- nmax must be greater or equal to 1'
        return, 0
    endif

    ; num_poly = maximum possible value of index - 1 (the piston)
    num_poly = zernike_index(nmax, nmax)

    result = intarr(num_poly)

    r_sub = 0
    dj = 0
    
    ; correlations to Z2, m=1
    for n = 1, nmax,2 do begin
        ; select correct parity
        result(r_sub)=zernike_index(n,1)+dj
        r_sub = r_sub+1
        dj = (dj + 1) mod 2
    endfor

    dj = 1
    ; correlations to Z3, m=1
    for n = 1, nmax,2 do begin
        ; select correct parity
        result(r_sub)=zernike_index(n,1)+dj
        r_sub = r_sub+1
        dj = (dj + 1) mod 2
    endfor

    if (nmax eq 1) then return, result

    ; correlations to Z4, m=0, discard piston
    for n = 2, nmax,2 do begin
        ; select correct parity
        result(r_sub)=zernike_index(n,0)
        r_sub = r_sub+1
    endfor

    ; other correlations
    for m = 2, nmax do begin
        for djm=0,1 do begin
            dj = djm
            for n=m,nmax,2 do begin
                ; select correct parity
                result(r_sub)=zernike_index(n,m)+dj
                r_sub = r_sub+1
                dj = (dj + 1) mod 2
            endfor
        endfor
    endfor

    return, result
end

