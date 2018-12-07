; $Id: complement.pro,v 1.4 2003/06/10 18:29:25 riccardi Exp $

function complement, list1, larger_list1, out_list, the_count
;+
; not_included = complement(list, larger_list, out_list, count)
;
; return in out_list the complement of list in the larger_list.
; list must be included in larger_list. If it is not included
; not_included=1B (=0B otherwise).
; count: # of elements in out_list. If the complement is empty
; the out_list is undefined (i.e. n_elements(out_list)=0) and count=0L
;
; if the range of the union between list and larger_list is larger then 256*1025
; the routine could be slow (depending on the length of larger_list)
;
; MODIFICATON HISTORY
;
;    Written by: A. Riccardi, Osservatorio Astrofisico di Arcetri, ITALY
;                riccardi@arcetri.astro.it
;-

if test_type(list1, /BYTE, /INT, /LONG) then message,'list must be integer'
if test_type(larger_list1, /BYTE, /INT, /LONG) then message,'larger_list must be integer'

list = list1[uniq(list1, sort(list1))]
larger_list = larger_list1[uniq(larger_list1, sort(larger_list1))]


min_val = min([list, larger_list], MAX=max_val)
;   +--> # of byte in a long (the output of histogram is long)
;   |
if (4d0*(max_val-min_val+1L))/1024d0^2 lt 1d0 then begin
	; the hist method can be used because it need less the 1Mb of memory
	join_list = [list, larger_list]
	hist =  histogram(join_list, MIN=min_val, REVERSE=r)

	; test if list is included in larger_list
	idx = where(hist eq 2L, count)
	if count ne n_elements(list) then return, 1B

	idx = where(hist eq 1L, count)
	if count eq 0 then begin
		if n_elements(out_list) ne 0 then $
			dummy=temporary(out_list)
	endif else begin
		out_list = join_list[r[r[idx]]]
	endelse
endif else begin
	; a slower method must be used, but less memory-expensive
	n_l_list = n_elements(larger_list)
	list_flag = bytarr(n_l_list)

	for i=0,n_elements(list)-1 do begin
		idx = where(larger_list eq list[i], count)

		; list must be included in larger_list
		if count eq 0 then return, 1B
		list_flag[idx] = 1B
	endfor

	idx = where(list_flag eq 0B, count)
	if count eq 0 then begin
		if n_elements(out_list) ne 0 then $
			dummy=temporary(out_list)
	endif else begin
		out_list = larger_list[idx]
	endelse
endelse

the_count = n_elements(out_list)
return, 0B
end
