;+
; UNWRAP_PHASE
;
; unwrap_phase, phase
;
; unwrap phase vector (in radians). The unwrapped phase is overwritten
;
; HISTORY
;   07-2003: written by A. Riccardi, Osservatorio di Arceri, ITALY
;            riccardi@arcetri.astro.it
;-
pro unwrap_phase, pass

    pass_der=(shift(pass, -1)-pass)[0:n_elements(pass)-2]
    jump_p=where(pass_der gt !PI, count_p)
    jump_m=where(pass_der lt -!PI, count_m)
    if count_p gt 0 then begin
        for ic=0,count_p-1 do begin
            pass[jump_p(ic)+1:*]=pass[jump_p[ic]+1:*]-2*!PI
        endfor
    endif
    if count_m gt 0 then begin
        for ic=0,count_m-1 do begin
            pass[jump_m[ic]+1:*]=pass[jump_m[ic]+1:*]+2*!PI
        endfor
    endif
end
