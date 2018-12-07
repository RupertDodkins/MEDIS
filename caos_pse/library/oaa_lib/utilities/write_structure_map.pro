;+
;WRITE_STRUCTURE_MAP
; 
;write_structure_map, name_struct, FILENAME=filename
;
;PURPOSE
;  writes a structure of  address map in a text file.
;
;name_struct: address map structure to write.
;
;KEYWORDS
;FILENAME: name of txt file.
;
;HISTORY:
;written by D.Zanotti (DZ)
;Osservatorio di Astrofisico di Arcetri
;zanotti@arcetri.astro.it
;
;-
pro  write_structure_map, name_struct, FILENAME=filename

struct=name_struct
if n_elements(struct) ne 1 then message,  'Struct is not defined'
field = strlowcase(tag_names(struct))
n_field = n_elements(field)
if not keyword_set(filename) then begin
    print, 'A default name is used for the data file'
    saved_file="Structure_data.txt"
endif else saved_file=filename

name_len = intarr(n_field)
for i=0,n_field-1 do name_len[i]=strlen(field[i])
field_len = max(name_len)+1

print, saved_file
openw, unit, saved_file, /GET_LUN

for i=0,n_field-1 do begin
    name = field[i]+string(replicate(byte(" "),field_len-name_len[i]))
    printf, unit, name, struct.(i), FORMAT="(A,'long x',Z8.8)"
    print, name, struct.(i), FORMAT="(A,'long x',Z8.8)"
endfor
free_lun, unit

end
