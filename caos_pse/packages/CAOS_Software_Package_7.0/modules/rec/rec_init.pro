; $Id: rec_init.pro,v 7.0 2016/05/19 marcel.carbillet $
;+
; NAME:
;    rec_init
;
; PURPOSE:
;    rec_init executes the initialization for the ReConstructor and Conjugation
;    (REC) module, that is:
;
;       0- check the formal validity of the input/output structure
;       1- initialize the output structure out_com_t
;
; CATEGORY:
;    module's initialisation routine
;
; CALLING SEQUENCE:
;    error = rec_init(inp_mes_t, $
;                     out_com_t, $
;                     par,       $
;                     INIT=init  )
;
; INPUTS/OUTPUTS/KEYWORDS/ETC.:
;    see rec.pro's help for a detailed description.
;
; MODIFICATION HISTORY:
;    program written: june 2002,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it].
;    modification   : november 2002,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -useless variable n_mat eliminated.
;                    -variable n_modes is now also a parameter.
;                   : january/february 2003,
;                     Marcel Carbillet (OAA) [marcel@arcetri.astro.it]:
;                    -"mod_type"->"mod_name"
;                     (for version 4.0 of the whole Software System CAOS).
;                    -variable calibration eliminated (useless).
;                    -"calib_file" now splitted into "mirdef_file" and "matint_file"
;                    -atmosphere-type output eliminated (became useless wrt to command
;                     output + use of new module DMC).
;                    -module's name from RCC to REC (eliminating old module REC).
;                   : january 2005,
;                     Stefan Hippler (MPIA) [hippler@mpia-hd.mpg.de],
;                     Marcel Carbillet (LUAN) [marcel.carbillet@unice.fr]:
;                    -LAPACK la_svd introduced in alternative to standard svdc
;                    -plots now show the normalized singular values as a function
;                     of the number of modes for the number of modes that were
;                     calibrated.
;                   : january 2011,
;                     Marcel Carbillet (Fizeau) [marcel.carbillet@unice.fr]:
;                    -no more actual duplication of DEF into mirdef and MATINT into
;                     matr by using the "temporary" command - avoiding a possibly
;                     useless huge time-consuming and memory-demanding process.
;                   : may 2016,
;                     Marcel Carbillet (Lagrange) [marcel.carbillet@unice.fr]:
;                    -adapted to Soft. Pack. CAOS 7.0.
;-
;
function rec_init, inp_mes_t, $
                   out_com_t, $
                   par,       $
                   INIT=init

; CAOS global common block
common caos_block, tot_iter, this_iter
 
; error code initialization
error = !caos_error.ok
 
; retrieve the module's informations
info = rec_info()
 
; get the individual output structure types
if info.out_type ne '' then out_type = str_sep(info.out_type,",")

; STANDARD CHECKS
;
; compute and test the requested number of rec arguments
n_par = 1  ; the parameter structure is always present within the arguments
if info.inp_type ne '' then begin
   inp_type = str_sep(info.inp_type,",")
   n_inp    = n_elements(inp_type)
endif else n_inp = 0
if info.out_type ne '' then begin
   out_type = str_sep(info.out_type,",")
   n_out    = n_elements(out_type)
endif else n_out = 0
n_par = n_par + n_inp + n_out
if n_params() ne n_par then message, 'wrong number of arguments'

; test the parameter structure
if test_type(par, /STRUCTURE, N_ELEMENTS=n) then $
   message, 'REC error: par must be a structure'
if n ne 1 then message, 'REC error: par cannot be a vector of structures'
if strlowcase(tag_names(par, /STRUCTURE_NAME)) ne info.mod_name then $
   message, 'par must be a parameter structure for the module REC'

; check the input arguments
; test if any optional input exists
if n_inp gt 0 then begin
   inp_opt = info.inp_opt
endif

dummy = test_type(inp_mes_t, TYPE=type)
if type eq 0 then begin         ; undefined variable
   inp_mes_t = $
      {        $
      data_type  : inp_type[0],         $
      data_status: !caos_data.not_valid $
      }
endif
if test_type(inp_mes_t, /STRUC, N_EL=n, TYPE=type) then $
   message, 'REC error: wrong definition for the first input.'
if n ne 1 then message, $
   'REC error: input cannot be a vector of structures'

; test the data type
if inp_type[0] ne 'gen_t' then begin
   if inp_mes_t.data_type ne inp_type[0] then                $
      message, 'wrong input data type: '+inp_mes_t.data_type $
              +' ('+inp_type[0]+' expected).'
endif

if inp_mes_t.data_status eq !caos_data.not_valid and not inp_opt[0] then $
      message, 'undefined input is not allowed'
;
; END OF STANDARD CHECKS

; RESTORING OR BUILDING THE direct RECONSTRUCTOR
;
if par.save_wuv eq 1 then begin

   restore, FILE=par.save_wuv_file
   n_modes_max = (size(w))[1]
   n_modes = par.n_modes
   if n_modes gt n_modes_max then begin
      print, "==============================================================="
      print, " REC WARNING:                                                  "
      print, " the number of modes corrected is "+strtrim(n_modes_max,2)+" !!"
      print, " (**NOT** "+strtrim(n_modes,2)+" !!)                           "
      print, "==============================================================="
      n_modes = n_modes_max
   endif

endif else begin

   restore, FILE=par.mirdef_file, /VERBOSE  ; importing deformations array DEF
   restore, FILE=par.matint_file, /VERBOSE  ; importing int. matrix MATINT
   n_modes_max = (size(MATINT))[1]
   n_modes = par.n_modes
   if n_modes gt n_modes_max then begin
      print, "==============================================================="
      print, " REC WARNING:                                                  "
      print, " the number of modes corrected is "+strtrim(n_modes_max,2)+" !!"
      print, " (**NOT** "+strtrim(n_modes,2)+" !!)                           "
      print, "==============================================================="
      n_modes = n_modes_max
   endif
   mirdef = (temporary(DEF))[*, *, 0:n_modes-1]
   matr   = (temporary(MATINT))[0:n_modes-1,*]

   if par.svd_type eq 0 then svdc, matr, w, u, v, /DOUBLE $
   else la_svd, matr, w, u, v, /DOUBLE

   window, /FREE
   win_index0 = !D.WINDOW
   plot_io, indgen(n_modes)+1, w/max(w), PSYM=2,                  $
            TIT="normalized singular values of mirror modes-to-commands matrix", $
            YTIT="normalized singular values", XTIT="mirror modes"
   print, "minimum value of w is "+strtrim(min(w),2)
   print, "maximum value of w is "+strtrim(max(w),2)
   print, "last value of w is "+strtrim(w[n_elements(w)-1],2)
   print, "approximate condition number is "+strtrim(max(w)/min(w),2)

   print, '(warning: the "condition nb" is the inverse of the normalized min. value seen on the plot)'
   read,cond_nb,PROMPT = 'maximum allowed "condition number" ? --> '
   idx = where(max(w)/abs(w) GE cond_nb,count)
   if count NE 0 THEN BEGIN
      print, "max. nb of modes to cut out: ", count
      res='n'
      for i=0,count-1 do begin
         print, '-> mode nb/index: ', idx[i], ' - cond. nb: ', max(w)/w[idx[i]]
         if res ne 'a' then begin
            dim=(size(mirdef))[1]
            pupil=makepupil(dim,dim,0.,XC=(dim-1)/2.,YC=(dim-1)/2.)
            modecon=fltarr(dim,dim)
            for k=0,n_modes-1 do modecon=modecon+v[idx[i],k]*mirdef[*,*,k]*pupil
            tvscl, modecon
         endif
         print, 'do you want to skip this mode ?'
         print, '[y=yes, a=skip all]'
         if res ne 'a' then res = get_kbrd(1)
         if res eq 'a' then w[idx[i]]=0. else if res eq 'y' then w[idx[i]] = 0.
      endfor
   endif

   idx = where(w NE 0., count)
   print, "... using ",count," modes"

   if par.save_wuv eq 0 then save, w, u, v, FILE=par.save_wuv_file

endelse

; FILL THE INIT STRUCTURE
;
z_rec = fltarr(n_modes)

init = $                 ; init structure definition
   {   $
   u       : u,        $
   v       : v,        $
   w       : w,        $
   z_rec   : z_rec,    $ ; vector of reconstructed modes
   n_modes : n_modes   $ ; nb of rec'd modes
   }

; INITIALIZE THE OUTPUT STRUCTURES
;
out_com_t = $
   {        $
   data_type  : out_type[0],      $
   data_status: !caos_data.valid, $
   command    : init.z_rec,       $
   flag       : 0,                $
   mod2com    : 0.,               $
   mode_idx   : 0.,               $
   meas       : inp_mes_t.meas    $
   }

return, error
end