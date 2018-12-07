; $Id: psg_openr_cube.pro,v 5.2 2007/04/18 marcel.carbillet@unice.fr $
;+
;
; err = psg_openr_cube(unit, filename, header, GET_LUN=get_lun)
;
; unit:          scalar int or named variable (see GET_LUN). Logical
;                unit associated to opened file.
; filename:      scalar string. Name of the file where save the data
;                cube.
;
; err:  error if ne 0
;
;-
function psg_openr_cube, unit, filename, header, GET_LUN=get_lun

err = !caos_error.ok

check_file = findfile(filename)
if check_file[0] eq "" then begin
    message, 'file '+filename+" doesn't exist.", /CONT
    return, -1L
endif

header = psg_empty_header()
h_id_str = header.id_string
h_ver    = header.ver

header.id_string = string(replicate(32B, strlen(h_id_str)))
header.ver = 0*h_ver            ; for future checks

openr, unit, filename, GET_LUN=get_lun, ERROR=error, /XDR
if error ne 0 then begin
    message, !ERR_STRING, /CONT
    return, -2L
endif


on_ioerror, IO_ERR
io_valid = 0B

readu, unit, header

if header.id_string ne h_id_str then begin
    if keyword_set(get_lun) then free_lun, unit else close, unit
    message, "the format of the file "+filename+" is not valid", /CONT
    return, -3L
end

io_valid = 1B
IO_ERR: if not io_valid then begin
    if keyword_set(get_lun) then free_lun, unit else close, unit
    message, !ERR_STRING, /CONT
    return, -4L
endif

return, err
end
