; $Id: list2ranges.pro,v 1.4 2004/03/10 18:49:25 riccardi Exp $

;+
;
; LIST2RANGES
;
; This function returns a list of couples of numbers
; giving the ranges of consecutive numbers in the input list.
;
; ranges = LIST2RANGES(list, range_count [,BREAK_MODULUS=br])
;
;
; INPUTS
;
;   list:            byte, short-int or long-int vector. The list don't need to
;                    be ordered or having unique elements.
;
; OUTPUTS
;
;   ranges:          byte, short-int or long-int array. Same type as list.
;                    List of ranges of consecutive values
;                    in list. The array has 2 columns and range_count rows.
;
;   range_count:     named variable. This variable is set in output to the number of
;                    indipendent ranges found in the list vector.
;
; KEYWORDS
;
;   BREAK_MODULUS:   byte, short-int or long-int scalar. If defined
;                    to a value N, it forces a range to be splitted
;                    when k*N is included in the range
;                    (k=+/-1,+/-2,+/-3,...). In other words it avoids
;                    that k*N-1 and k*N are included in the same range.
;
;
; EXAMPLE
;
;   list = [3, 14, 2, 13, 4, 1, 13, 11, -1, 5, 0]
;   print, list2ranges(list, count)
;
;   -1  5
;   11  11
;   13  14
;
;   print, count
;
;   3
;
;   The result means that the list can be considered as 3
;   not overlapping groups of numbers, the first ranging from
;   -1 to 5, the second from 11 to 11 and the last from 13 to 14.
;
;   The same list, using the BREAK_MODULUS keyword:
;   list = [3, 14, 2, 13, 4, 1, 13, 11, -1, 5, 0]
;   print, list2ranges(list, count, BREAK_MODULUS=5)
;
;   -1   4
;    5   5
;   11  11
;   13  14
;
;   print, count
;
;   4
;
;
; HISTORY:
;
;       Nov 27 1999, Armando Riccardi (AR)
;       <riccardi@riccardi.arcetri.astro.it>
;
;       Mar 10 2004: AR, BREAK_MODULUS keyword added.
;
;
;-
;
function list2ranges_core, the_list, n_first_last

on_error, 2

n_first_last = 0L

if n_elements(the_list) eq 1 then begin
    n_first_last = 1L
    ranges = [the_list[0], the_list[0]]
endif else begin
    
    last  = long(shift(the_list, -1)) - long(the_list)
    first = long(the_list) - long(shift(the_list, 1))
    
    idx_first = where(first gt 1 or first lt 0, first_count)
    idx_last  = where(last gt 1 or last lt 0, last_count)
    
    if first_count ne last_count or first_count eq 0 then begin
        message, 'The algorithm for the first/last choice failed'
    endif
    
    n_first_last = first_count
    ranges = [transpose(the_list[idx_first]), transpose(the_list[idx_last])]
    
endelse

return, ranges
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

function list2ranges, list, n_ranges, BREAK_MODULUS=n2break

on_error, 2

n_ranges = 0

if test_type(list, /NOFLOATING, N_EL=n) then begin
    message, 'list must be a vector of byte, int or long'
endif

the_list = list[sort(list)]      ; an ordered list is needed
the_list = the_list[uniq(the_list)] ; a not redundant list is needed
n = n_elements(the_list)

if n_elements(n2break) ne 0 then begin
    if test_type(n2break, /NOFLOATING, N_EL=dummy) then begin
        message, 'BREAK_EVERY content must be byte, int or long'
    endif
    if dummy ne 1 then begin
        message, 'BREAK_EVERY must be scalar'
    endif
    test = the_list/n2break[0]
    test_val = test[uniq(test)]
    n_test_val = n_elements(test_val)
endif else begin
    return, list2ranges_core(the_list,n_ranges)
endelse

for ib=0,n_test_val-1 do begin
    idx = where(test eq test_val[ib])
    
    if ib eq 0 then begin
        ranges = list2ranges_core(the_list[idx],n_sub_ranges)
    endif else begin
        ranges = [[temporary(ranges)], $
                  [list2ranges_core(the_list[idx],n_sub_ranges)]]
    endelse
    n_ranges = n_ranges+n_sub_ranges
endfor

return, ranges

end
