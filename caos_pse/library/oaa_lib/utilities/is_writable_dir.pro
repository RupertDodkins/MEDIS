; $Id: is_writable_dir.pro,v 1.3 2003/06/10 18:29:26 riccardi Exp $

;+
;
; NAME
;
;    IS_WRITABLE_DIR
;
; SYNTAX
;
;    ret = is_writable_dir(dirname)
;
; dirname: scalar string containing the directory name to test.
;
; ret:     scalar byte. 1B if it is possible to write in dirname. 0B otherwise.
;
; April 1999, written by A. Riccardi (OAA) <riccardi@arcetri.astro.it>
;-
function is_writable_dir, dirname

;; try to open a temporary file
filename = filepath("tmp"+strtrim(long(systime(1)),2), ROOT=dirname)
openw, unit, filename, /GET_LUN, ERROR=error, /DELETE

is_writable = error eq 0

if is_writable then free_lun, unit

return, is_writable
end
