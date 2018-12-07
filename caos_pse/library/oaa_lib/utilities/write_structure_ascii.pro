;+
;WRITE_STRUCTURE_ASCII, name_struct, FILENAME=filename
;
;PURPOSE:
; writes a structure in a file text in order to the text definition
; format.
;
;   name_struct: The structure to write in the text file.
;
; KEYWORDS:
;   FILENAME: the name of text file, if not set a default_name is
;   used.
;
; HISTORY  
; written by D.Zanotti(DZ)
; Osservatorio Astrofisico di Arcetri, ITALY
; zanotti@arcetri.astro.it
; 
;
;
;-
pro write_structure_ascii, name_struct, FILENAME=filename

struct=name_struct
if (size(struct))[0] ne 1 then message,  'Struct is not defined'

field = strlowcase(tag_names(struct))
n_field = n_elements(field)
name_len = intarr(n_field)
for i=0,n_field-1 do name_len[i]=strlen(field[i])
field_len = max(name_len)+1


 if not keyword_set(filename) then begin 
     print, "Used a default file name"
     path_file="Default_structure.txt"
 endif else path_file=filename

print, path_file
openw, unit, path_file, /GET_LUN


for i=0,n_field-1 do begin

 dim_size = size(struct.(i))
 var_type = dim_size[dim_size[0]+1]
 t_name = tell_type(var_type, F_TYPE=frmt_tp)
;=============
name = field[i]+string(replicate(byte(" "),field_len-name_len[i]))
if dim_size[0] eq 0  then $
    printf, unit, name, t_name, " ",struct.(i), FORMAT="(A, A, A,"+frmt_tp+")" $
else begin
    if dim_size[0] eq 1 then begin
        if var_type eq 8 then begin
            err=write_struct(unit, struct.(i), name)
            if err then message, 'Error writting the in-line struct'
        endif else begin
            n_arr=n_elements(struct.(i))
            printf,unit,  name, "array"
            printf, unit, " ", t_name, dim_size[1]
            val_arr=struct.(i)
            for dd=0, n_arr-1 do  printf, unit," ", val_arr[dd], FORMAT="(A, "+frmt_tp+")"
            printf,unit,  "end"
        endelse
    endif    
    if dim_size[0] ne 1 then begin
        printf,unit,  name, "array"
        printf,unit,  " ", t_name, dim_size[1:dim_size[0]]
        value_arr=struct.(i)
        n_val=n_elements(value_arr)
        for p=0, n_val-1 do  printf, unit,  "  ", value_arr[p], FORMAT="(A, "+frmt_tp+")"
        printf,unit,  "end"
    endif
endelse            

endfor
free_lun, unit


end
