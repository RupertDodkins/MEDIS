; $Id: rst_openr.pro,v 7.0 2016/05/03 marcel.carbillet@unice.fr $
;+
; NAME:
;    rst_openr
;
; CATEGORY
;    utility module routine
;
; CALLING PROCEDURE:
;    error = rst_openr(unit,                 $
;                     filename,              $
;                     structure,             $
;                     N_STRUC=n_struc,       $
;                     STRUC_SIZE=struc_size, $
;                     GET_LUN=get_lun  )
;
; PURPOSE:
;    this utility permits to open a structure contained in a saved (using the
;    module SAV with format XDR) file containing a certain number of these structures.
;    the other utility rst_read has to be used after this one in order to read
;    the data.
;
; NOTA BENE:
;    take care to always close the file after using these utilities by typing:
;       free_lun, unit        (if GET_LUN was used)
;    or:
;       close, unit           (if a unit was specified).
;
; INPUTS:
;    unit      : scalar int. logical unit number (LUN) associated to the file
;               opened with rst_openr.
;    filename  : generic file name (with no extension like ".sav" or ".xdr").
;
; INCLUDED OUTPUT:
;    structure : structure prototype.
;
; KEYWORDS:
;    N_STRUC   : to get the number of structures contained within the file.
;    STRUC_SIZE: to get the structure size in bytes (MUST BE set if N_STRUC is).
;    GET_LUN   : in order to set the LUN, if not (see unit).
;
; OUTPUT:
;    error     : error if ne 0
;
; EXAMPLE:
;    see RST_READ help.
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: march 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : may 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -help example suppressed (only once in RST_READ help now).
;                    -error messages clarified.
;                   : december 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 2.0 (CAOS)
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -moved from Soft.Pack.CAOS 5.2 to new package "Utilities"
;                     of new version (7.0) of the CAOS PSE.
;-
;
function rst_openr, unit,                  $ ; file unit number
                    filename,              $ ; generic file name
                    structure,             $ ; structure prototype
                    N_STRUC=n_struc,       $ ; nb of structures within the file
                    STRUC_SIZE=struc_size, $ ; structure size (bytes)
                    GET_LUN=get_lun          ; get file unit number

error = !caos_error.ok

; build the prototype file name and data file name
sav_file  = filename+string(".sav")
data_file = filename+string(".xdr")

; check if files exist
check_file = findfile(sav_file)
if check_file[0] eq "" then begin
    message, 'prototype file '+sav_file+" doesn't exist.", /CONT
    return, -1L
endif

check_file = findfile(data_file)
if check_file[0] eq "" then begin
    message, 'data file '+data_file+" doesn't exist.", /CONT
    return, -1L
endif

; take the prototype structure from the ".sav" file
restore, FILE=sav_file & structure = inp_yyy_t

; open the file
openr, unit, data_file, GET_LUN=get_lun, ERROR=error, /XDR

if error ne 0 then begin
    message, !ERR_STRING, /CONT
    return, -2L
endif

; read the first structure
readu, unit, structure

; get the pointer position and the file size, and deduce from it the number
; of structures present in the file
struc_size = (fstat(unit)).cur_ptr & file_size = (fstat(unit)).size
n_struc = fix(file_size/struc_size)

; rewind at the beginning of the file
point_lun, unit, 0

; back to calling program
return, error
end