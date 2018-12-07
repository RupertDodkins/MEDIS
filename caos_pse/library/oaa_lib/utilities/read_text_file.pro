; $Id: read_text_file.pro,v 1.3 2003/06/10 18:29:27 riccardi Exp $

function read_text_file, filename

openr, unit, filename, /GET_LUN
max_num_lines = 1000
buffer = strarr(max_num_lines)

is_first = 1B
on_ioerror, at_eof
while 1B do begin
	readf, unit, buffer
	if is_first then begin
		tot_buffer = buffer
		is_first = 0B
	endif else tot_buffer = [temporary(tot_buffer), buffer]
endwhile

at_eof:
on_ioerror, null
n_lines = (fstat(unit)).transfer_count
if n_lines gt 0 then begin
	if is_first then begin
		tot_buffer = buffer[0:(n_lines-1)]
	endif else begin
		tot_buffer = [temporary(tot_buffer), buffer[0:(n_lines-1)]]
	endelse
endif
free_lun, unit
return, tot_buffer
end
