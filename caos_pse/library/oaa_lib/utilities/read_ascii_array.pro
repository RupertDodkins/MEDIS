;+
; NAME:
;        READ_ASCII_ARRAY
;
; PURPOSE:
;        The READ_ASCII_ARRAY function reads a text file containing the definition
;        of an array. See below for format definition of the text file.
;
; SYNTAX:
;        array = read_ascii_array(filename)
;
; RETURN VALUE:
;        returns the array defined in filename. In case of error the return
;        value is undefined.
;
; ARGUMENTS:
;   filename:  scalar string containing the name of the text file that contains the
;              array definition. The file has to have the ".txt" extension.
;
; DEFINITION OF THE FILE FORMAT
;
; The format of a text file describing an array is the following:
;
; ;optional comment or blank lines
; type dim1_len dim2_len ... dimn_len ; optional description
; array_val1 array_val2 ... array_valn
; array_valn+1 ... array_valm
; ...
; ...array_val_last
;
; Empty lines or lines having ";" or "#" as first non-blank character (optional
; comment lines) are skipped.
;
; The optional description must start with ";" or "#" character and cannot include
; any other ";" or "#" character.
;
; The first non-comment line contains the array type (type) and
; the size of each dimension of the array (dim1_len dim2_len ... dimn_len).
; Type can be one of the following case insensitive string:
;        byte       (byte)
;        int        (16bit short integer)
;        long       (32bit long integer)
;        float      (floating point)
;        double     (double-precision floating point)
;        complex    (complex floating-point)
;        string     (double-quoted string, like "foo")
;        dcomplex   (complex double-precision floating)
;        uint       (unsigned 16bit short integer)
;        ulong      (unsigned 32bit long integer)
;        long64     (64bit long integer)
;        ulong64    (unsigned 64bit long integer)
;
; Type and dimension sizes are separated by (single or multiple) tabs or spaces.
; The ordering of dimensions follows the standard standard IDL/Fortran index
; ordering (from the most to the least fast index, i.e. column-major format in the
; 2D-array case).
;
; The array values start form the second non-comment line. The number of array values
; per line is arbitrary and can be different line by line.
; No comment or blank lines or pending comment are allowed among array values and
; between the first value and the type and dimension size line.
; The ordering of the array values follows the IDL/Fortran ordering (column-major format
; in case of 2D-arrays), with the first index running faster than the second, the second
; runnig faster than the third, etc..
;
; If type is string, the array string items are not limited by single or double
; quotes. The whole line (including leading or pending spaces) is consideres as
; correct array item value.
;
; Hexadecimal format is NOT supported for content of int, long, uint, ulong,
; long64 and ulong64 types, yet.
; Complex and dcomplex types are not supported, yet.
;
;
; FORMAT HISTORY:
;   11 Dec 2003: Created by A. Riccardi riccardi@arcetri.astro.it
;   30 May 2004: Help modified: NO hex format supported
;-
;

function read_ascii_array, filename, UNIT=unit, ERROR=error_occurred, DEBUG=debug
;print,"DEBUG=",keyword_set(debug)
if not keyword_set(debug) then on_error, 2

catch, error_status
if (error_status ne 0) then begin
    catch, /CANCEL
    ;
    ; start of cleaning code and return value setting
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    error_occurred = 1B
    if (n_elements(unit) ne 0) and (not is_open) then $
       free_lun, unit
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; end of cleaning code and return value setting
    ;
    message, !ERROR_STATE.MSG
endif

is_open = n_elements(unit) ne 0
if not is_open then openr, unit, filename, /GET_LUN

comment_chars = [";","#"]
comment_regex = "["+strjoin(comment_chars)+"]"
line_found=0B
the_line = ""
while not (eof(unit) or line_found) do begin
    readf, unit, the_line
    the_line = strtrim(the_line,2)
    if strlen(the_line) ne 0 then begin
       first_char = strmid(the_line,0,1)
       if total(first_char eq comment_chars) eq 0 then begin
         the_line = (strsplit(the_line, "[;#]", /EXTRACT, /REGEX))[0]
         field = strsplit(the_line, /EXTRACT, /REGEX)
         n_dimensions = n_elements(field)-1
         if n_dimensions lt 1 then begin
          message, "At least one dimension size must be specified in "+filename $
                 , /NONAME, /NOPRINT
         endif
         field[1] = strlowcase(field[1])
         line_found = 1B
       endif
    endif
endwhile
if not line_found then begin
    message, "Line containing type and dimension size list not found in "+filename $
           , /NONAME, /NOPRINT
endif

type=field[0]

dim_size = long(field[1:*])

type_code = type_str_to_code(type)
if type_code eq -1 then begin
    message, "Unknown type ("+type+") in "+filename, /NONAME, /NOPRINT
endif

sz = lonarr(n_dimensions+3)
sz[0] = n_dimensions
sz[1:n_dimensions] = dim_size
sz[n_dimensions+1] = type_code
sz[n_dimensions+2] = product(dim_size)

array = make_array(SIZE=sz)

readf, unit, array

if is_open then begin
    readf, unit, the_line
    if strlowcase(strmid(strtrim(the_line,2),0,3)) ne "end" then begin
       message, "No end keyword found for in-line structure definition." $
              , /NONAME, /NOPRINT
    endif
endif else $
    free_lun, unit

return ,array

end
