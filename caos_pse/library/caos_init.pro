; $Id: caos_init.pro,v 7.0 2016/06/20 marcel.carbillet $
;+
; CAOS initialisation procedure
;
; MODIFICATION HISTORY:
;    program written: 1998/1999,
;                     Armando   Riccardi   (OAA) [riccardi@arcetri.astro.it],
;                     Marcel    Carbillet  (OAA) [marcel@arcetri.astro.it],
;                     Francoise Delplancke (ESO) [fdelplan@eso.org].
;    modifications  : november 1999,
;                     Marcel Carbillet (OAA) [marcel@astro.arcetri.it]:
;                    -adapted to version 2.0 (CAOS).
;                   : november 1999,
;                     Bruno Femenia (OAA) [bfemenia@astro.arcetri.it]:
;                    -adding tags for MCA and TCE error codes.
;                   : may 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -CAOS prompt added.
;                   : september 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -environment variable !CAOS_WORK added.
;                   : december 2000,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -modified for cAOs 3.0 (the new package-oriented version).
;                   : june 2002,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -tag "package" added for CAOS Application Builder 3.1,
;                    -a few minor modifications for cAOs Software Package 3.6.
;                   : january/february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -completely restructured for version 4.0 of the whole
;                     CAOS software system: error codes relevant only
;                     to a given module of a given package eliminated,
;                     tags of variable caos_env linked to the definition of
;                     one package only eliminated (now all the packages can
;                     be used together).
;                   : may-june 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -global variable browser eliminated (became useless with
;                     the use of "online_help" in the GUI of each module),
;                    -global variable exp_delim added (now used by run.pro).
;-
;
pro caos_init

; CAOS debugging variable
; !caos_debug eq 0B: delivered release
; !caos_debug eq 1B: debugging release
;
defsysv, "!caos_debug", EXISTS=exists
if not exists then defsysv, "!caos_debug", 0B

; CAOS data stati
;
caos_data = $
   {        $
   valid    : 0, $    ; data are valid and can be used
   wait     : 1, $    ; data are not available yet, wait for next iteration
   not_valid: 2  $    ; data are not valid: no module produces these data
   }
defsysv, "!caos_data", EXISTS=exists
if not exists then defsysv, "!caos_data", caos_data

; general error codes structure
;
caos_error = $
   {         $
   ok                  :    0L, $ ; all ok (initialisation value)
   cancel              : -100L, $ ; exit GUI pressing cancel
   file_not_found      : -150L, $ ; the file name was not found
   wrong_file_format   : -160L, $ ; file format not supported
   incorrect_sav_syntax: -170L, $ ; when saving under SAV, the
                                  ; variables must have specific
                                  ; names. here it is not correct
   not_yet_implemented : -200L, $ ; feature not yet implemented
   non_ident_par       : -300L, $ ; restored and GUI parameters
                                  ; not identical
   non_ident_annex     : -310L, $ ; restored and GUI input annex
                                  ; parameters not identical
   unexpected          : -666L, $ ; should not occur !!
   module_error        : -777L  $ ; some error relevant only to a
                                  ; given module of a given package
   }

defsysv, "!caos_error", EXISTS=exists
if not exists then defsysv, "!caos_error", caos_error

; some definitions of environment variables
;
case !VERSION.OS_FAMILY of
   "unix": begin
      path_delim   = "/"
      expand_delim = ":"
   end
   "Windows": begin
      path_delim   = "\"
      expand_delim = ";"
   end
   "vms": begin
      path_delim   = "."
      expand_delim = ","
   end
   "MacOS": begin
      path_delim   = ":"
      expand_delim = ","
   end
   else: message, "the operative system of the family "+!VERSION.OS_FAMILY $ 
                   +" is not supported."
endcase

caos_root = getenv("CAOS_ROOT")
if caos_root eq "" then $
  message, "the CAOS_ROOT operative system variable is not defined"

caos_work = getenv("CAOS_WORK")
if caos_work eq "" then $
  message, "the CAOS_WORK operative system variable is not defined"

;caos_html = getenv("CAOS_HTML")
;if caos_html eq "" then $
;  message, "the CAOS_HTML operative system variable is not defined"

; environment string definitions
;
caos_env = $
   {       $
   module_len: 3,                                         $
   delim     : path_delim,                                $
   exp_delim : expand_delim,                                $
;   browser   : caos_html,                                 $
   work      : caos_work+path_delim,                      $
   root      : caos_root+path_delim,                      $
   modules   : caos_root+path_delim+"packages"+path_delim $
;   lib       : caos_root+path_delim+"lib"+path_delim      $
   }

defsysv, "!caos_env", EXISTS=exists
if not exists then defsysv, "!caos_env", caos_env

!PROMPT = "CAOS PSE 7.0 > "

cd, !caos_env.work

end