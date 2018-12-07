; $Id: gzp2pid.pro,v 1.4 2003/06/10 18:29:24 riccardi Exp $

;+
; GPZ2PID
;
; convert a filter parametrized as gain-zero-pole into a PID
;
;        (s+z[0])*...*(s+z[nz-1])               1         A
; gain * ------------------------  ==> kp + ki*--- + kd*-----*s
;        (s+p[0])*...*(p+p[np-1])               s       (s+A)
;
; where z and p are the zeros and poles of the fileter.
;
; In this frame a valid PID is considered having:
;    kp,ki,kd >= 0 and A > 0
; hence the constrains on gain, z, and p are:
;    gain >= 0 and (nz = np or (nz = 0 and np = 1))
;    if nz eq 0 and np eq 1: the pole must be real and not-negative;
;    if nz eq 1: the zero and the pole must be real and not-negative;
;    if nz eq 2: one pole is zero and the other real and strictly
;                positive. The zeros complex conjugated (real
;                part not-negative) or real and strictly positive;
;    the gain can be zero only if nz = np = 0.
;
;
;
; err = gpz2pid(gain, z, p, kp, ki, kd, A, N_ZEROS=nz, N_POLES=np)
;
;
; gain:    real scalar. Filer Gain (not-negative). If gain eq 0.0 then
;          the number of zeros and poles is forced to be 0.
; z:       real or complex vector. Vector of zeros. If N_ZERO is
;          defined only the first N_ZERO elements are considered.
;          z must have 0 (unefined=no zeros), 1 or 2 valid elements.
; p:       real vector. Vector of poles. If N_POLES is
;          defined only the first N_POLES elements are considered.
;          z must have the same number of valid elements as z.
;
;
; err eq 0 => the filter defined by gain, z, p is a valid PID
; err ne 0 => the filter is not a valid PID
;
; if N_ZEROS is set, only the first nz zeros in the vector z are used.
;            For a valid PID nz can be 0, 1 or 2
;            (set N_ZEROS to 0 if the filter has not zeros).
; if N_POLES is set, only the first np poles in the vector z are used.
;            For a valid PID nz can be 0, 1 or 2
;            (set N_POLES to 0 if the filter has not poles).
;
; NOTE: the GZP to PID conversion work well if poles are different
;       from any zero and vice versa.
;
; MODIFICATON HISTORY
;
;    Written by: A. Riccardi, Osservatorio Astrofisico di Arcetri, ITALY
;                riccardi@arcetri.astro.it
;-

function gzp2pid, gain, z, p, kp, ki, kd, A, N_ZEROS=nz, N_POLES=np

if test_type(gain, /REAL, n_el=n) then $
  message, 'The gain must be real'
if n ne 1 then $
  message, 'The gain must be a scalar'
if gain lt 0.0 then $
  message, 'The gain must be a not-negative'

;; if gain eq 0 the "zero" filter is returned
if gain eq 0.0 then begin
    kp = 0d0
    ki = 0d0
    kd = 0d0
    A  = 0d0
    return, 0L
endif

;; hereafter gain can be assumed to be strictly positive

;; Tests on the zeros
if test_type(z, /NUMERIC, /UNDEFINED, N_EL=nnz, TYPE=tz) then $
  message, 'The vector of zeros must be numeric or undefined'

if n_elements(nz) eq 0 then begin
    nz = nnz
endif else begin
    if test_type(nz, /NOFLOAT, N_EL=n) then $
      message, 'N_ZEROS must be an integer'
    if n ne 1 then $
      message, 'N_ZEROS must be a scalar'
    if nz gt nnz then $
      message, 'N_ZEROS is larger then the no. of avaliable zeros'
endelse

if total([0,1,2] eq nz) ne 1 then begin
    message, 'The vector of valid zeros must have 0, 1 or 2 elements', /CONT
    return, -1L
endif

if nz gt 0 then zz = z[0:nz-1]

; the zeros can be complex only if nz eq 2
if ((tz eq 6) or (tz eq 9)) then begin
    case nz of
        2: begin
            ;;eps=(machar(DOUBLE = tz eq 9)).eps
            if imaginary(zz[0]) ne -imaginary(zz[1]) then begin
                message, 'A valid PID must have real or conjugated zeros (if complex)'
                return, -1L
            endif
            if imaginary(zz[0]) eq 0.0 then begin
                ;; convert in real zero
                if tz eq 6 then begin
                    zz = float(zz)
                    tz = 4
                endif else begin
                    zz = double(zz)
                    tz = 5
                endelse
            endif
        end

        1: begin
            eps=(machar(DOUBLE = tz eq 9)).eps
            if (abs(imaginary(zz)) gt eps*abs(zz))[0] then begin
                message, 'A valid PID can not have a single complex zero' $
                  , /CONT
                return, -1L
            endif else begin
                ;; convert in real zero
                if tz eq 6 then begin
                    zz = float(zz)
                    tz = 4
                endif else begin
                    zz = double(zz)
                    tz = 5
                endelse
            endelse
        end

        0: begin
            ;; do nothing
        end
    endcase
end



;; Tests on the poles
if test_type(p, /NUMERIC, /UNDEFINED, N_EL=nnp, TYPE=tp) then $
  message, 'The vector of zeros must be numeric or undefined'

if n_elements(np) eq 0 then begin
    np = nnp
endif else begin
    if test_type(np, /NOFLOAT, N_EL=n) then $
      message, 'N_POLES must be an integer'
    if n ne 1 then $
      message, 'N_POLES must be a scalar'
    if np gt nnp then $
      message, 'N_POLES is larger then the no. of avaliable poles'
endelse

if total([0,1,2] eq np) ne 1 then begin
    message, 'The vector of valid poles must have 0, 1 or 2 elements', /CONT
    return, -1L
endif

if np gt 0 then pp = p[0:np-1]

; the poles cannot be complex
if ((tp eq 6) or (tp eq 9)) then begin
    if np gt 0 then begin
        eps=(machar(DOUBLE = tp eq 9)).eps
        if total(abs(imaginary(pp)) gt eps*abs(pp)) gt 0 then begin
            message, 'A valid PID must have real poles.', /CONT
            return, -1L
        endif
        ;; convert in real poles
        if tp eq 6 then begin
            pp = float(pp)
            tp = 4
        endif else begin
            pp = double(pp)
            tp = 5
        endelse
        if total(pp lt 0.0) gt 0 then begin
            message, 'A valid PID must have not-negative poles.', /CONT
            return, -1L
        endif
    endif
endif


;; PID computation
case 1B of
    nz eq np: begin
        case nz of
            0: begin
                kp = gain
                ki = 0d0
                kd = 0d0
                A  = 0d0
                return, 0L
            end

            1: begin
                if pp[0] eq 0.0 then begin
                    kp = gain
                    ki = zz[0]*kp
                    kd = 0d0
                    A  = 0d0
                    return, 0L
                endif else begin
                    ;; pp[0] gt 0.0
                    A  = pp[0]
                    ki = 0d0
                    kd = gain*(A-zz[0])/A^2
                    kp = gain*zz[0]/A
                    return, 0L
                endelse
            end

            2: begin
                if total((pp eq 0.0) + (pp gt 0.0)) ne 2 then begin
                    message,'Not valid poles for a PID ' $
                      + '(one eq 0 and one gt 0 pole is needed)' $
                      , /CONT
                    return, -1L
                endif
                alpha = z[0]+z[1]
                beta  = abs(z[0]*z[1])
                if tz eq 4 or tz eq 6 then $
                  alpha = float(alpha) $
                else $
                  alpha = double(alpha)

                A  = max(pp)    ; extract the not-null pole
                kp = gain*[alpha-beta/A]/A
                ;kd = gain*(beta + A^2 - A*alpha)/A^3
                kd = gain*((beta/A - alpha)/A + 1.0)/A
                ki = gain*beta/A
                return, 0L
            end
        endcase
    end
    nz eq 0 and np eq 1: begin
        if pp[0] ne 0.0 then begin
            message,'Not valid zero-pole combination for a PID.', /CONT
            return, -1L
        endif

        kp = 0d0
        ki = gain
        kd = 0d0
        A  = 0d0
        return, 0L
    end

    else: begin
        message, 'Invalid PID. Wrong combination of zeros and poles.', $
          /CONT
        return, -1L
    end
endcase

return, 0L
end
