; $Id: psg_read_cube.pro,v 5.2 2007/04/18 marcel.carbillet@unice.fr $
;+
;
; err = psg_read_cube(unit, header, phase_screen)
;
; unit:          scalar int. Logical unit associated to the file
;                opened with psg_open_cube.
; header:        structure. Header structure of the data cube file,
;                returned by psg_open_cube.
; phase_screen:  named variable. The next phase screen in the data cube.
;
; err:  error if ne 0
;
;-
;
function psg_read_cube, unit, header, phase_screen

err = !caos_error.ok

dim_x = header.dim_x
dim_y = header.dim_y

if header.double then begin
    phase_screen = dblarr(dim_x, dim_y)
endif else begin
    phase_screen = fltarr(dim_x, dim_y)
endelse

on_ioerror, IO_ERR
io_valid = 0B

readu, unit, phase_screen

io_valid = 1B
IO_ERR: if not io_valid then begin
    message, !ERR_STRING, /CONT
    return, -1L
endif

return, err
end
