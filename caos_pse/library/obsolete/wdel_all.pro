;+
;
; NAME
;
;  WDEL_ALL
;
; wdel_all
;
; delete all the windows currently defined.
;
; April 1999, A.R. (AOO)
;-

pro wdel_all

while (!D.WINDOW ne -1) do begin
    wdelete, !D.WINDOW
endwhile

end

