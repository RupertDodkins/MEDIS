pro reorder_matrix, modes, reference_modes, INDEX=idx_ordering, VERBOSE=verb

;+
; reorder a matrix of orthonormal modes with respect to a reference matrix of
; orthonormal modes
;
;           modes: matrix of modes (by columns) to reorder
; reference_modes: matrix of reference modes (by columns)
;
; modes and reference_modes have to have the same number of rows
; Modes in both matrixes have to be normalized like follows:
;
; transpose(modes)##modes = Identity_matrix
; transpose(reference_modes)##reference_modes = Identity_matrix
;
; HISTORY:
;
; 29 May 2003 written by A. Riccardi (Osservatorio di Arcetri, Italy)
;             riccardi@arcetri.astro.it
;
;-

	n_cl_act = n_elements(modes[0,*])

    p_coeff = transpose(reference_modes) ## modes

    v_ord = lonarr(n_cl_act)
    negative = bytarr(n_cl_act)
    new_idx_to_use = lindgen(n_cl_act)
    threshold = 1.0/sqrt(2.0)

    for i=0,n_cl_act-1 do begin
        idx_to_use = new_idx_to_use
        max_p_coeff = max(abs(p_coeff[i,idx_to_use]), idx)
        idx_of_max = idx_to_use[idx]
        if max_p_coeff lt threshold and keyword_set(verb) then begin
            message, "WARNING: the ordering of modes may be affected by error. " $
                     +strtrim(idx_of_max,2), /INFO
        endif
        v_ord[i] = idx_of_max
        if p_coeff[i,idx_of_max] lt 0 then negative[i]=1B
        dummy = complement(idx_of_max, idx_to_use, new_idx_to_use, count)
    endfor

    idx = where(negative eq 1B, count)
    if count ne 0 then begin
        modes[idx, *] = -modes[idx, *]
    endif

    idx_ordering = sort(v_ord)
    modes = modes[idx_ordering, *]
end