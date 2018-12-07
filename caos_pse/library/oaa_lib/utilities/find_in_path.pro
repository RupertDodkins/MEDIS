; $Id: find_in_path.pro,v 1.1 2002/03/22 15:14:58 riccardi Exp $
;
;+
; FIND_IN_PATH
;
; The function searches a file in all the directories specified
; in the !PATH system variable
;
; SYNTAX
;
;   res = find_in_path(filename, /VERBOSE)
;
; INPUTS
;
;   filename:  scalar string. File name to search for. only the
;              filename without any path. Wild characters are allowed.
;
; OUTPUT
;
;   res:       empty string ("") if no file has been found. Vector of
;              strings containing the results of the search if
;              successful.
;
; HISTORY
;
;   22 Mar 2002:  Written by A. Riccardi
;                 Osservatorio Astrofisico di Arcetri, Italy
;                 riccardi@arcetri.astro.it
;
;-

function find_in_path, filename

if !version.os_family eq "Windows" then delim = ';' else delim = ':'
dirs = strsplit(!PATH, delim, /EXTRACT)

nd = n_elements(dirs)

res = [""]
for id=0,nd-1 do begin
    fn = findfile(filepath(ROOT=dirs[id],filename))
    if fn[0] ne "" then res=[temporary(res),fn]
endfor

if n_elements(res) gt 1 then return, res[1:*] else return, res
end
