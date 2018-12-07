; $Id: fp_read.pro,v 1.2 2004/04/08 11:23:28 marco Exp $$
;
;+
; NAME:
;	FP_READ
;
; PURPOSE:
;	READ the field point data.
;
; CATEGORY:
;	Data acquisition.
;
; CALLING SEQUENCE:
;	err = fp_read (fp_setting, module_idx, channel_list, UNIT=unit, VERBOSE=verb, $
;						PORT_ID=port_id , ERROR=return_error, FP_ERROR=err_resp)
;
; INPUTS:
; 	fp_setting:
;
; OUTPUT:
;	fp_config: 	configuration structure
;	module_idx: int index of the module fp to read
;	channel_list: int list of the channels to read 
;
; KEYWORDS:
;	VERBOSE: prints more informations.
;	UNIT:	return measur unit of the data read.
;	PORT_ID: port_id on which to read the data.
;	ERROR: error code return
;	FP_ERROR: field point error string
;
; PROCEDURE:
;	The procedure read the data from the field point device by fp_send_command.pro
;
; MODIFICATION HISTORY:
;
;	Created by Armando Riccardi on 2003
;
;	16 Jan 2004: A. Riccardi
;  	Added PORT_ID, ERROR and FP_ERROR keywords.
;     In case of error the function returns 0 and
;     fills ERROR with a error code. FP_ERROR
;     returns the value contained in the fp_send_command
;     ERROR_RESP keyword.
;; 08 Apr 2004: M. Xompero
;		Arg_present test fixed
;-
function fp_read, fp_setting, module_idx, channel_list, UNIT=unit, VERBOSE=verb, $
						PORT_ID=port_id , ERROR=return_error, FP_ERROR=err_resp

err_resp=""
return_error=0L

com_port_str = fp_setting.com_port_str
if test_type(fp_setting.com_port_str, /STRUCT) then begin
	; serial communication. com_port_str is a string or no init'ed device (null string)
	if com_port_str eq "" then begin
	    message, 'The FieldPoint has not been initialized', /CONT
	    return_error=1L
	    return, 0
	endif
endif

if module_idx lt 0 or module_idx ge fp_setting.n_modules then begin
    message, 'Module index outside the valid range', /CONT
    return_error=2L
    return, 0
endif

addr = fp_setting.module[module_idx].addr

idx = reverse(sort(channel_list))
n_ch = n_elements(channel_list)
if (n_ch gt 8) then begin
    message, 'Wrong number of channels', /CONT
    return_error=3L
    return, 0
endif

position = total(2^channel_list)
if position ge 256 then begin
    message, 'Wrong channels', /CONT
    retur_error=4L
endif
position = string(position, FORMAT='(Z4.4)')

command = addr + '!F' + position
if (n_elements(port_id) ne 0) or (arg_present(port_id)) then begin
	err = fp_send_command(com_port_str, command, resp, ERROR=err_resp, VERBOSE=verb, PORT_ID=port_id)
endif else begin
	err = fp_send_command(com_port_str, command, resp, ERROR=err_resp, VERBOSE=verb)
endelse
if err ne 0L then begin
    return_error = err
    return, 0
endif

meas = fltarr(n_ch)
unit = strarr(n_ch)

for j=0,n_ch-1 do begin
    j_ch = channel_list[idx[j]]
    reads, strmid(resp, j*4, 4), adc_val, FORMAT='(Z4.4)'
    meas[idx[j]] = fp_adc2meas(adc_val, fp_setting.module[module_idx].id $
                             , fp_setting.module[module_idx].ch[j_ch].range_entry $
                             , UNIT=temp)
    unit[idx[j]] = temp
endfor

return, meas

end
