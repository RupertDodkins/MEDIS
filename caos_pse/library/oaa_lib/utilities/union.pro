; $Id: union.pro,v 1.2 2002/03/14 11:49:14 riccardi Exp $

function union, list1, list2
;+
; list_union = union(list1, list2)
;
; list1, list2: numeric scalar or vector or array
; list_union: union (without repeated elements) of the input lists
;-

if test_type(list1,/NUMERIC) then message,'list1 must be real or complex'
if test_type(list2,/NUMERIC) then message,'list2 must be real or complex'

out_list = [list1, list2]
return, out_list[uniq(out_list, sort(out_list))]

end
