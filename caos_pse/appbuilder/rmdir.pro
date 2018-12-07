;T+
; \subsubsection{Function: {\tt rmdir}}		\label{rmdir}
;
; The following procedure deletes a file or a directory. In the latter case
; the directory content is removed too.
;
;T-

PRO rmdir, filename

; --------------------------------------------------- BEGIN SYSDEP
case !VERSION.OS_FAMILY of
    "unix": begin
        cmd = 'rm -fr ' + filename
        spawn, cmd
    end

    "Windows": begin
        cmd = 'echo y|del '+filename+'\*.*'
        spawn, cmd
        cmd = 'rd '+filename
        spawn, cmd
    end

    else: begin
        message, "Operating System not supported"
    end
endcase
; --------------------------------------------------- END SYSDEP

END
