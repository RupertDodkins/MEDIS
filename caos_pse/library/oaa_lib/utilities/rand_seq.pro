; $Id: rand_seq.pro,v 1.4 2004/08/06 09:13:17 marco Exp $

function rand_seq, f_min, f_max, dt, n_samples, SEED=seed, SPECTRUM=spec $
                 , ZERO_DC_LEVEL=no_dc, FREQ_VECTOR=f_vec, BIN_STEP=bin_step
;
;+
;
; RAND_SEQ
;
; This function computes a real random sequence having a flat power
; spectral density inside the frequency range [f_min,f_max] and 0
; outside. The variance (i.e. the total power) of the output sequence is 1.
;
; seq = RAND_SEQ(f_min, f_max, dt, n_samples, SEED=seed, SPECTRUM=spec)
;
; f_min:   float, scalar. On input the lower limit of the bandpass.
;          On output the lower limit used by the function because of the
;          finite sampling.
;
; f_max:   float, scalar. The same as above for the higher limit of the
;          bandpass.
;
; dt:      float, scalar. The sampling step of the sequence.
;
; n_samples: long or short integer, scalar. The number of sampling points
;            in the sequence.
;
; SEED:    see randomu procedure.
;
; ZERO_DC_LEVEL: if set force zero-mean sequence even if f_min is equal to 0.
;
; SPECTRUM: named variable. On output this variable contains the spectrum of
;           the sequence.
;
; FREQ_VECTOR: named variable. On output the frequency vector related to
;              SPECTRUM.
;
; BIN_STEP: integer scalar. By default is 1. The step (in frequency bins) between
;           two successive excited frequencyes. If it is 1 (or not defined) the
;           power spectral density of the output signals is a box starting from
;           f_min to f_max. If it is greater then one, the power spectral density
;           is a sequence of equispaced Dirac's deltas starting from f_min, one
;           every BIN_STEP frequency bins. The higher excited frequency bin is less
;           then or equal to f_max.
;
; HISTORY:
;   written by Armando Riccardi (AR)
;   riccardi@arcetri.astro.it
;
;   06 Aug 2004 Marco Xompero (MX)
;    Now the number of samples can be ini, unit, long, ulong.
;-

    if test_type(f_min, /FLOAT, /NOFLOAT, N_EL=n_el) then $
        message, "f_min must be float."
    if n_el ne 1 then $
        message, "f_min must be a scalar."
    if f_min[0] lt 0.0 then $
        message, "f_min must be greater then or equal to zero."

    if test_type(f_max, /FLOAT, /NOFLOAT, N_EL=n_el) then $
        message, "f_max must be float."
    if n_el ne 1 then $
        message, "f_max must be a scalar."
    if f_max[0] lt f_min[0] then $
        message, "f_max must be greater then or equal to f_min."

    if test_type(dt, /FLOAT, /NOFLOAT, N_EL=n_el) then $
        message, "dt must be float."
    if n_el ne 1 then $
        message, "dt must be a scalar."
    if dt[0] le 0.0 then $
        message, "dt must be positive."

    if test_type(n_samples, /INT, /LONG, /UINT, /ULONG, N_EL=n_el) then $
        message, "n_samples must be an integer."
    if n_el ne 1 then $
        message, "n_samples must be a scalar."
    if n_samples[0] lt 3 then $
        message, "n_samples must be greater then or equal to 3."

    if n_elements(bin_step) ne 0 then begin
        if test_type(bin_step, /INT, /LONG, N_EL=n_el) then $
            message, "bin_step must be a long or short integer."
        if n_el ne 1 then $
            message, "bin_step must be a scalar."
        if n_samples[0] le 1 then $
            message, "bin_step must be greater then or equal to 1."
    endif else begin
        bin_step = 1
    endelse


    f_step = 1.0/dt/n_samples
    f_niq = 0.5/dt
    iu = complex(0.0, 1.0)

    ; n_ph: number of independent phase values
    n_ph = n_samples/2 - 1 + (n_samples mod 2)
    temp = randomu(seed, n_ph)

    ; build the phase vector for the hermitian spectrum
    phase = fltarr(n_samples)
    phase[1:n_ph] = temp
    phase[n_samples-n_ph:*] = -reverse(temp)

    ; absolute value of the frequency vector
    f_vec = f_step*dist(n_samples, 1)

    eps = epsilon()
    f_idx = where((f_vec ge f_min*(1.0-eps)) and (f_vec le f_max*(1.0+eps)), count)
    ; f_idx contains the indexes of the positive and negative frequencies
    if count eq 0 then $
        message, "Wrong frequency range"

    ; override the real f_min and f_max that will be used
    f_max = max(f_vec(f_idx), MIN=f_min)

    ; set the right sign of the frequencies for the output
    f_vec[n_samples-n_ph:*] = -f_vec[n_samples-n_ph:*]

    modulus=fltarr(n_samples)
    modulus(f_idx) = 1.0

    if bin_step gt 1 then begin
        f_idx = where((f_vec ge f_min*(1.0-eps)) and (f_vec le f_max*(1.0+eps)), count)
        ; now f_idx contains only the indexes of the positive frequencies
        min_f_idx=min(f_idx) & max_f_idx=max(f_idx)
        mask = replicate(0B, n_samples)
        mask[min_f_idx+bin_step*lindgen((max_f_idx-min_f_idx)/bin_step+1)]=1B
        dummy = shift(reverse(mask), 1)
        mask = (mask+dummy) < 1B
        modulus = modulus*mask
    endif

    ; filter out the DC component if requested
    if keyword_set(no_dc) and (f_min eq 0.0) then begin
        modulus[0]=0.0
        f_min = f_step
    endif

    spec=modulus*exp(2*!pi*iu*phase)
    spec = spec/sqrt(total(modulus^2))

    time_hist = fft(spec, /INVERSE)

    return, float(time_hist)
end
