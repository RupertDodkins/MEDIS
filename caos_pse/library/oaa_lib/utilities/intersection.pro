; $Id: intersection.pro,v 1.2 2002/03/14 11:49:12 riccardi Exp $

function intersection, the_list1, the_list2, out_list
;+
; empty_inters = intersection(list1, list2, out_list)
;
; if the range of the union between list1 and list2 is larger then 256*1025
; the routine could be slow (depending on the length of list2)
;-

if test_type(the_list1, /BYTE, /INT, /LONG) then message,'list1 must be integer'
if test_type(the_list2, /BYTE, /INT, /LONG) then message,'list2 must be integer'

list1 = the_list1[uniq(the_list1, sort(the_list1))]
list2 = the_list2[uniq(the_list2, sort(the_list2))]

min_val = min([list1, list2], max=max_val)
;   +--> # of byte in a long (the output of histogram is long)
;   |
if (4d0*(max_val-min_val+1))/1024d0^2 lt 1d0 then begin
	; the hist method can be used because it need less the 1Mb of memory
	join_list = [list1, list2]
	hist =  histogram(join_list, min=min_val, REVERSE=r)
	idx = where(hist ge 2L, count)
	if count eq 0 then return, 1B
	out_list = join_list[r[r[idx]]]
endif else begin
	; a slower method must be used, but less memory-expensive
	empty_inters = 1B
	for i=0,n_elements(list1)-1 do begin
		idx = where(list2 eq list1[i], count)
		if count ne 0 then begin
			if empty_inters then begin
				out_list=list2[idx]
				empty_inters = 0B
			endif else begin
				out_list=[out_list, list2[idx]]
			endelse
		endif
	endfor

	if empty_inters then return, 1B

	out_list = out_list[uniq(out_list, sort(out_list))]
endelse

return, 0B
end
