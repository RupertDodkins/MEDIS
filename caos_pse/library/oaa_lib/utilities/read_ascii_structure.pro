; $Id: read_ascii_structure.pro,v 1.3 2005/06/10 11:08:25 labot Exp $
;+
; NAME:
;        READ_ASCII_STRUCTURE
;
; PURPOSE:
;        The READ_ASCII_STRUCTURE function reads a text file containing the definition
;        of a structure. See below for format definition of the text file.
;
; SYNTAX:
;        struc = read_ascii_structure(filename)
;
; RETURN VALUE:
;        returns the structure defined in filename. In case of error the return
;        value is undefined.
;
; ARGUMENTS:
;   filename:  scalar string containing the name of the text file that contains the
;              sructure definition. The file has to have the ".txt" extension.
;
; DEFINITION OF THE FILE FORMAT
;
; The format of a text file describing a structure is the following:
;
; ;optional comment or blank lines
; name1   type1   content1 ;optional description
; ;optional comment or blank lines
; name2   type2   content2 ;optional description
; ...
; ;optional comment or blank lines
; nameN   typeN   contentN ;optional description
;
; Empty lines or lines having ";" or "#" as first non-blank character (optional
; comment lines) are skipped.
;
; Fields are separated by (single or multiple) spaces or tabs.
;
; name: valid IDL variable name
; type: one of the following case insensitive strings:
;        array      (see 'Content of array' section)
;        byte       (content is a scalar byte)
;        int        (content is a scalar 16bit short integer)
;        long       (content is a scalar 32bit long integer)
;        float      (content is a scalar floating point)
;        double     (content is a scalar double-precision floating point)
;        complex    (content is a scalar complex floating-point)
;        string     (content is a double-quoted string, like "foo")
;        structure  (see 'Content of strcture' section)
;        dcomplex   (content is a scalar complex double-precision floating)
;        uint       (content is a scalar unsigned 16bit short integer)
;        ulong      (content is a scalar undigned 32bit long integer)
;        long64     (content is a scalar 64bit long integer)
;        ulong64    (content is a scalar unsigned 64bit long integer)
;
; Content of int, long, uint, ulong, long64 and ulong64 types can be
; given in hexadecimal format pre-pending x (or X), like x1F8C
; Complex and dcomplex are not supported, yet.
;
; CONTENT OF ARRAY
; The content of an array can refere to an external file or can be specified in-line.
;
; In the first case we have two possibilities: text files or FITS files. In case of text
; files the content is a double-quoted string addressing
; the array definition, like "./conf/array.txt". Only ".txt" extension is allowed.
; See read_ascii_array.pro help for a complete desription of the array definition format.
; Use unix-like ("/") directory separator.
;
; In case of FITS files the content is again a double-quoted string addressing
; the FITS file, like "./conf/array.fits" or "./conf/array.fts". Only ".fits" or ".fts"
; extensions are allowed. Use unix-like ("/") directory separator. Astrolib is required.
;
; The content of small arrays can be defined in-line using the same format used for
; array definition files:
;
; varname  array  ; no content after array string
;   (array definition, see read_ascii_array help)
; end
;
; CONTENT OF STRUCTURES
; The content of a structure can refere to an external file or can be specified in-line.
; In the first case the content is a double-quoted string addressing
; the structure definition, like "./conf/struc.txt". The format is the same described in
; this help. Only ".txt" extension is allowed. Use unix-like ("/") directory separator.
; The content of small structures can be defined in-line using the same format used for
; structure definition files:
;
; varname  structure  ; no content after array string
;    ... (structure definition, see above)
; end
;
; Example:
;
; ;start of structure definitin file
; name   string "test" ;string definition
; var    float  1.2    ;float definition
; struc1 structure "./struc.txt" ; indirect structure definition
;
; struc2 structure     ;in-line structure definition
;     aa     int    5  ;int definition
;     dd     double 6d0;double definition
; end                  ;end of in-line structure definition
;
; mat1   array  "./array.txt" ; indirect array definition
;
; mat2   array         ;in-line structure definition
;     long 2 3         ;type and dimesion size definition
;     123 233
;     333 44
;     6   1234
; end                  ;end of in-line structure definition
;
; ppp    ulong64 6457648638  ;unsigned 64-bit long int definition
; ; end of structure definition file
;
; HISTORY
;  Created: 13 Dec 2003, A. Riccardi (AR), riccardi@arcetri.astro.it
;	04 Feb 2004		AR and M.Xompero (MX)
;					Fixed the bug in extensions retrieval.
;   April 2005      D.Zanotti(DZ), comment unuseful keyword regex in row 279.
;-

function read_ascii_structure, filename, UNIT=unit, DEBUG=debug

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
the_line = ""
is_first = 1B
while not eof(unit) do begin
    readf, unit, the_line
    the_line = strtrim(the_line,2)
    if strlen(the_line) ne 0 then begin
       first_char = strmid(the_line,0,1)
       if total(first_char eq comment_chars) eq 0 then begin
         the_line = (strsplit(the_line, "[;#]", /EXTRACT, /REGEX))[0]
         field = strsplit(the_line, /EXTRACT, /REGEX)

         if is_open and strlowcase(field[0]) eq "end" then break

         n_fields = n_elements(field)
         if n_fields lt 2 then begin
          message, "Wrong format for variable "+field[0]+" in "+filename $
                 , /NONAME, /NOPRINT
         endif

         case field[1] of

       "array": begin
         nf = n_elements(field)
         if nf eq 2 then begin
          content = read_ascii_array(filename, UNIT=unit, DEBUG=debug)
         endif else begin
          if nf ne 3 then begin
              ; there are some spaces in the filename string
              field[2] = stregex(the_line, field[2]+'.*"', /EXTRACT, /REGEX)
              if field[2] eq "" then begin
                 message, "Wrong format for variable "+field[0]+" in "+filename $
                 , /NONAME, /NOPRINT
              endif
          endif
          array_filename = (strsplit(field[2], '"', /EXTRACT, /REGEX))[0]
          ext = strsplit(array_filename, '\.', /EXTRACT, /REGEX)
          ext = ext[n_elements(ext)-1]
          case ext of
              'txt': content = read_ascii_array(array_filename, DEBUG=debug)
              'fts': content = readfits(array_filename)
              'fits': content = readfits(array_filename)
              else: message, "Unsupported file extension ("+ext+") in "+filename
          endcase
         endelse
       end

         "byte": begin
          if n_fields ne 3 then begin
              message, "Wrong format for variable "+field[0]+" in "+filename $
                     , /NONAME, /NOPRINT
          endif
          if strlowcase(strmid(field[2],0,1)) eq "x" then $
              format="("+strmid(field[2],0,1)+",Z)" $
          else $
              format="(I)"
          content = 0B
          reads, field[2], content, FORMAT=format
         end

         "int": begin
          if n_fields ne 3 then begin
              message, "Wrong format for variable "+field[0]+" in "+filename $
                     , /NONAME, /NOPRINT
          endif
          if strlowcase(strmid(field[2],0,1)) eq "x" then $
              format="("+strmid(field[2],0,1)+",Z)" $
          else $
              format="(I)"
          content = 0
          reads, field[2], content, FORMAT=format
         end

         "long": begin
          if n_fields ne 3 then begin
              message, "Wrong format for variable "+field[0]+" in "+filename $
                     , /NONAME, /NOPRINT
          endif
          if strlowcase(strmid(field[2],0,1)) eq "x" then $
              format="("+strmid(field[2],0,1)+",Z)" $
          else $
              format="(I)"
          content = 0L
          reads, field[2], content, FORMAT=format
         end

         "float": begin
          if n_fields ne 3 then begin
              message, "Wrong format for variable "+field[0]+" in "+filename $
              , /NONAME, /NOPRINT
          endif
          content = 0e0
          reads, field[2], content, FORMAT="(F)"
         end

         "double": begin
          if n_fields ne 3 then begin
              message, "Wrong format for variable "+field[0]+" in "+filename $
              , /NONAME, /NOPRINT
          endif
          content = 0d0
          reads, field[2], content, FORMAT="(D)"
         end

         "string": begin
          if n_fields eq 2 then begin
              message, "Wrong format for variable "+field[0]+" in "+filename $
                     , /NONAME, /NOPRINT
          endif
          if n_fields gt 3 then begin
              ; there are some spaces in the string
              field[2] = stregex(the_line, field[2]+'.*"', /EXTRACT)
              if field[2] eq "" then begin
                 message, "Wrong format for variable "+field[0]+" in "+filename $
                 , /NONAME, /NOPRINT
              endif
          endif
          content = (strsplit(field[2], '"', /EXTRACT, /REGEX))[0]
         end

         "structure": begin
         nf = n_elements(field)
         if nf eq 2 then begin
          content = read_ascii_structure(filename, UNIT=unit, DEBUG=debug)
         endif else begin
          if nf ne 3 then begin
              ; there are some spaces in the filename string
              field[2] = stregex(the_line, field[2]+'.*"', /EXTRACT, /REGEX)
              if field[2] eq "" then begin
                 message, "Wrong format for variable "+field[0]+" in "+filename $
                 , /NONAME, /NOPRINT
              endif
          endif
          struc_filename = (strsplit(field[2], '"', /EXTRACT, /REGEX))[0]
          ext = strsplit(struc_filename, '.', /EXTRACT);, /REGEX)
          ext = ext[n_elements(ext)-1]
          case ext of
              'txt': content = read_ascii_structure(struc_filename, DEBUG=debug)
              else: message, "Unsupported file extension ("+ext+") in "+filename
          endcase
         endelse
         end

         "uint": begin
          if n_fields ne 3 then begin
              message, "Wrong format for variable "+field[0]+" in "+filename $
                     , /NONAME, /NOPRINT
          endif
          if strlowcase(strmid(field[2],0,1)) eq "x" then $
              format="("+strmid(field[2],0,1)+",Z)" $
          else $
              format="(I)"
          content = 0U
          reads, field[2], content, FORMAT=format
         end

         "ulong": begin
          if n_fields ne 3 then begin
              message, "Wrong format for variable "+field[0]+" in "+filename $
                     , /NONAME, /NOPRINT
          endif
          if strlowcase(strmid(field[2],0,1)) eq "x" then $
              format="("+strmid(field[2],0,1)+",Z)" $
          else $
              format="(I)"
          content = 0UL
          reads, field[2], content, FORMAT=format
         end

         "long64": begin
          if n_fields ne 3 then begin
              message, "Wrong format for variable "+field[0]+" in "+filename $
              , /NONAME, /NOPRINT
          endif
          if strlowcase(strmid(field[2],0,1)) eq "x" then $
              format="("+strmid(field[2],0,1)+",Z)" $
          else $
              format="(I)"
          content = 0LL
          reads, field[2], content, FORMAT=format
         end

         "ulong64": begin
          if n_fields ne 3 then begin
              message, "Wrong format for variable "+field[0]+" in "+filename $
              , /NONAME, /NOPRINT
          endif
          if strlowcase(strmid(field[2],0,1)) eq "x" then $
              format="("+strmid(field[2],0,1)+",Z)" $
          else $
              format="(I)"
          content = 0ULL
          reads, field[2], content, FORMAT=format
         end

         "complex": message, "Complex data are not supported, yet.", /NONAME, /NOPRINT

         "dcomplex": message, "Complex data are not supported, yet.", /NONAME, /NOPRINT

         else: begin
         message, "Wrong format for variable "+field[0]+" in "+filename $
             , /NONAME, /NOPRINT
         end

         endcase

         if is_first then begin
         map_struct = create_struct(field[0], content)
         is_first = 0B
         endif else begin
         map_struct = create_struct(temporary(map_struct), field[0], content)
         endelse
       endif
    endif
endwhile

if n_elements(map_struct) eq 0 then begin
    message, "No data in structure definition." $
           , /NONAME, /NOPRINT
endif else begin
    if not is_open then free_lun, unit
    return, map_struct
endelse

end
