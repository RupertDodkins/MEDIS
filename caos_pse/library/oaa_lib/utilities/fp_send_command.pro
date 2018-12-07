; $Id: fp_send_command.pro,v 1.2 2004/04/08 11:23:28 marco Exp $$
;
;+
; NAME:
;	FP_SEND_COMMAND
;
; PURPOSE:
;	Send a command to the Field Point device.
;
; CATEGORY:
;	Device driver.
;
; CALLING SEQUENCE:
;	err = fp_send_command (com_data, command_in, resp, N_ITERATIONS=n_iter $
;                        , ERROR_RESP=err_resp, VERBOSE=verb, PORT_ID=port_id)
;
; INPUTS:
;	com_data: input structure.
;					If the device is driven by socket, it needs two fields:
;								- ip_address: 	ipaddress of the device
;								- port:			port number
;					If the device is a COM port, it's need only the string name of the port.
;	command_in: command to send
;
; OUTPUT:
;	resp:		data collected
;
; KEYWORDS:
;	VERBOSE: prints more informations.
;	PORT_ID: return the port_id opened.
;	ERROR_RESP: error code response
;	N_ITERATIONS: return the iteration made for an exact checksum (min 1)
;
; PROCEDURE:
;	The procedure send the command to the Field Point davice and return the data if they are corrects.
;
; MODIFICATION HISTORY:
;
;	Created by Armando Riccardi on 2003
;
; 	16 Jan 2004: A. Riccardi
; 		Socket communication is now supported thru serial<->TCP/IP converter
; 		Added VERBOSE and PORT_ID keywords
; 
; 	08 Apr 2004: M. Xompero
; 		Arg_present test fixed
;-

function fp_send_command, com_data, command_in, resp, N_ITERATIONS=n_iter $
                        , ERROR_RESP=err_resp, VERBOSE=verb, PORT_ID=port_id

	if (arg_present(port_id)) or (n_elements(port_id) eq 0) then begin
		if n_elements(port_id) eq 0 then open_port=1B else open_port=0B
		close_port=0B
	endif else begin
		open_port=1B
		close_port=1B
	endelse

    timeout = 4.0
    block_size = 2L
    cr = string(['0D'XB])

    ;; build the command string: prompt+command+checksum
    cs = string(total(byte(command_in)) mod 256, FORMAT="(Z2.2)")
    command = ">" + command_in + cs
    ;; print, command

    n_iter = 1
    max_iter = 3 ;; maximum number of iterations in case of wrong
                 ;; checksum in the response

	if not test_type(com_data, /STRUCT) then begin
		comm_type = "socket"
		ip_address = com_data.ip_address
		port = com_data.port
	endif else begin
		comm_type = "serial"
		com_port_str = com_data
	endelse

    repeat begin
		if comm_type eq "serial" then begin
	        err = com_query(com_port_str, command, resp, TIMEOUT=timeout $
	                        , RESP_LEN=resp_len, BLOCK_SIZE=block_size, PORT_ID=port_id, VERB=verb)
	    endif else begin
	        err = socket_query(ip_address, port, command, resp $
	                        , RESP_LEN=resp_len, PORT_ID=port_id, VERB=verb)
	    endelse
        ;; check for any communication error
        if err ne 0L then begin
        	if close_port then free_lun, port_id
        	return, -1000L-err
        endif
        ;; print, resp

        ;; check for any FieldPoint error
        if strmid(resp, 0, 1) ne "A" then begin
            err_resp = strmid(resp, 1, 2)
            reads, err_resp, err, FORMAT="(Z2.2)"
            if close_port then free_lun, port_id
            message, "FieldPoint returned error: "+err_resp, /CONT
            return, -2000L-err
        endif

        if resp_len eq 2 then begin
            ;; no data in the responce. resp="A"+CR, no checksum available
            resp=""
            if close_port then free_lun, port_id
            return, 0L
        endif

        ;; check for any checksum error
        ;; retrieve the checksum. Last 3 chars: checksum + CR
        reads, strmid(resp, resp_len-3, 3), resp_cs, FORMAT="(Z2.2)"
        ;; retrieve the data responce. First char "A", last 3 chars as above
        resp = strmid(resp, 1, resp_len-4)
        if (total(byte(resp)) mod 256) eq resp_cs then begin
        	if close_port then free_lun, port_id
        	return, 0L
        endif

        ;; if the checksum is wrong retry to send the command
        n_iter = n_iter+1
    endrep until n_iter gt max_iter

	if close_port then free_lun, port_id
    ;; the checksum failed too many times
    return, -3000L

end

