;+
;Write_array_ascii, vector, FILENAME=filename
;Purpose:
; Write an array in an ascii file txt
;INPUT:
; vector: array to write in tne file
;KEYWORD
; FILENAME: name of file where writes the array in ascci format.
;HISTORY
; created by D.Zanotti(DZ)
;  Osservatorio Astrofisico di Arcetri, ITALY
;  <zanotti@arcetri.astro.it>
;
;
;-
pro write_array_ascii, vector, FILENAME=filename

if n_elements(vector) eq 0 then message, "The array vector is not defined"

if not keyword_set(filename) then begin 
    print, "Used a default file name"
    path_file="Default_array.txt"
endif else path_file=filename

dim_size = size(vector)
var_type = dim_size[dim_size[0]+1]
type_name = tell_type(var_type, F_TYPE=frmt_tp)
n_arr = n_elements(vector)
print, path_file
openw, unit, path_file, /GET_LUN
printf, unit, type_name, dim_size[1:dim_size[0]] 
for i=0,n_arr-1 do begin
        printf, unit, vector[i],  FORMAT="("+frmt_tp+")"
endfor
free_lun, unit


end
