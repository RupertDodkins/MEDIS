; $Id: idx_array.pro,v 1.2 2002/12/11 18:39:09 riccardi Exp $
;+
;   IDX_ARRAY
;
;  The function convert a one-dimensional indexes of a
;  N-dimensional array (returned by the where function,
;  as instance) in vectors containinig the corresponding
;  collections of N-dimensional indexes
;
;   idx_vec = idx_array(idx, array)
;  or
;   idx_vec = idx_array(idx, size(array), /SIZE_OF_ARRAY)
;
;  	idx:   input. non floating point M-elemnts vector.
;          one-dimensional index of array[*]
;   array: input. N-dimensional array.
;
;   index_vec: output, long NxM array.
;
;  EXAMPLE:
;
; IDL> a=fltarr(10,5,6)
; IDL> a[7,2:3,5]=1
; IDL> idx=where(a eq 1)
; IDL> print, idx
;          277         287
; IDL> print, idx_array(idx, a)
; IDL> print, idx_array(idx, a)
;            7           2           5
;            7           3           5
; IDL> print, idx_array(idx, size(a), /SIZE_OF_ARRAY)
;            7           2           5
;            7           3           5
;
; HISTORY:
;    04 Dic 2002. Written by A. Riccardi. INAF, OAA, Italy
;                 riccardi@arcetri.astro.it
;-
function idx_array, idx1, array, SIZE_OF_ARRAY=soa

	if keyword_set(soa) then s=array else s=size(array)
	idx=idx1
	nidx=n_elements(idx)
	idx_vec = lonarr(s[0],nidx)
	for id=1,s[0] do begin
		idx_vec[id-1,*]=idx mod s[id]
		idx=idx/s[id]
	endfor
	return, idx_vec
end

