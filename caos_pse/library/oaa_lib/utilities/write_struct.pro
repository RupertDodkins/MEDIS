;+
;WRITE_STRUCT
;err = write_struct(unit_s, struct_value, name_str)
;
;PURPOSE:
; Writes a in-line struct in a text file, if the in-line struct
; cointains an array or another struct, for the struct another 
; text file is created and  refered in the source text file. 
;
;unit_s: The unit number associated with the opened file.
;struct_value: the structure to write in the file txt.
;name_str: name of the structure
;
;KEYWORDS 
; None.
;
; HISTORY
; written by D.Zanotti(DZ)
; Osservatorio Astrofisico di Arcetri, ITALY
; zanotti@arcetri.astro.it
; 
;
;-
function write_struct, unit_s, struct_value, name_str

if (size(struct_value))[0] ne 1 then begin 
    print,'Struct is not defined'
    return, 1
endif
if n_elements(unit_s) eq 0 then begin 
    print, 'Unit not defined'
    return, 1
endif

if n_elements(name_str) eq 0 then begin
    print, 'Name structure is not defined'
    return, 1
endif

field_st = strlowcase(tag_names(struct_value))
n_field_st = n_elements(field_st)
name_len_st = intarr(n_field_st)
for i=0,n_field_st-1 do name_len_st[i]=strlen(field_st[i])
field_len_st = max(name_len_st)+1
dim_arr = intarr(n_field_st)
var_type_st = intarr(n_field_st)

for i=0,n_field_st-1 do begin
 dim_size_st = size(struct_value.(i))
 dim_arr[i] = dim_size_st[0]
 var_type_st[i] = dim_size_st[dim_size_st[0]+1]
endfor
if total(dim_arr) ne 0 then begin
    struct_file = strtrim(name_str)+".txt"
    write_structure_ascii, struct_value, FILENAME= struct_file
    printf,unit_s,  name_str, " structure",' "'+"./"+struct_file+'"' ,FORMAT="(A8,A,A)" 
endif else begin
    printf,unit_s,  name_str, "structure"
    for v=0, n_field_st-1 do begin
        t_name = tell_type(var_type_st[v], F_TYPE=frmt_tp)
        name = field_st[v]+string(replicate(byte(" "),field_len_st-name_len_st[v]))
        printf, unit_s," ", name, t_name, struct_value.(v), FORMAT="(A,A, A,"+frmt_tp+")" 
    endfor    
    printf,unit_s,"end"
endelse            

return, 0
end


