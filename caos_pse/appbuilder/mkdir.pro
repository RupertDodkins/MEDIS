;T+
;
; \subsubsection{Function: {\tt mkdir}}
;
; The following procedure creates a new directory relative to the current
; working directory.
;
;T-

; NAME:
;       mkdir
;
; PURPOSE:
;       creates a subdirectory of current working directory.
;
; CATEGORY:
;
;	Miscellaneous
;

PRO mkdir, filename

cmd = 'mkdir ' + filename

spawn, cmd 

END


