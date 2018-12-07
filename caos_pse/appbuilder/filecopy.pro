;T+
; \subsubsection{Function: {\tt filecopy}}           \label{filecopy}
;
; The following procedure copies a file 
;
;T-

PRO filecopy, from, to

; --------------------------------------------------- BEGIN SYSDEP
case !VERSION.OS_FAMILY of
    "unix": begin
        cmd = 'cp -f ' + from + ' ' + to
	spawn, cmd
    end

    "Windows": begin
        cmd = 'copy ' + from + ' ' + to
	spawn, cmd
    end

    else: begin
        message, "Operating System not supported"
    end
endcase
; --------------------------------------------------- END SYSDEP

END


