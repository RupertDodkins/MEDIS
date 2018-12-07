; $Id: socket_query.pro,v 1.1 2004/02/24 12:23:47 riccardi Exp $

;+
;   NAME
;       socket_query
;
;   The function send a string to the socket port and wait for a string as responce.
;
;   CALLING SEQUENCE
;       err = socket_query(ip_addr_str, com_port, commandS, responceS)
;
;   PARAMETERS
;       ip_addr_str string, scalar. IP address of the host device
;       commandS    string or integer, scalar. Port number or identification string of the
;                   host listening socket.
;       commandS    string, scalar. String to send to the serial port. By default
;                   a CR character is appended to the string before sending it
;                   to the serial port (see keyword NO_APPEND_CR).
;       responceS   named variable. On output, the string containing the
;                   responce to the command.
;
;
;   KEYWORDS
;       RESP_END_STR       string, scalar. Character identifying the end of
;                          the response to the command. If it is not defined
;                          a CR is considered. For instance the end string in a
;                          responce to a valid AT modem command is "OK"+string([13B,10B]).
;       NO_APPEND_CR       if it is set, no CR character is appended to the
;                          command string before sending the command to the
;                          serial port.
;       RESP_LEN           named variable. On output it contains the number of
;                          character read in the responce (including the
;                          end-of-responce string).
;       NUM_RESP_LINES     integer, scalar. Number of lines ending with RESP_END_STR
;                          expected in the responce. Default=1. 0 is allowed.
;		CONNECT_TIMEOUT    see socket online help. Default values 10, 2, 2 seconds respectively.
;		WRITE_TIMEOUT
;		READ_TIMEOUT
;
;   RETURN VALUE
;       err          0: no errors
;                   -1: error sending the string
;                   -2: error while reading
;                   -3: timeout error. No answare from socket
;                   -4: wrong parameters
;
; MODIFICATION HISTORY
;
;   June 2003: written by S. Busoni and A. Riccardi.
;              Osservatorio di Arcetri, Italy.
;              Based on com_query routine.
;
;   Jan 2004: A. Riccardi.
;             Modified default values for timeouts
;+

function socket_query, ip_addr_str, com_port, command, resp $
                  , RESP_END_STR=resp_ch $
                  , NO_APPEND_CR=no_append   $
                  , RESP_LEN=resp_len    $
                  , VERBOSE=verbose $
                  , NUM_RESP_LINES=n_resp_lines $
                  , PORT_ID=port_id $
                  , CONNECT_TIMEOUT=connect_timeout $
                  , WRITE_TIMEOUT=write_timeout $
                  , READ_TIMEOUT=read_timeout


	if test_type(ip_addr_str, /STRING, DIM=n_dim) then begin
		message, "IP Address must be a string", /CONT
		return, -4
	endif
	if n_dim[0] ne 0 then begin
		message, "IP Address must be a scalar string", /CONT
		return, -4
	endif

	if test_type(com_port, /STRING, /NOFLOATING, DIM=n_dim, TYPE=type) then begin
		message, "Port must be a string or an integer number", /CONT
		return, -4
	endif
	if n_dim[0] ne 0 then begin
		message, "Port must be a scalar string or integer number", /CONT
		return, -4
	endif

	if n_elements(connect_timeout) eq 0 then connect_timeout=10
	if n_elements(write_timeout) eq 0 then write_timeout=2
	if n_elements(read_timeout) eq 0 then read_timeout=2

    cr = string(['0D'XB]) ; CR character

    ;; set the sub-string identifying the end of the response string
    if n_elements(resp_ch) eq 0 then resp_end=cr else resp_end=resp_ch[0]
    resp_ch_len = strlen(resp_end)

    ;; set the timeout for the responce
    if n_elements(timeout) eq 0 then timeout=20.0

	if n_elements(n_resp_lines) eq 0 then n_resp_lines=1

	if arg_present(port_id) then begin
		if n_elements(port_id) eq 0 then open_port=1B else open_port=0B
		close_port=0B
	endif else begin
		open_port=1B
		close_port=1B
	endelse

	if open_port then begin
		socket, comid, ip_addr_str, com_port, /GET_LUN, ERROR=err, CONNECT_TIMEOUT=connect_timeout $
		      , WRITE_TIMEOUT=write_timeout ,READ_TIMEOUT=read_timeout

		if err ne 0 then begin
			message, "Error opening Socket port."+!ERROR_STATE.MSG, /CONT
			return, -1
		endif
		port_id=comid
	endif else comid=port_id

    ;; send the command string
    if keyword_set(no_append) then append_ch="" else append_ch=cr
	catch, trapped_err
	if trapped_err ne 0 then begin
		catch, /CANCEL
		if close_port then free_lun, comid
		message, !ERROR_STATE.MSG, /CONT
		return, -2
	endif
	if strlen(command+append_ch) ne 0 then begin
    	writeu, comid, byte(command+append_ch), TRANSFER_COUNT=sent_chars
    	flush, comid
    endif else sent_chars=0
	catch, /CANCEL

    ;; test for an error
    if (sent_chars ne strlen(command+append_ch)) then begin
    	if close_port then free_lun, comid
    	return, -3
    endif

	if keyword_set(verbose) then begin
		print, "Sent string:"
		dummy = strsplit(command,cr,/EXTRACT)
		print, reform(dummy, 1, n_elements(dummy))
	endif
    ;; read the answer from COM port, put it in a buffer until the end of the
    ;; responce is identifyed
    ;;
    prompt_received = 0B
    err = 0B
    resp_len = 0
    resp=""

    t0=systime(1)

    the_char = 0B
    nread=0
	n_lines=0
    repeat begin
		catch, trapped_err
		if trapped_err ne 0 then begin
			if !ERROR_STATE.NAME ne "IDL_M_FILE_EOF" then begin
				catch, /CANCEL
				if close_port then free_lun, comid
				message, !ERROR_STATE.MSG, /CONT
				return, -4
			endif
		endif else begin
    		readu, comid, the_char, TRANSFER_COUNT=nread
    	endelse
    	catch, /CANCEL

        ;print, nread ;;;;;;;;;;;;;;;;
        if nread gt 0 then begin
            resp = resp+string(the_char)
            ;print, byte(resp) ;;;;;;;;;;;;;;;;;;;;;;;;
            resp_len = resp_len+nread
            if resp_len ge resp_ch_len then $
                if strmid(resp, resp_len-resp_ch_len, resp_ch_len) eq resp_end then begin
                	n_lines = n_lines+1
                	if n_lines eq n_resp_lines then begin
						if keyword_set(verbose) then begin
							print, "Received string:"
							dummy = strsplit(resp,cr,/EXTRACT)
							print, reform(dummy, 1, n_elements(dummy))
						endif
						if close_port then free_lun, comid
	                	return, 0
	                endif
                endif
        endif
    endrep until 0B
end

