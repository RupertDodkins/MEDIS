; $Id: wdel.pro,v 1.3 2003/06/10 18:29:28 riccardi Exp $

;+
;
; NAME
;
;  WDEL
;
; wdel
;
; delete all the windows currently defined.
;
; April 1999, A.R. (AOO)
;-

pro wdel

while (!D.WINDOW ne -1) do begin
    wdelete, !D.WINDOW
endwhile

end

