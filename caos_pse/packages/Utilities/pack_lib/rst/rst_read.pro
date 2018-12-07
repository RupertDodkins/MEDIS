; $Id: rst_read.pro,v 7.0 2016/05/03 marcel.carbillet@unice.fr $
;+
; NAME:
;    rst_read
;
; CATEGORY
;    utility module routine
;
; CALLING PROCEDURE:
;    error = rst_read(unit,                $
;                     structure,           $
;                     STRUC_NB=struc_nb,   $
;                     STRUC_SIZE=struc_size)
;
; PURPOSE:
;    this utility permits to read a structure contained in a saved (using the
;    module SAV with format XDR) file containing a certain number of these structures.
;    it has to be used after opening the file using the other utility rst_openr.
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
;
; OUTPUT INCLUDED IN INPUT:
;    structure : named variable. the output structure.
;
; KEYWORDS:
;    STRUC_NB  : desired output structure number within the file.
;    STRUC_SIZE: size of the output structure (bytes).
;
; OUTPUT:
;    error     :  error if ne 0
;
; EXAMPLE:
;    ; pick-up the *generic* file name using the IDL dialog_pickfile function:
;    ; (don't forget to edit the *generic* file name, with no extension) 
;    filename=dialog_pickfile()
;
;    ; open the file and print the unit got using GET_LUN, the number and the
;    ; size of each structure contained in the file, and have a look at the
;    ; prototype structure:
;    print, rst_openr(unit, /GET_LUN,        $ ; to get unit
;                     filename,              $ ; the generic file name
;                     structure,             $ ; to get the prototype structure
;                     N_STRUC=n_struc,       $ ; to get the nb of structures
;                     STRUC_SIZE=struc_size) $ ; to get the size of each struc.
;         , unit                             $
;         , n_struc                          $
;         , struc_size
;    help, structure
;
;    ; read the desired structure and have a look at it:
;    print, rst_read(unit,                  $ ; unit from rst_openr
;                    structure,             $ ; proto. struc. from rst_openr
;                    STRUC_SIZE=struc_size, $ ; struc. size from rst_openr
;                    STRUC_NB=3)              ; to get the 3rd structure
;    help, structure
;
;    ; close the unit after all:
;    free_lun, unit
;
; ROUTINE MODIFICATION HISTORY:
;    routine written: march 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modifications  : may 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it],
;                     Armando Riccardi (OAA) [riccardi@arcetri.astro.it]:
;                    -useless input "filename" eliminated.
;                    -help clarified.
;                   : december 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 2.0 (CAOS).
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -moved from Soft.Pack.CAOS 5.2 to new package "Utilities"
;                     of new version (7.0) of the CAOS PSE.
;                    -help improved.
;-
;
function rst_read, unit,              $
                   structure,         $
                   STRUC_NB=struc_nb, $
                   STRUC_SIZE=struc_size

; error code initialisation
error = !caos_error.ok

; check the keywords
if (n_elements(struc_nb) eq 0) then struc_nb = 1

if (struc_nb le 0) then begin

   print, "structure number MUST BE greater than or equal to 1"
   error = -1L
   return, error

endif else begin

   if (n_elements(struc_size) eq 0) then begin

      print, "the structure size keyword MUST BE filled"
      error = -1L
      return, error

   endif else if (struc_size le 0) then begin

      print, "the structure MUST BE greater than 0"
      error = -1L
      return, error

   endif

endelse

; set the pointer position to the beginning of the desired structure
if (struc_nb gt 1) then point_lun, unit, (struc_nb-1)*struc_size

; read the desired structure
readu, unit, structure

; back to calling program
return, error
end