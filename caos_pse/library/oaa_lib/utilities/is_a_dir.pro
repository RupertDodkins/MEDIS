; $Id: is_a_dir.pro,v 1.3 2003/06/10 18:29:26 riccardi Exp $

;+
;
; NAME
;
;    IS_A_DIR
;
; SYNTAX
;
;    ret = is_a_dir(dirname)
;
; dirname: scalar string containing the directory name to test.
;
; ret:     scalar byte. 1B or 0B if dirname is or is not the name of an 
;                       existing directory.
;
function is_a_dir, dirname

cd, CURR=curr_dir

catch, no_valid_dir
if no_valid_dir ne 0 then begin
    ;; error occurred changing the directory
    return, 0B
endif

;; try to change directory to dirname
cd, dirname

;; if you are here the directory changing succeeded
cd, curr_dir
return, 1B

end
