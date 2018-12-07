;T+
; \subsubsection{Function: {\tt rename}}           \label{rename}
;
; The following procedure renames a file or a directory
;
;T-

PRO rename, fromname, toname

; --------------------------------------------------- BEGIN SYSDEP
ff=FINDFILE(fromname,COUNT=nn)

IF nn EQ 0 THEN RETURN

case !VERSION.OS_FAMILY of
    "unix": begin
        cmd = 'mv -f ' + fromname + ' ' + toname
	spawn, cmd
    end

    "Windows": begin
        cmd = 'move ' + fromname + ' ' + toname
	spawn, cmd
    end

    else: begin
        message, "Operating System not supported"
    end
endcase
; --------------------------------------------------- END SYSDEP

END


