; $Id: sav_prog.pro,v 7.0 2016/05/03 marcel.carbillet $
;
;+
; NAME:
;    sav_prog
;
; PURPOSE:
;    sav_prog represents the scientific algorithm for the data
;    SAVing (SAV) module.
;
; CATEGORY:
;    module's program routine
;
; CALLING SEQUENCE:
;    error = sav_prog(inp_yyy_t, $ ; yyy_t input structure
;                     par,       $ ; parameters structure
;                     INIT=init  ) ; initialisation structure
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.:
;       see module help for a detailed description. 
;
; ROUTINE MODIFICATION HISTORY: 
;    routine written: march 1999,
;                     Simone Esposito (OAA) [esposito@arcetri.astro.it].
;    modifications  : march 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -the file name is now a generic one, the data file is
;                     now a ".xdr" file.
;                   : june 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -there is now a dedicated counter (counter_run) for the
;                     running steps only.
;                    -added a control to know if save of the data was
;                     actually asked for during the running steps (and not
;                     only during the calibration steps).
;                    -unit closed using "free_lun" instead of "close" (since
;                     "get_lun" is used in sav_init.pro).
;                   : december 1999,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -adapted to version 2.0 (CAOS) => simplified.
;                   : may 2016,
;                     Ulysse Perruchon-Monge & Adama Sy (Dépt.Physique UNS),
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -moved from Soft.Pack.CAOS 5.2 to new package "Utilities"
;                     of new version (7.0) of the CAOS PSE,
;                    -simple IDL "save" format and FITS format added.
;                    -useless init.counter eliminated (this_iter used instead).
;-
;
function sav_prog, inp_yyy_t, $
                   par,       $
                   INIT=init

common caos_block, tot_iter, this_iter

; initialization of the error code: no error as default
error = !caos_error.ok

; program itself
if inp_yyy_t.data_status EQ !caos_data.valid then begin

  ; .xdr case
  if par.format eq 0 then begin
     if init.unit_data ne 0 then begin
        if (this_iter mod par.iteration EQ 0) then begin
           openw, init.unit_data, par.data_file+".xdr", /APPEND, /XDR
           writeu, init.unit_data, inp_yyy_t
           free_lun, init.unit_data
        endif
     endif
   endif

   ; simple .sav case 
   if par.format eq 1 then begin
      if (this_iter mod par.iteration EQ 0) then begin
         data = inp_yyy_t
         save, FILE=par.data_file+strtrim(this_iter,2)+".sav", data
      endif
   endif

   ; .fits case 
   if par.format eq 2 then begin
      if (this_iter mod par.iteration EQ 0) then $
      mwrfits, inp_yyy_t, par.data_file+strtrim(this_iter,2)+".fits"
   endif

endif 

; back to calling program
return, error
end