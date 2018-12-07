; $Id: sep_path.pro,v 1.4 2003/06/10 18:29:27 riccardi Exp $

;+
; NAME:
;    SEP_PATH
;
; PURPOSE:
;
;    The SEP_PATH function separates the different components of a
;    string containing a pathname. It returns the filename, a vector
;    of subdirectories in which the filename should be located and the
;    root directory, if present (in the Windows OS the latter contains
;    the drive tag). The function works ONLY with the unix and Windows
;    Operative System families.
;
; CATEGORY:
;
;
;
; CALLING SEQUENCE:
;
;    filename = sep_path(path)
;
; INPUTS:
;
;    path:      scalar string. The path string to process.
;
; KEYWORD PARAMETERS:
;
;    ROOT_DIR:     named variable. Scalar string. The root or current
;                  directory path. A disk specification is prepended
;                  disk+root
;                  in the path. A null string ("") if not defined in
;                  path.
;    SUBDIRECTORY: named variable. Vector of strings. The sequence of
;                  subdirectories contained in path.
;
; OUTPUTS:
;
;    filename:     scalar string. The filename if present in path,
;                  otherwise a null string is returned.
;                  Any trailing substring of path that doesn't end
;                  with a directory-separator character is considered
;                  to be a filename.
;
; MODIFICATION HISTORY:
;
;    April 1999, written by A. Riccardi (OAA) <ricardi@arcetri.astro.it>
;-

function sep_path, complete_path, ROOT_DIR=root_dir, SUBDIRECTORY=sub

the_path = complete_path
path_len = strlen(the_path)


root_dir = ""
sub = [""]
filename = ""

if path_len ne 0 then begin

    ;; set the directory separator character
    case !VERSION.OS_FAMILY of
        'unix' : sep = "/"
        'Windows': sep = "\"
        ;'MacOS' : sep = ":"
        ;'vms': sep = "."
        else: message, "The OS Family "+!VERSION.OS_FAMILY $
          +" is not yet supported."
    endcase

    ;; extract the root directory
    if !VERSION.OS_FAMILY eq 'Windows' and $
      strmid(the_path,1,1) eq ":" then begin
        root_dir = strmid(the_path,0,2)
        path_len = path_len-2
        the_path = strmid(the_path,2,path_len)
    endif

    first_char = strmid(the_path, 0, 1)
    if first_char eq sep then begin
        root_dir = root_dir+sep
        repeat begin
            path_len = path_len-1
            the_path = strmid(the_path,1,path_len)
        endrep until (strmid(the_path, 0, 1) ne sep)
    endif else begin
        root_dir = root_dir+"."
    endelse

    ;; extract the filename. Any trailing string that doesn't end
    ;; with a sep char is considered a filename
    last_char = strmid(the_path, path_len-1, 1)
    if last_char ne sep then begin
        sep_pos = rstrpos(the_path, sep)
        filename = strmid(the_path, sep_pos+1, path_len-(sep_pos+1))
        the_path = strmid(the_path, 0, sep_pos+1)
    endif
    ;; remove not effective separator chars
    while (strmid(the_path, path_len-1, 1) eq sep) do begin
        path_len = path_len-1
        the_path = strmid(the_path, 0, path_len)
    endwhile

    ;;separate the directory path components
    sub = str_sep(the_path, sep)
    n_sub = n_elements(sub)
    idx = where(sub ne "", count)
    if count eq 0 then begin
        sub = [""]
    endif else begin
        sub = sub[idx]
    endelse
endif

return, filename

end
